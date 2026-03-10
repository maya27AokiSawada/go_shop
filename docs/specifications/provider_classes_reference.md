# Provider Classes Reference

**作成日**: 2026-02-19
**プロバイダーファイル数**: 21ファイル
**総プロバイダー数**: 60+ providers
**目的**: GoShoppingアプリで使用される全プロバイダーの包括的なリファレンス

---

## 📚 凡例

Provider種別による分類:

- 🔵 **Provider** - 不変値提供（Repositoryインスタンス、サービスインスタンス等）
- 🟢 **StateProvider** - 単純な状態管理（プリミティブ値）
- 🟡 **StateNotifierProvider** - カスタムStateNotifierによる状態管理
- 🔴 **AsyncNotifierProvider** - 非同期データフェッチ＋状態管理
- 🟠 **FutureProvider** - 非同期データ取得（読み取り専用）
- 🟣 **StreamProvider** - リアルタイムデータストリーム監視
- 🟤 **Family** - パラメータ付きプロバイダー（`.family`サフィックス）
- 🔷 **AutoDispose** - 使用されていない時に自動破棄（`.autoDispose`サフィックス）

機能分類:

- 🔐 認証・ユーザー
- 👥 グループ管理
- 📋 リスト管理
- 🎨 ホワイトボード
- 📰 ニュース
- 💳 サブスクリプション
- 🔒 セキュリティ
- 💾 ストレージ
- 🔄 同期
- 🖥️ UI状態

---

## 📦 プロバイダー一覧 (アルファベット順)

### A

#### 🟠 allGroupsProvider {#allGroupsProvider}

**ファイル**: `lib/providers/shared_group_provider.dart` (Line 1060)
**種別**: 🔴 AsyncNotifierProvider<AllGroupsNotifier, List<SharedGroup>>
**目的**: 現在ログイン中ユーザーの全グループを管理

**主要メソッド**:

- `build()`: Firestoreから全グループフェッチ（allowedUidフィルタリング）
- `createNewGroup(String groupName)`: 新規グループ作成（デバイスIDプレフィックス使用）
- `deleteGroup(String groupId)`: グループ削除
- `updateGroup(String groupId, SharedGroup group)`: グループ更新
- `syncFromFirestore()`: Firestore→Hive同期を強制実行
- `_cleanupInvalidHiveGroups()`: 他ユーザーのグループをHiveから削除

**使用場所**: GroupListWidget, HomeScreen, InitialSetupWidget

**特徴**:

- Firestore優先アーキテクチャ（Hiveはキャッシュ）
- allowedUidフィルタリングで他ユーザーのグループを除外
- グループ作成時にデバイスIDプレフィックス自動付与（ID衝突防止）
- Recent Fix (2026-02-13): デフォルトグループ機能削除、Firestore優先チェック実装

**データフロー**:

```dart
Firestore (allowedUid filter) → Hive cache → allGroupsProvider
                                                    ↓
                                          GroupListWidget表示
```

---

#### 🟠 allWhiteboardsProvider {#allWhiteboardsProvider}

**ファイル**: `lib/providers/whiteboard_provider.dart` (Line 53)
**種別**: 🟠 FutureProvider.family<List<Whiteboard>, String>
**目的**: グループの全ホワイトボード取得（グループ共通＋個人用全て）

**パラメータ**: `groupId` (String)

**使用場所**: GroupMemberManagementPage（ホワイトボード一覧表示）

**特徴**:

- グループ共通ホワイトボード＋全メンバーの個人ホワイトボードを取得
- Firestore Subcollection `/SharedGroups/{groupId}/whiteboards/` から取得

---

#### 🔵 appModeNotifierProvider {#appModeNotifierProvider}

**ファイル**: `lib/providers/app_mode_notifier_provider.dart`
**種別**: 🟢 StateProvider<AppMode>
**目的**: アプリモード切り替え通知（買い物リスト⇄TODOタスク）

**初期値**: `AppModeSettings.currentMode`（AppModeConfigから取得）

**使用場所**: SettingsPage（モード切り替えボタン）, HomeScreen（BottomNavigation表示名）

**関連機能**: `lib/config/app_mode_config.dart` (AppMode enum, AppModeConfig)

**特徴**:

- UI強制再構築用の通知プロバイダー
- 実際の設定値は`AppModeSettings.currentMode`が保持
- Recent Implementation (2025-11-18): アプリモード機能実装

---

#### 🟠 authProvider {#authProvider}

**ファイル**: `lib/providers/auth_provider.dart` (661 lines)
**種別**: Providerクラス（FirebaseAuthService）
**目的**: Firebase Authentication操作を提供

**主要メソッド**:

- `signIn(String email, String password)`: メールアドレス/パスワードでサインイン
- `signUp(String email, String password)`: 新規アカウント作成
- `signOut()`: ログアウト実行
- `sendPasswordResetEmail(String email)`: パスワードリセットメール送信（レート制限付き）

**使用場所**: HomePage, SettingsPage, 全ての認証が必要な画面

**特徴**:

- Firebase Extensionメール送信統合（Firestore Trigger Email）
- レート制限機能（24時間で5通まで）
- Firestore `/mail_rate_limit/{email}` コレクション活用
- Recent Fix (2025-12-17): サインアップ時のデータクリア順序修正

**Firebase Extension連携**:

```dart
// Firestore Trigger Email用のドキュメントを作成
await FirebaseFirestore.instance.collection('mail').add({
  'to': [email],
  'template': {
    'name': 'password-reset',
    'data': { 'email': email, 'resetLink': '...' },
  },
  'createdAt': FieldValue.serverTimestamp(),
});
```

---

#### 🟣 authStateProvider {#authStateProvider}

**ファイル**: `lib/providers/auth_provider.dart`
**種別**: 🟣 StreamProvider<User?>
**目的**: Firebase Authの認証状態リアルタイム監視

**データソース**: `FirebaseAuth.instance.authStateChanges()`

**使用場所**: 全アプリ画面（認証状態でUI切り替え）

**特徴**:

- ユーザーがログイン/ログアウトすると自動的にUIが更新される
- null = 未認証, User型 = 認証済み
- アプリ起動時の初期化トリガーとしても使用

---

#### 🔵 authRequiredProvider {#authRequiredProvider}

**ファイル**: `lib/providers/security_provider.dart`
**種別**: 🔵 Provider<bool>
**目的**: 認証が必要かどうかを判定

**依存プロバイダー**: secretModeProvider, authStateProvider

**ロジック**:

```dart
if (!isSecretMode) return false; // シークレットモード無効 → 認証不要
return authState.when(
  data: (user) => user == null,  // 未ログイン → 認証必要
  loading: () => true,
  error: (_, __) => true,
);
```

**使用場所**: HomePage, SharedListPage（認証ガード）

**特徴**: シークレットモードが有効かつ未ログインの場合のみ`true`

---

### C

#### 🔵 currentListProvider {#currentListProvider}

**ファイル**: `lib/providers/current_list_provider.dart` (143 lines)
**種別**: 🟡 StateNotifierProvider<CurrentListNotifier, SharedList?>
**目的**: 現在選択中の買い物リストを管理（グループごとに保存）

**主要メソッド**:

- `selectList(SharedList list, {String? groupId})`: リスト選択（SharedPreferences保存）
- `getSavedListIdForGroup(String groupId)`: グループの最終使用リストID取得
- `clearSelection()`: 選択解除

**SharedPreferences構造**:

```json
{
  "group_list_map": "{\"groupId1\":\"listId1\", \"groupId2\":\"listId2\"}"
}
```

**使用場所**: SharedListPage, ShoppingListHeaderWidget

**特徴**:

- グループごとに最終使用リストを記憶
- 後方互換モード対応（`current_list_id`キー）
- Recent Fix (2025-12-05): DropdownButton reactive updates対応

---

#### 🔵 currentNewsProvider {#currentNewsProvider}

**ファイル**: `lib/providers/news_provider.dart`
**種別**: 🟠 FutureProvider<AppNews>
**目的**: アプリニュースをFirestoreから一度だけ取得

**データソース**: `FirestoreNewsService.getCurrentNews()`

**使用場所**: NewsAndAdsPanelWidget（初期ロード）

**特徴**: 一度取得したら再取得しない（FutureProvider特性）

---

#### 🔵 currentUserIdProvider {#currentUserIdProvider}

**ファイル**: `lib/providers/user_specific_hive_provider.dart`
**種別**: 🔵 Provider<String?>
**目的**: 現在ログイン中のユーザーIDを取得

**依存プロバイダー**: authStateProvider

**使用場所**: HiveInitializationService, UserSpecificHiveService

---

### D

#### 🔵 dataVisibilityProvider {#dataVisibilityProvider}

**ファイル**: `lib/providers/security_provider.dart`
**種別**: 🔵 Provider<bool>
**目的**: データを表示可能かどうかを判定

**依存プロバイダー**: secretModeProvider, authStateProvider

**ロジック**:

```dart
if (!isSecretMode) return true;  // シークレットモード無効 → 常に表示OK
return authState.when(
  data: (user) => user != null,  // ログイン済み → 表示OK
  loading: () => false,
  error: (_, __) => false,
);
```

**使用場所**: HomePage, SharedListPage（データ表示制御）

---

#### 🔵 deviceSettingsServiceProvider {#deviceSettingsServiceProvider}

**ファイル**: `lib/providers/device_settings_provider.dart`
**種別**: 🔵 Provider<DeviceSettingsService>
**目的**: デバイス設定サービスインスタンス提供

**使用場所**: secretModeProvider

---

### F

#### 🔵 firestoreProvider {#firestoreProvider}

**ファイル**: `lib/providers/firestore_provider.dart`
**種別**: 🔵 Provider<FirebaseFirestore>
**目的**: FirebaseFirestoreインスタンスを一元管理

**特徴**:

- アプリ全体で同じインスタンス使用
- 設定は初回のみ適用（複数回呼び出しても安全）
- 開発環境（Flavor.dev）では設定スキップ

**使用場所**: 全てのFirestore操作

---

#### 🟠 forceSyncProvider {#forceSyncProvider}

**ファイル**: `lib/providers/shared_group_provider.dart`
**種別**: 🟠 FutureProvider<void>
**目的**: 手動同期トリガー（Firestore→Hive強制同期）

**実行内容**: `SyncService.syncAllGroupsFromFirestore()`呼び出し

**使用場所**: HomePage（手動同期ボタン）, サインイン後の自動同期

**特徴**:

- `ref.refresh(forceSyncProvider)`で手動実行可能
- Recent Implementation (2025-12-17): サインイン時の自動同期統合

---

### G

#### 🟠 groupSharedListsProvider {#groupSharedListsProvider}

**ファイル**: `lib/providers/group_shopping_lists_provider.dart`
**種別**: 🟠🔷 FutureProvider.autoDispose<List<SharedList>>
**目的**: 現在のグループに属するリスト一覧を取得

**依存プロバイダー**: selectedGroupIdProvider, allGroupsProvider

**使用場所**: ShoppingListHeaderWidget（ドロップダウン表示）

**特徴**:

- リストが1件のみの場合は自動的にcurrentListProviderに設定
- 削除されたグループのリストは表示しない（`isDeleted`チェック）
- Recent Fix (2025-12-06): リスト作成後の自動選択実装

**自動選択ロジック**:

```dart
if (groupLists.length == 1) {
  final shouldSetCurrent = currentList == null ||
      currentList.groupId != currentGroup.groupId ||
      !groupLists.any((list) => list.listId == currentList.listId);

  if (shouldSetCurrent) {
    await ref.read(currentListProvider.notifier).selectList(
      groupLists.first, groupId: currentGroup.groupId
    );
  }
}
```

---

#### 🟠 groupWhiteboardProvider {#groupWhiteboardProvider}

**ファイル**: `lib/providers/whiteboard_provider.dart`
**種別**: 🟠🟤 FutureProvider.family<Whiteboard?, String>
**目的**: グループ共通ホワイトボードを取得（一度だけ）

**パラメータ**: `groupId` (String)

**使用場所**: WhiteboardPreviewWidget（初期ロード）

---

### H

#### 🟠 hiveInitializationStatusProvider {#hiveInitializationStatusProvider}

**ファイル**: `lib/providers/user_specific_hive_provider.dart`
**種別**: 🔵 Provider<bool>
**目的**: Hive初期化完了状態を監視

**依存プロバイダー**: hiveUserInitializationProvider

**使用場所**: AppInitializeWidget（初期化待機）

---

#### 🟠 hiveUserInitializationProvider {#hiveUserInitializationProvider}

**ファイル**: `lib/providers/user_specific_hive_provider.dart`
**種別**: 🟠 FutureProvider<void>
**目的**: ユーザー固有のHive初期化を実行

**プラットフォーム別処理**:

- **Windows**: 最後に使用したUIDフォルダを継続（認証状態に関係なし）
- **Android/iOS**: デフォルトフォルダ使用

**使用場所**: main.dart（アプリ起動時）

---

#### 🔵 hybridRepositoryProvider {#hybridRepositoryProvider}

**ファイル**: `lib/providers/shared_group_provider.dart`
**種別**: 🔵 Provider<HybridSharedGroupRepository?>
**目的**: HybridSharedGroupRepositoryインスタンス提供

**使用場所**: SyncService, AllGroupsNotifier

---

### I

#### 🔵 isNewsLoadingProvider {#isNewsLoadingProvider}

**ファイル**: `lib/providers/news_provider.dart`
**種別**: 🔵 Provider<bool>
**目的**: ニュースが読み込み中かどうかを取得

**依存プロバイダー**: newsStreamProvider

---

#### 🔵 isPremiumActiveProvider {#isPremiumActiveProvider}

**ファイル**: `lib/providers/subscription_provider.dart`
**種別**: 🔵 Provider<bool>
**目的**: プレミアム機能が利用可能かどうかを判定

**依存プロバイダー**: subscriptionProvider

**ロジック**: トライアル期間中または有料プラン有効期限内で`true`

**使用場所**: HomePage, PremiumPage（機能制限チェック）

---

#### 🟣 isSyncingProvider {#isSyncingProvider}

**ファイル**: `lib/providers/shared_group_provider.dart`
**種別**: 🟣 StreamProvider<bool>
**目的**: 同期中かどうかをリアルタイム監視

**データソース**: `SyncService.syncStatusStream`（SyncService起動時のStream）

**使用場所**: CommonAppBar（同期アイコン表示）

---

### L

#### 🔵 lastUsedGroupIdProvider {#lastUsedGroupIdProvider}

**ファイル**: `lib/providers/user_settings_provider.dart`
**種別**: 🔵 Provider<String>
**目的**: 最後に使用したグループIDを取得

**依存プロバイダー**: userSettingsProvider

**使用場所**: GroupListWidget（前回選択グループの自動選択）

---

#### 🔵 lastUsedSharedListIdProvider {#lastUsedSharedListIdProvider}

**ファイル**: `lib/providers/user_settings_provider.dart`
**種別**: 🔵 Provider<String>
**目的**: 最後に使用したリストIDを取得

**依存プロバイダー**: userSettingsProvider

**使用場所**: ShoppingListHeaderWidget（前回選択リストの自動選択）

---

### M

#### 🔵 memberPoolProvider {#memberPoolProvider}

**ファイル**: `lib/providers/shared_group_provider.dart`
**種別**: 🟠 FutureProvider<List<SharedGroupMember>>
**目的**: 全グループのメンバープールを取得

**使用場所**: GroupMemberManagementPage（メンバー選択ダイアログ）

---

### N

#### 🔵 newsErrorProvider {#newsErrorProvider}

**ファイル**: `lib/providers/news_provider.dart`
**種別**: 🔵 Provider<String?>
**目的**: ニュース表示エラーを取得

**依存プロバイダー**: newsStreamProvider

---

#### 🟣 newsStreamProvider {#newsStreamProvider}

**ファイル**: `lib/providers/news_provider.dart`
**種別**: 🟣 StreamProvider<AppNews>
**目的**: リアルタイムニュース更新監視

**データソース**: `FirestoreNewsService.watchCurrentNews()`（Firestore snapshots()）

**使用場所**: NewsAndAdsPanelWidget（リアルタイム更新表示）

**特徴**: Firestoreの`/appNews/current`ドキュメントを監視

---

### P

#### 🔵 pageIndexProvider {#pageIndexProvider}

**ファイル**: `lib/providers/page_index_provider.dart`
**種別**: 🟡🔷 StateNotifierProvider.autoDispose<PageIndexNotifier, int>
**目的**: BottomNavigationBarの現在ページインデックス管理

**使用場所**: HomeScreen（BottomNavigationBar）

**特徴**: 自動破棄（autoDispose）でメモリ効率化

---

#### 🟠 personalWhiteboardProvider {#personalWhiteboardProvider}

**ファイル**: `lib/providers/whiteboard_provider.dart`
**種別**: 🟠🟤 FutureProvider.family<Whiteboard?, ({String groupId, String userId})>
**目的**: 個人用ホワイトボードを取得

**パラメータ**: record型 `({String groupId, String userId})`

**使用場所**: MemberTileWithWhiteboard（個人ホワイトボードプレビュー）

---

### S

#### 🔵 secretModeProvider {#secretModeProvider}

**ファイル**: `lib/providers/device_settings_provider.dart`
**種別**: 🟡 StateNotifierProvider<SecretModeNotifier, bool>
**目的**: シークレットモード状態管理

**主要メソッド**:

- `toggleSecretMode()`: ON/OFF切り替え
- `setSecretMode(bool enabled)`: 直接設定

**使用場所**: SettingsPage（ToggleSwitch）

**特徴**: DeviceSettingsServiceと連携してSharedPreferencesに永続化

---

#### 🔵 selectedGroupIdProvider {#selectedGroupIdProvider}

**ファイル**: `lib/providers/shared_group_provider.dart`
**種別**: 🟡 StateNotifierProvider<SelectedGroupIdNotifier, String?>
**目的**: 選択中のグループIDを管理（SharedPreferences永続化）

**主要メソッド**:

- `selectGroupId(String? groupId)`: グループID選択
- `clearSelection()`: 選択解除

**使用場所**: GroupListWidget, HomeScreen

**特徴**:

- SharedPreferencesに`selected_group_id`キーで保存
- アプリ再起動時に前回選択グループを復元

---

#### 🔴 selectedGroupNotifierProvider {#selectedGroupNotifierProvider}

**ファイル**: `lib/providers/shared_group_provider.dart`
**種別**: 🔴 AsyncNotifierProvider<SelectedGroupNotifier, SharedGroup?>
**目的**: 選択中のグループの詳細情報管理

**主要メソッド**:

- `build()`: selectedGroupIdProviderからグループID取得→詳細フェッチ
- `saveGroup(SharedGroup group)`: グループ情報保存（楽観的更新）
- `loadGroup(String groupId)`: 特定グループロード
- `deleteCurrentGroup()`: 現在のグループ削除
- `_fixLegacyMemberRoles()`: レガシーロール修正

**使用場所**: GroupMemberManagementPage, SharedListPage

**特徴**:

- レガシーロール（parent, child）を自動的にmemberに変換
- 複数ownerがいる場合は最初のownerのみ保持
- Recent Fix (2025-11-17): UID変更時のmemberId自動修正

**⚠️ Critical Pattern**:

```dart
// Refフィールド（他のメソッドでプロバイダーアクセスに使用）
Ref? _ref;

@override
Future<SharedGroup?> build() async {
  _ref ??= ref;  // ⚠️ nullable + null-aware代入でbuild()の複数回呼び出しに対応
  // ...
}
```

詳細: `docs/riverpod_best_practices.md` Section 4

---

#### 🔵 selectedGroupProvider {#selectedGroupProvider}

**ファイル**: `lib/providers/shared_group_provider.dart`
**種別**: 🔵 Provider<AsyncValue<SharedGroup?>>
**目的**: selectedGroupNotifierProviderの状態を取得（ショートカット）

**使用場所**: SharedListPage, GroupMemberManagementPage

---

#### 🔵 SharedGroupBoxProvider {#SharedGroupBoxProvider}

**ファイル**: `lib/providers/hive_provider.dart`
**種別**: 🔵 Provider<Box<SharedGroup>>
**目的**: Hive SharedGroupsボックスインスタンス提供

**エラーハンドリング**: Boxが開いていない場合はStateError

**使用場所**: HiveSharedGroupRepository

---

#### 🔵 SharedGroupRepositoryProvider {#SharedGroupRepositoryProvider}

**ファイル**: `lib/providers/shared_group_provider.dart`
**種別**: 🔵 Provider<SharedGroupRepository>
**目的**: SharedGroupRepositoryインスタンス提供（Hybrid構成）

**実装**: HybridSharedGroupRepository返却（Firestore + Hiveハイブリッド）

**使用場所**: AllGroupsNotifier, SelectedGroupNotifier

**特徴**: devフレーバーもprodフレーバーも同じHybrid実装使用

---

#### 🔵 sharedListBoxProvider {#sharedListBoxProvider}

**ファイル**: `lib/providers/hive_provider.dart`, `lib/providers/shared_list_provider.dart`
**種別**: 🔵 Provider<Box<SharedList>>
**目的**: Hive sharedListsボックスインスタンス提供

**使用場所**: HiveSharedListRepository

---

#### 🔴 sharedListForGroupProvider {#sharedListForGroupProvider}

**ファイル**: `lib/providers/shared_list_provider.dart`
**種別**: 🔴🟤 AsyncNotifierProvider.family<SharedListForGroupNotifier, SharedList, String>
**目的**: グループ別のSharedList状態管理

**パラメータ**: `groupId` (String)

**使用場所**: （現在は未使用、レガシー）

---

#### 🔴 sharedListProvider {#sharedListProvider}

**ファイル**: `lib/providers/shared_list_provider.dart` (442 lines)
**種別**: 🔴 AsyncNotifierProvider<SharedListNotifier, SharedList>
**目的**: 現在のSharedList状態管理

**主要メソッド**:

- `build()`: selectedGroupProviderからグループ取得→デフォルトリスト作成/復元
- `addItem(SharedItem item)`: アイテム追加
- `removeItem(String itemId)`: アイテム削除（論理削除）
- `updateItem(SharedItem item)`: アイテム更新

**使用場所**: SharedListPage, ShoppingListPageV2

**特徴**:

- SharedGroup nullの場合はデフォルトリスト返却
- Hiveから既存リスト復元時にグループ情報を自動更新
- Recent Fix (2025-11-25): Map形式への移行（`activeItems`使用）

---

#### 🔵 sharedListRepositoryProvider {#sharedListRepositoryProvider}

**ファイル**: `lib/providers/shared_list_provider.dart`
**種別**: 🔵 Provider<SharedListRepository>
**目的**: SharedListRepositoryインスタンス提供（Hybrid構成）

**実装**: HybridSharedListRepository返却

**使用場所**: SharedListNotifier, groupSharedListsProvider

---

#### 🔵 shouldShowAdsProvider {#shouldShowAdsProvider}

**ファイル**: `lib/providers/subscription_provider.dart`
**種別**: 🔵 Provider<bool>
**目的**: 広告を表示すべきかどうかを判定

**依存プロバイダー**: subscriptionProvider

**ロジック**: `!isPremiumActive`（プレミアム非アクティブなら広告表示）

**使用場所**: HomePage, NewsAndAdsPanelWidget（AdBannerWidget表示制御）

---

#### 🔵 shouldShowPaymentReminderProvider {#shouldShowPaymentReminderProvider}

**ファイル**: `lib/providers/subscription_provider.dart`
**種別**: 🔵 Provider<bool>
**目的**: 課金リマインダーを表示すべきかどうかを判定

**依存プロバイダー**: subscriptionProvider

**ロジック**:

```dart
final state = ref.watch(subscriptionProvider);
// トライアル残り≤3日 または 有料プラン期限≤7日
return (state.isTrialActive && state.remainingTrialDays <= 3) ||
       (state.plan != SubscriptionPlan.free && state.expiryDate != null &&
        state.expiryDate.difference(DateTime.now()).inDays <= 7);
```

**使用場所**: HomePage（PaymentReminderWidget表示制御）

---

#### 🔵 subscriptionProvider {#subscriptionProvider}

**ファイル**: `lib/providers/subscription_provider.dart` (304 lines)
**種別**: 🟡 StateNotifierProvider<SubscriptionNotifier, SubscriptionState>
**目的**: サブスクリプション状態管理（無料/年間/3年）

**主要メソッド**:

- `startTrial()`: 無料体験開始（7日間）
- `purchasePlan(SubscriptionPlan plan)`: プラン購入
- `cancelSubscription()`: サブスクリプションキャンセル
- `restoreSubscription()`: 購入復元

**Stateフィールド**:

- `plan`: SubscriptionPlan (free/yearly/threeYear)
- `purchaseDate`, `expiryDate`: 購入日・有効期限
- `isTrialActive`: トライアル中フラグ
- `trialStartDate`: トライアル開始日
- `trialDays`: トライアル日数（デフォルト7日）

**Getter**:

- `isPremiumActive`: プレミアム機能利用可能か（トライアルまたは有料プラン有効）
- `remainingTrialDays`: トライアル残り日数
- `planDisplayName`: プラン表示名
- `planPrice`: プラン価格

**使用場所**: PremiumPage, HomePage（プレミアム機能制限）

**Hive永続化**: SubscriptionStateをHive Boxに保存

---

#### 🔵 syncStatusProvider {#syncStatusProvider}

**ファイル**: `lib/providers/shared_group_provider.dart`
**種別**: 🔵 Provider<SyncStatus>
**目的**: 同期状態を取得（online/offline/syncing/error）

**依存プロバイダー**: isSyncingProvider, hybridRepositoryProvider

**使用場所**: CommonAppBar（同期アイコン色変更）

**SyncStatus値**:

- `online`: 同期成功（緑）
- `offline`: オフライン（灰色）
- `syncing`: 同期中（オレンジ）
- `error`: 同期エラー（赤）

---

### U

#### 🔵 userNameDisplayProvider {#userNameDisplayProvider}

**ファイル**: `lib/providers/user_name_provider.dart`
**種別**: 🟡 StateNotifierProvider<UserNameDisplayNotifier, AsyncValue<String?>>
**目的**: ユーザー名表示用（プリファレンスベース、リアクティブ更新）

**主要メソッド**:

- `refresh()`: プリファレンスから再読み込み
- `updateUserName(String newUserName)`: ユーザー名更新

**使用場所**: HomePage, UserNamePanelWidget

**特徴**:

- コンストラクタで即座に初期読み込み（再起動時の問題回避）
- Firestore同期は一時的に無効化（デバッグ用）

---

#### 🔵 userNameFromSettingsProvider {#userNameFromSettingsProvider}

**ファイル**: `lib/providers/user_settings_provider.dart`
**種別**: 🔵 Provider<String>
**目的**: UserSettingsからユーザー名を取得

**依存プロバイダー**: userSettingsProvider

---

#### 🔵 userNameManagerProvider {#userNameManagerProvider}

**ファイル**: `lib/providers/user_name_manager.dart` (131 lines)
**種別**: 🔵🟤 Provider.family<UserNameManager, WidgetRef>
**目的**: ユーザー名管理の統合インターフェース（UIロジック統合）

**主要メソッド**:

- `getUserName()`: 優先順位で取得（Prefs → Firestore → Auth → Email）
- `updateUserName(String name)`: Prefs + Firestore同期更新
- `_saveToPreferences(String name)`: SharedPreferences保存
- `_saveToFirestore(String name)`: Firestore保存

**使用場所**: HomePage, SettingsPage（ユーザー名表示・編集）

**特徴**: Widgetレベルでrefを受け取り、プロバイダー無効化等のUI操作を実行

---

#### 🔵 userNameNotifierProvider {#userNameNotifierProvider}

**ファイル**: `lib/providers/user_name_provider.dart`
**種別**: 🔴 AsyncNotifierProvider<UserNameNotifier, void>
**目的**: ユーザー名設定・復元操作

**主要メソッド**:

- `setUserName(String userName)`: SharedPreferences + Firestore両方に保存
- `restoreUserNameFromFirestore()`: Firestoreから復帰
- `restoreUserNameFromPreferences()`: SharedPreferencesから復帰

**使用場所**: HomePage（サインアップ・サインイン時）

---

#### 🔵 userNameProvider {#userNameProvider}

**ファイル**: `lib/providers/user_name_provider.dart`
**種別**: 🟠 FutureProvider<String>
**目的**: ユーザー名を非同期取得

**使用場所**: （現在は未使用、レガシー）

---

#### 🔴 userSettingsProvider {#userSettingsProvider}

**ファイル**: `lib/providers/user_settings_provider.dart`
**種別**: 🔴 AsyncNotifierProvider<UserSettingsNotifier, UserSettings>
**目的**: ユーザー設定の全般管理

**主要メソッド**:

- `updateUserName(String userName)`: ユーザー名更新
- `updateLastUsedGroupId(String groupId)`: 最終使用グループID更新
- `updateLastUsedSharedListId(String sharedListId)`: 最終使用リストID更新
- `clearAllSettings()`: 全設定クリア
- `updateUserId(String userId)`: ユーザーID更新
- `updateUserEmail(String userEmail)`: ユーザーメール更新
- `updateListNotifications(bool enabled)`: リスト通知設定更新
- `hasUserIdChanged(String newUserId)`: ユーザーID変更チェック

**使用場所**: SettingsPage, HomePage（設定読み書き）

**特徴**: UserSettingsRepositoryと連携してHiveに永続化

---

#### 🔵 userSettingsBoxProvider {#userSettingsBoxProvider}

**ファイル**: `lib/providers/hive_provider.dart`
**種別**: 🔵 Provider<Box<UserSettings>>
**目的**: Hive userSettingsボックスインスタンス提供

**使用場所**: UserSettingsRepository

---

#### 🔵 userSpecificHiveProvider {#userSpecificHiveProvider}

**ファイル**: `lib/providers/user_specific_hive_provider.dart`
**種別**: 🔵 Provider<UserSpecificHiveService>
**目的**: ユーザー固有Hiveサービスインスタンス提供

**使用場所**: hiveUserInitializationProvider

---

### W

#### 🟠 watchGroupWhiteboardProvider {#watchGroupWhiteboardProvider}

**ファイル**: `lib/providers/whiteboard_provider.dart`
**種別**: 🟣🟤 StreamProvider.family<Whiteboard?, String>
**目的**: グループ共通ホワイトボードリアルタイム監視

**パラメータ**: `groupId` (String)

**データソース**: `WhiteboardRepository.watchWhiteboard()`（Firestore snapshots()）

**使用場所**: WhiteboardPreviewWidget（リアルタイム編集反映）

**特徴**:

- まずgetGroupWhiteboard()でwhiteboardId取得
- その後リアルタイム監視開始

---

#### 🟠 watchWhiteboardProvider {#watchWhiteboardProvider}

**ファイル**: `lib/providers/whiteboard_provider.dart`
**種別**: 🟣🟤 StreamProvider.family<Whiteboard?, ({String groupId, String whiteboardId})>
**目的**: 特定ホワイトボードのリアルタイム監視

**パラメータ**: record型 `({String groupId, String whiteboardId})`

**使用場所**: WhiteboardEditorPage（編集中のリアルタイム同期）

**特徴**: `_hasEditLock`フラグで自分の編集中は上書きしない制御

---

#### 🔵 whiteboardRepositoryProvider {#whiteboardRepositoryProvider}

**ファイル**: `lib/providers/whiteboard_provider.dart`
**種別**: 🔵 Provider<WhiteboardRepository>
**目的**: WhiteboardRepositoryインスタンス提供

**使用場所**: 全whiteboardプロバイダー

---

## 📊 統計情報

### プロバイダー種別統計

| 種別                      | 個数 | 主要用途                                                     |
| ------------------------- | ---- | ------------------------------------------------------------ |
| **Provider**              | 25   | リポジトリ・サービスインスタンス提供、算出値取得             |
| **StateProvider**         | 2    | シンプルなプリミティブ値状態管理（AppMode, PageIndex）       |
| **StateNotifierProvider** | 8    | カスタムロジック付き状態管理（Subscription, SecretMode等）   |
| **AsyncNotifierProvider** | 9    | 非同期データフェッチ＋状態管理（AllGroups, SelectedGroup等） |
| **FutureProvider**        | 9    | 一度だけの非同期データ取得（News, Whiteboard等）             |
| **StreamProvider**        | 7    | リアルタイムデータストリーム監視（Auth, News, Whiteboard等） |
| **Family**                | 10   | パラメータ付きプロバイダー（groupId, whiteboardId等）        |
| **AutoDispose**           | 3    | 自動破棄プロバイダー（GroupSharedLists, PageIndex等）        |

### 機能分類統計

| カテゴリ               | プロバイダー数 | 主要プロバイダー                                                                                         |
| ---------------------- | -------------- | -------------------------------------------------------------------------------------------------------- |
| **認証・ユーザー**     | 12             | authProvider, authStateProvider, userSettingsProvider, userNameProvider系                                |
| **グループ管理**       | 10             | allGroupsProvider, selectedGroupProvider, selectedGroupIdProvider, memberPoolProvider                    |
| **リスト管理**         | 6              | sharedListProvider, currentListProvider, groupSharedListsProvider                                        |
| **ホワイトボード**     | 6              | groupWhiteboardProvider, watchWhiteboardProvider, personalWhiteboardProvider                             |
| **ニュース**           | 4              | newsStreamProvider, currentNewsProvider, isNewsLoadingProvider, newsErrorProvider                        |
| **サブスクリプション** | 4              | subscriptionProvider, isPremiumActiveProvider, shouldShowAdsProvider                                     |
| **セキュリティ**       | 3              | secretModeProvider, dataVisibilityProvider, authRequiredProvider                                         |
| **ストレージ**         | 9              | HiveBoxプロバイダー（3）, Repositoryプロバイダー（4）, firestoreProvider, hiveUserInitializationProvider |
| **同期**               | 4              | forceSyncProvider, isSyncingProvider, syncStatusProvider, hybridRepositoryProvider                       |
| **UI状態**             | 2              | pageIndexProvider, appModeNotifierProvider                                                               |

### ファイル行数分布

| 行数範囲    | ファイル数 | 主要ファイル                                                          |
| ----------- | ---------- | --------------------------------------------------------------------- |
| **1000+**   | 1          | shared_group_provider.dart (1227行)                                   |
| **500-999** | 1          | auth_provider.dart (661行)                                            |
| **300-499** | 2          | shared_list_provider.dart (442行), subscription_provider.dart (304行) |
| **100-299** | 9          | current_list_provider.dart (143行), user_name_provider.dart (140行)等 |
| **<100**    | 8          | 小規模プロバイダー（news, security, device_settings等）               |

---

## 🏗️ アーキテクチャパターン

### 1. Repository提供パターン

**目的**: Repositoryインスタンスを一元管理し、依存性注入を実現

**パターン**:

```dart
// Repositoryインスタンス提供
final SharedGroupRepositoryProvider = Provider<SharedGroupRepository>((ref) {
  return HybridSharedGroupRepository(ref);
});

// NotifierでRepository使用
class AllGroupsNotifier extends AsyncNotifier<List<SharedGroup>> {
  @override
  Future<List<SharedGroup>> build() async {
    final repository = ref.read(SharedGroupRepositoryProvider);
    return await repository.getAllGroups();
  }
}
```

**使用例**: SharedGroupRepositoryProvider, sharedListRepositoryProvider, whiteboardRepositoryProvider

**メリット**: テスト時にモックRepositoryに差し替え可能

---

### 2. AsyncNotifierプロバイダーパターン

**目的**: 非同期データフェッチ＋状態管理を統合

**パターン**:

```dart
// AsyncNotifierでデータフェッチ＋操作
class AllGroupsNotifier extends AsyncNotifier<List<SharedGroup>> {
  @override
  Future<List<SharedGroup>> build() async {
    // Firestoreからデータフェッチ
    final repository = ref.read(SharedGroupRepositoryProvider);
    return await repository.getAllGroups();
  }

  // データ操作メソッド
  Future<void> createNewGroup(String groupName) async {
    // ...
    ref.invalidateSelf(); // 自動再フェッチ
  }
}

// プロバイダー定義
final allGroupsProvider = AsyncNotifierProvider<AllGroupsNotifier, List<SharedGroup>>(
  () => AllGroupsNotifier(),
);
```

**AsyncValue状態**:

- `AsyncData`: データ取得成功
- `AsyncLoading`: ロード中
- `AsyncError`: エラー発生

**使用例**: allGroupsProvider, selectedGroupNotifierProvider, userSettingsProvider

---

### 3. StreamProviderパターン（リアルタイム監視）

**目的**: Firestoreのリアルタイム更新をUIに自動反映

**パターン**:

```dart
// Firestore snapshots()監視
final newsStreamProvider = StreamProvider<AppNews>((ref) {
  return FirestoreNewsService.watchCurrentNews(); // Stream<AppNews>を返す
});

// UIで使用
final newsAsync = ref.watch(newsStreamProvider);
newsAsync.when(
  data: (news) => Text(news.title),
  loading: () => CircularProgressIndicator(),
  error: (e, _) => Text('エラー: $e'),
);
```

**使用例**: authStateProvider, newsStreamProvider, watchWhiteboardProvider

**メリット**: Firestoreドキュメント変更時に自動的にUIが更新される

---

### 4. Family + AutoDisposeパターン

**目的**: パラメータ付きプロバイダー＋不要時の自動破棄

**パターン**:

```dart
// パラメータ付きプロバイダー
final groupWhiteboardProvider = FutureProvider.family<Whiteboard?, String>(
  (ref, groupId) async {
    final repository = ref.read(whiteboardRepositoryProvider);
    return await repository.getGroupWhiteboard(groupId);
  },
);

// AutoDisposeで自動破棄
final groupSharedListsProvider = FutureProvider.autoDispose<List<SharedList>>(
  (ref) async {
    final selectedGroupId = ref.watch(selectedGroupIdProvider);
    // ...
  },
);

// 使用
final whiteboard = ref.watch(groupWhiteboardProvider('groupId123'));
```

**使用例**: groupWhiteboardProvider, watchWhiteboardProvider, groupSharedListsProvider

**メリット**: メモリ効率改善、パラメータごとにキャッシュ

---

### 5. StateNotifierプロバイダーパターン

**目的**: カスタムロジック付きの単純な状態管理

**パターン**:

```dart
// StateNotifierで状態管理
class SecretModeNotifier extends StateNotifier<bool> {
  final DeviceSettingsService _deviceSettings;

  SecretModeNotifier(this._deviceSettings) : super(false) {
    _loadSecretMode();
  }

  Future<void> toggleSecretMode() async {
    final newValue = !state;
    await _deviceSettings.setSecretMode(newValue);
    state = newValue; // 状態更新
  }
}

// プロバイダー定義
final secretModeProvider = StateNotifierProvider<SecretModeNotifier, bool>((ref) {
  return SecretModeNotifier(ref.read(deviceSettingsServiceProvider));
});
```

**使用例**: secretModeProvider, subscriptionProvider, pageIndexProvider

**メリット**: 初期化ロジックやサービス統合が可能

---

### 6. 算出プロバイダーパターン

**目的**: 他のプロバイダーから算出値を取得

**パターン**:

```dart
// 算出プロバイダー
final isPremiumActiveProvider = Provider<bool>((ref) {
  final state = ref.watch(subscriptionProvider);
  return state.isPremiumActive;
});

final dataVisibilityProvider = Provider<bool>((ref) {
  final isSecretMode = ref.watch(secretModeProvider);
  final authState = ref.watch(authStateProvider);

  if (!isSecretMode) return true;
  return authState.when(
    data: (user) => user != null,
    loading: () => false,
    error: (_, __) => false,
  );
});
```

**使用例**: isPremiumActiveProvider, shouldShowAdsProvider, dataVisibilityProvider

**メリット**: ロジックの再利用、テスタビリティ向上

---

### 7. プロバイダー依存チェーンパターン

**目的**: 複数のプロバイダーを連鎖させて複雑な状態を管理

**パターン**:

```dart
// レイヤー1: 基本プロバイダー
final authStateProvider = StreamProvider<User?>(...);

// レイヤー2: 選択状態管理
final selectedGroupIdProvider = StateNotifierProvider<SelectedGroupIdNotifier, String?>();

// レイヤー3: 選択されたグループの詳細
final selectedGroupNotifierProvider = AsyncNotifierProvider<SelectedGroupNotifier, SharedGroup?>(
  () => SelectedGroupNotifier(),
);
// build()内でselectedGroupIdProviderを監視してグループフェッチ

// レイヤー4: 選択されたグループのリスト一覧
final groupSharedListsProvider = FutureProvider.autoDispose<List<SharedList>>((ref) async {
  final selectedGroupId = ref.watch(selectedGroupIdProvider);
  // ...
});
```

**使用例**: selectedGroupId → selectedGroup → groupSharedLists

**メリット**: 状態変更が自動的に下流に伝播

---

## 💡 使用ガイドライン

### 1. プロバイダー選択チートシート

| 目的                                 | 推奨プロバイダー種別      | 例                                    |
| ------------------------------------ | ------------------------- | ------------------------------------- |
| サービス・リポジトリインスタンス提供 | **Provider**              | SharedGroupRepositoryProvider         |
| 単純な状態管理（int, String, bool）  | **StateProvider**         | appModeNotifierProvider               |
| カスタムロジック付き状態管理         | **StateNotifierProvider** | subscriptionProvider                  |
| 非同期データフェッチ＋CRUD操作       | **AsyncNotifierProvider** | allGroupsProvider                     |
| 一度だけの非同期データ取得           | **FutureProvider**        | currentNewsProvider                   |
| リアルタイムデータストリーム監視     | **StreamProvider**        | authStateProvider, newsStreamProvider |
| 他プロバイダーから算出値             | **Provider**              | isPremiumActiveProvider               |
| パラメータ付きプロバイダー           | **.family**               | groupWhiteboardProvider               |
| 不要時の自動破棄                     | **.autoDispose**          | groupSharedListsProvider              |

---

### 2. ref.watch vs ref.read使い分け

**⚠️ CRITICAL**: `docs/riverpod_best_practices.md` Section 1-3を必ず参照

#### ref.watch() - 依存関係追跡

**使用場所**: build()メソッド内、State.build()内

```dart
// ✅ Correct: build()内でwatch
@override
Widget build(BuildContext context, WidgetRef ref) {
  final groups = ref.watch(allGroupsProvider);
  // groupsの変更時にウィジェット再ビルド
}

// ✅ Correct: AsyncNotifier.build()内でwatch
@override
Future<List<SharedList>> build() async {
  final selectedGroupId = ref.watch(selectedGroupIdProvider);
  // selectedGroupIdの変更時に自動的にbuild()再実行
}
```

**メリット**: プロバイダー値変更時に自動的にUIを更新

---

#### ref.read() - 一度だけアクセス

**使用場所**: イベントハンドラ（onPressed, onTap等）、メソッド内部

```dart
// ✅ Correct: イベントハンドラ内でread
ElevatedButton(
  onPressed: () {
    final repository = ref.read(SharedGroupRepositoryProvider);
    repository.createGroup(...);
  },
)

// ✅ Correct: メソッド内でread
Future<void> deleteGroup(String groupId) async {
  final repository = ref.read(SharedGroupRepositoryProvider);
  await repository.deleteGroup(groupId);
  ref.invalidate(allGroupsProvider); // 手動更新
}
```

**メリット**: 不要な再ビルドを防止、Repositoryアクセス等に最適

---

### 3. AsyncNotifier.build()内の依存性管理

**⚠️ CRITICAL**: `docs/riverpod_best_practices.md` Section 4参照

#### ❌ Wrong Pattern - late final Ref

```dart
class AllGroupsNotifier extends AsyncNotifier<List<SharedGroup>> {
  late final Ref _ref; // ❌ 2回目のbuild()でLateInitializationError

  @override
  Future<List<SharedGroup>> build() async {
    _ref = ref; // ❌ 既に初期化済みならエラー
    return [];
  }
}
```

#### ✅ Correct Pattern - Ref?

```dart
class SelectedGroupNotifier extends AsyncNotifier<SharedGroup?> {
  Ref? _ref; // ✅ nullable

  @override
  Future<SharedGroup?> build() async {
    _ref ??= ref; // ✅ null-aware代入で初回のみ設定
    // ...
  }
}
```

**理由**: AsyncNotifier.build()は複数回呼び出される可能性がある

---

### 4. Provider無効化とUI更新

#### ref.invalidate() - プロバイダー無効化

```dart
// ✅ Correct: CRUD操作後にinvalidate
Future<void> createNewGroup(String groupName) async {
  final repository = ref.read(SharedGroupRepositoryProvider);
  await repository.createGroup(...);

  ref.invalidate(allGroupsProvider); // 🔥 無効化→自動再フェッチ
}
```

**動作**: プロバイダーの状態をクリアし、次回アクセス時に再フェッチ

**注意**: invalidate()は即座にデータを更新しない（次回watch時に再ビルド）

---

#### await ref.read(provider.future) - 再フェッチ完了待機

```dart
// ✅ Correct: invalidate後に再フェッチ完了を待つ
ref.invalidate(groupSharedListsProvider);
await ref.read(groupSharedListsProvider.future);
// この時点でUIに最新データが反映される

// ❌ Wrong: invalidateのみ（UIが古いデータで再ビルドされる可能性）
ref.invalidate(groupSharedListsProvider);
// すぐにUI再ビルド → データ未到着の可能性
```

**使用例**: リスト作成後のDropdownButton自動選択（`shopping_list_header_widget.dart`）

詳細: `copilot-instructions.md` Section "Critical Flutter/Riverpod Patterns"

---

### 5. DropdownButtonでの reactive updates

**⚠️ CRITICAL**: `initialValue`ではなく`value`を使用

```dart
// ❌ Wrong: initialValue（非リアクティブ）
DropdownButtonFormField<String>(
  initialValue: ref.watch(currentListProvider)?.listId, // 初回のみ反映
  items: [...],
)

// ✅ Correct: value（リアクティブ）
DropdownButtonFormField<String>(
  value: ref.watch(currentListProvider)?.listId, // プロバイダー更新で自動反映
  items: [...],
)
```

**理由**: `initialValue`はウィジェット作成時のみ評価され、プロバイダー変更を無視

詳細: `copilot-instructions.md` Section "DropdownButtonFormField - Reactive Updates"

---

### 6. StreamProvider使用時の注意点

#### 無限ループ防止

```dart
// ❌ Wrong: 無限ループ
final dataProvider = StreamProvider<Data>((ref) async* {
  final authState = ref.watch(authStateProvider); // ❌ Streamの中でwatch
  // authState変更→dataProviderリビルド→再度authState watch→無限ループ
});

// ✅ Correct: 依存関係を明確化
final dataProvider = StreamProvider<Data>((ref) {
  final userId = ref.watch(authStateProvider).value?.uid;
  if (userId == null) return Stream.value(null);

  return FirebaseFirestore.instance
    .collection('data')
    .where('userId', isEqualTo: userId)
    .snapshots()
    .map((snapshot) => ...);
});
```

---

#### StreamSubscriptionのメモリリーク防止

StreamProviderは自動的にStreamSubscriptionを破棄するため、手動cancel不要

```dart
// ✅ Correct: StreamProviderが自動管理
final newsStreamProvider = StreamProvider<AppNews>((ref) {
  return FirestoreNewsService.watchCurrentNews();
});
// ref不要時に自動的にStreamSubscription.cancel()実行
```

---

### 7. Family使用時のキャッシュ注意

**Family**はパラメータごとにインスタンスをキャッシュする

```dart
final groupWhiteboardProvider = FutureProvider.family<Whiteboard?, String>(
  (ref, groupId) async {
    // groupId='group1' → インスタンスA
    // groupId='group2' → インスタンスB（別キャッシュ）
  },
);

// 同じgroupIdなら同じキャッシュを使用
final whiteboard1 = ref.watch(groupWhiteboardProvider('group1'));
final whiteboard2 = ref.watch(groupWhiteboardProvider('group1')); // 同じインスタンス
```

**注意**: パラメータが多いとメモリ消費増加 → AutoDisposeと併用推奨

---

## 🚀 今後の拡張計画

### 1. プロバイダー統合の機会

**統合候補**:

- `userNameProvider`, `userNameNotifierProvider`, `userNameDisplayProvider` → 単一のuserNameProviderに統合
- `selectedGroupProvider`, `selectedGroupNotifierProvider` → 命名統一

**メリット**: コードベース簡素化、API一貫性向上

---

### 2. 型安全性向上

**現在の課題**: String型のID（groupId, listId等）が型チェックされない

**改善案**:

```dart
// 型安全なID
typedef GroupId = String;
typedef ListId = String;

final groupWhiteboardProvider = FutureProvider.family<Whiteboard?, GroupId>(
  (ref, groupId) async { ... },
);
```

---

### 3. Provider Generatorへの移行検討

**現状**: Traditional syntax使用（手動Provider定義）

**将来的な移行**:

```dart
// Generator syntax（将来）
@riverpod
Future<List<SharedGroup>> allGroups(AllGroupsRef ref) async {
  final repository = ref.read(sharedGroupRepositoryProvider);
  return await repository.getAllGroups();
}
```

**注意**: 現在はバージョン競合によりGenerator無効化（`copilot-instructions.md`）

---

### 4. テストカバレッジ向上

**優先度**: プロバイダーロジックの単体テスト実装

**テスト対象**:

- AsyncNotifierのbuild()ロジック
- StateNotifierの状態遷移
- 算出プロバイダーのロジック
- エラーハンドリング

---

### 5. パフォーマンス最適化

**課題**:

- 大量のref.watch()による不要な再ビルド
- Familyプロバイダーのキャッシュメモリ使用量

**改善策**:

- select()によるピンポイント更新
- AutoDisposeの積極活用
- Computed値のメモ化

---

## 📚 関連ドキュメント

- **データモデル**: `docs/specifications/data_classes_reference.md` (26クラス)
- **UIコンポーネント**: `docs/specifications/widget_classes_reference.md` (42ウィジェット)
- **画面**: `docs/specifications/page_widgets_reference.md` (17画面)
- **サービス**: `docs/specifications/service_classes_reference.md` (46サービス、66クラス)
- **Riverpodベストプラクティス**: `docs/riverpod_best_practices.md`
- **プロジェクト概要**: `.github/copilot-instructions.md`

---

**ドキュメント作成日**: 2026-02-19
**最終更新**: 2026-02-19
**バージョン**: 1.0
