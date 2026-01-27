const admin = require("firebase-admin");
const serviceAccount = require("./path-to-service-account.json"); // パスを正しく設定

// Firebase Admin初期化
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

async function checkEditLocks() {
  try {
    console.log("🔍 編集ロック状態を確認中...");

    // 全ての SharedGroups を取得
    const groupsSnapshot = await db.collection("SharedGroups").get();
    console.log(`📁 グループ数: ${groupsSnapshot.docs.length}`);

    for (const groupDoc of groupsSnapshot.docs) {
      const groupId = groupDoc.id;
      console.log(`\n📋 グループ: ${groupId}`);

      // ホワイトボードコレクションを取得
      const whiteboardsSnapshot = await db
        .collection("SharedGroups")
        .doc(groupId)
        .collection("whiteboards")
        .get();

      console.log(`  🎨 ホワイトボード数: ${whiteboardsSnapshot.docs.length}`);

      for (const whiteboardDoc of whiteboardsSnapshot.docs) {
        const whiteboardId = whiteboardDoc.id;
        const data = whiteboardDoc.data();

        if (data.editLock) {
          const editLock = data.editLock;
          const now = new Date();
          const createdAt = editLock.createdAt.toDate();
          const expiresAt = editLock.expiresAt.toDate();
          const isExpired = now > expiresAt;

          console.log(`    📄 ホワイトボード: ${whiteboardId}`);
          console.log(`      🔒 編集中ユーザー: ${editLock.userName}`);
          console.log(`      📅 作成日時: ${createdAt.toLocaleString()}`);
          console.log(`      ⏰ 有効期限: ${expiresAt.toLocaleString()}`);
          console.log(`      ❌ 期限切れ: ${isExpired ? "YES" : "NO"}`);

          if (isExpired) {
            console.log("    🗑️ 期限切れロックを削除中...");
            await whiteboardDoc.ref.update({
              editLock: admin.firestore.FieldValue.delete(),
            });
            console.log("    ✅ 削除完了");
          }
        }
      }
    }

    console.log("\n✅ 編集ロック確認完了");
  } catch (error) {
    console.error("❌ エラー:", error);
  } finally {
    process.exit(0);
  }
}

checkEditLocks();
