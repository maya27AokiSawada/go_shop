"use strict";

const assert = require("node:assert/strict");
const test = require("node:test");
const {
    ReceiptValidationError,
    acknowledgeGooglePurchase,
    evaluateAppleTransaction,
    evaluateGoogleSubscription,
    fingerprint,
    persistVerifiedEntitlement,
    verifyGooglePurchase,
} = require("../receipt_verification");

const PRODUCT_ID = "goshopping_premium_monthly";
const NOW = new Date("2026-08-29T00:00:00.000Z");

test("Google Play active subscription is accepted", () => {
    const result = evaluateGoogleSubscription(
        {
            subscriptionState: "SUBSCRIPTION_STATE_ACTIVE",
            acknowledgementState: "ACKNOWLEDGEMENT_STATE_PENDING",
            lineItems: [
                {
                    productId: PRODUCT_ID,
                    expiryTime: "2026-09-29T00:00:00.000Z",
                },
            ],
        },
        PRODUCT_ID,
        NOW,
    );

    assert.equal(result.active, true);
    assert.equal(result.needsAcknowledgement, true);
    assert.equal(result.expiresAt.toISOString(), "2026-09-29T00:00:00.000Z");
});

test("Google Play canceled subscription remains active until expiry", () => {
    const result = evaluateGoogleSubscription(
        {
            subscriptionState: "SUBSCRIPTION_STATE_CANCELED",
            acknowledgementState: "ACKNOWLEDGEMENT_STATE_ACKNOWLEDGED",
            lineItems: [
                {
                    productId: PRODUCT_ID,
                    expiryTime: "2026-09-01T00:00:00.000Z",
                },
            ],
        },
        PRODUCT_ID,
        NOW,
    );

    assert.equal(result.active, true);
    assert.equal(result.needsAcknowledgement, false);
});

test("Google Play expired or mismatched subscription is rejected", () => {
    assert.throws(
        () => evaluateGoogleSubscription(
            {
                subscriptionState: "SUBSCRIPTION_STATE_EXPIRED",
                lineItems: [
                    { productId: PRODUCT_ID, expiryTime: "2026-08-01T00:00:00.000Z" },
                ],
            },
            PRODUCT_ID,
            NOW,
        ),
        ReceiptValidationError,
    );
    assert.throws(
        () => evaluateGoogleSubscription(
            {
                subscriptionState: "SUBSCRIPTION_STATE_ACTIVE",
                lineItems: [
                    { productId: "other_product", expiryTime: "2026-09-01T00:00:00.000Z" },
                ],
            },
            PRODUCT_ID,
            NOW,
        ),
        ReceiptValidationError,
    );
});

test("Apple active StoreKit 2 transaction is accepted", () => {
    const result = evaluateAppleTransaction(
        {
            productId: PRODUCT_ID,
            transactionId: "2000000000001",
            originalTransactionId: "1000000000001",
            expiresDate: Date.parse("2026-09-29T00:00:00.000Z"),
            environment: "Sandbox",
        },
        PRODUCT_ID,
        NOW,
    );

    assert.equal(result.active, true);
    assert.equal(result.originalTransactionId, "1000000000001");
});

test("Apple expired or revoked transaction is rejected", () => {
    assert.throws(
        () => evaluateAppleTransaction(
            {
                productId: PRODUCT_ID,
                transactionId: "2",
                originalTransactionId: "1",
                expiresDate: Date.parse("2026-08-01T00:00:00.000Z"),
            },
            PRODUCT_ID,
            NOW,
        ),
        ReceiptValidationError,
    );
    assert.throws(
        () => evaluateAppleTransaction(
            {
                productId: PRODUCT_ID,
                transactionId: "2",
                originalTransactionId: "1",
                expiresDate: Date.parse("2026-09-29T00:00:00.000Z"),
                revocationDate: Date.parse("2026-08-20T00:00:00.000Z"),
            },
            PRODUCT_ID,
            NOW,
        ),
        ReceiptValidationError,
    );
});

test("receipt fingerprint is deterministic and does not expose token", () => {
    const token = "sensitive-purchase-token";
    const first = fingerprint(`google_play:${token}`);
    const second = fingerprint(`google_play:${token}`);

    assert.equal(first, second);
    assert.equal(first.length, 64);
    assert.equal(first.includes(token), false);
});

test("Google verification queries v2 API and links old token", async () => {
    const requests = [];
    const authClient = {
        async request(request) {
            requests.push(request);
            if (request.method === "GET") {
                return {
                    data: {
                        subscriptionState: "SUBSCRIPTION_STATE_ACTIVE",
                        acknowledgementState: "ACKNOWLEDGEMENT_STATE_PENDING",
                        linkedPurchaseToken: "old-token",
                        lineItems: [
                            {
                                productId: PRODUCT_ID,
                                expiryTime: "2026-09-29T00:00:00.000Z",
                            },
                        ],
                    },
                };
            }
            return { data: {} };
        },
    };

    const result = await verifyGooglePurchase({
        packageName: "example.package",
        productId: PRODUCT_ID,
        purchaseToken: "new-token",
        now: NOW,
        authClient,
    });

    assert.equal(requests.length, 1);
    assert.match(requests[0].url, /subscriptionsv2\/tokens\/new-token$/);
    assert.equal(result.storeAcknowledged, false);
    assert.equal(
        result.linkedReceiptKey,
        fingerprint("google_play:old-token"),
    );
});

test("Google acknowledgement is a separate post-verification operation", async () => {
    const requests = [];
    const authClient = {
        async request(request) {
            requests.push(request);
            return { data: {} };
        },
    };

    await acknowledgeGooglePurchase({
        packageName: "example.package",
        productId: PRODUCT_ID,
        purchaseToken: "new-token",
        authClient,
    });

    assert.equal(requests.length, 1);
    assert.equal(requests[0].method, "POST");
    assert.match(requests[0].url, /:acknowledge$/);
});

test("receipt already bound to another Firebase user is rejected", async () => {
    const receiptKey = fingerprint("google_play:shared-token");
    const db = createFakeFirestore({
        [`purchaseReceipts/${receiptKey}`]: { uid: "other-user" },
    });

    await assert.rejects(
        persistVerifiedEntitlement({
            db,
            uid: "current-user",
            platform: "google_play",
            productId: PRODUCT_ID,
            verification: {
                receiptKey,
                expiresAt: new Date("2026-09-29T00:00:00.000Z"),
                storeStatus: "SUBSCRIPTION_STATE_ACTIVE",
            },
        }),
        (error) => error instanceof ReceiptValidationError &&
            error.code === "already-exists",
    );
    assert.equal(db.writes.length, 0);
});

test("verified entitlement stores only receipt fingerprint", async () => {
    const rawToken = "raw-secret-token";
    const receiptKey = fingerprint(`google_play:${rawToken}`);
    const db = createFakeFirestore();

    await persistVerifiedEntitlement({
        db,
        uid: "current-user",
        platform: "google_play",
        productId: PRODUCT_ID,
        verification: {
            receiptKey,
            expiresAt: new Date("2026-09-29T00:00:00.000Z"),
            storeStatus: "SUBSCRIPTION_STATE_ACTIVE",
        },
    });

    assert.equal(db.writes.length, 2);
    const serializedWrites = JSON.stringify(db.writes);
    assert.equal(serializedWrites.includes(rawToken), false);
    assert.equal(serializedWrites.includes(receiptKey), true);
});

function createFakeFirestore(initialDocuments = {}) {
    const writes = [];
    return {
        writes,
        collection(collectionName) {
            return {
                doc(documentId) {
                    return { path: `${collectionName}/${documentId}` };
                },
            };
        },
        async runTransaction(handler) {
            return handler({
                async get(reference) {
                    const data = initialDocuments[reference.path];
                    return {
                        exists: data !== undefined,
                        data: () => data,
                    };
                },
                set(reference, data, options) {
                    writes.push({ path: reference.path, data, options });
                },
            });
        },
    };
}
