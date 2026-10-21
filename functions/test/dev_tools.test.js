"use strict";

const assert = require("node:assert/strict");
const test = require("node:test");
const {
    DEV_PROJECT_ID,
    DevToolError,
    setDevPurchaseType,
} = require("../dev_tools");

function makeFakeDb(seed = {}) {
    const store = new Map(Object.entries(seed));
    return {
        store,
        collection(path) {
            return {
                doc(id) {
                    const key = `${path}/${id}`;
                    return {
                        async get() {
                            const data = store.get(key);
                            return { exists: data !== undefined, data: () => data };
                        },
                        async update(data) {
                            store.set(key, { ...store.get(key), ...data });
                        },
                    };
                },
            };
        },
    };
}

test("dev プロジェクトでは purchaseType を subscribe / free に切り替えられる", async () => {
    const db = makeFakeDb({ "users/u1": { displayName: "A", purchaseType: "free" } });

    await setDevPurchaseType({
        db,
        uid: "u1",
        projectId: DEV_PROJECT_ID,
        purchaseType: "subscribe",
    });
    assert.equal(db.store.get("users/u1").purchaseType, "subscribe");
    assert.equal(db.store.get("users/u1").displayName, "A");

    await setDevPurchaseType({
        db,
        uid: "u1",
        projectId: DEV_PROJECT_ID,
        purchaseType: "free",
    });
    assert.equal(db.store.get("users/u1").purchaseType, "free");
});

test("dev プロジェクト以外では拒否する", async () => {
    const db = makeFakeDb({ "users/u1": { purchaseType: "free" } });
    for (const projectId of ["goshopping-48db9", undefined]) {
        await assert.rejects(
            setDevPurchaseType({ db, uid: "u1", projectId, purchaseType: "subscribe" }),
            (error) => error instanceof DevToolError && error.code === "permission-denied",
        );
    }
    assert.equal(db.store.get("users/u1").purchaseType, "free");
});

test("subscribe / free 以外の purchaseType は拒否する", async () => {
    const db = makeFakeDb({ "users/u1": { purchaseType: "free" } });
    for (const purchaseType of ["family", "purchase", undefined]) {
        await assert.rejects(
            setDevPurchaseType({ db, uid: "u1", projectId: DEV_PROJECT_ID, purchaseType }),
            (error) => error instanceof DevToolError && error.code === "invalid-argument",
        );
    }
});

test("ユーザー情報がなければ拒否する", async () => {
    const db = makeFakeDb();
    await assert.rejects(
        setDevPurchaseType({
            db,
            uid: "u1",
            projectId: DEV_PROJECT_ID,
            purchaseType: "subscribe",
        }),
        (error) => error instanceof DevToolError && error.code === "failed-precondition",
    );
});
