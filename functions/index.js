"use strict";

const { onSchedule } = require("firebase-functions/v2/scheduler");
const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore, Timestamp } = require("firebase-admin/firestore");
const { getStorage } = require("firebase-admin/storage");

initializeApp();

const REGION = "asia-northeast1";
const BACKUP_PREFIX = "firestore-snapshots";
const RETENTION_DAYS = 5;

// ─────────────────────────────────────────────────────────────────────────────
// 1. スケジュールバックアップ
//    毎日 JST 00:00（= UTC 15:00）に実行
// ─────────────────────────────────────────────────────────────────────────────
exports.scheduledFirestoreBackup = onSchedule(
  {
    schedule: "0 15 * * *", // UTC 15:00 = JST 00:00
    timeZone: "UTC",
    region: REGION,
    timeoutSeconds: 540,
    memory: "512MiB",
  },
  async () => {
    await runBackup();
  },
);

// ─────────────────────────────────────────────────────────────────────────────
// 2. バックアップ一覧取得（Callable）
// ─────────────────────────────────────────────────────────────────────────────
exports.listBackups = onCall({ region: REGION }, async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "認証が必要です");
  }

  const bucket = getStorage().bucket();
  const [files] = await bucket.getFiles({ prefix: BACKUP_PREFIX });

  const backups = files
    .filter((f) => f.name.endsWith(".json"))
    .map((f) => ({
      fileName: f.name,
      date: (f.name.match(/(\d{4}-\d{2}-\d{2})/) || [])[1] || null,
      sizeBytes: parseInt(f.metadata.size || "0", 10),
      createdAt: f.metadata.timeCreated || null,
    }))
    .sort((a, b) => (b.date || "").localeCompare(a.date || ""));

  return { backups };
});

// ─────────────────────────────────────────────────────────────────────────────
// 3. ユーザーデータリストア（Callable）
//    呼び出し元の ownerUid に一致するグループのみリストア
//    dryRun: true にすると書き込みなしで件数だけ確認できる
// ─────────────────────────────────────────────────────────────────────────────
exports.restoreUserData = onCall({ region: REGION }, async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "認証が必要です");
  }

  const { backupFileName, dryRun = false } = request.data;
  if (!backupFileName) {
    throw new HttpsError("invalid-argument", "backupFileName は必須です");
  }

  const ownerUid = request.auth.uid;
  const backupData = await loadBackupFile(backupFileName);

  return await restoreUser(backupData, ownerUid, dryRun);
});

// ─────────────────────────────────────────────────────────────────────────────
// 4. 全データリストア（Callable・管理者のみ）
//    adminSecret（.env の ADMIN_RESTORE_SECRET と一致）が必要
// ─────────────────────────────────────────────────────────────────────────────
exports.restoreAllData = onCall({ region: REGION }, async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "認証が必要です");
  }

  const { backupFileName, adminSecret, dryRun = false } = request.data;

  const expectedSecret = process.env.ADMIN_RESTORE_SECRET;
  if (!expectedSecret || adminSecret !== expectedSecret) {
    throw new HttpsError("permission-denied", "管理者シークレットが不正です");
  }

  if (!backupFileName) {
    throw new HttpsError("invalid-argument", "backupFileName は必須です");
  }

  const backupData = await loadBackupFile(backupFileName);
  return await restoreAll(backupData, dryRun);
});

// ─────────────────────────────────────────────────────────────────────────────
// 内部ヘルパー
// ─────────────────────────────────────────────────────────────────────────────

/** バックアップ実体 */
async function runBackup() {
  const dateStr = new Date().toISOString().split("T")[0]; // YYYY-MM-DD
  const timestamp = new Date().toISOString().replace(/[:.]/g, "-");
  console.log(`🔒 Firestoreバックアップ開始: ${dateStr}`);

  const db = getFirestore();
  const bucket = getStorage().bucket();

  // データ収集
  const snapshot = await collectAllData(db);

  // GCS 保存
  const fileName = `${BACKUP_PREFIX}/${dateStr}/backup_${timestamp}.json`;
  const file = bucket.file(fileName);
  await file.save(JSON.stringify(snapshot, null, 2), {
    contentType: "application/json",
    metadata: { backupDate: dateStr, createdAt: new Date().toISOString() },
  });
  console.log(`✅ バックアップ保存: gs://${bucket.name}/${fileName}`);

  // 古いバックアップ削除（5日超）
  await deleteOldBackups(bucket);
}

/** Firestore の全データを収集（SharedGroups + サブコレクション + notifications） */
async function collectAllData(db) {
  const data = {
    exportedAt: new Date().toISOString(),
    projectId: process.env.GCLOUD_PROJECT || "goshopping-48db9",
    collections: { SharedGroups: {}, notifications: {} },
  };

  // SharedGroups
  const groupsSnap = await db.collection("SharedGroups").get();
  for (const groupDoc of groupsSnap.docs) {
    const groupEntry = {
      ...serializeDoc(groupDoc.data()),
      _subCollections: { SharedLists: {}, whiteboards: {} },
    };

    // SharedLists
    const listsSnap = await db
      .collection(`SharedGroups/${groupDoc.id}/SharedLists`)
      .get();
    for (const listDoc of listsSnap.docs) {
      const listEntry = {
        ...serializeDoc(listDoc.data()),
        _subCollections: { items: {} },
      };

      // items
      const itemsSnap = await db
        .collection(
          `SharedGroups/${groupDoc.id}/SharedLists/${listDoc.id}/items`,
        )
        .get();
      for (const itemDoc of itemsSnap.docs) {
        listEntry._subCollections.items[itemDoc.id] = serializeDoc(
          itemDoc.data(),
        );
      }

      groupEntry._subCollections.SharedLists[listDoc.id] = listEntry;
    }

    // whiteboards
    const wbSnap = await db
      .collection(`SharedGroups/${groupDoc.id}/whiteboards`)
      .get()
      .catch(() => ({ docs: [] }));
    for (const wbDoc of wbSnap.docs) {
      groupEntry._subCollections.whiteboards[wbDoc.id] = serializeDoc(
        wbDoc.data(),
      );
    }

    data.collections.SharedGroups[groupDoc.id] = groupEntry;
  }

  // notifications
  const notifSnap = await db.collection("notifications").get();
  for (const doc of notifSnap.docs) {
    data.collections.notifications[doc.id] = serializeDoc(doc.data());
  }

  return data;
}

/** 5日超のバックアップを GCS から削除 */
async function deleteOldBackups(bucket) {
  const [files] = await bucket.getFiles({ prefix: BACKUP_PREFIX });
  const cutoff = new Date();
  cutoff.setDate(cutoff.getDate() - RETENTION_DAYS);

  let deleted = 0;
  for (const file of files) {
    const match = file.name.match(/(\d{4}-\d{2}-\d{2})/);
    if (match && new Date(match[1]) < cutoff) {
      await file.delete();
      deleted++;
      console.log(`🗑️ 削除: ${file.name}`);
    }
  }
  console.log(`🧹 古いバックアップ削除完了: ${deleted}件`);
}

/** GCS からバックアップ JSON を読み込み */
async function loadBackupFile(fileName) {
  const bucket = getStorage().bucket();
  const file = bucket.file(fileName);
  const [exists] = await file.exists();
  if (!exists) {
    throw new HttpsError(
      "not-found",
      `バックアップファイルが見つかりません: ${fileName}`,
    );
  }
  const [content] = await file.download();
  return JSON.parse(content.toString("utf-8"));
}

/** 指定 ownerUid のグループだけリストア */
async function restoreUser(backupData, ownerUid, dryRun) {
  const db = getFirestore();
  const groups = backupData.collections?.SharedGroups ?? {};
  let restored = 0;
  let skipped = 0;

  for (const [groupId, groupData] of Object.entries(groups)) {
    if (groupData.ownerUid !== ownerUid) {
      skipped++;
      continue;
    }
    if (!dryRun) await writeGroupData(db, groupId, groupData);
    restored++;
    console.log(
      `✅ グループリストア: ${groupId} (${groupData.groupName ?? ""})`,
    );
  }

  return {
    success: true,
    dryRun,
    restored,
    skipped,
    message: dryRun
      ? `[DRY RUN] ${restored}件のグループをリストア予定（スキップ: ${skipped}件）`
      : `${restored}件のグループをリストアしました`,
  };
}

/** 全データリストア */
async function restoreAll(backupData, dryRun) {
  const db = getFirestore();
  const groups = backupData.collections?.SharedGroups ?? {};
  const notifications = backupData.collections?.notifications ?? {};
  let restoredGroups = 0;
  let restoredNotifications = 0;

  for (const [groupId, groupData] of Object.entries(groups)) {
    if (!dryRun) await writeGroupData(db, groupId, groupData);
    restoredGroups++;
  }

  for (const [docId, docData] of Object.entries(notifications)) {
    if (!dryRun) {
      await db
        .collection("notifications")
        .doc(docId)
        .set(deserializeDoc(docData));
    }
    restoredNotifications++;
  }

  return {
    success: true,
    dryRun,
    restoredGroups,
    restoredNotifications,
    message: dryRun
      ? `[DRY RUN] グループ${restoredGroups}件・通知${restoredNotifications}件をリストア予定`
      : `グループ${restoredGroups}件・通知${restoredNotifications}件をリストアしました`,
  };
}

/** グループ本体 + SharedLists + items + whiteboards を書き込み */
async function writeGroupData(db, groupId, groupData) {
  const { _subCollections, ...groupFields } = groupData;

  // グループ本体
  await db
    .collection("SharedGroups")
    .doc(groupId)
    .set(deserializeDoc(groupFields));

  // SharedLists
  for (const [listId, listData] of Object.entries(
    _subCollections?.SharedLists ?? {},
  )) {
    const { _subCollections: listSubs, ...listFields } = listData;
    await db
      .collection(`SharedGroups/${groupId}/SharedLists`)
      .doc(listId)
      .set(deserializeDoc(listFields));

    // items
    for (const [itemId, itemData] of Object.entries(listSubs?.items ?? {})) {
      await db
        .collection(`SharedGroups/${groupId}/SharedLists/${listId}/items`)
        .doc(itemId)
        .set(deserializeDoc(itemData));
    }
  }

  // whiteboards
  for (const [wbId, wbData] of Object.entries(
    _subCollections?.whiteboards ?? {},
  )) {
    await db
      .collection(`SharedGroups/${groupId}/whiteboards`)
      .doc(wbId)
      .set(deserializeDoc(wbData));
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Timestamp シリアライズ / デシリアライズ
//   Firestore Timestamp → { __type: "Timestamp", seconds: N, nanoseconds: N }
// ─────────────────────────────────────────────────────────────────────────────

function serializeDoc(data) {
  if (data === null || data === undefined) return data;
  if (data instanceof Timestamp) {
    return {
      __type: "Timestamp",
      seconds: data.seconds,
      nanoseconds: data.nanoseconds,
    };
  }
  if (Array.isArray(data)) return data.map(serializeDoc);
  if (typeof data === "object") {
    return Object.fromEntries(
      Object.entries(data).map(([k, v]) => [k, serializeDoc(v)]),
    );
  }
  return data;
}

function deserializeDoc(data) {
  if (data === null || data === undefined) return data;
  if (
    typeof data === "object" &&
    data.__type === "Timestamp" &&
    "seconds" in data
  ) {
    return new Timestamp(data.seconds, data.nanoseconds);
  }
  if (Array.isArray(data)) return data.map(deserializeDoc);
  if (typeof data === "object") {
    return Object.fromEntries(
      Object.entries(data).map(([k, v]) => [k, deserializeDoc(v)]),
    );
  }
  return data;
}
