"use strict";

const assert = require("node:assert/strict");
const test = require("node:test");
const {
    FAMILY_MEMBER_LIMIT,
    FamilyCouponError,
    generateCouponCode,
    issueFamilyCoupon,
    normalizeCouponCode,
    redeemFamilyCoupon,
    removeFamilyMember,
    syncFamilyBenefitsOnUserWrite,
} = require("../family_coupon");

const NOW = new Date("2026-10-19T00:00:00.000Z");
const DELETE = Symbol("delete");
const deleteField = () => DELETE;

// ── 最小 Firestore フェイク（get / update / set / delete / where array-contains） ──
function makeFakeDb(seed = {}) {
    const store = new Map(Object.entries(seed));

    function snapshot(key) {
        const data = store.get(key);
        return { exists: data !== undefined, data: () => data };
    }
    function applyUpdate(key, data) {
        const prev = store.get(key);
        if (prev === undefined) throw new Error(`not-found: ${key}`);
        const next = { ...prev };
        for (const [k, v] of Object.entries(data)) {
            if (v === DELETE) delete next[k];
            else next[k] = v;
        }
        store.set(key, next);
    }
    function docRef(path, id) {
        const key = `${path}/${id}`;
        return {
            _key: key,
            async get() {
                return snapshot(key);
            },
            async delete() {
                store.delete(key);
            },
        };
    }

    return {
        store,
        collection(path) {
            return {
                doc: (id) => docRef(path, id),
                where(field, op, value) {
                    assert.equal(op, "array-contains");
                    return {
                        async get() {
                            const docs = [...store.entries()]
                                .filter(([k, d]) =>
                                    k.startsWith(`${path}/`) &&
                                    Array.isArray(d[field]) &&
                                    d[field].includes(value))
                                .map(([, d]) => ({ data: () => d }));
                            return { docs };
                        },
                    };
                },
            };
        },
        async runTransaction(fn) {
            return fn({
                async get(ref) {
                    return snapshot(ref._key);
                },
                set(ref, data) {
                    store.set(ref._key, { ...data });
                },
                update(ref, data) {
                    applyUpdate(ref._key, data);
                },
            });
        },
    };
}

function seedFamily(extra = {}) {
    return {
        "users/sponsor": { displayName: "Mom", purchaseType: "subscribe" },
        "users/child": { displayName: "Kid", purchaseType: "free" },
        "SharedGroups/g1": { ownerUid: "sponsor", allowedUid: ["sponsor", "child"] },
        ...extra,
    };
}

async function issuedDb(extra = {}) {
    const db = makeFakeDb(seedFamily(extra));
    const { code } = await issueFamilyCoupon({
        db, uid: "sponsor", now: NOW, generateCode: () => "ABCD-EFGH",
    });
    assert.equal(code, "ABCD-EFGH");
    return db;
}

async function rejects(promise, reason) {
    await assert.rejects(promise, (e) => e instanceof FamilyCouponError && e.reason === reason);
}

// ── コード ─────────────────────────────────────────────────────────────
test("generateCouponCode は XXXX-XXXX 形式で正規化できる", () => {
    const code = generateCouponCode();
    assert.match(code, /^[A-Z2-9]{4}-[A-Z2-9]{4}$/);
    assert.equal(normalizeCouponCode(code), code);
});

test("normalizeCouponCode は小文字・区切りの揺れを吸収し、不正な形式は null", () => {
    assert.equal(normalizeCouponCode(" abcd efgh "), "ABCD-EFGH");
    assert.equal(normalizeCouponCode("ABCDEFG"), null);
    assert.equal(normalizeCouponCode("ABCD-EFG0"), null); // 0 は使わない
    assert.equal(normalizeCouponCode(null), null);
});

// ── 発行 ─────────────────────────────────────────────────────────────
test("issueFamilyCoupon は Premium ユーザーに固有のクーポンを1回だけ発行する", async () => {
    const db = await issuedDb();
    assert.equal(db.store.get("familyCoupons/ABCD-EFGH").sponsorUid, "sponsor");
    const again = await issueFamilyCoupon({
        db, uid: "sponsor", generateCode: () => "ZZZZ-ZZZZ",
    });
    assert.equal(again.code, "ABCD-EFGH");
    assert.equal(again.memberLimit, FAMILY_MEMBER_LIMIT);
});

test("issueFamilyCoupon は衝突したら作り直す", async () => {
    const db = makeFakeDb(seedFamily({ "familyCoupons/AAAA-AAAA": { sponsorUid: "other" } }));
    const codes = ["AAAA-AAAA", "BBBB-BBBB"];
    const { code } = await issueFamilyCoupon({ db, uid: "sponsor", generateCode: () => codes.shift() });
    assert.equal(code, "BBBB-BBBB");
});

test("issueFamilyCoupon は subscribe 以外（早期ダウンロード特典・家族特典）には発行しない", async () => {
    for (const purchaseType of ["free", "purchase", "family"]) {
        const db = makeFakeDb({ "users/u": { purchaseType } });
        await rejects(issueFamilyCoupon({ db, uid: "u" }), "not-premium");
    }
});

// ── 入力 ─────────────────────────────────────────────────────────────
test("redeemFamilyCoupon は家族を family にし、発行者の uid を記録する", async () => {
    const db = await issuedDb();
    const result = await redeemFamilyCoupon({ db, uid: "child", code: "abcd-efgh", now: NOW });
    assert.equal(result.purchaseType, "family");
    const child = db.store.get("users/child");
    assert.equal(child.purchaseType, "family");
    assert.equal(child.familyBenefit.sponsorUid, "sponsor");
    assert.equal(child.familyBenefit.sponsorDisplayName, "Mom");
    assert.equal(db.store.get("users/sponsor").familyCoupon.members.child.displayName, "Kid");
});

test("redeemFamilyCoupon は自分で課金中の purchaseType を上書きしない", async () => {
    const db = await issuedDb({ "users/child": { displayName: "Kid", purchaseType: "purchase" } });
    await redeemFamilyCoupon({ db, uid: "child", code: "ABCD-EFGH" });
    const child = db.store.get("users/child");
    assert.equal(child.purchaseType, "purchase");
    assert.equal(child.familyBenefit.sponsorUid, "sponsor");
});

test("redeemFamilyCoupon はグループのメンバー（オーナー以外）同士でも使える", async () => {
    const db = await issuedDb({
        "SharedGroups/g1": { ownerUid: "grandma", allowedUid: ["grandma", "sponsor", "child"] },
    });
    await redeemFamilyCoupon({ db, uid: "child", code: "ABCD-EFGH" });
    assert.equal(db.store.get("users/child").purchaseType, "family");
});

test("redeemFamilyCoupon の拒否条件", async () => {
    const db = await issuedDb({
        "users/stranger": { purchaseType: "free" },
        "SharedGroups/g2": { ownerUid: "stranger", allowedUid: ["stranger"] },
        "SharedGroups/deleted": { ownerUid: "sponsor", allowedUid: ["sponsor", "exmember"], isDeleted: true },
        "users/exmember": { purchaseType: "free" },
    });
    await rejects(redeemFamilyCoupon({ db, uid: "child", code: "bad" }), "invalid-code");
    await rejects(redeemFamilyCoupon({ db, uid: "child", code: "ZZZZ-ZZZZ" }), "invalid-code");
    await rejects(redeemFamilyCoupon({ db, uid: "sponsor", code: "ABCD-EFGH" }), "own-coupon");
    await rejects(redeemFamilyCoupon({ db, uid: "stranger", code: "ABCD-EFGH" }), "not-family");
    await rejects(redeemFamilyCoupon({ db, uid: "exmember", code: "ABCD-EFGH" }), "not-family");
    await redeemFamilyCoupon({ db, uid: "child", code: "ABCD-EFGH" });
    await rejects(redeemFamilyCoupon({ db, uid: "child", code: "ABCD-EFGH" }), "already-member");
});

test("redeemFamilyCoupon は発行者の Premium が無効なら拒否する", async () => {
    const db = await issuedDb();
    db.store.set("users/sponsor", { ...db.store.get("users/sponsor"), purchaseType: "free" });
    await rejects(redeemFamilyCoupon({ db, uid: "child", code: "ABCD-EFGH" }), "sponsor-inactive");
});

test(`redeemFamilyCoupon は同時に ${FAMILY_MEMBER_LIMIT} 人まで`, async () => {
    const seed = {};
    const allowed = ["sponsor"];
    for (let i = 0; i <= FAMILY_MEMBER_LIMIT; i++) {
        seed[`users/m${i}`] = { purchaseType: "free" };
        allowed.push(`m${i}`);
    }
    seed["SharedGroups/g1"] = { ownerUid: "sponsor", allowedUid: allowed };
    const db = await issuedDb(seed);
    for (let i = 0; i < FAMILY_MEMBER_LIMIT; i++) {
        await redeemFamilyCoupon({ db, uid: `m${i}`, code: "ABCD-EFGH" });
    }
    await rejects(
        redeemFamilyCoupon({ db, uid: `m${FAMILY_MEMBER_LIMIT}`, code: "ABCD-EFGH" }),
        "limit-reached",
    );
    // 解除すると枠が空く
    await removeFamilyMember({ db, sponsorUid: "sponsor", memberUid: "m0", deleteField });
    await redeemFamilyCoupon({ db, uid: `m${FAMILY_MEMBER_LIMIT}`, code: "ABCD-EFGH" });
});

test("redeemFamilyCoupon は有効な別の家族特典があれば拒否し、停止中なら乗り換える", async () => {
    const db = await issuedDb({
        "users/sponsor2": {
            purchaseType: "subscribe",
            familyCoupon: { code: "WXYZ-WXYZ", members: { child: { displayName: "Kid" } } },
        },
        "familyCoupons/WXYZ-WXYZ": { sponsorUid: "sponsor2" },
        "users/child": {
            displayName: "Kid", purchaseType: "family",
            familyBenefit: { sponsorUid: "sponsor2" },
        },
    });
    await rejects(redeemFamilyCoupon({ db, uid: "child", code: "ABCD-EFGH" }), "other-benefit-active");

    db.store.set("users/child", { ...db.store.get("users/child"), purchaseType: "free" });
    await redeemFamilyCoupon({ db, uid: "child", code: "ABCD-EFGH" });
    assert.equal(db.store.get("users/child").familyBenefit.sponsorUid, "sponsor");
    assert.equal(db.store.get("users/sponsor2").familyCoupon.members.child, undefined);
});

// ── 解除 ─────────────────────────────────────────────────────────────
test("removeFamilyMember は特典を外して free に戻す", async () => {
    const db = await issuedDb();
    await redeemFamilyCoupon({ db, uid: "child", code: "ABCD-EFGH" });
    await removeFamilyMember({ db, sponsorUid: "sponsor", memberUid: "child", deleteField });
    const child = db.store.get("users/child");
    assert.equal(child.purchaseType, "free");
    assert.equal(child.familyBenefit, undefined);
    assert.deepEqual(db.store.get("users/sponsor").familyCoupon.members, {});
    await rejects(
        removeFamilyMember({ db, sponsorUid: "sponsor", memberUid: "child", deleteField }),
        "invalid-member",
    );
});

// ── トリガー ─────────────────────────────────────────────────────────
async function writeUser(db, uid, patch) {
    const before = db.store.get(`users/${uid}`) ?? null;
    const after = patch === null ? null : { ...before, ...patch };
    if (after) db.store.set(`users/${uid}`, after);
    else db.store.delete(`users/${uid}`);
    await syncFamilyBenefitsOnUserWrite({ db, uid, before, after, deleteField });
}

test("発行者の Premium が切れると家族は free、再開すると family に戻る（グループ脱退後も）", async () => {
    const db = await issuedDb();
    await redeemFamilyCoupon({ db, uid: "child", code: "ABCD-EFGH" });
    db.store.delete("SharedGroups/g1"); // グループから外れても特典は続く

    await writeUser(db, "sponsor", { purchaseType: "free" });
    assert.equal(db.store.get("users/child").purchaseType, "free");
    assert.equal(db.store.get("users/child").familyBenefit.sponsorUid, "sponsor");

    await writeUser(db, "sponsor", { purchaseType: "subscribe" });
    assert.equal(db.store.get("users/child").purchaseType, "family");
});

test("発行者の状態変化は自分で課金している家族の purchaseType を変えない", async () => {
    const db = await issuedDb({ "users/child": { displayName: "Kid", purchaseType: "subscribe" } });
    await redeemFamilyCoupon({ db, uid: "child", code: "ABCD-EFGH" });
    await writeUser(db, "sponsor", { purchaseType: "free" });
    assert.equal(db.store.get("users/child").purchaseType, "subscribe");
});

test("家族自身の課金が切れて free になったら、発行者が有効なら family に戻す", async () => {
    const db = await issuedDb({ "users/child": { displayName: "Kid", purchaseType: "subscribe" } });
    await redeemFamilyCoupon({ db, uid: "child", code: "ABCD-EFGH" });
    await writeUser(db, "child", { purchaseType: "free" });
    assert.equal(db.store.get("users/child").purchaseType, "family");
});

test("関係のない更新では何もしない", async () => {
    const db = await issuedDb();
    await redeemFamilyCoupon({ db, uid: "child", code: "ABCD-EFGH" });
    await writeUser(db, "sponsor", { appUIMode: 1 });
    await writeUser(db, "child", { appUIMode: 1 });
    assert.equal(db.store.get("users/child").purchaseType, "family");
});

test("発行者のアカウント削除で家族の特典とクーポンを片付ける", async () => {
    const db = await issuedDb();
    await redeemFamilyCoupon({ db, uid: "child", code: "ABCD-EFGH" });
    await writeUser(db, "sponsor", null);
    const child = db.store.get("users/child");
    assert.equal(child.purchaseType, "free");
    assert.equal(child.familyBenefit, undefined);
    assert.equal(db.store.has("familyCoupons/ABCD-EFGH"), false);
});

test("家族のアカウント削除で発行者の枠を空ける", async () => {
    const db = await issuedDb();
    await redeemFamilyCoupon({ db, uid: "child", code: "ABCD-EFGH" });
    await writeUser(db, "child", null);
    assert.deepEqual(db.store.get("users/sponsor").familyCoupon.members, {});
});
