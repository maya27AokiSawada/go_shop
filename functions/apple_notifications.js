"use strict";

const {
  Environment,
  SignedDataVerifier,
} = require("@apple/app-store-server-library");
const { FieldValue, Timestamp } = require("firebase-admin/firestore");
const {
  PREMIUM_ANNUAL_IOS_ID,
  PREMIUM_MONTHLY_IOS_ID,
  fingerprint,
  loadAppleRootCertificates,
} = require("./receipt_verification");

/**
 * App Store Server Notifications V2 の処理。
 *
 * App Store Connect の「App情報 > App Store Server Notifications」に
 * `appStoreNotifications` 関数の URL を登録すると、購読の更新・解約・失効・返金が
 * `{ signedPayload }` として POST される。`index.js` の onRequest から呼ばれる。
 *
 * 通知は uid を含まないため、`purchaseReceipts/{sha256(app_store:originalTransactionId)}`
 * に保存済みの uid で本人を特定する。初回購入がクライアント検証より先に届いた等で
 * ローカルレシートが無い場合は何もしない（クライアントの verifyPurchase が付与する）。
 */

const SUPPORTED_IOS_PRODUCT_IDS = new Set([
  PREMIUM_MONTHLY_IOS_ID,
  PREMIUM_ANNUAL_IOS_ID,
]);

// 返金・取り消し系の通知。期限前でも即時に権限を外す。
const REVOKING_NOTIFICATION_TYPES = new Set(["REFUND", "REVOKE"]);

/** 恒久的エラー（署名不正・ペイロード不正など）。再送しても成功しないため 2xx 以外で拒否する。 */
class AppleNotificationError extends Error {
  constructor(message) {
    super(message);
    this.name = "AppleNotificationError";
  }
}

/**
 * signedPayload を署名検証して、通知・取引・更新情報を復号する。
 * 本番（appAppleId がある場合）→ Sandbox の順に検証する。
 */
async function decodeAppleNotification({
  signedPayload,
  bundleId,
  appAppleId,
  rootCertificates,
}) {
  if (typeof signedPayload !== "string" || signedPayload.split(".").length !== 3) {
    throw new AppleNotificationError("signedPayload が JWS ではありません");
  }

  const roots = rootCertificates || (await loadAppleRootCertificates());
  const environments = [];
  if (Number.isInteger(appAppleId) && appAppleId > 0) {
    environments.push({ environment: Environment.PRODUCTION, appAppleId });
  }
  environments.push({ environment: Environment.SANDBOX, appAppleId: undefined });

  for (const candidate of environments) {
    const verifier = new SignedDataVerifier(
      roots,
      true,
      candidate.environment,
      bundleId,
      candidate.appAppleId,
    );
    let notification;
    try {
      notification = await verifier.verifyAndDecodeNotification(signedPayload);
    } catch (_) {
      continue;
    }

    const data = notification.data || {};
    const transaction = data.signedTransactionInfo
      ? await verifier.verifyAndDecodeTransaction(data.signedTransactionInfo)
      : null;
    const renewalInfo = data.signedRenewalInfo
      ? await verifier.verifyAndDecodeRenewalInfo(data.signedRenewalInfo)
      : null;
    return {
      notificationType: notification.notificationType,
      subtype: notification.subtype || null,
      notificationUUID: notification.notificationUUID || null,
      signedDate: notification.signedDate || null,
      environment: data.environment || candidate.environment,
      transaction,
      renewalInfo,
    };
  }

  throw new AppleNotificationError("App Store 通知の署名を検証できません");
}

/**
 * 取引と更新情報から「現在有効か」と失効日時を判定する。
 * 猶予期間（Billing Grace Period）中は gracePeriodExpiresDate まで有効とみなす。
 */
function resolveAppleSubscriptionActive({
  notificationType,
  transaction,
  renewalInfo,
  now = new Date(),
}) {
  if (
    REVOKING_NOTIFICATION_TYPES.has(notificationType) ||
    transaction.revocationDate ||
    transaction.revocationReason !== undefined
  ) {
    return { active: false, status: "revoked", expiresAt: null };
  }

  const expiresMillis = Number.isFinite(transaction.expiresDate)
    ? transaction.expiresDate
    : 0;
  const graceMillis = Number.isFinite(renewalInfo?.gracePeriodExpiresDate)
    ? renewalInfo.gracePeriodExpiresDate
    : 0;
  const effectiveMillis = Math.max(expiresMillis, graceMillis);

  return {
    active: effectiveMillis > now.getTime(),
    status: effectiveMillis > now.getTime() ? "active" : "expired",
    expiresAt: effectiveMillis > 0 ? new Date(effectiveMillis) : null,
  };
}

function toEventTimestamp(signedDate) {
  const millis = Number(signedDate);
  return Number.isFinite(millis) && millis > 0
    ? Timestamp.fromMillis(millis)
    : FieldValue.serverTimestamp();
}

/** 有効状態を purchaseReceipts と users に反映する（source=app_store_notification）。 */
async function applyAppleActiveState({
  db,
  uid,
  receiptRef,
  receiptKey,
  transaction,
  decision,
  notificationType,
  signedDate,
}) {
  const userRef = db.collection("users").doc(uid);
  const expiresTs = decision.expiresAt
    ? Timestamp.fromDate(decision.expiresAt)
    : null;

  await db.runTransaction(async (tx) => {
    tx.set(
      receiptRef,
      {
        uid,
        platform: "app_store",
        productId: transaction.productId,
        status: "active",
        expiresAt: expiresTs,
        storeStatus: transaction.environment || "unknown",
        originalTransactionId: transaction.originalTransactionId,
        transactionId: transaction.transactionId || null,
        lastNotificationType: notificationType,
        notificationEventAt: toEventTimestamp(signedDate),
        verifiedAt: FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
    tx.set(
      userRef,
      {
        purchaseType: "subscribe",
        purchaseVerification: {
          platform: "app_store",
          productId: transaction.productId,
          status: "active",
          expiresAt: expiresTs,
          receiptFingerprint: receiptKey,
          source: "app_store_notification",
          verifiedAt: FieldValue.serverTimestamp(),
        },
        updatedAt: FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
  });
}

/**
 * 失効・返金を反映する。
 * user ドキュメントを free に落とすのは「このレシートが現在の権限源である」場合のみ。
 * Android など別のレシートで購読中なら user は触らず、レシートのみ失効印を付ける。
 */
async function applyAppleInactiveState({
  db,
  uid,
  receiptRef,
  receiptKey,
  status,
  notificationType,
  signedDate,
}) {
  const userRef = db.collection("users").doc(uid);

  await db.runTransaction(async (tx) => {
    const userSnap = await tx.get(userRef);

    tx.set(
      receiptRef,
      {
        status,
        lastNotificationType: notificationType,
        notificationEventAt: toEventTimestamp(signedDate),
        expiredAt: FieldValue.serverTimestamp(),
      },
      { merge: true },
    );

    if (!userSnap.exists) return;

    const user = userSnap.data() || {};
    const verification = user.purchaseVerification || {};
    const shouldDowngrade =
      user.purchaseType === "subscribe" &&
      verification.receiptFingerprint === receiptKey;

    if (shouldDowngrade) {
      tx.set(
        userRef,
        {
          purchaseType: "free",
          purchaseVerification: {
            ...verification,
            status,
            source: "app_store_notification",
            downgradedAt: FieldValue.serverTimestamp(),
          },
          updatedAt: FieldValue.serverTimestamp(),
        },
        { merge: true },
      );
    }
  });
}

/**
 * App Store Server Notification 1 通を処理する。
 * @param {object}   params
 * @param {FirebaseFirestore.Firestore} params.db
 * @param {string}   params.signedPayload     リクエストボディの signedPayload
 * @param {string}   params.bundleId
 * @param {number}  [params.appAppleId]       本番通知の検証に必要
 * @param {Function}[params.decode]           テスト用の復号関数
 * @param {Date}    [params.now]
 * @param {object}  [params.logger]
 */
async function handleAppleNotification({
  db,
  signedPayload,
  bundleId,
  appAppleId,
  decode = decodeAppleNotification,
  now = new Date(),
  logger = console,
}) {
  const notification = await decode({ signedPayload, bundleId, appAppleId });
  const { notificationType, subtype, transaction, renewalInfo, signedDate } =
    notification;

  if (notificationType === "TEST") {
    logger.log("[apple-notify] テスト通知を受信", {
      environment: notification.environment,
    });
    return { handled: "test" };
  }

  if (!transaction || !transaction.originalTransactionId) {
    logger.log("[apple-notify] 取引情報の無い通知を無視", {
      notificationType,
      subtype,
    });
    return { handled: "ignored" };
  }

  if (!SUPPORTED_IOS_PRODUCT_IDS.has(transaction.productId)) {
    logger.warn("[apple-notify] 未対応の商品IDの通知を無視", {
      notificationType,
      productId: transaction.productId,
    });
    return { handled: "ignored" };
  }

  const receiptKey = fingerprint(
    `app_store:${transaction.originalTransactionId}`,
  );
  const receiptRef = db.collection("purchaseReceipts").doc(receiptKey);
  const receiptSnap = await receiptRef.get();
  if (!receiptSnap.exists) {
    logger.log("[apple-notify] ローカルレシート無し。スキップ", {
      receiptKey,
      notificationType,
    });
    return { handled: "unmapped", receiptKey };
  }

  const uid = (receiptSnap.data() || {}).uid;
  const decision = resolveAppleSubscriptionActive({
    notificationType,
    transaction,
    renewalInfo,
    now,
  });

  if (decision.active) {
    await applyAppleActiveState({
      db,
      uid,
      receiptRef,
      receiptKey,
      transaction,
      decision,
      notificationType,
      signedDate,
    });
    logger.log("[apple-notify] 権限を更新（active）", {
      uidPrefix: uid.slice(0, 3),
      notificationType,
      subtype,
      expiresAt: decision.expiresAt ? decision.expiresAt.toISOString() : null,
    });
    return { handled: "active", uid, receiptKey };
  }

  await applyAppleInactiveState({
    db,
    uid,
    receiptRef,
    receiptKey,
    status: decision.status,
    notificationType,
    signedDate,
  });
  logger.log("[apple-notify] 権限をダウングレード", {
    uidPrefix: uid.slice(0, 3),
    notificationType,
    subtype,
    status: decision.status,
  });
  return { handled: decision.status, uid, receiptKey };
}

module.exports = {
  AppleNotificationError,
  decodeAppleNotification,
  handleAppleNotification,
  resolveAppleSubscriptionActive,
};
