"use strict";

// 開発用ツール（dev プロジェクトでのみ動く）
//
// - setDevPurchaseType: 自分の purchaseType を subscribe / free に切り替える。
//   ストアで購入せずに Premium 前提の機能（家族特典クーポンなど）を確認するためのもの。
//   本番プロジェクトでは常に拒否する。

const DEV_PROJECT_ID = "gotoshop-572b7";
const DEV_PURCHASE_TYPES = new Set(["subscribe", "free"]);

class DevToolError extends Error {
  /**
   * @param {string} code HttpsError のコード
   * @param {string} message
   */
  constructor(code, message) {
    super(message);
    this.name = "DevToolError";
    this.code = code;
  }
}

function isDevProject(projectId) {
  return projectId === DEV_PROJECT_ID;
}

/** dev プロジェクトで自分の purchaseType を切り替える */
async function setDevPurchaseType({ db, uid, projectId, purchaseType }) {
  if (!isDevProject(projectId)) {
    throw new DevToolError("permission-denied", "dev プロジェクト以外では使えません");
  }
  if (!DEV_PURCHASE_TYPES.has(purchaseType)) {
    throw new DevToolError("invalid-argument", "purchaseType が不正です");
  }
  const userRef = db.collection("users").doc(uid);
  const userSnap = await userRef.get();
  if (!userSnap.exists) {
    throw new DevToolError("failed-precondition", "ユーザー情報がありません");
  }
  await userRef.update({ purchaseType });
  return { purchaseType };
}

module.exports = {
  DEV_PROJECT_ID,
  DevToolError,
  isDevProject,
  setDevPurchaseType,
};
