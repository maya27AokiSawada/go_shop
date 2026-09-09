"use strict";

const assert = require("node:assert/strict");
const test = require("node:test");
const { Timestamp } = require("firebase-admin/firestore");
const {
    RtdnError,
    handlePlayRtdn,
    parseDeveloperNotification,
    resolveSubscriptionActive,
} = require("../play_rtdn");
const { fingerprint } = require("../receipt_verification");

const NOW = new Date("2026-09-09T00:00:00.000Z");
const TOKEN = "purchase-token-abc";
const RECEIPT_KEY = fingerprint(`google_play:${TOKEN}`);
const PRODUCT_ID = "goshopping_premium_monthly";

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

function pubsubMessage(obj) {
    return { data: Buffer.from(JSON.stringify(obj), "utf8").toString("base64") };
}

function subscriptionEvent(notificationType, extra = {}) {
    return pubsubMessage({
        version: "1.0",
        packageName: "net.sumomo_planning.goshopping",
        eventTimeMillis: "1757376000000",
        subscriptionNotification: {
            version: "1.0",
            notificationType,
            purchaseToken: TOKEN,
            subscriptionId: PRODUCT_ID,
            ...extra,
        },
    });
}

// ── parseDeveloperNotification ───────────────────────────────────────────
test("parseDeveloperNotification は base64 の data を復号する", () => {
    const payload = parseDeveloperNotification(pubsubMessage({ version: "1.0", packageName: "x" }));
    assert.equal(payload.packageName, "x");
});

test("parseDeveloperNotification は message.json を優先する", () => {
    const payload = parseDeveloperNotification({ json: { testNotification: { version: "1.0" } } });
    assert.ok(payload.testNotification);
});

test("parseDeveloperNotification は不正 JSON で RtdnError", () => {
    assert.throws(
        () => parseDeveloperNotification({ data: Buffer.from("not-json").toString("base64") }),
        RtdnError,
    );
});

// ── resolveSubscriptionActive ───────────────────────────────────────────
test("resolveSubscriptionActive: 有効期限が未来かつ ACTIVE なら active", () => {
    const r = resolveSubscriptionActive(
        {
            subscriptionState: "SUBSCRIPTION_STATE_ACTIVE",
            lineItems: [{ productId: PRODUCT_ID, expiryTime: "2026-10-09T00:00:00.000Z" }],
        },
        NOW,
    );
    assert.equal(r.active, true);
    assert.equal(r.expiresAt.toISOString(), "2026-10-09T00:00:00.000Z");
});

test("resolveSubscriptionActive: CANCELED でも期限内なら active", () => {
    const r = resolveSubscriptionActive(
        {
            subscriptionState: "SUBSCRIPTION_STATE_CANCELED",
            lineItems: [{ productId: PRODUCT_ID, expiryTime: "2026-09-20T00:00:00.000Z" }],
        },
        NOW,
    );
    assert.equal(r.active, true);
});

test("resolveSubscriptionActive: EXPIRED は非 active", () => {
    const r = resolveSubscriptionActive(
        {
            subscriptionState: "SUBSCRIPTION_STATE_EXPIRED",
            lineItems: [{ productId: PRODUCT_ID, expiryTime: "2026-09-01T00:00:00.000Z" }],
        },
        NOW,
    );
    assert.equal(r.active, false);
});

test("resolveSubscriptionActive: subscriptionState 欠落は例外（再送に委ねる）", () => {
    assert.throws(() => resolveSubscriptionActive({ lineItems: [] }, NOW));
});

// ── handlePlayRtdn: テスト通知 ───────────────────────────────────────────
test("テスト通知は何もせず handled=test", async () => {
    const db = makeFakeDb();
    const result = await handlePlayRtdn({
        db,
        message: pubsubMessage({ version: "1.0", packageName: "x", testNotification: { version: "1.0" } }),
        packageName: "x",
        now: NOW,
        logger: SILENT_LOGGER,
    });
    assert.equal(result.handled, "test");
    assert.equal(db.store.size, 0);
});

// ── handlePlayRtdn: RENEWED → active 更新 ────────────────────────────────
test("RENEWED はレシートとユーザーを active に更新する", async () => {
    const db = makeFakeDb({
        [`purchaseReceipts/${RECEIPT_KEY}`]: {
            uid: "user-1",
            productId: PRODUCT_ID,
            status: "active",
        },
        "users/user-1": {
            purchaseType: "subscribe",
            purchaseVerification: { receiptFingerprint: RECEIPT_KEY, status: "active" },
        },
    });

    const result = await handlePlayRtdn({
        db,
        message: subscriptionEvent(2),
        packageName: "net.sumomo_planning.goshopping",
        fetchSubscription: async () => ({
            subscriptionState: "SUBSCRIPTION_STATE_ACTIVE",
            lineItems: [{ productId: PRODUCT_ID, expiryTime: "2026-10-09T00:00:00.000Z" }],
        }),
        now: NOW,
        logger: SILENT_LOGGER,
    });

    assert.equal(result.handled, "active");
    const user = db.store.get("users/user-1");
    assert.equal(user.purchaseType, "subscribe");
    assert.equal(user.purchaseVerification.source, "rtdn");
    assert.equal(
        db.store.get(`purchaseReceipts/${RECEIPT_KEY}`).expiresAt.toDate().toISOString(),
        "2026-10-09T00:00:00.000Z",
    );
});

// ── handlePlayRtdn: EXPIRED → free へダウングレード ─────────────────────
test("EXPIRED は権限源レシートのユーザーを free に落とす", async () => {
    const db = makeFakeDb({
        [`purchaseReceipts/${RECEIPT_KEY}`]: { uid: "user-1", productId: PRODUCT_ID, status: "active" },
        "users/user-1": {
            purchaseType: "subscribe",
            purchaseVerification: { receiptFingerprint: RECEIPT_KEY, status: "active" },
        },
    });

    const result = await handlePlayRtdn({
        db,
        message: subscriptionEvent(13),
        packageName: "net.sumomo_planning.goshopping",
        fetchSubscription: async () => ({
            subscriptionState: "SUBSCRIPTION_STATE_EXPIRED",
            lineItems: [{ productId: PRODUCT_ID, expiryTime: "2026-09-01T00:00:00.000Z" }],
        }),
        now: NOW,
        logger: SILENT_LOGGER,
    });

    assert.equal(result.handled, "expired");
    assert.equal(db.store.get("users/user-1").purchaseType, "free");
    assert.equal(db.store.get(`purchaseReceipts/${RECEIPT_KEY}`).status, "expired");
});

test("REVOKED は status=revoked で free に落とす", async () => {
    const db = makeFakeDb({
        [`purchaseReceipts/${RECEIPT_KEY}`]: { uid: "user-1", productId: PRODUCT_ID },
        "users/user-1": {
            purchaseType: "subscribe",
            purchaseVerification: { receiptFingerprint: RECEIPT_KEY },
        },
    });

    const result = await handlePlayRtdn({
        db,
        message: subscriptionEvent(12),
        packageName: "net.sumomo_planning.goshopping",
        fetchSubscription: async () => ({
            subscriptionState: "SUBSCRIPTION_STATE_EXPIRED",
            lineItems: [{ productId: PRODUCT_ID, expiryTime: "2026-09-01T00:00:00.000Z" }],
        }),
        now: NOW,
        logger: SILENT_LOGGER,
    });

    assert.equal(result.handled, "revoked");
    assert.equal(db.store.get(`purchaseReceipts/${RECEIPT_KEY}`).status, "revoked");
    assert.equal(db.store.get("users/user-1").purchaseType, "free");
});

// ── handlePlayRtdn: 再購読済みユーザーは触らない ───────────────────────
test("別トークンで再購読済みなら EXPIRED でも user は free にしない", async () => {
    const db = makeFakeDb({
        [`purchaseReceipts/${RECEIPT_KEY}`]: { uid: "user-1", productId: PRODUCT_ID, status: "active" },
        "users/user-1": {
            purchaseType: "subscribe",
            purchaseVerification: { receiptFingerprint: "some-newer-receipt-key", status: "active" },
        },
    });

    await handlePlayRtdn({
        db,
        message: subscriptionEvent(13),
        packageName: "net.sumomo_planning.goshopping",
        fetchSubscription: async () => ({
            subscriptionState: "SUBSCRIPTION_STATE_EXPIRED",
            lineItems: [{ productId: PRODUCT_ID, expiryTime: "2026-09-01T00:00:00.000Z" }],
        }),
        now: NOW,
        logger: SILENT_LOGGER,
    });

    assert.equal(db.store.get("users/user-1").purchaseType, "subscribe");
    // 旧レシートには失効印だけ付く
    assert.equal(db.store.get(`purchaseReceipts/${RECEIPT_KEY}`).status, "expired");
});

// ── handlePlayRtdn: ローカルレシート無し ───────────────────────────────
test("ローカルレシートが無ければ何もしない", async () => {
    const db = makeFakeDb();
    let fetched = false;
    const result = await handlePlayRtdn({
        db,
        message: subscriptionEvent(4),
        packageName: "net.sumomo_planning.goshopping",
        fetchSubscription: async () => {
            fetched = true;
            return {};
        },
        now: NOW,
        logger: SILENT_LOGGER,
    });

    assert.equal(result.handled, "unmapped");
    assert.equal(fetched, false);
    assert.equal(db.store.size, 0);
});

// ── handlePlayRtdn: 返金通知 ───────────────────────────────────────────
test("voidedPurchaseNotification は権限を取り消す", async () => {
    const db = makeFakeDb({
        [`purchaseReceipts/${RECEIPT_KEY}`]: { uid: "user-1", productId: PRODUCT_ID },
        "users/user-1": {
            purchaseType: "subscribe",
            purchaseVerification: { receiptFingerprint: RECEIPT_KEY },
        },
    });

    const result = await handlePlayRtdn({
        db,
        message: pubsubMessage({
            version: "1.0",
            packageName: "net.sumomo_planning.goshopping",
            voidedPurchaseNotification: { purchaseToken: TOKEN, orderId: "GPA.1", productType: 1, refundType: 1 },
        }),
        packageName: "net.sumomo_planning.goshopping",
        now: NOW,
        logger: SILENT_LOGGER,
    });

    assert.equal(result.handled, "revoked");
    assert.equal(db.store.get("users/user-1").purchaseType, "free");
    assert.equal(db.store.get(`purchaseReceipts/${RECEIPT_KEY}`).storeStatus, "VOIDED");
});

// ── handlePlayRtdn: transient エラーは再送に委ねる ─────────────────────
test("subscriptionsv2 取得失敗は例外を伝播する（再送）", async () => {
    const db = makeFakeDb({
        [`purchaseReceipts/${RECEIPT_KEY}`]: { uid: "user-1", productId: PRODUCT_ID },
    });

    await assert.rejects(
        handlePlayRtdn({
            db,
            message: subscriptionEvent(2),
            packageName: "net.sumomo_planning.goshopping",
            fetchSubscription: async () => {
                throw new Error("androidpublisher 503");
            },
            now: NOW,
            logger: SILENT_LOGGER,
        }),
        /androidpublisher 503/,
    );
});
