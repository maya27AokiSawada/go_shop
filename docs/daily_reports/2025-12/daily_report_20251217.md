# 日報 2025-12-17

## 作業概要

サインイン必須仕様への対応として、認証フロー全体のデータ管理を徹底的に改善。特にサインイン時の**Firestore優先読み込み**と**Hiveクリーンアップ機能**を実装し、他ユーザーデータ紛れ込み問題を完全解決。

## 実装内容

### 1. ユーザー名設定ロジック修正 ✅

**問題**: UIで「まや」入力→「fatima.sumomo」（メールアドレス前半）が設定される

**原因**:

- SharedPreferencesクリアがFirebase Auth登録**後**だった
- 前ユーザーの名前が残っていた

**修正** (`lib/pages/home_page.dart`):

```dart
// サインアップ処理順序の最適化
// 1. SharedPreferences + Hiveクリア（Firebase Auth登録前）
await UserPreferencesService.clearAllUserInfo();
await SharedGroupBox.clear();
await sharedListBox.clear();

// 2. Firebase Auth新規登録
await ref.read(authProvider).signUp(email, password);

// 3-9. プロバイダー無効化、displayName更新、同期処理
```

**結果**: デフォルトグループ名も正しいユーザー名になる

### 2. サインアウト時のデータクリア実装 ✅

**問題**: サインアウト後も前ユーザーのグループが残る

**修正** (`lib/pages/home_page.dart` Lines 705-750):

```dart
// サインアウト処理
// 1. Hive + SharedPreferencesクリア
await SharedGroupBox.clear();
await sharedListBox.clear();
await UserPreferencesService.clearAllUserInfo();

// 2. プロバイダー無効化
ref.invalidate(allGroupsProvider);
ref.invalidate(selectedGroupProvider);
ref.invalidate(sharedListProvider);

// 3. Firebase Authサインアウト
await ref.read(authProvider).signOut();
```

### 3. サインイン時のFirestore→Hive同期追加 ✅

**修正** (`lib/pages/home_page.dart` Lines 187-250):

```dart
// サインイン処理
await ref.read(authProvider).signIn(email, password);

// ユーザー名取得・保存
final firestoreUserName = await FirestoreUserNameService.getUserName();
await UserPreferencesService.saveUserName(firestoreUserName);

// Firestore→Hive同期
await Future.delayed(const Duration(seconds: 1));
await ref.read(forceSyncProvider.future);
ref.invalidate(allGroupsProvider);
await Future.delayed(const Duration(milliseconds: 500));
```

### 4. 🔥 サインイン時のFirestore優先読み込み実装（本日のメイン）

**問題**:

- デフォルトグループ作成時にHiveを先にチェック
- サインイン状態なのにFirestoreを見ない
- Firestoreに既存のデフォルトグループがあるのに新規作成してしまう

**根本原因**: サインイン必須仕様なのに、Hiveローカルキャッシュを優先していた

**修正** (`lib/providers/purchase_group_provider.dart` Lines 765-825):

```dart
// 🔥 CRITICAL: サインイン状態ではFirestoreを優先チェック
if (user != null && F.appFlavor == Flavor.prod) {
  Log.info('🔥 [CREATE DEFAULT] サインイン状態 - Firestoreから既存グループ確認');

  try {
    // Firestoreから全グループ取得
    final firestore = FirebaseFirestore.instance;
    final groupsSnapshot = await firestore
        .collection('SharedGroups')
        .where('allowedUid', arrayContains: user.uid)
        .get();

    Log.info('📊 [CREATE DEFAULT] Firestoreに${groupsSnapshot.docs.length}グループ存在');

    // デフォルトグループ（groupId = user.uid）が存在するか確認
    final defaultGroupDoc = groupsSnapshot.docs.firstWhere(
      (doc) => doc.id == defaultGroupId,
      orElse: () => throw Exception('デフォルトグループなし'),
    );

    // Firestoreにデフォルトグループが存在 → Hiveに同期して終了
    // FirestoreからSharedGroupモデルに変換
    final firestoreGroup = SharedGroup(...);
    await hiveRepository.saveGroup(firestoreGroup);

    // 🔥 Hiveクリーンアップ実行
    await _cleanupInvalidHiveGroups(user.uid, hiveRepository);

    return;
  } catch (e) {
    Log.info('💡 [CREATE DEFAULT] Firestoreにデフォルトグループなし: $e');
    // 新規作成前にもHiveクリーンアップ
    await _cleanupInvalidHiveGroups(user.uid, hiveRepository);
  }
}
```

### 5. 🔥 Hiveクリーンアップ機能実装（allowedUid不一致グループ削除）

**目的**: Hiveに残っている他ユーザーのグループを自動削除

**実装** (`lib/providers/purchase_group_provider.dart` Lines 1415-1448):

```dart
/// Hiveから不正なグループを削除（allowedUidに現在ユーザーが含まれないもの）
Future<void> _cleanupInvalidHiveGroups(
  String currentUserId,
  HiveSharedGroupRepository hiveRepository,
) async {
  try {
    Log.info('🧹 [CLEANUP] Hiveクリーンアップ開始');

    final allHiveGroups = await hiveRepository.getAllGroups();

    int deletedCount = 0;
    for (final group in allHiveGroups) {
      // allowedUidに現在のユーザーが含まれているか確認
      if (!group.allowedUid.contains(currentUserId)) {
        Log.info('🗑️ [CLEANUP] Hiveから削除（Firestoreは保持）: ${group.groupName}');
        await hiveRepository.deleteGroup(group.groupId);  // ⚠️ Hiveのみ削除
        deletedCount++;
      }
    }

    if (deletedCount > 0) {
      Log.info('✅ [CLEANUP] ${deletedCount}個の不正グループをHiveから削除（Firestoreは保持）');
    }
  } catch (e) {
    Log.error('❌ [CLEANUP] Hiveクリーンアップエラー: $e');
  }
}
```

**重要**: Firestoreは削除しない（他ユーザーが使用している可能性があるため）

### 6. getAllGroups()でのallowedUidフィルタリング追加 ✅

**二重の安全策** (`lib/providers/purchase_group_provider.dart` Lines 438-446):

```dart
// 🔥 CRITICAL: allowedUidに現在ユーザーが含まれないグループを除外
final currentUser = ref.read(authStateProvider).value;
if (currentUser != null) {
  final beforeFilterCount = allGroups.length;
  allGroups = allGroups.where((g) => g.allowedUid.contains(currentUser.uid)).toList();
  final invalidCount = beforeFilterCount - allGroups.length;
  if (invalidCount > 0) {
    Log.warning('⚠️ [ALL GROUPS] allowedUid不一致グループを除外: $invalidCount グループ');
  }
}
```

### 7. デバッグログ強化 ✅

**データソース追跡** (`lib/datastore/hybrid_purchase_group_repository.dart`, `firestore_purchase_group_repository.dart`):

```dart
// Hybrid Repository
AppLogger.info('🔍 [HYBRID] _getAllGroupsInternal開始 - Flavor: ${F.appFlavor}, Online: $_isOnline');
AppLogger.info('📦 [HYBRID] Hiveから${cachedGroups.length}グループ取得');
for (var group in cachedGroups) {
  AppLogger.info('  📦 [HIVE] ${group.groupName} - allowedUid: [...]');
}

// Firestore Repository
AppLogger.info('🔥 [FIRESTORE_REPO] getAllGroups開始 - currentUserId: ***');
AppLogger.info('✅ [FIRESTORE_REPO] ${groupsSnapshot.docs.length}グループ取得');
for (var doc in groupsSnapshot.docs) {
  AppLogger.info('  📄 [FIRESTORE_DOC] ${groupName} - allowedUid: [...]');
}
```

## テスト結果

### 動作確認（物理デバイス: SH 54D）

1. **すもも**でサインアウト→サインイン:
   - ✅ すもものデフォルトグループのみ表示
   - ✅ ファティマのグループは表示されない

2. **ファティマ**でサインアウト→サインイン:
   - ✅ ファティマのデフォルトグループのみ表示
   - ✅ すもものグループは表示されない

3. **Hiveクリーンアップ動作確認**:
   - ✅ ログに「🧹 [CLEANUP]」表示
   - ✅ 不正グループ削除数が表示
   - ✅ Firestoreコンソールで他ユーザーのグループが保持されていることを確認

### Firebase Console確認

- ✅ allowedUidに各ユーザーのUIDのみ含まれる
- ✅ デフォルトグループのgroupIdがuser.uidと一致
- ✅ グループの物理的分離が正しく機能

## 技術的学び

### 1. サインイン必須仕様の徹底

**Before**:

- Hiveローカルキャッシュ優先
- Firestoreはバックグラウンド同期のみ

**After**:

- サインイン状態では**Firestore優先**
- Hiveはキャッシュとして扱う
- Source of TruthはFirestore

### 2. データクリーンアップの重要性

**教訓**:

- ローカルキャッシュ（Hive）は汚染される
- サインイン/サインアウト時に積極的にクリーンアップ
- allowedUidを基準にフィルタリング

### 3. 二重の安全策

**実装した防御レイヤー**:

1. `createDefaultGroup()`: Firestore優先 + Hiveクリーンアップ
2. `_cleanupInvalidHiveGroups()`: 積極的な不正グループ削除
3. `getAllGroups()`: 念のためallowedUidフィルタリング

## 修正ファイル

### 認証フロー

- `lib/pages/home_page.dart` (サインアップ/サインイン/サインアウト処理)

### プロバイダー

- `lib/providers/purchase_group_provider.dart` (createDefaultGroup, getAllGroups, _cleanupInvalidHiveGroups)

### リポジトリ

- `lib/datastore/hybrid_purchase_group_repository.dart` (デバッグログ追加)
- `lib/datastore/firestore_purchase_group_repository.dart` (デバッグログ追加)

### UI

- `lib/widgets/group_list_widget.dart` (ローディングウィジェット改善)

## コミット履歴

- `4ba82a7` - "fix: ユーザー名設定ロジック修正（SharedPreferences/Hiveクリア順序）"
- `a5eb33c` - "fix: サインアウト時のHive/SharedPreferencesクリア実装"
- `09246b5` - "feat: グループ画面ローディングスピナー追加"
- `1a869a3` - "fix: サインイン時のFirestore優先読み込みとHiveクリーンアップ実装"

## 既知の問題

**なし**

前回までの「他ユーザーデータ紛れ込み問題」は完全に解決。

## 明日の予定（2025-12-18）

### 優先タスク: サインイン必須仕様への完全対応確認

**目的**: 「サインイン状態でないと操作しない」という仕様変更に全モジュールが対応しているか確認

**確認項目**:

1. **グループ操作**:
   - グループ作成（createNewGroup）
   - グループ削除（deleteGroup）
   - グループメンバー管理
   - グループ選択（selectGroup）

2. **リスト操作**:
   - リスト作成（createSharedList）
   - リスト削除（deleteSharedList）
   - リスト選択

3. **アイテム操作**:
   - アイテム追加（addSingleItem）
   - アイテム削除（removeSingleItem）
   - アイテム更新（updateSingleItem）
   - 購入状態トグル

4. **招待機能**:
   - QR招待作成（createQRInvitationData）
   - QR招待受諾（acceptQRInvitation）

5. **同期機能**:
   - Firestore→Hive同期（forceSyncProvider）
   - バックグラウンド同期

**確認方法**:

- 各操作の冒頭で`currentUser`チェック
- `currentUser == null`の場合はエラーメッセージ表示 or ログイン画面誘導
- UI側でもサインアウト状態では操作ボタン無効化

**期待される修正内容**:

- 全操作メソッドに`if (currentUser == null) return;`追加
- UI側に`enabled: currentUser != null`追加
- 適切なエラーメッセージ表示

### 予想される問題箇所

1. **リスト操作** (`shopping_list_repository.dart`):
   - Hive直接アクセスが残っている可能性
   - Firestore優先に変更が必要か確認

2. **アイテム操作** (`shopping_list_page_v2.dart`):
   - 匿名ユーザー対応コードが残っている可能性
   - `currentMemberId`取得ロジックの確認

3. **招待機能** (`qr_invitation_service.dart`):
   - サインイン必須は既に実装済みのはず
   - 念のため再確認

4. **同期処理** (`sync_service.dart`):
   - オフライン対応コードがサインイン必須と矛盾していないか確認

## その他メモ

### デバイス設定

- **SH 54D**: 192.168.0.12:42767 (デバッグ実行中)
- **TBA1011**: 192.168.0.25:40109

### 開発環境

- Branch: `oneness`
- Flavor: `dev` (Firestore有効)
- Windows + Android物理デバイステスト
