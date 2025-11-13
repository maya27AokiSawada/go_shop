# Firebase Firestore インデックス修正ガイド

## 問題の概要

QR招待機能で確認通知のクエリを実行する際、以下のエラーが発生しています：

```
W/Firestore: The query requires an index. You can create it here: https://console.firebase.google.com/...
```

## 必要なインデックス

### sync_confirmation 通知クエリ用インデックス

**コレクション**: `notifications`

**クエリフィールド（順序重要）**:
1. `userId` (Ascending)
2. `type` (Ascending)
3. `groupId` (Ascending)
4. `read` (Ascending)
5. `timestamp` (Descending) ← ソート用
6. `__name__` (Descending) ← 自動追加

## 自動作成リンク

エラーログに表示されたURLをクリックすると、Firebase Consoleで自動的にインデックス作成画面が開きます：

```
https://console.firebase.google.com/v1/r/project/gotoshop-572b7/firestore/indexes?create_composite=ClRwcm9qZWN0cy9nb3Rvc2hvcC01NzJiNy9kYXRhYmFzZXMvKGRlZmF1bHQpL2NvbGxlY3Rpb25Hcm91cHMvbm90aWZpY2F0aW9ucy9pbmRleGVzL18QARoLCgdncm91cElkEAEaCAoEcmVhZBABGggKBHR5cGUQARoKCgZ1c2VySWQQARoNCgl0aW1lc3RhbXAQAhoMCghfX25hbWVfXxAC
```

## 手動作成手順

もしリンクが使えない場合は、以下の手順で作成してください：

1. Firebase Console > Firestore Database > インデックス タブ
2. 「複合」タブを選択
3. 「インデックスを作成」をクリック
4. 以下の設定を入力：

| フィールド | モード | 並び順 |
|----------|------|------|
| userId | Ascending | ↑ |
| type | Ascending | ↑ |
| groupId | Ascending | ↑ |
| read | Ascending | ↑ |
| timestamp | Descending | ↓ |
| __name__ | Descending | ↓ |

5. 「作成」をクリック
6. インデックス構築完了まで数分待つ

## クエリ詳細

このインデックスは以下のクエリで使用されます：

```dart
// lib/services/notification_service.dart
_firestore
  .collection('notifications')
  .where('userId', isEqualTo: userId)
  .where('type', isEqualTo: 'sync_confirmation')
  .where('groupId', isEqualTo: groupId)
  .where('read', isEqualTo: false)
  .orderBy('timestamp', descending: true)
  .limit(1)
  .snapshots()
```

## 影響範囲

このインデックスがないと：
- ✅ 招待受諾自体は成功する
- ❌ 確認通知の待機がタイムアウトする
- ❌ 同期タイミングが遅れる（5秒のフォールバック遅延）

インデックス作成後は：
- ✅ 確認通知が即座に検出される
- ✅ 同期が高速化される

## 確認方法

1. インデックス構築完了後、アプリを再起動
2. QR招待を実行
3. ログに以下が表示されればOK：
   ```
   ✅ [BACKGROUND] 確認通知受信 - 即座に同期
   ```
4. エラーログが消えていることを確認：
   ```
   W/Firestore: The query requires an index
   ```
   ↑ このエラーが出なければ成功

## 関連修正

このドキュメントと同時に、以下のコード修正も実施しました：

1. **HybridRepository**: `_unawaited()` → `await`
   - Firestore書き込み完了を待つように変更
   - 同期前にデータが確実にFirestoreに反映される

2. **QRInvitationService**: 遅延時間 2秒 → 5秒
   - Firestoreクエリキャッシュの更新を待つ
   - インデックス作成後は確認通知で即座に同期される

## トラブルシューティング

### インデックス作成後もエラーが出る

- インデックスの構築状態を確認（緑のチェックマークが表示されるまで待つ）
- アプリを完全に再起動
- デバイスのネットワーク接続を確認

### クエリが遅い

- Firebase Console > Firestore > 使用状況 で読み取り数を確認
- インデックスが正しく使われているか確認
- 必要に応じてキャッシュ設定を見直す
