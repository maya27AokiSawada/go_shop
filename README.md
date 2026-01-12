# Go Shop - 買い物リスト共有アプリ

## Recent Implementations (2026-01-12)

### 1. Firebase設定のパッケージ名統一 ✅

**Purpose**: プロジェクト名が`go_shop`と`goshopping`で混在していた問題を解消

**Modified Files**:

- `pubspec.yaml`: `name: go_shop` → `name: goshopping`
- `google-services.json`: 
  - prod: `net.sumomo_planning.goshopping`
  - dev: `net.sumomo_planning.go_shop.dev`
- `android/app/build.gradle.kts`: `namespace = "net.sumomo_planning.goshopping"`
- `android/app/src/main/AndroidManifest.xml`: パッケージ名とラベルを統一
- 全importパス修正: `package:go_shop/` → `package:goshopping/` (15ファイル)
- `android/app/src/main/kotlin/.../MainActivity.kt`: パッケージ名を`goshopping`に統一

**Commit**: `0fe085f` - "fix: Firebase設定のパッケージ名を正式名称に統一"

### 2. アイテムタイル操作機能の改善 ✅

**Problem**: ダブルタップ編集機能が動作しなくなっていた

**Root Cause**: 
- `GestureDetector`の子要素が`ListTile`だったため、ListTile内部のインタラクティブ要素（Checkbox、IconButton）がタップイベントを優先処理

**Solution**:
- `GestureDetector` → `InkWell`に変更
- `onDoubleTap`: アイテム編集ダイアログ表示
- `onLongPress`: アイテム削除（削除権限がある場合のみ）

**Modified File**: `lib/pages/shared_list_page.dart`

**Usage Pattern**:
```dart
InkWell(
  onDoubleTap: () => _showEditItemDialog(),
  onLongPress: canDelete ? () => _deleteItem() : null,
  child: ListTile(...),
)
```

### 3. Google Play Store公開準備 ✅

**Status**: 70%完了

**Completed**:
- ✅ プライバシーポリシー: `docs/specifications/privacy_policy.md`
- ✅ 利用規約: `docs/specifications/terms_of_service.md`
- ✅ Firebase設定完了
- ✅ パッケージ名統一: `net.sumomo_planning.goshopping`
- ✅ `.gitignore`でkeystore保護
- ✅ 署名設定実装

**File Structure**:
```
android/
├── app/
│   └── upload-keystore.jks  # リリース署名用（未配置）
├── key.properties           # 署名情報（未作成）
└── key.properties.template  # テンプレート
```

**Remaining Tasks**:
- [ ] keystoreファイル配置（作業所PCから）
- [ ] key.properties作成
- [ ] AABビルドテスト
- [ ] プライバシーポリシー公開URL取得
- [ ] Play Consoleアプリ情報準備

**Build Commands**:
```bash
# リリースAPK
flutter build apk --release --flavor prod

# Play Store用AAB
flutter build appbundle --release --flavor prod
```

---

## Recent Implementations (2026-01-07)

### 1. エラー履歴機能実装 ✅

**Purpose**: ユーザーの操作エラー履歴をローカルに保存し、トラブルシューティングを支援

**Implementation Files**:

- **New Service**: `lib/services/error_log_service.dart`
  - SharedPreferencesベースの軽量エラーログ保存
  - 最新20件のみ保持（FIFO方式）
  - 5種類のエラータイプ対応（permission, network, sync, validation, operation）
  - 既読管理機能

- **New Page**: `lib/pages/error_history_page.dart`
  - エラー履歴表示画面
  - エラータイプ別アイコン・色表示
  - 時間差表示（たった今、3分前、2日前など）
  - 既読マーク・一括削除機能

- **Modified**: `lib/widgets/common_app_bar.dart`
  - 三点メニューに「エラー履歴」項目追加

**特徴**:
- ✅ SharedPreferencesのみ使用（Firestore不使用、コストゼロ）
- ✅ 最新20件自動保存
- ✅ ローカル完結（通信なし、即座に表示）
- ✅ 将来のジャーナリング機能への統合を考慮した設計

**Commit**: `7044e0c`

### 2. グループ・リスト作成時の重複名チェック実装 ✅

**Purpose**: 同じ名前のグループ・リストの作成を防止

**Implementation Files**:

- **Modified**: `lib/widgets/shared_list_header_widget.dart`
  - リスト作成時に同じグループ内の既存リスト名をチェック
  - 重複があればエラーログに記録

- **Modified**: `lib/widgets/group_creation_with_copy_dialog.dart`
  - グループ作成時に既存グループ名をチェック
  - バリデーション失敗時にエラーログ記録

**エラーメッセージ**:
- リスト: 「〇〇という名前のリストは既に存在します」
- グループ: 「〇〇という名前のグループは既に存在します」

**Commits**: `8444977`, `16485de`, `909945f`, `1e4e4cd`, `df84e44`

---

## Recent Implementations (2025-12-25)

### 1. Riverpodベストプラクティス確立 ✅

**Purpose**: LateInitializationError対応パターンの文書化とAI Coding Agent指示書整備

**Implementation Files**:

- **New Document**: `docs/riverpod_best_practices.md` (拡充)

  - セクション4追加: build()外でのRefアクセスパターン
  - `late final Ref _ref`の危険性を明記
  - `Ref? _ref` + `_ref ??= ref`パターンの説明
  - 実例（SelectedGroupNotifier）を追加
  - AsyncNotifier.build()の複数回呼び出しリスクを解説

- **Modified**: `.github/copilot-instructions.md`
  - Riverpod修正時の必須参照指示を追加
  - `docs/riverpod_best_practices.md`参照の強制化
  - `late final Ref`使用禁止の警告

**Key Pattern**:

```dart
// ❌ 危険: late final Ref → LateInitializationError
class MyNotifier extends AsyncNotifier<Data> {
  late final Ref _ref;

  @override
  Future<Data> build() async {
    _ref = ref;  // 2回目の呼び出しでエラー
    return fetchData();
  }
}

// ✅ 安全: Ref? + null-aware代入
class MyNotifier extends AsyncNotifier<Data> {
  Ref? _ref;

  @override
  Future<Data> build() async {
    _ref ??= ref;  // 初回のみ代入
    return fetchData();
  }
}
```

**Commits**: `f9da5f5`, `2e12c80`

### 2. 招待受諾バグ完全修正 ✅

**Background**: QRコード招待受諾時に通知送信は成功するが、UI・Firestoreに反映されない問題を段階的に修正

#### Phase 1: デバッグログ強化

**Modified**: `lib/services/notification_service.dart`

- `sendNotification()`に詳細ログ追加
- `_handleNotification()`に処理追跡ログ追加
- Firestore保存成功確認ログ追加

#### Phase 2: 構文エラー修正

**Problem**: if-elseブロックのインデントエラー

**Solution**: UI更新処理をifブロック内に移動

**Commit**: `38a1859`

#### Phase 3: permission-deniedエラー修正

**Problem**: 受諾者がまだグループメンバーではないのに招待使用回数を更新しようとした

**Solution**:

- **受諾側**: `_updateInvitationUsage()`削除（通知送信のみ）
- **招待元側**: メンバー追加後に`_updateInvitationUsage()`実行
- 理由: 受諾者はまだグループメンバーではない → Firestore Rules違反

**Commit**: `f2be455`

#### Phase 4: Firestoreインデックスエラー修正

**Problem**: 通知リスナーが`userId + read + timestamp`の3フィールドクエリを実行するが、インデックスが`userId + read`の2フィールドしかなかった

**Solution**: `firestore.indexes.json`に`timestamp`フィールドを追加

**Before**:

```json
{
  "collectionGroup": "notifications",
  "fields": [
    {"fieldPath": "userId", "order": "ASCENDING"},
    {"fieldPath": "read", "order": "ASCENDING"}
  ]
}
```

**After**:

```json
{
  "collectionGroup": "notifications",
  "fields": [
    {"fieldPath": "userId", "order": "ASCENDING"},
    {"fieldPath": "read", "order": "ASCENDING"},
    {"fieldPath": "timestamp", "order": "DESCENDING"}  // ← 追加
  ]
}
```

**Deployment**:

```bash
$ firebase deploy --only firestore:indexes
✔ firestore: deployed indexes successfully
```

**Commit**: `b13c7b7`

#### 修正後の期待動作

```
1. Pixel（まや）: QRコード受諾
   ✅ acceptQRInvitation()
   ✅ sendNotification() → Firestore保存成功

2. SH54D（すもも）: 通知受信 ← 修正後はこれが動作する！
   ✅ 通知リスナー起動（インデックスエラー解消）
   ✅ _handleNotification() 実行
   ✅ SharedGroups更新（allowedUid + members）
   ✅ _updateInvitationUsage() 実行（招待元権限で）
   ✅ UI反映（グループメンバー表示）
```

**Status**: 理論上完全修正 ⏳ 次回セッションで動作確認予定

**検証手順**:

1. 両デバイス再起動（Firestoreインデックス反映確認）
2. 通知リスナー起動確認（SH54Dログ: "✅ [NOTIFICATION] リスナー起動完了！"）
3. 招待受諾テスト（エンドツーエンド動作確認）
4. エラーログ確認（問題がないか最終確認）

---

## プロジェクト概要

Go Shop は家族・グループ向けの買い物リスト共有 Flutter アプリです。Firebase Auth（ユーザー認証）と Cloud Firestore（データベース）を使用し、Hive をローカルキャッシュとして併用する**Firestore-first ハイブリッドアーキテクチャ**を採用しています。

**Current Status (December 2025)**: 認証必須アプリとして、全データレイヤー（Group/List/Item）で Firestore 優先＋効率的な差分同期を実現。

## 主要機能

### ✅ 実装済み機能

1. **グループ管理**

   - グループ作成・編集・削除
   - メンバー招待（QR コード）
   - デフォルトグループ（個人専用）

2. **リスト管理**

   - リスト作成・編集・削除
   - リアルタイム同期

3. **アイテム管理**

   - アイテム追加・編集・削除
   - 購入状態トグル（全メンバー可能）
   - 削除権限チェック（登録者・オーナーのみ）
   - 期限設定（バッジ表示）
   - 定期購入設定（自動リセット）

4. **通知システム**
   - リスト作成・削除・名前変更の通知送信
   - 通知履歴表示（未読/既読管理）
   - マルチデバイス対応（同一ユーザーへの通知送信）
   - リアルタイム通知受信（Firestore Snapshots）

5. **エラー管理**
   - エラー履歴表示
   - AppBar 未確認エラーアイコン
   - 確認ボタンでアイコン消去

### 🔨 今後の実装予定

- アイテム編集機能の UI 改善
- カテゴリタグ
- 価格トラッキング

## アーキテクチャ

### 🔥 Firestore-First Hybrid Pattern（2025 年 12 月実装）

全 3 つのデータレイヤーで Firestore を優先：

1. **SharedGroup** (グループ)
2. **SharedList** (リスト)
3. **SharedItem** (アイテム) - **差分同期で 90%データ削減**

```dart
// ✅ 正しいパターン: Firestore優先、Hiveキャッシュ
if (F.appFlavor == Flavor.prod && _firestoreRepo != null) {
  try {
    // 1. Firestoreから取得（常に最新）
    final firestoreData = await _firestoreRepo!.getData();

    // 2. Hiveにキャッシュ
    await _hiveRepo.saveData(firestoreData);

    return firestoreData;
  } catch (e) {
    // Firestoreエラー → Hiveフォールバック
    return await _hiveRepo.getData();
  }
}
```

### ⚡ 差分同期（Differential Sync）

**SharedItem は Map 形式で単一アイテムのみ送信**：

```dart
// ❌ 従来: リスト全体送信（10アイテム = ~5KB）
final updatedItems = {...currentList.items, newItem.itemId: newItem};
await repository.updateSharedList(currentList.copyWith(items: updatedItems));

// ✅ 現在: 単一アイテム送信（1アイテム = ~500B）
await repository.addSingleItem(currentList.listId, newItem);
await repository.updateSingleItem(currentList.listId, updatedItem);
await repository.removeSingleItem(currentList.listId, itemId); // 論理削除
```

**パフォーマンス**:

- データ転送量: **90%削減**
- 同期速度: < 1 秒
- ネットワーク効率: 大幅改善

### 状態管理 - Riverpod

```dart
// AsyncNotifierProviderパターン
final sharedListRepositoryProvider = Provider<SharedListRepository>((ref) {
  if (F.appFlavor == Flavor.prod) {
    return HybridSharedListRepository(ref); // Firestore + Hiveキャッシュ
  } else {
    return HiveSharedListRepository(ref); // 開発環境
  }
});
```

⚠️ **重要**: Riverpod Generator は無効（バージョン競合）。従来の Provider 構文のみ使用。

## 開発環境セットアップ

### 必要な環境

- Flutter SDK: 3.27.2 以降
- Dart SDK: 3.6.1 以降
- Firebase CLI: 最新版

### 初期セットアップ

```bash
# 依存パッケージのインストール
flutter pub get

# コード生成（Hiveアダプター、Freezedクラス）
dart run build_runner build --delete-conflicting-outputs

# Firebase設定の生成
flutterfire configure
```

### ビルドコマンド

```bash
# 開発環境（Hiveのみ、高速テスト用）
flutter run --flavor dev

# 本番環境（Firestore + Hiveハイブリッド）
flutter run --flavor prod

# Androidデバッグビルド
cd android
./gradlew assembleDebug --no-daemon

# リリースビルド
flutter build apk --release --flavor prod
```

## プロジェクト構成

### 主要ディレクトリ

```
lib/
├── adapters/              # Hive TypeAdapter（カスタム）
│   ├── shopping_item_adapter_override.dart
│   └── user_settings_adapter_override.dart
├── config/                # アプリ設定
│   └── app_mode_config.dart
├── datastore/             # データレイヤー
│   ├── *_repository.dart           # 抽象インターフェース
│   ├── firestore_*_repository.dart # Firestore実装
│   ├── hive_*_repository.dart      # Hive実装
│   └── hybrid_*_repository.dart    # ハイブリッド実装
├── models/                # データモデル（Freezed + Hive）
├── pages/                 # 画面
├── providers/             # Riverpodプロバイダー
│   ├── error_notifier_provider.dart # エラー管理
│   ├── auth_provider.dart
│   ├── purchase_group_provider.dart
│   └── shared_list_provider.dart
├── services/              # ビジネスロジック
│   ├── qr_invitation_service.dart
│   ├── sync_service.dart
│   └── periodic_purchase_service.dart
├── utils/                 # ユーティリティ
│   └── app_logger.dart    # ログ管理
└── widgets/               # 再利用可能ウィジェット
```

### 重要ファイル

- **main.dart**: アプリエントリーポイント、Hive 初期化
- **flavors.dart**: 環境切り替え（dev/prod）
- **firebase_options.dart**: Firebase 設定
- **firestore.rules**: Firestore セキュリティルール

## 認証フロー

### サインアップ処理順序（重要！）

```dart
// 1. ローカルデータクリア（Firebase Auth登録前）
await UserPreferencesService.clearAllUserInfo();
await SharedGroupBox.clear();
await sharedListBox.clear();

// 2. Firebase Auth新規登録
await ref.read(authProvider).signUp(email, password);

// 3. displayName設定（SharedPreferences + Firebase Auth）
await UserPreferencesService.saveUserName(userName);
await user.updateDisplayName(userName);
await user.reload();

// 4. プロバイダー無効化
ref.invalidate(allGroupsProvider);

// 5. Firestore→Hive同期
await ref.read(forceSyncProvider.future);
```

### サインイン処理

```dart
// 1. Firebase Authサインイン
await ref.read(authProvider).signIn(email, password);

// 2. Firestoreからユーザー名取得
final firestoreUserName = await FirestoreUserNameService.getUserName();
await UserPreferencesService.saveUserName(firestoreUserName);

// 3. ネットワーク安定化待機
await Future.delayed(const Duration(seconds: 1));

// 4. Firestore→Hive同期
await ref.read(forceSyncProvider.future);
ref.invalidate(allGroupsProvider);
```

### サインアウト処理

```dart
// 1. ローカルデータクリア
await SharedGroupBox.clear();
await sharedListBox.clear();
await UserPreferencesService.clearAllUserInfo();

// 2. プロバイダー無効化
ref.invalidate(allGroupsProvider);

// 3. Firebase Authサインアウト
await ref.read(authProvider).signOut();
```

## デフォルトグループシステム

**デフォルトグループ** = ユーザー専用のプライベートグループ

### 識別ルール

```dart
bool isDefaultGroup(SharedGroup group, User? currentUser) {
  // Legacy対応
  if (group.groupId == 'default_group') return true;

  // 正式仕様
  if (currentUser != null && group.groupId == currentUser.uid) return true;

  return false;
}
```

### 特徴

- **groupId**: `user.uid`（ユーザー固有）
- **syncStatus**: `SyncStatus.local`（Firestore に同期しない）
- **削除保護**: UI/Repository/Provider の 3 層で保護
- **招待不可**: 招待機能は無効化

### 🔥 Firestore 優先チェック（サインイン時）

```dart
// サインイン状態ではFirestoreを最初にチェック
if (user != null && F.appFlavor == Flavor.prod) {
  try {
    // Firestoreから既存デフォルトグループ確認
    final groupsSnapshot = await firestore
        .collection('SharedGroups')
        .where('allowedUid', arrayContains: user.uid)
        .get();

    final defaultGroupDoc = groupsSnapshot.docs.firstWhere(
      (doc) => doc.id == user.uid,
      orElse: () => throw Exception('デフォルトグループなし'),
    );

    // 存在すればHiveに同期
    final firestoreGroup = SharedGroup.fromFirestore(defaultGroupDoc);
    await hiveRepository.saveGroup(firestoreGroup);

    // Hiveクリーンアップ実行
    await _cleanupInvalidHiveGroups(user.uid, hiveRepository);

    return;
  } catch (e) {
    // Firestoreにない → 新規作成
  }
}
```

### Hive クリーンアップ

**目的**: 他ユーザーのグループを Hive から削除

```dart
Future<void> _cleanupInvalidHiveGroups(
  String currentUserId,
  HiveSharedGroupRepository hiveRepository,
) async {
  final allHiveGroups = await hiveRepository.getAllGroups();

  for (final group in allHiveGroups) {
    if (!group.allowedUid.contains(currentUserId)) {
      await hiveRepository.deleteGroup(group.groupId); // ⚠️ Hiveのみ削除
    }
  }
}
```

⚠️ **重要**: Firestore は削除しない（他ユーザーが使用中の可能性）

## QR 招待システム

### データ構造（Firestore）

```dart
/invitations/{invitationId}
{
  'invitationId': String,
  'groupId': String,
  'groupName': String,
  'invitedBy': String,
  'inviterName': String,
  'securityKey': String,
  'maxUses': 5,
  'currentUses': 0,
  'usedBy': [],
  'status': 'pending',
  'expiresAt': DateTime,
}
```

### 招待作成

```dart
await _firestore.collection('invitations').doc(invitationId).set({
  ...invitationData,
  'maxUses': 5,
  'currentUses': 0,
  'usedBy': [],
});
```

### 招待受諾（アトミック更新）

```dart
await _firestore.collection('invitations').doc(invitationId).update({
  'currentUses': FieldValue.increment(1),
  'usedBy': FieldValue.arrayUnion([acceptorUid]),
  'lastUsedAt': FieldValue.serverTimestamp(),
});
```

## エラー管理システム（2025 年 12 月 23 日実装）

### エラー履歴プロバイダー

```dart
// lib/providers/error_notifier_provider.dart
class ErrorEntry {
  final DateTime timestamp;
  final String message;
  final String? stackTrace;
  final String? source;
  final bool isConfirmed; // 確認済みフラグ
}

class ErrorNotifier extends StateNotifier<List<ErrorEntry>> {
  void addError(String message, {String? stackTrace, String? source});
  void confirmAllErrors(); // 全エラーを確認済みに
  void clearErrors();

  int get unconfirmedErrorCount; // 未確認エラー件数
  bool get hasUnconfirmedErrors; // 未確認エラー存在
}
```

### UI 統合

**AppBar**:

- 未確認エラー時のみ×アイコン表示（バッジ付き）
- タップでエラー履歴ダイアログ表示

**スリードットメニュー**:

- エラー履歴表示（件数付き）
- エラー履歴クリア

**エラーダイアログ**:

- 「確認」ボタン → 全エラーを確認済みに変更 → ×アイコン消える
- 「クリア」ボタン → 履歴完全削除
- 未確認エラーは赤い背景で表示

### エラー記録統合箇所

```dart
// アイテム追加エラー
catch (e, stackTrace) {
  ref.read(errorNotifierProvider.notifier).addError(
    'アイテム追加失敗: $e',
    stackTrace: stackTrace.toString(),
    source: '買い物リスト - アイテム追加',
  );
}

// 購入状態変更エラー
catch (e, stackTrace) {
  ref.read(errorNotifierProvider.notifier).addError(
    '購入状態更新失敗: $e',
    stackTrace: stackTrace.toString(),
    source: '買い物リスト - 購入状態変更',
  );
}

// アイテム削除エラー
catch (e, stackTrace) {
  ref.read(errorNotifierProvider.notifier).addError(
    'アイテム削除失敗: $e',
    stackTrace: stackTrace.toString(),
    source: '買い物リスト - アイテム削除',
  );
}
```

## プライバシー保護

### ログマスキング

```dart
// 個人情報を自動マスキング
AppLogger.maskUserId(userId);        // abc*** （最初3文字のみ）
AppLogger.maskName(name);            // すも*** （最初2文字のみ）
AppLogger.maskItem(itemName, itemId); // 牛乳*** (itemId)
```

### SecretMode（実装済み）

- シークレットモード ON: 全データ非表示
- デフォルト OFF

## 開発ルール

### Git Push ポリシー

```bash
# 通常: onenessブランチのみ
git push origin oneness

# 明示的指示がある場合のみ: mainブランチにも
git push origin oneness
git push origin oneness:main
```

### コーディング規約

1. **Firestore 優先**: 常に Firestore から読み取り、Hive はキャッシュ
2. **差分同期**: `addSingleItem()`, `updateSingleItem()`, `removeSingleItem()`を使用
3. **プロパティ名**: `memberId`（`memberID`ではない）
4. **Riverpod Generator 禁止**: 従来構文のみ
5. **ログマスキング**: 個人情報は`AppLogger.mask*()`で必ずマスク

### エラーハンドリング

```dart
try {
  // 処理
} catch (e, stackTrace) {
  Log.error('❌ エラーメッセージ: $e', stackTrace);

  // エラー履歴に追加
  ref.read(errorNotifierProvider.notifier).addError(
    'ユーザー向けメッセージ: $e',
    stackTrace: stackTrace.toString(),
    source: '画面名 - 操作名',
  );
}
```

## トラブルシューティング

### ビルドエラー

```bash
# Riverpod Generatorインポートを削除
# 伝統的なProvider構文のみ使用

# コード生成
dart run build_runner build --delete-conflicting-outputs

# 静的解析
flutter analyze
```

### Hive データエラー

```bash
# Hiveボックスクリア
await SharedGroupBox.clear();
await sharedListBox.clear();

# アダプター登録順序確認
# UserSettingsAdapterOverride → その他のアダプター
```

### Firestore 同期エラー

```bash
# セキュリティルール確認
firebase deploy --only firestore:rules

# allowedUid配列に現在ユーザーが含まれるか確認
```

## Known Issues

- **TBA1011 Firestore 接続問題**: 特定デバイスで`Unable to resolve host firestore.googleapis.com`エラー（モバイル通信で回避可能）

## Recent Updates（2025 年 12 月 23 日）

### 1. エラー管理システム実装 ✅

- ErrorNotifier プロバイダー作成
- AppBar に未確認エラーアイコン表示
- エラー履歴ダイアログ（確認・クリアボタン付き）
- 全 CRUD 操作にエラー記録統合

### 2. アイテム削除権限チェック ✅

- **削除**: アイテム登録者・グループオーナーのみ
- **購入状態変更**: 全メンバー可能
- UI でボタン無効化＋ツールチップ表示

### 3. 個人情報マスキング ✅

- ログ出力を`AppLogger.maskItem()`でマスキング
- アイテム名を最初の 2 文字＋itemId のみ記録

## ライセンス

MIT License

## 開発者

- Owner: maya27AokiSawada
- Branch: oneness（開発ブランチ）
- Main: 安定版リリースブランチ
