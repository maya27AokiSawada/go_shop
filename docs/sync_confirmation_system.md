# 同期確認システム実装ドキュメント

## 📋 実装日
2025年11月10日

**最終更新**: 2025年11月10日 - 非ブロッキング同期対応

## 🎯 目的
招待受諾時のFirestore→Hive同期タイミング問題を解決するため、通知ベースの確認システムを実装。

## 🔍 問題の背景

### 従来の問題
Android側で招待受諾後、Firestoreへの書き込みが完了する前にFirestore→Hive同期を実行し、クエリ結果が0件となり、新しく追加されたグループが誤って削除されていた。

```
[Android] Firestore書き込み開始
  ↓ (0.1秒)
[Android] 通知送信完了
  ↓ (2-5秒待機) ← 不確実な待機
[Android] Firestore→Hive同期開始
  ↓
[Firestore] まだ書き込み処理中...
  ↓
[Android] クエリ結果: 0件 → グループを削除
```

## ✅ 解決策

### 通知ベースの確認システム（非ブロッキング版）
招待元が実際にFirestoreからグループを再取得し、確認通知を送信。受諾側はバックグラウンドで確認を待機し、UIをブロックしない。

```
[受諾側] 招待受諾 → Firestore書き込み → 通知送信 → 即座に成功返却
  ↓                                              ↓
[招待元] 通知受信                         [バックグラウンド]
  ↓                                       確認通知待機
[招待元] Firestore再取得                    (最大10秒)
  ↓                                              ↓
[招待元] 確認通知送信 ──────────────────────> 確認受信
                                               ↓
                                          同期実行 + UI更新
```

### 二重保険システム
1. **バックグラウンド待機**: 確認通知を待機して同期
2. **通知リスナー**: 確認通知受信時も同期実行
3. **タイムアウト**: 10秒後にフォールバック同期

## 🔧 実装内容

### 1. 新しい通知タイプ追加

**`notification_service.dart`**
```dart
enum NotificationType {
  groupMemberAdded('group_member_added'),
  groupUpdated('group_updated'),
  invitationAccepted('invitation_accepted'),
  groupDeleted('group_deleted'),
  syncConfirmation('sync_confirmation'), // 新規追加
}
```

### 2. 確認通知待機メソッド（短縮版）

**`notification_service.dart`**
```dart
/// 確認通知を待機（最大10秒）
Future<bool> waitForSyncConfirmation({
  required String groupId,
  Duration timeout = const Duration(seconds: 10),
}) async
```

**機能**:
- 最大10秒間、確認通知を待機（短縮）
- タイムアウト時は`false`を返却
- 確認通知受信時は自動的に既読にする

### 3. 通知リスナーでの二重保険

**`notification_service.dart`の`_handleNotification`**
```dart
case NotificationType.syncConfirmation:
  // 同期確認通知 - 念のため同期実行（二重保険）
  AppLogger.info('✅ [NOTIFICATION] 同期確認受信 - 念のため同期実行');
  final userInitService = _ref.read(userInitializationServiceProvider);
  await userInitService.syncFromFirestoreToHive(currentUser);
  _ref.invalidate(allGroupsProvider);
  break;
```

**理由**: バックグラウンド待機がタイムアウトした場合でも、通知リスナーが確認通知を受信すれば自動的に同期される。

### 4. 招待元の確認通知送信

**`notification_service.dart`の`_handleNotification`**
```dart
case NotificationType.groupMemberAdded:
  // 新メンバー追加通知 - 特定グループのみFirestoreから再取得
  final groupId = notification.metadata?['groupId'] as String?;
  if (groupId != null) {
    await _syncSpecificGroupFromFirestore(groupId);

    // 受諾者に確認通知を送信
    final acceptorUid = notification.metadata?['acceptorUid'] as String?;
    if (acceptorUid != null) {
      await sendNotification(
        targetUserId: acceptorUid,
        type: NotificationType.syncConfirmation,
        groupId: groupId,
        message: 'グループ同期完了',
        metadata: {'confirmedBy': currentUser.uid},
      );
    }
    }
  }
```

### 5. 受諾側の非ブロッキング処理

**`qr_invitation_service.dart`の`acceptQRInvitation`**
```dart
// 即座に成功を返す（UIをブロックしない）
// バックグラウンドで確認通知を待機して同期
_waitForConfirmationAndSync(
  groupId: invitationData['SharedGroupId'],
  currentUser: currentUser,
);

Log.info('✅ 招待受諾処理完了 - バックグラウンド同期開始');
return true;
```

### 6. バックグラウンド同期処理

**`qr_invitation_service.dart`の`_waitForConfirmationAndSync`**
```dart
Future<void> _waitForConfirmationAndSync({
  required String groupId,
  required User currentUser,
}) async {
  try {
    Log.info('⏳ [BACKGROUND] 確認通知待機開始...');

    final notificationService = _ref.read(notificationServiceProvider);

    // 最大10秒待機（短縮）
    final confirmed = await notificationService.waitForSyncConfirmation(
      groupId: groupId,
      timeout: const Duration(seconds: 10),
    );

    if (!confirmed) {
      Log.warning('⚠️ [BACKGROUND] 確認通知タイムアウト - 短い待機後同期');
      await Future.delayed(const Duration(seconds: 2));
    } else {
      Log.info('✅ [BACKGROUND] 確認通知受信 - 即座に同期');
    }

    // Firestore→Hive同期を実行
    final userInitService = _ref.read(userInitializationServiceProvider);
    await userInitService.syncFromFirestoreToHive(currentUser);
    _ref.invalidate(allGroupsProvider);
  } catch (e) {
    Log.error('❌ [BACKGROUND] バックグラウンド同期エラー: $e');
  }
}
```

### 7. metadata拡張

**個別招待**(`_processIndividualInvitation`)
```dart
metadata: {
  'groupId': groupId,
  'newMemberId': acceptorUid,
  'newMemberName': userName,
  'acceptorUid': acceptorUid, // 確認通知送信先
}
```

**パートナー招待**(`_processPartnerInvitation`)
```dart
metadata: {
  'groupId': doc.id,
  'newMemberId': acceptorUid,
  'newMemberName': userName,
  'acceptorUid': acceptorUid, // 確認通知送信先
  'invitationType': 'partner',
}
```

## 📊 フロー図

### 個別招待の場合

```
1. [Android/受諾側] QRコードスキャン
2. [Android/受諾側] グループにメンバー追加 → Firestore書き込み
3. [Android/受諾側] グループメンバー全員に通知送信
4. [Android/受諾側] 確認通知を待機 (最大30秒)
   ↓
5. [Windows/招待元] 通知受信
6. [Windows/招待元] Firestoreからグループ再取得
7. [Windows/招待元] 確認通知を送信 → acceptorUid宛
   ↓
8. [Android/受諾側] 確認通知受信
9. [Android/受諾側] Firestore→Hive同期実行
10. [Android/受諾側] UI更新
```

### パートナー招待の場合

### パートナー招待の場合（非ブロッキング版）

```
1. [Android/受諾側] QRコードスキャン
2. [Android/受諾側] パートナーリストに追加
3. [Android/受諾側] 招待者の全グループにメンバー追加
4. [Android/受諾側] 各グループメンバー全員に通知送信
5. [Android/受諾側] 即座に成功返却（UIブロックせず）
   ↓                  ↓
   |         [バックグラウンド] 確認通知待機 (最大10秒)
   |                  ↓
6. [Windows/招待元] 複数の通知受信（各グループ分）
7. [Windows/招待元] 各グループをFirestoreから再取得
8. [Windows/招待元] 確認通知を送信 → acceptorUid宛
   |                  ↓
   |         [バックグラウンド] 確認通知受信
   |                  ↓
   |         [バックグラウンド] Firestore→Hive同期実行
   |                  ↓
   |         [Android/受諾側] UI更新
   ↓
[Android/受諾側] ユーザーは既に別画面に遷移可能
```

## ⚙️ タイムアウト処理（改善版）

### 三重保険システム

#### 1. バックグラウンド待機（第一保険）
- **タイムアウト時間**: 10秒（短縮）
- **フォールバック**: 2秒待機後に同期実行
- **理由**: UIをブロックせず、適切なタイミングで同期

```dart
if (!confirmed) {
  Log.warning('⚠️ [BACKGROUND] 確認通知タイムアウト - 短い待機後同期');
  await Future.delayed(const Duration(seconds: 2));
}
```

#### 2. 通知リスナー（第二保険）
- 確認通知が遅れて届いた場合も自動同期
- バックグラウンド待機がタイムアウトしても安心

```dart
case NotificationType.syncConfirmation:
  // 念のため同期実行（二重保険）
  await userInitService.syncFromFirestoreToHive(currentUser);
  _ref.invalidate(allGroupsProvider);
```

#### 3. 通常の通知システム（第三保険）
- `groupMemberAdded`通知でもUI更新
- 最終的な同期保証

### 長時間タイムアウトのケース対応

**ケース1**: 招待元が完全オフライン
- バックグラウンド: 10秒待機 → 2秒待機後同期
- 結果: 最大12秒後に同期完了
- ユーザー体験: UIブロックなし

**ケース2**: 通知が大幅に遅延（30秒以上）
- バックグラウンド: タイムアウト後同期完了
- 通知リスナー: 遅延通知を受信して再同期
- 結果: データ整合性保証

**ケース3**: アプリがバックグラウンドに移行
- バックグラウンド処理: OSが許可すれば継続
- 通知リスナー: フォアグラウンド復帰時に処理
- 結果: アプリ再開時に自動同期

## 🎯 利点（改善版）

### 1. 確実性
- Firestoreへの書き込みが完了してから同期
- タイミング問題による削除を防止
- **三重保険でデータ損失リスク最小化**

### 2. リアルタイム性
- 招待元の確認を待ってから同期
- 不要な待機時間を削減
- **最適ケースでは確認通知後即座に同期（1-2秒）**

### 3. ユーザー体験
- **UIブロッキングなし**
- **即座に成功メッセージ表示**
- **バックグラウンドで自動同期**

### 4. フォールバック
- タイムアウト時も動作を保証
- オフライン環境でも対応可能

### 4. 拡張性
- 他の非同期処理にも適用可能
- 通知システムの汎用的な活用

## 🧪 テスト手順

### 正常系
1. Windows(maya)でグループ作成
2. QRコード生成
3. Android(すもも)でQRスキャン
4. 受諾処理実行
5. **確認**: Android側ログで`✅ 確認通知受信`を確認
6. **確認**: Windows側ログで`📤 [NOTIFICATION] 確認通知を送信`を確認
7. **確認**: Android側でグループが表示される
8. **確認**: Windows側でメンバーが追加表示される

### タイムアウトケース
1. Windows側のアプリを停止
2. Android側で招待受諾
3. **確認**: 30秒後に`⚠️ 確認通知タイムアウト`ログ
4. **確認**: フォールバック同期が実行される
5. Windows再起動後、同期でグループが表示される

## 📝 ログ出力例

### 受諾側（Android）
```
💡 ⏳ 招待元の確認通知を待機中...
💡 ⏳ [NOTIFICATION] 確認通知待機中... (最大30秒)
💡 ✅ [NOTIFICATION] 確認通知受信！
💡 ✅ 確認通知受信 - 同期準備完了
💡 🔄 招待受諾後のFirestore→Hive同期を開始
```

### 招待元（Windows）
```
💡 📬 [NOTIFICATION] 受信: group_member_added - すもも さんがグループに参加しました
💡 👥 [NOTIFICATION] 新メンバー追加 - グループ再取得
💡 🔄 [NOTIFICATION] グループ同期開始: 1762741012244
💡 📤 [NOTIFICATION] 確認通知を送信: K35DAuQUktfhSr4XWFoAtBNL32E3
```

## 🔧 関連ファイル

### 変更されたファイル
1. `lib/services/notification_service.dart`
   - `NotificationType`に`syncConfirmation`追加
   - `waitForSyncConfirmation`メソッド追加
   - `_handleNotification`に確認通知送信処理追加

2. `lib/services/qr_invitation_service.dart`
   - `acceptQRInvitation`で確認通知待機
   - `_processIndividualInvitation`でmetadata拡張
   - `_processPartnerInvitation`で通知送信とmetadata拡張

## 🚀 今後の改善案

### 1. リトライ機構
- タイムアウト時に再試行
- 指数バックオフ実装

### 2. 通知キュー
- 複数通知の一括処理
- 優先度制御

### 3. オフライン対応強化
- ローカルキャッシュ活用
- 再接続時の自動同期

### 4. パフォーマンス最適化
- 不要な同期の削減
- 差分同期の実装
