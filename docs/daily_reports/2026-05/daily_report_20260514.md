# 開発日報 - 2026年5月14日

## 📅 本日の目標

- [x] QR招待のクロスデバイス動作不良の原因調査・修正（Mac iOS → SH-54D Android prod）
- [x] Mac Copilot が発見・修正したコードバグをWindows側に反映
- [x] SETUP.md の記載誤り修正と新規環境セットアップ注意事項の追加

---

## ✅ 完了した作業

### 1. QR招待クロスデバイスエラーの根本原因特定・修正 ✅

**Purpose**: MacのiOSシミュレーターで発行したQR招待をSH-54D（Android prod）でスキャンすると「招待が見つかりません」エラーが発生する問題を解消する

**Background**:

- Mac環境でiOS prod flavorを使用してQRコードを発行していた
- SH-54D（Android prod）でスキャンするとFirestoreの招待ドキュメントが見つからずエラー

**Root Cause**:

`ios/GoogleService-Info-prod.plist` がMac上で古いFirebaseプロジェクト (`legacy-prod-firebase-project-id`) を参照していた。
iOSネイティブSDKはこのplistを使ってFirestoreへ書き込むため、招待ドキュメントが
`legacy-prod-firebase-project-id` プロジェクトに作成された。
一方 SH-54D は `your-prod-firebase-project-id` を参照しているため、ドキュメントが見つからなかった。

```
Mac iOS (legacy-prod-firebase-project-id) → 招待ドキュメントを書き込む
SH-54D Android (your-prod-firebase-project-id) → ドキュメントが存在しない → 「招待が見つかりません」
```

副次的原因: `lib/firebase_options.dart` も Mac 上で古い `legacy-prod-firebase-project-id` の値が使われていたが、
こちらは plist 修正に加えて `flutter clean` が必要だった（Xcodeビルドキャッシュのため）。

**Solution**:

1. Mac の `ios/GoogleService-Info-prod.plist` を Firebase Console（your-prod-firebase-project-id）から再ダウンロード・置き換え
2. `flutter clean && flutter run --flavor prod --dart-define=FLAVOR=prod` で再ビルド

**検証結果**:

- 起動ログで `📋 プロジェクトID: your-prod-firebase-project-id` を確認
- 新規QR発行 → SH-54D でスキャン → 正常招待確認

**Modified Files**:

- `ios/GoogleService-Info-prod.plist`（gitignore済み・手動更新）
- `lib/firebase_options.dart`（gitignore済み・手動更新）

**Status**: ✅ 完了・動作検証済み

---

### 2. Bug Fix: watchUserGroups() — 旧コレクション名参照 ✅

**Purpose**: `firestore_group_sync_service.dart` の `watchUserGroups()` が旧コレクション名 `groups` を参照していたためリアルタイム同期が機能しない問題を修正

**Root Cause**:

```dart
// ❌ 修正前 — 旧コレクション名
return _firestore
    .collection('groups')  // 現行は 'SharedGroups'
    .where('allowedUid', arrayContains: user.uid)
    ...
```

roleのパースもインデックス参照（Firestoreに文字列で保存されているため常に範囲外）だった:

```dart
// ❌ 修正前 — インデックス参照はNG
role: SharedGroupRole.values[memberData['role']]
```

**Solution**:

```dart
// ✅ 修正後 — 正しいコレクション名
return _firestore
    .collection('SharedGroups')
    .where('allowedUid', arrayContains: user.uid)
    ...

// ✅ 修正後 — 文字列ベースのパース
role: SharedGroupRole.values.firstWhere(
  (e) => e.name == memberData['role'],
  orElse: () => SharedGroupRole.member,
),
```

また `isDeleted` フィールドのサポートも追加し、削除済みグループをフィルタリング:

```dart
isDeleted: groupData['isDeleted'] ?? false,
...
.where((g) => !g.isDeleted)
.toList();
```

**Modified Files**:

- `lib/services/firestore_group_sync_service.dart`

**Commit**: Mac Copilot が修正 → Windows側で `git pull origin future` で取り込み
**Status**: ✅ 完了

---

### 3. Bug Fix: syncConfirmation 通知ハンドラー — Dev環境でHive同期スキップ ✅

**Purpose**: `syncConfirmation` 通知受信時に、Dev環境でHiveへのグループ保存がスキップされる問題を修正

**Root Cause**:

`user_initialization_service.dart` の `syncFromFirestoreToHive()` に Dev 環境での早期リターンがある:

```dart
// user_initialization_service.dart
Future<void> syncFromFirestoreToHive(...) async {
  if (F.appFlavor != Flavor.prod) { return; }  // ← Dev環境では処理をスキップ
  ...
}
```

`syncConfirmation` ハンドラーはこのメソッドのみに依存していたため、Dev では同期が実行されなかった。

**Solution**:

`syncConfirmation` ハンドラーで `notification.groupId` を使い、直接 Firestore からグループを取得して Hive に保存するパスを追加:

```dart
// ✅ 修正後 — groupIdで直接Firestoreから取得してHiveへ保存
case NotificationType.syncConfirmation:
  final syncGroupId = notification.groupId;
  if (syncGroupId.isNotEmpty) {
    final repository = _ref.read(SharedGroupRepositoryProvider);
    final group = await repository.getGroupById(syncGroupId);
    final hiveRepository = _ref.read(hiveSharedGroupRepositoryProvider);
    await hiveRepository.saveGroup(group);
  }
  // 念のため既存パスも実行（prod環境向け）
  await userInitService.syncFromFirestoreToHive(currentUser);
  _ref.invalidate(allGroupsProvider);
```

**Modified Files**:

- `lib/services/notification_service.dart`

**Commit**: Mac Copilot が修正 → Windows側で `git pull origin future` で取り込み
**Status**: ✅ 完了

---

### 4. SETUP.md 修正・注意事項追加 ✅

**Purpose**: SETUP.md の誤った Firebase プロジェクトID と、gitignore済みファイルの手動セットアップ手順の不足を修正

**Changes**:

1. Section 2 の Production Project ID を `legacy-prod-firebase-project-id` → `your-prod-firebase-project-id` に修正
2. FlutterFire CLI コマンドのプロジェクト ID も修正
3. Section 3.3 に iOS plist ファイルは gitignore 対象であり **新規Mac環境では手動配置が必須** であることを警告追加
4. Section 10 に「iOS/MacでQR招待スキャン時『招待が見つかりません』」のトラブルシューティング追加

**Modified Files**:

- `SETUP.md`

**Commit**: `1e032b0` docs: SETUP.md - fix prod project ID and add iOS plist setup warnings
**Status**: ✅ 完了

---

### 5. Bug Fix: SingleGroupCreationDialog — サインアップ後グループ作成クラッシュ ✅

**Purpose**: サインアップ → 最初のグループ作成時に `_dependents.isEmpty: is not true` アサーションが発生してクラッシュする問題を修正

**Background**:

- サインアップ完了後に `SingleGroupCreationDialog` が表示される
- グループ名を入力して「作成」を押すとクラッシュ

**Root Cause**:

`_create()` 内で `createNewGroup()` を呼び出した直後に `await ref.read(allGroupsProvider.future)` を待っていた。
`createNewGroup()` は完了時に `allGroupsProvider` を `AsyncData([...currentGroups, newGroup])` に直接更新する。
この更新を受けて `SharedGroupPage` が即座に再ビルドされ、`InitialSetupWidget` → `GroupListWidget` に切り替わる。
この切り替えでダイアログのウィジェットコンテキストが破棄されるが、直後に `allGroupsProvider.future` の await が再開し
破棄済みの `ref` を参照したため `_dependents.isEmpty` アサーションが発生した。

```dart
// ❌ 修正前 — createNewGroup() 後に future を await するのが危険
await ref.read(allGroupsProvider.notifier).createNewGroup(groupName);
// ↑ この時点で SharedGroupPage が再ビルドされダイアログが破棄される可能性がある
final allGroups = await ref.read(allGroupsProvider.future);  // ← クラッシュ
final uid = ref.read(authStateProvider).valueOrNull?.uid;    // ← await より後に取得
```

**Solution**:

1. `createNewGroup()` より前に `uid` と `listRepo` を同期的に取得する
2. `allGroupsProvider.future` を await する代わりに、`allGroupsProvider.valueOrNull` で同期的に現在値を取得する

```dart
// ✅ 修正後 — await 前に必要な値をすべて取得済み
final uid = ref.read(authStateProvider).valueOrNull?.uid;          // ← await より前
final listRepo = ref.read(sharedListRepositoryProvider) as HybridSharedListRepository;

await ref.read(allGroupsProvider.notifier).createNewGroup(groupName);

// future を await せず同期的に現在値を取得（ウィジェット破棄後も安全）
final currentGroups = ref.read(allGroupsProvider).valueOrNull ?? [];
final newGroup = currentGroups.where((g) => g.groupName == groupName).firstOrNull;
```

**Modified Files**:

- `lib/widgets/single_group_creation_dialog.dart`

**Status**: ✅ 完了・動作確認済み

---

## 🐛 発見された問題

### 旧プロジェクトID (legacy-prod-firebase-project-id) 参照 ✅ 修正済み

- **症状**: Macで発行したQR招待をAndroidでスキャンしても「招待が見つかりません」
- **原因**: `ios/GoogleService-Info-prod.plist` が古い Firebase プロジェクトを参照
- **対処**: Firebase Console から最新の plist を取得して置き換え + flutter clean
- **状態**: 修正完了・動作確認済み

---

## 📊 バグ対応進捗

### 完了 ✅

1. ✅ QR招待クロスデバイスエラー（Mac iOS → Android prod）（完了: 2026-05-14）
2. ✅ watchUserGroups() 旧コレクション名参照バグ（完了: 2026-05-14）
3. ✅ syncConfirmation Dev環境Hive同期スキップバグ（完了: 2026-05-14）
4. ✅ SingleGroupCreationDialog サインアップ後グループ作成クラッシュ（完了: 2026-05-14）

---

## 💡 技術的学習事項

### iOS gitignore済みファイルは新規環境で必ず手動配置が必要

**問題パターン**:

- `ios/GoogleService-Info-prod.plist` は gitignore 対象
- 別のMacやマシンに環境を作ると古いファイル（前のプロジェクト）が残っている可能性がある
- `lib/firebase_options.dart` も同様（gitignore 対象）

**対処パターン**:

1. `PROJECT_ID` フィールドを確認する (`grep PROJECT_ID ios/GoogleService-Info-prod.plist`)
2. 正しい Project ID（prod: `your-prod-firebase-project-id`）でなければ Firebase Console から再取得
3. 置き換え後は **必ず** `flutter clean` を実行（Xcodeキャッシュが残るため）

**教訓**: Flavorシステムを使うiOSアプリでは、gitignore済みファイルの陳腐化が原因で本番/開発環境の混在バグが発生する。新規環境セットアップ時は必ずファイルの中身を確認すること。

---

### syncFromFirestoreToHive() は Dev 環境では無効 — 直接 Firestore 取得が必要

**問題パターン**:

```dart
// ❌ Dev環境ではスキップされるため通知ハンドラーの単独依存は危険
await userInitService.syncFromFirestoreToHive(currentUser);
```

**正しいパターン**:

```dart
// ✅ groupId で直接 Firestore からグループを取得して Hive に保存
final group = await repository.getGroupById(syncGroupId);
await hiveRepository.saveGroup(group);
// その後 syncFromFirestoreToHive() も呼ぶ（prod向け二重保険）
await userInitService.syncFromFirestoreToHive(currentUser);
```

**教訓**: `syncFromFirestoreToHive()` は Dev 環境で早期リターンするため、通知ハンドラーの Hive 同期はこのメソッドのみに依存してはいけない。

---

### createNewGroup() 完了後の allGroupsProvider.future await は危険

**問題パターン**:

```dart
// ❌ createNewGroup() 後に future を await するのは危険
// createNewGroup() が state を直接更新 → ウィジェットが破棄される可能性
await ref.read(allGroupsProvider.notifier).createNewGroup(groupName);
final allGroups = await ref.read(allGroupsProvider.future);  // クラッシュ
```

**正しいパターン**:

```dart
// ✅ 同期的に現在値を取得（ウィジェット破棄後も安全）
await ref.read(allGroupsProvider.notifier).createNewGroup(groupName);
final currentGroups = ref.read(allGroupsProvider).valueOrNull ?? [];
final newGroup = currentGroups.where((g) => g.groupName == groupName).firstOrNull;
```

また、非同期処理の前に必要な `ref.read()` を取得しておくことで、処理途中でウィジェットが破棄されても問題が起きにくくなる:

```dart
// ✅ await より前に必要な値をすべて取得
final uid = ref.read(authStateProvider).valueOrNull?.uid;
final listRepo = ref.read(sharedListRepositoryProvider) as HybridSharedListRepository;
await someLongAsyncOperation();  // この間にウィジェットが破棄されても uid/listRepo は有効
```

**教訓**: Providerの状態更新が呼び出し元ウィジェットのツリーを変更する場合（例: `allGroupsProvider` の更新で `SharedGroupPage` が `InitialSetupWidget` → `GroupListWidget` に再ビルドされる場合）、その後の `future` await はウィジェット破棄後に再開して `_dependents.isEmpty` アサーションを引き起こす。同期的な `valueOrNull` 取得に切り替えること。

---

## 🗓 翌日（2026-05-15）の予定

1. 引き続き動作検証（必要に応じて追加バグ調査）

---

## 📝 ドキュメント更新

| ドキュメント                              | 更新内容                                                                                 |
| ----------------------------------------- | ---------------------------------------------------------------------------------------- |
| `SETUP.md`                                | prod Project ID修正、iOS plist手動配置警告追加、QR招待エラーのトラブルシューティング追加 |
| `instructions/40_qr_and_notifications.md` | 通知タイプ表に `syncConfirmation` を追加、syncFromFirestoreToHive()のDev制限注意を追記   |
| `instructions/20_groups_lists_items.md`   | 更新なし（ロール文字列パース・コレクション名のルールは既に記載済み）                     |
| `instructions/50_user_and_settings.md`    | `SingleGroupCreationDialog` の非同期アンチパターン禁止事項を追加                         |
