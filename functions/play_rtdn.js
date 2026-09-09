"use strict";

const { FieldValue, Timestamp } = require("firebase-admin/firestore");
const {
  ACTIVE_GOOGLE_STATES,
  fetchGoogleSubscriptionV2,
  fingerprint,
} = require("./receipt_verification");

/**
 * Google Play リアルタイム デベロッパー通知（RTDN）の処理。
 *
 * Play Console の「収益化のセットアップ > Google Play 請求サービス」で
 * Cloud Pub/Sub トピックを登録すると、購読の更新・解約・保留・失効・返金が
 * このトピックへ publish される。`index.js` の onMessagePublished から呼ばれる。
 *
 * 通知は uid を含まないため、`purchaseReceipts/{sha256(google_play:token)}` に
 * 保存済みの uid で本人を特定する。初回購入がクライアント検証より先に届いた等で
 * ローカルレシートが無い場合は何もしない（クライアントの verifyPurchase が付与する）。
 */

// SubscriptionNotification.notificationType
// https://developer.android.com/google/play/billing/rtdn-reference
const SUBSCRIPTION_NOTIFICATION_TYPE = {
  RECOVERED: 1,
  RENEWED: 2,
  CANCELED: 3,
  PURCHASED: 4,
  ON_HOLD: 5,
  IN_GRACE_PERIOD: 6,
  RESTARTED: 7,
  PRICE_CHANGE_CONFIRMED: 8,
  DEFERRED: 9,
  PAUSED: 10,
  PAUSE_SCHEDULE_CHANGED: 11,
  REVOKED: 12,
  EXPIRED: 13,
};

/** 恒久的エラー（ペイロード不正など）。再送しても成功しないため ack して捨てる。 */
class RtdnError extends Error {
  constructor(message) {
    super(message);
    this.name = "RtdnError";
  }
}

/**
 * Pub/Sub メッセージから DeveloperNotification オブジェクトを取り出す。
 * `message.json`（firebase-functions が base64+JSON を復号）を優先し、
 * 無ければ `message.data`（base64 文字列）を自前で復号する。
 */
function parseDeveloperNotification(message) {
  if (!message) {
    throw new RtdnError("Pub/Sub メッセージが空です");
  }

  let payload;
  try {
    payload = message.json;
  } catch (_) {
    payload = undefined;
  }

  if (payload === undefined || payload === null) {
    const raw = message.data
      ? Buffer.from(message.data, "base64").toString("utf8")
      : "";
    if (!raw) {
      throw new RtdnError("Pub/Sub メッセージに data ペイロードがありません");
    }
    try {
      payload = JSON.parse(raw);
    } catch (error) {
      throw new RtdnError(`RTDN ペイロードが JSON ではありません: ${error.message}`);
    }
  }

  if (typeof payload !== "object" || Array.isArray(payload)) {
    throw new RtdnError("RTDN ペイロードが JSON オブジェクトではありません");
  }
  return payload;
}

/**
 * subscriptionsv2 の生レスポンスから「現在有効か」と失効日時を判定する。
 * subscriptionState が取得できない異常応答は例外にして再送に委ねる（誤ダウングレード防止）。
 */
function resolveSubscriptionActive(data, now = new Date()) {
  if (!data || typeof data !== "object" || !data.subscriptionState) {
    throw new Error("subscriptionsv2 応答に subscriptionState がありません");
  }

  const lineItems = Array.isArray(data.lineItems) ? data.lineItems : [];
  const expiryTimes = lineItems
    .map((item) => Date.parse(item && item.expiryTime ? item.expiryTime : ""))
    .filter(Number.isFinite);
  const expiryMillis = expiryTimes.length === 0 ? 0 : Math.max(...expiryTimes);
  const stateActive = ACTIVE_GOOGLE_STATES.has(data.subscriptionState);

  return {
    active: stateActive && expiryMillis > now.getTime(),
    expiresAt: expiryMillis > 0 ? new Date(expiryMillis) : null,
    subscriptionState: data.subscriptionState,
  };
}

function toEventTimestamp(eventTimeMillis) {
  const millis = Number(eventTimeMillis);
  return Number.isFinite(millis) && millis > 0
    ? Timestamp.fromMillis(millis)
    : FieldValue.serverTimestamp();
}

/** 有効状態を purchaseReceipts と users に反映する（source=rtdn）。 */
async function applyActiveState({
  db,
  uid,
  receiptRef,
  receiptKey,
  productId,
  decision,
  notificationType,
  eventTimeMillis,
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
        platform: "google_play",
        productId: productId || null,
        status: "active",
        expiresAt: expiresTs,
        storeStatus: decision.subscriptionState,
        lastNotificationType: notificationType ?? null,
        rtdnEventAt: toEventTimestamp(eventTimeMillis),
        verifiedAt: FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
    tx.set(
      userRef,
      {
        purchaseType: "subscribe",
        purchaseVerification: {
          platform: "google_play",
          productId: productId || null,
          status: "active",
          expiresAt: expiresTs,
          receiptFingerprint: receiptKey,
          source: "rtdn",
          verifiedAt: FieldValue.serverTimestamp(),
        },
        updatedAt: FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
  });
}

/**
 * 失効・保留・返金を反映する。
 * user ドキュメントを free に落とすのは「このレシートが現在の権限源である」場合のみ。
 * 別トークンで再購読済みなら user は触らず、レシートのみ失効印を付ける。
 */
async function applyInactiveState({
  db,
  uid,
  receiptRef,
  receiptKey,
  status,
  storeStatus,
  notificationType,
  eventTimeMillis,
  now,
}) {
  const userRef = db.collection("users").doc(uid);

  await db.runTransaction(async (tx) => {
    const userSnap = await tx.get(userRef);

    tx.set(
      receiptRef,
      {
        status,
        storeStatus: storeStatus || null,
        lastNotificationType: notificationType ?? null,
        rtdnEventAt: toEventTimestamp(eventTimeMillis),
        expiredAt: FieldValue.serverTimestamp(),
      },
      { merge: true },
    );

    if (!userSnap.exists) return;

    const user = userSnap.data() || {};
    const verification = user.purchaseVerification || {};
    const backsThisUser = verification.receiptFingerprint === receiptKey;
    const expiresAtMillis =
      typeof verification.expiresAt?.toMillis === "function"
        ? verification.expiresAt.toMillis()
        : 0;
    const storedExpired =
      expiresAtMillis > 0 && expiresAtMillis <= now.getTime();

    // 現在 subscribe 判定のユーザーのうち、
    //  - このレシートが権限源  … 明確にダウングレード
    //  - レシート指紋が未記録だが保存済み期限も切れている … 旧データ救済としてダウングレード
    const shouldDowngrade =
      user.purchaseType === "subscribe" &&
      (backsThisUser || (!verification.receiptFingerprint && storedExpired));

    if (shouldDowngrade) {
      tx.set(
        userRef,
        {
          purchaseType: "free",
          purchaseVerification: {
            ...verification,
            status,
            source: "rtdn",
            downgradedAt: FieldValue.serverTimestamp(),
          },
          updatedAt: FieldValue.serverTimestamp(),
        },
        { merge: true },
      );
    }
  });
}

async function lookupReceipt(db, purchaseToken) {
  const receiptKey = fingerprint(`google_play:${purchaseToken}`);
  const receiptRef = db.collection("purchaseReceipts").doc(receiptKey);
  const receiptSnap = await receiptRef.get();
  return { receiptKey, receiptRef, receiptSnap };
}

async function handleSubscriptionNotification({
  db,
  packageName,
  authClient,
  fetchSubscription,
  now,
  logger,
  sub,
  eventTimeMillis,
}) {
  const purchaseToken = sub && sub.purchaseToken;
  const notificationType = sub && sub.notificationType;
  if (!purchaseToken) {
    logger.warn("[play-rtdn] purchaseToken 無しの subscription 通知を無視");
    return { handled: "invalid" };
  }

  const { receiptKey, receiptRef, receiptSnap } = await lookupReceipt(
    db,
    purchaseToken,
  );
  if (!receiptSnap.exists) {
    logger.log("[play-rtdn] ローカルレシート無し。スキップ", {
      receiptKey,
      notificationType,
    });
    return { handled: "unmapped", receiptKey };
  }

  const receipt = receiptSnap.data() || {};
  const uid = receipt.uid;
  const productId = (sub && sub.subscriptionId) || receipt.productId || null;

  const data = await fetchSubscription({
    packageName,
    purchaseToken,
    authClient,
  });
  const decision = resolveSubscriptionActive(data, now);

  if (decision.active) {
    await applyActiveState({
      db,
      uid,
      receiptRef,
      receiptKey,
      productId,
      decision,
      notificationType,
      eventTimeMillis,
    });
    logger.log("[play-rtdn] 権限を更新（active）", {
      uidPrefix: uid.slice(0, 3),
      notificationType,
      expiresAt: decision.expiresAt ? decision.expiresAt.toISOString() : null,
    });
    return { handled: "active", uid, receiptKey };
  }

  const status =
    notificationType === SUBSCRIPTION_NOTIFICATION_TYPE.REVOKED
      ? "revoked"
      : "expired";
  await applyInactiveState({
    db,
    uid,
    receiptRef,
    receiptKey,
    status,
    storeStatus: decision.subscriptionState,
    notificationType,
    eventTimeMillis,
    now,
  });
  logger.log("[play-rtdn] 権限をダウングレード", {
    uidPrefix: uid.slice(0, 3),
    notificationType,
    status,
  });
  return { handled: status, uid, receiptKey };
}

async function handleVoidedNotification({ db, now, logger, voided }) {
  const purchaseToken = voided && voided.purchaseToken;
  if (!purchaseToken) {
    logger.warn("[play-rtdn] purchaseToken 無しの voided 通知を無視");
    return { handled: "invalid" };
  }

  const { receiptKey, receiptRef, receiptSnap } = await lookupReceipt(
    db,
    purchaseToken,
  );
  if (!receiptSnap.exists) {
    logger.log("[play-rtdn] voided purchase のローカルレシート無し", {
      receiptKey,
    });
    return { handled: "unmapped", receiptKey };
  }

  const uid = (receiptSnap.data() || {}).uid;
  await applyInactiveState({
    db,
    uid,
    receiptRef,
    receiptKey,
    status: "revoked",
    storeStatus: "VOIDED",
    notificationType: null,
    eventTimeMillis: null,
    now,
  });
  logger.log("[play-rtdn] 返金により権限を取り消し", {
    uidPrefix: uid.slice(0, 3),
    refundType: voided.refundType,
  });
  return { handled: "revoked", uid, receiptKey };
}

/**
 * RTDN 1 通を処理する。
 * @param {object}   params
 * @param {FirebaseFirestore.Firestore} params.db
 * @param {object}   params.message           Pub/Sub メッセージ（event.data.message）
 * @param {string}   params.packageName       本番 application ID（フォールバック用）
 * @param {object}  [params.authClient]       テスト用の Google 認証クライアント
 * @param {Function}[params.fetchSubscription] テスト用の subscriptionsv2 取得関数
 * @param {Date}    [params.now]
 * @param {object}  [params.logger]
 */
async function handlePlayRtdn({
  db,
  message,
  packageName,
  authClient,
  fetchSubscription = fetchGoogleSubscriptionV2,
  now = new Date(),
  logger = console,
}) {
  const notification = parseDeveloperNotification(message);

  if (notification.testNotification) {
    logger.log("[play-rtdn] テスト通知を受信", {
      version: notification.testNotification.version,
    });
    return { handled: "test" };
  }

  const pkg = notification.packageName || packageName;

  if (notification.subscriptionNotification) {
    return handleSubscriptionNotification({
      db,
      packageName: pkg,
      authClient,
      fetchSubscription,
      now,
      logger,
      sub: notification.subscriptionNotification,
      eventTimeMillis: notification.eventTimeMillis,
    });
  }

  if (notification.voidedPurchaseNotification) {
    return handleVoidedNotification({
      db,
      now,
      logger,
      voided: notification.voidedPurchaseNotification,
    });
  }

  if (notification.oneTimeProductNotification) {
    // 旧「買い切り」プラン。サーバー検証対象外なので記録のみ。
    logger.log("[play-rtdn] one-time product 通知は未対応のため無視", {
      type: notification.oneTimeProductNotification.notificationType,
    });
    return { handled: "one-time-ignored" };
  }

  logger.warn("[play-rtdn] 未知の通知形状", {
    keys: Object.keys(notification),
  });
  return { handled: "unknown" };
}

module.exports = {
  RtdnError,
  SUBSCRIPTION_NOTIFICATION_TYPE,
  handlePlayRtdn,
  parseDeveloperNotification,
  resolveSubscriptionActive,
};
