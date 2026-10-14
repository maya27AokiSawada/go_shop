"use strict";

const crypto = require("crypto");
const { GoogleAuth } = require("google-auth-library");
const {
  Environment,
  SignedDataVerifier,
} = require("@apple/app-store-server-library");
const { FieldValue, Timestamp } = require("firebase-admin/firestore");

const ANDROID_PUBLISHER_SCOPE =
  "https://www.googleapis.com/auth/androidpublisher";
const PREMIUM_PRODUCT_ID = "goshopping_premium_monthly";
const PREMIUM_MONTHLY_IOS_ID = "goshopping2_premium_monthly";
const PREMIUM_ANNUAL_PRODUCT_ID = "goshopping-premium-annual";
const PREMIUM_ANNUAL_IOS_ID = "goshopping2_premium_annual";
// 早期ダウンロード特典（Google Play の1回限りのアイテム）。アプリ内では販売せず、
// プロモーションコードの引き換えで付与する。有効期間は引き換えから1年間。
const EARLY_DOWNLOAD_BENEFIT_PRODUCT_ID = "goshopping_onetime_1000";
const GOOGLE_PRODUCT_PURCHASE_STATE_PURCHASED = 0;
const GOOGLE_PRODUCT_ACKNOWLEDGED = 1;
const ACTIVE_GOOGLE_STATES = new Set([
  "SUBSCRIPTION_STATE_ACTIVE",
  "SUBSCRIPTION_STATE_IN_GRACE_PERIOD",
  "SUBSCRIPTION_STATE_CANCELED",
]);
const APPLE_ROOT_CA_URLS = [
  "https://www.apple.com/certificateauthority/AppleRootCA-G3.cer",
  "https://www.apple.com/certificateauthority/AppleRootCA-G2.cer",
  "https://www.apple.com/appleca/AppleIncRootCertificate.cer",
];

let appleRootCertificatesPromise;

function fingerprint(value) {
  return crypto.createHash("sha256").update(value).digest("hex");
}

function requireNonEmptyString(value, fieldName, maxLength = 200000) {
  if (typeof value !== "string" || value.trim().length === 0) {
    throw new ReceiptValidationError(
      "invalid-argument",
      `${fieldName} は必須です`,
    );
  }
  if (value.length > maxLength) {
    throw new ReceiptValidationError(
      "invalid-argument",
      `${fieldName} が長すぎます`,
    );
  }
  return value.trim();
}

class ReceiptValidationError extends Error {
  constructor(code, message) {
    super(message);
    this.name = "ReceiptValidationError";
    this.code = code;
  }
}

function evaluateGoogleSubscription(subscription, expectedProductId, now) {
  const lineItems = Array.isArray(subscription.lineItems)
    ? subscription.lineItems
    : [];
  const matchingItems = lineItems.filter(
    (item) => item.productId === expectedProductId,
  );
  if (matchingItems.length === 0) {
    throw new ReceiptValidationError(
      "permission-denied",
      "購入商品がPremiumプランと一致しません",
    );
  }

  const expiryTimes = matchingItems
    .map((item) => Date.parse(item.expiryTime || ""))
    .filter(Number.isFinite);
  const expiryMillis = expiryTimes.length === 0 ? 0 : Math.max(...expiryTimes);
  const activeState = ACTIVE_GOOGLE_STATES.has(subscription.subscriptionState);
  if (!activeState || expiryMillis <= now.getTime()) {
    throw new ReceiptValidationError(
      "failed-precondition",
      "Google Playサブスクリプションは有効ではありません",
    );
  }

  return {
    active: true,
    expiresAt: new Date(expiryMillis),
    storeStatus: subscription.subscriptionState,
    needsAcknowledgement:
      subscription.acknowledgementState === "ACKNOWLEDGEMENT_STATE_PENDING",
  };
}

function evaluateAppleTransaction(transaction, expectedProductId, now) {
  if (transaction.productId !== expectedProductId) {
    throw new ReceiptValidationError(
      "permission-denied",
      "購入商品がPremiumプランと一致しません",
    );
  }
  if (!transaction.transactionId || !transaction.originalTransactionId) {
    throw new ReceiptValidationError(
      "failed-precondition",
      "App Store取引IDを確認できません",
    );
  }
  if (
    transaction.revocationDate ||
    transaction.revocationReason !== undefined
  ) {
    throw new ReceiptValidationError(
      "failed-precondition",
      "App Store購入は取り消されています",
    );
  }
  if (
    !Number.isFinite(transaction.expiresDate) ||
    transaction.expiresDate <= now.getTime()
  ) {
    throw new ReceiptValidationError(
      "failed-precondition",
      "App Storeサブスクリプションは有効ではありません",
    );
  }

  return {
    active: true,
    expiresAt: new Date(transaction.expiresDate),
    storeStatus: transaction.environment || "unknown",
    originalTransactionId: transaction.originalTransactionId,
    transactionId: transaction.transactionId,
    storeAcknowledged: false,
  };
}

async function verifyGooglePurchase({
  packageName,
  productId,
  purchaseToken,
  now = new Date(),
  authClient,
}) {
  const token = requireNonEmptyString(purchaseToken, "verificationData", 10000);
  const client =
    authClient ||
    (await new GoogleAuth({ scopes: [ANDROID_PUBLISHER_SCOPE] }).getClient());
  const getUrl =
    "https://androidpublisher.googleapis.com/androidpublisher/v3/" +
    `applications/${encodeURIComponent(packageName)}/` +
    `purchases/subscriptionsv2/tokens/${encodeURIComponent(token)}`;
  const response = await client.request({ url: getUrl, method: "GET" });
  const evaluation = evaluateGoogleSubscription(response.data, productId, now);

  return {
    ...evaluation,
    receiptKey: fingerprint(`google_play:${token}`),
    linkedReceiptKey: response.data.linkedPurchaseToken
      ? fingerprint(`google_play:${response.data.linkedPurchaseToken}`)
      : null,
    storeAcknowledged: !evaluation.needsAcknowledgement,
  };
}

/**
 * subscriptionsv2 の生レスポンスを取得する（有効性判定はしない）。
 * RTDN 受信時に「現在のストア状態」を能動照会するために使う。
 */
async function fetchGoogleSubscriptionV2({
  packageName,
  purchaseToken,
  authClient,
}) {
  const token = requireNonEmptyString(purchaseToken, "purchaseToken", 10000);
  const client =
    authClient ||
    (await new GoogleAuth({ scopes: [ANDROID_PUBLISHER_SCOPE] }).getClient());
  const url =
    "https://androidpublisher.googleapis.com/androidpublisher/v3/" +
    `applications/${encodeURIComponent(packageName)}/` +
    `purchases/subscriptionsv2/tokens/${encodeURIComponent(token)}`;
  const response = await client.request({ url, method: "GET" });
  return response.data;
}

async function acknowledgeGooglePurchase({
  packageName,
  productId,
  purchaseToken,
  authClient,
}) {
  const token = requireNonEmptyString(purchaseToken, "verificationData", 10000);
  const client =
    authClient ||
    (await new GoogleAuth({ scopes: [ANDROID_PUBLISHER_SCOPE] }).getClient());
  const acknowledgeUrl =
    "https://androidpublisher.googleapis.com/androidpublisher/v3/" +
    `applications/${encodeURIComponent(packageName)}/purchases/` +
    `subscriptions/${encodeURIComponent(productId)}/tokens/` +
    `${encodeURIComponent(token)}:acknowledge`;
  await client.request({
    url: acknowledgeUrl,
    method: "POST",
    data: {},
  });
}

/** 早期ダウンロード特典の失効日時（引き換え日時の1年後）。 */
function earlyDownloadBenefitExpiry(purchaseTimeMillis) {
  const expiresAt = new Date(purchaseTimeMillis);
  expiresAt.setUTCFullYear(expiresAt.getUTCFullYear() + 1);
  return expiresAt;
}

function evaluateGoogleOneTimeProduct(purchase, now) {
  if (purchase.purchaseState !== GOOGLE_PRODUCT_PURCHASE_STATE_PURCHASED) {
    throw new ReceiptValidationError(
      "failed-precondition",
      "Google Playの購入が完了していません",
    );
  }
  const purchaseTimeMillis = Number(purchase.purchaseTimeMillis);
  if (!Number.isFinite(purchaseTimeMillis) || purchaseTimeMillis <= 0) {
    throw new ReceiptValidationError(
      "failed-precondition",
      "Google Playの購入日時を確認できません",
    );
  }
  const expiresAt = earlyDownloadBenefitExpiry(purchaseTimeMillis);
  if (expiresAt.getTime() <= now.getTime()) {
    throw new ReceiptValidationError(
      "failed-precondition",
      "早期ダウンロード特典の有効期間は終了しています",
    );
  }

  return {
    active: true,
    purchaseType: "purchase",
    expiresAt,
    storeStatus: "PURCHASED",
    needsAcknowledgement:
      purchase.acknowledgementState !== GOOGLE_PRODUCT_ACKNOWLEDGED,
  };
}

/** 1回限りのアイテム（早期ダウンロード特典）を purchases.products API で検証する。 */
async function verifyGoogleOneTimePurchase({
  packageName,
  productId,
  purchaseToken,
  now = new Date(),
  authClient,
}) {
  const token = requireNonEmptyString(purchaseToken, "verificationData", 10000);
  const client =
    authClient ||
    (await new GoogleAuth({ scopes: [ANDROID_PUBLISHER_SCOPE] }).getClient());
  const getUrl =
    "https://androidpublisher.googleapis.com/androidpublisher/v3/" +
    `applications/${encodeURIComponent(packageName)}/purchases/` +
    `products/${encodeURIComponent(productId)}/tokens/` +
    `${encodeURIComponent(token)}`;
  const response = await client.request({ url: getUrl, method: "GET" });
  const evaluation = evaluateGoogleOneTimeProduct(response.data, now);

  return {
    ...evaluation,
    receiptKey: fingerprint(`google_play:${token}`),
    linkedReceiptKey: null,
    storeAcknowledged: !evaluation.needsAcknowledgement,
  };
}

async function acknowledgeGoogleProductPurchase({
  packageName,
  productId,
  purchaseToken,
  authClient,
}) {
  const token = requireNonEmptyString(purchaseToken, "verificationData", 10000);
  const client =
    authClient ||
    (await new GoogleAuth({ scopes: [ANDROID_PUBLISHER_SCOPE] }).getClient());
  const acknowledgeUrl =
    "https://androidpublisher.googleapis.com/androidpublisher/v3/" +
    `applications/${encodeURIComponent(packageName)}/purchases/` +
    `products/${encodeURIComponent(productId)}/tokens/` +
    `${encodeURIComponent(token)}:acknowledge`;
  await client.request({
    url: acknowledgeUrl,
    method: "POST",
    data: {},
  });
}

/**
 * 有効期間（1年間）を過ぎた早期ダウンロード特典を free に戻す。
 * 1回限りのアイテムはストアから失効通知が届かないため、スケジュール実行で反映する。
 */
async function expireEarlyDownloadBenefits({ db, now = new Date() }) {
  const snapshot = await db
    .collection("users")
    .where("purchaseType", "==", "purchase")
    .get();

  let expired = 0;
  for (const doc of snapshot.docs) {
    const verification = doc.data().purchaseVerification || {};
    const expiresAtMillis =
      typeof verification.expiresAt?.toMillis === "function"
        ? verification.expiresAt.toMillis()
        : 0;
    if (
      verification.productId !== EARLY_DOWNLOAD_BENEFIT_PRODUCT_ID ||
      expiresAtMillis <= 0 ||
      expiresAtMillis > now.getTime()
    ) {
      continue;
    }

    await doc.ref.set(
      {
        purchaseType: "free",
        purchaseVerification: {
          ...verification,
          status: "expired",
          downgradedAt: FieldValue.serverTimestamp(),
        },
        updatedAt: FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
    if (verification.receiptFingerprint) {
      await db
        .collection("purchaseReceipts")
        .doc(verification.receiptFingerprint)
        .set(
          { status: "expired", expiredAt: FieldValue.serverTimestamp() },
          { merge: true },
        );
    }
    expired++;
  }
  return { expired };
}

async function loadAppleRootCertificates(fetchImpl = fetch) {
  if (!appleRootCertificatesPromise) {
    appleRootCertificatesPromise = Promise.all(
      APPLE_ROOT_CA_URLS.map(async (url) => {
        const response = await fetchImpl(url);
        if (!response.ok) {
          throw new Error(`Apple root CA download failed: ${response.status}`);
        }
        return Buffer.from(await response.arrayBuffer());
      }),
    );
  }
  return appleRootCertificatesPromise;
}

async function verifyApplePurchase({
  bundleId,
  appAppleId,
  productId,
  signedTransaction,
  now = new Date(),
  rootCertificates,
}) {
  const jws = requireNonEmptyString(
    signedTransaction,
    "verificationData",
    200000,
  );
  if (jws.split(".").length !== 3) {
    throw new ReceiptValidationError(
      "failed-precondition",
      "StoreKit 2の署名済み取引データが必要です",
    );
  }

  const roots = rootCertificates || (await loadAppleRootCertificates());
  const environments = [];
  if (Number.isInteger(appAppleId) && appAppleId > 0) {
    environments.push({ environment: Environment.PRODUCTION, appAppleId });
  }
  environments.push({
    environment: Environment.SANDBOX,
    appAppleId: undefined,
  });

  let lastError;
  for (const candidate of environments) {
    try {
      const verifier = new SignedDataVerifier(
        roots,
        true,
        candidate.environment,
        bundleId,
        candidate.appAppleId,
      );
      const transaction = await verifier.verifyAndDecodeTransaction(jws);
      const evaluation = evaluateAppleTransaction(transaction, productId, now);
      return {
        ...evaluation,
        receiptKey: fingerprint(
          `app_store:${transaction.originalTransactionId}`,
        ),
      };
    } catch (error) {
      lastError = error;
    }
  }

  throw new ReceiptValidationError(
    "permission-denied",
    "App Store取引を検証できません",
  );
}

async function persistVerifiedEntitlement({
  db,
  uid,
  platform,
  productId,
  verification,
}) {
  const receiptRef = db
    .collection("purchaseReceipts")
    .doc(verification.receiptKey);
  const linkedReceiptRef = verification.linkedReceiptKey
    ? db.collection("purchaseReceipts").doc(verification.linkedReceiptKey)
    : null;
  const userRef = db.collection("users").doc(uid);

  await db.runTransaction(async (transaction) => {
    const existingReceipt = await transaction.get(receiptRef);
    const linkedReceipt = linkedReceiptRef
      ? await transaction.get(linkedReceiptRef)
      : null;
    if (existingReceipt.exists && existingReceipt.data().uid !== uid) {
      throw new ReceiptValidationError(
        "already-exists",
        "この購入は別のアカウントに関連付けられています",
      );
    }
    if (linkedReceipt?.exists && linkedReceipt.data().uid !== uid) {
      throw new ReceiptValidationError(
        "already-exists",
        "変更前の購入は別のアカウントに関連付けられています",
      );
    }

    transaction.set(
      receiptRef,
      {
        uid,
        platform,
        productId,
        status: "active",
        expiresAt: Timestamp.fromDate(verification.expiresAt),
        storeStatus: verification.storeStatus,
        originalTransactionId: verification.originalTransactionId || null,
        transactionId: verification.transactionId || null,
        verifiedAt: FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
    transaction.set(
      userRef,
      {
        purchaseType: verification.purchaseType || "subscribe",
        purchaseVerification: {
          platform,
          productId,
          status: "active",
          expiresAt: Timestamp.fromDate(verification.expiresAt),
          receiptFingerprint: verification.receiptKey,
          verifiedAt: FieldValue.serverTimestamp(),
        },
        updatedAt: FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
  });
}

module.exports = {
  ACTIVE_GOOGLE_STATES,
  EARLY_DOWNLOAD_BENEFIT_PRODUCT_ID,
  PREMIUM_PRODUCT_ID,
  PREMIUM_MONTHLY_IOS_ID,
  PREMIUM_ANNUAL_PRODUCT_ID,
  PREMIUM_ANNUAL_IOS_ID,
  ReceiptValidationError,
  acknowledgeGoogleProductPurchase,
  acknowledgeGooglePurchase,
  evaluateAppleTransaction,
  evaluateGoogleOneTimeProduct,
  evaluateGoogleSubscription,
  expireEarlyDownloadBenefits,
  fetchGoogleSubscriptionV2,
  fingerprint,
  persistVerifiedEntitlement,
  verifyApplePurchase,
  verifyGoogleOneTimePurchase,
  verifyGooglePurchase,
};
