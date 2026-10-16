"use strict";

const assert = require("node:assert/strict");
const test = require("node:test");
const {
    AppleNotificationError,
    decodeAppleNotification,
    handleAppleNotification,
    resolveAppleSubscriptionActive,
} = require("../apple_notifications");
const { fingerprint } = require("../receipt_verification");

const NOW = new Date("2027-01-10T00:00:00.000Z");
const ORIGINAL_TX_ID = "2000000123456789";
const RECEIPT_KEY = fingerprint(`app_store:${ORIGINAL_TX_ID}`);
const PRODUCT_ID = "goshopping2_premium_monthly";
const UID = "user-abc";

const SILENT_LOGGER = { log() {}, warn() {}, error() {} };

// ── 最小 Firestore フェイク ───────────────────────────────────────────────
function makeFakeDb(seed = {}) {
    const store = new Map(Object.entries(seed));
    const keyOf = (path, id) => `${path}/${id}`;

    function snapshot(k) {
        const data = store.get(k);
        return { exists: data !== undefined, data: () => data };
    }
    function docRef(path, id) {
        return {
            _key: keyOf(path, id),
            async get() {
                return snapshot(keyOf(path, id));
            },
        };
    }
    function mergeDeep(prev, next) {
        const out = { ...prev };
        for (const [k, v] of Object.entries(next)) {
            out[k] =
                v && typeof v === "object" && !Array.isArray(v) &&
                    prev[k] && typeof prev[k] === "object"
                    ? mergeDeep(prev[k], v)
                    : v;
        }
        return out;
    }

    return {
        store,
        collection(path) {
            return { doc: (id) => docRef(path, id) };
        },
        async runTransaction(fn) {
            const tx = {
                async get(ref) {
                    return snapshot(ref._key);
                },
                set(ref, data, opts) {
                    const prev = opts && opts.merge ? store.get(ref._key) || {} : {};
                    store.set(ref._key, mergeDeep(prev, data));
                },
            };
            return fn(tx);
        },
    };
}

function seededDb({ userFingerprint = RECEIPT_KEY } = {}) {
    return makeFakeDb({
        [`purchaseReceipts/${RECEIPT_KEY}`]: {
            uid: UID,
            platform: "app_store",
            productId: PRODUCT_ID,
            status: "active",
        },
        [`users/${UID}`]: {
            purchaseType: "subscribe",
            purchaseVerification: {
                platform: "app_store",
                productId: PRODUCT_ID,
                status: "active",
                receiptFingerprint: userFingerprint,
            },
        },
    });
}

function transaction(overrides = {}) {
    return {
        productId: PRODUCT_ID,
        transactionId: "2000000999999999",
        originalTransactionId: ORIGINAL_TX_ID,
        expiresDate: NOW.getTime() + 30 * 24 * 60 * 60 * 1000,
        environment: "Sandbox",
        ...overrides,
    };
}

function fakeDecode(decoded) {
    return async () => ({
        subtype: null,
        signedDate: NOW.getTime(),
        environment: "Sandbox",
        renewalInfo: null,
        ...decoded,
    });
}

async function run(db, decoded) {
    return handleAppleNotification({
        db,
        signedPayload: "a.b.c",
        bundleId: "net.sumomo-planning.goshopping",
        decode: fakeDecode(decoded),
        now: NOW,
        logger: SILENT_LOGGER,
    });
}

// ── resolveAppleSubscriptionActive ────────────────────────────────────────
test("期限内の取引は active", () => {
    const result = resolveAppleSubscriptionActive({
        notificationType: "DID_RENEW",
        transaction: transaction(),
        renewalInfo: null,
        now: NOW,
    });
    assert.equal(result.active, true);
    assert.equal(result.status, "active");
});

test("期限切れの取引は expired", () => {
    const result = resolveAppleSubscriptionActive({
        notificationType: "EXPIRED",
        transaction: transaction({ expiresDate: NOW.getTime() - 1000 }),
        renewalInfo: null,
        now: NOW,
    });
    assert.equal(result.active, false);
    assert.equal(result.status, "expired");
});

test("猶予期間中は期限切れでも active", () => {
    const graceEnd = NOW.getTime() + 3 * 24 * 60 * 60 * 1000;
    const result = resolveAppleSubscriptionActive({
        notificationType: "DID_FAIL_TO_RENEW",
        transaction: transaction({ expiresDate: NOW.getTime() - 1000 }),
        renewalInfo: { gracePeriodExpiresDate: graceEnd },
        now: NOW,
    });
    assert.equal(result.active, true);
    assert.equal(result.expiresAt.getTime(), graceEnd);
});

test("REFUND は期限内でも revoked", () => {
    const result = resolveAppleSubscriptionActive({
        notificationType: "REFUND",
        transaction: transaction(),
        renewalInfo: null,
        now: NOW,
    });
    assert.equal(result.active, false);
    assert.equal(result.status, "revoked");
});

test("revocationDate 付きの取引は revoked", () => {
    const result = resolveAppleSubscriptionActive({
        notificationType: "DID_CHANGE_RENEWAL_STATUS",
        transaction: transaction({ revocationDate: NOW.getTime() - 1000 }),
        renewalInfo: null,
        now: NOW,
    });
    assert.equal(result.status, "revoked");
});

// ── handleAppleNotification ───────────────────────────────────────────────
test("TEST 通知は記録のみ", async () => {
    const db = seededDb();
    const result = await run(db, { notificationType: "TEST", transaction: null });
    assert.equal(result.handled, "test");
});

test("DID_RENEW で期限が延長される", async () => {
    const db = seededDb();
    const result = await run(db, {
        notificationType: "DID_RENEW",
        transaction: transaction(),
    });
    assert.equal(result.handled, "active");
    const user = db.store.get(`users/${UID}`);
    assert.equal(user.purchaseType, "subscribe");
    assert.equal(user.purchaseVerification.source, "app_store_notification");
    assert.equal(
        user.purchaseVerification.expiresAt.toMillis(),
        transaction().expiresDate,
    );
});

test("EXPIRED で free に戻る", async () => {
    const db = seededDb();
    const result = await run(db, {
        notificationType: "EXPIRED",
        subtype: "VOLUNTARY",
        transaction: transaction({ expiresDate: NOW.getTime() - 1000 }),
    });
    assert.equal(result.handled, "expired");
    assert.equal(db.store.get(`users/${UID}`).purchaseType, "free");
    assert.equal(
        db.store.get(`purchaseReceipts/${RECEIPT_KEY}`).status,
        "expired",
    );
});

test("REFUND で free に戻り revoked になる", async () => {
    const db = seededDb();
    const result = await run(db, {
        notificationType: "REFUND",
        transaction: transaction({ revocationDate: NOW.getTime() - 1000 }),
    });
    assert.equal(result.handled, "revoked");
    const user = db.store.get(`users/${UID}`);
    assert.equal(user.purchaseType, "free");
    assert.equal(user.purchaseVerification.status, "revoked");
});

test("別のレシートで購読中なら user は free にしない", async () => {
    const db = seededDb({ userFingerprint: "other-receipt" });
    await run(db, {
        notificationType: "EXPIRED",
        transaction: transaction({ expiresDate: NOW.getTime() - 1000 }),
    });
    assert.equal(db.store.get(`users/${UID}`).purchaseType, "subscribe");
    assert.equal(
        db.store.get(`purchaseReceipts/${RECEIPT_KEY}`).status,
        "expired",
    );
});

test("ローカルレシートが無ければ何もしない", async () => {
    const db = makeFakeDb();
    const result = await run(db, {
        notificationType: "DID_RENEW",
        transaction: transaction(),
    });
    assert.equal(result.handled, "unmapped");
    assert.equal(db.store.size, 0);
});

test("未対応の商品IDは無視する", async () => {
    const db = seededDb();
    const result = await run(db, {
        notificationType: "EXPIRED",
        transaction: transaction({
            productId: "goshopping_premium_monthly",
            expiresDate: NOW.getTime() - 1000,
        }),
    });
    assert.equal(result.handled, "ignored");
    assert.equal(db.store.get(`users/${UID}`).purchaseType, "subscribe");
});

// ── decodeAppleNotification ───────────────────────────────────────────────
test("JWS 形式でない signedPayload は恒久エラー", async () => {
    await assert.rejects(
        decodeAppleNotification({
            signedPayload: "not-a-jws",
            bundleId: "net.sumomo-planning.goshopping",
            rootCertificates: [],
        }),
        AppleNotificationError,
    );
});

test("署名を検証できない signedPayload は恒久エラー", async () => {
    await assert.rejects(
        decodeAppleNotification({
            signedPayload: "a.b.c",
            bundleId: "net.sumomo-planning.goshopping",
            appAppleId: 1234567890,
            rootCertificates: [],
        }),
        AppleNotificationError,
    );
});
