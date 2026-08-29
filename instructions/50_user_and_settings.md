# ユーザー管理・設定指示書

> 共通ルールは `00_project_common.md` を先に読むこと。

---

## 1. 認証フロー詳細

認証フローの順序は `00_project_common.md` §2 を参照すること。
以下は補足ルール。

- **Firestore 同期完了前に「グループ0件」と UI 判定してはならない**
- `authStateChanges()` は Hive box 初期化より先に発火することがある
  → `forceSyncProvider` / `allGroupsProvider` を触る前に box の open を確認する
- サインイン後は `waitForSafeInitialization()` が `_firestoreRepo` の準備を保証するまで CRUD を呼ばない

---

## 2. ユーザー名の取得・保存

### 優先順位

```text
Firestore /users/{uid}.displayName
  → SharedPreferences
    → UserSettings (Hive)
      → Firebase Auth displayName
        → email prefix
          → UID（最終フォールバック）
```

### ユーザー名保存は Firebase Auth 登録の**前に SharedPreferences をクリア**してから行う

```dart
// サインアップ時の正しい順序
await UserPreferencesService.clearAllUserInfo();  // ← 先にクリア
await SharedGroupBox.clear();
await auth.signUp(email, password);
await UserPreferencesService.saveUserName(userName);  // ← Auth 後に保存
await user.updateDisplayName(userName);
```

---

## 3. アカウント削除

### 必須手順

1. **再認証**（`EmailAuthProvider.credential()` → `reauthenticateWithCredential()`）
   - `requires-recent-login` エラー対策
2. **2段階確認ダイアログ**（誤操作防止）
3. **Batch 分割削除**
   - Batch 1: サブコレクション（sharedLists, whiteboards）を削除 → commit
   - Batch 2: 親グループ削除 + メンバー離脱 + 通知 + user プロファイル削除 → commit

> ⚠️ **注意**: `/invitations` トップレベルコレクション（レガシー）は `allow read, write: if false` で全拒否のためクエリ不可。v3.x 以降は `SharedGroups/{groupId}/invitations/` サブコレクションに移行済みのため Batch 2 から除外すること。アクセスすると `permission-denied` 例外が発生し後続の `user.delete()` がブロックされる。

### Batch を分割する理由

サブコレクションと親ドキュメントを同一 Batch で削除すると、
サブコレクション削除時の権限チェックで親ドキュメントへの `get()` が失敗して
`permission-denied` になる。

### オーナーグループと参加グループの扱い

```dart
// オーナーグループ → 完全削除
batch2.delete(group.reference);

// 参加グループ（メンバーとして参加） → allowedUid から自分を外すだけ
batch2.update(group.reference, {
  'allowedUid': FieldValue.arrayRemove([currentUser.uid]),
});
```

---

## 4. AppMode（買い物リスト ⇄ TODO 切替）

- `AppModeSettings.config.{property}` を使って用語を動的に切り替える
- UI にグループ名・リスト名・アイテム名をハードコードする **禁止**
- モード切替は `AppModeSettings.setMode()` + `appModeNotifierProvider` 更新
- 設定値は Hive の `UserSettings` に永続化

---

## 4a. AppUIMode（single / multi UI 切替）

### 概要

| モード             | 用途                                            | 差異                                                       |
| ------------------ | ----------------------------------------------- | ---------------------------------------------------------- |
| `AppUIMode.single` | 家族・カップル向けシンプルUI（グループ1つ固定） | FAB非表示、リストDropdown→Text固定、add/deleteボタン非表示 |
| `AppUIMode.multi`  | 従来の複数グループUI                            | 全機能有効                                                 |

### ファイル構成

| ファイル                                               | 役割                                                 |
| ------------------------------------------------------ | ---------------------------------------------------- |
| `lib/config/app_ui_mode_config.dart`                   | `AppUIMode` enum + `AppUIModeSettings` singleton     |
| `lib/providers/app_ui_mode_provider.dart`              | `appUIModeProvider` (StateProvider)                  |
| `lib/widgets/settings/app_ui_mode_switcher_panel.dart` | 設定画面のモード切替UIパネル（プレミアムゲート付き） |
| `lib/widgets/single_group_creation_dialog.dart`        | サインアップ後シングルモードのグループ作成ダイアログ |

### 永続化

- Hive `UserSettings.appUIMode` (`HiveField(9)`) に `int` で保存（0=single, 1=multi）
- SharedPreferences / Firestore `/users/{uid}.appUIMode` とも双方向同期
- 起動時に `app_initialize_widget.dart` で Hive → `AppUIModeSettings` → Provider に初期化

### ルール

- モード判定は `ref.watch(appUIModeProvider) == AppUIMode.single` を使う
- `isSingle` が true のとき、グループ追加 FAB・リストDropdown・add/deleteボタンを非表示にする
- single → multi 変更は Free / Premium 共通で利用可能。Free プランのグループ数・メンバー数上限は各操作側で適用する
- multi → single 変更は確認ダイアログを必ず表示する
- **Hive に新フィールドを追加したら `UserSettingsAdapterOverride` の `read()` と `write()` を必ず更新する**（null安全のため `(fields[N] as Type?) ?? defaultValue` パターンを使う）
- **新規ユーザーのデフォルトは `appUIMode: 0`（シングルモード）**。`firestore_user_name_service.dart` の `saveUserName()` で新規ドキュメント作成時に `appUIMode: 0` を明示設定すること。SharedPreferences に前ユーザーの stale な値（`1` = multi）が残っていても上書きされる。
- **サインアップ直後は `_syncUserProfile` の非同期完了を待たずに 3 箇所を即座に設定すること**（stale 値が UI に反映される時間を排除する）:

```dart
// ✅ サインアップ成功直後（sign_up_form.dart / home_page.dart）
AppUIModeSettings.setMode(AppUIMode.single);
ref.read(appUIModeProvider.notifier).state = AppUIMode.single;
await UserPreferencesService.saveAppUIMode(0);
```

- `user_initialization_service.dart` の `_syncUserProfile()` は、Firestore にデータがなくローカルにある場合（新規ユーザー直後）は `localAppUIMode` を使わず `appUIMode: 0` を強制書き込みすること（`localAppUIMode` は前ユーザーの stale 値の可能性があるため）。

### グループの自動選択（シングルモード対応）

`allGroupsProvider` は返却リストを `updatedAt` 降順でソートする。
これにより `SelectedGroupIdNotifier` が SharedPreferences に保存済みIDを持たない場合（新規端末サインイン等）、`availableGroups.first` が「最近更新されたグループ」になる。

```dart
// ✅ allGroupsProvider（shared_group_provider.dart）での実装パターン
deduplicatedGroups.sort((a, b) =>
    (b.updatedAt ?? DateTime(0)).compareTo(a.updatedAt ?? DateTime(0)));
```

- Firestore リアルタイムリスナー更新時も同じソートを適用すること
- `updatedAt` が null のグループは `DateTime(0)`（最古）として扱う

---

## 5. DeviceIdService

- プレフィックスは **SharedPreferences に永続化**する（再生成禁止）
- Android ID が 8 文字未満でも安全に処理する
- iOS の `identifierForVendor` は null になりうる → フォールバック UUID を使う

---

## 6. 設定画面のウィジェット構成

`lib/pages/settings_page.dart` は薄いオーケストレーターとして機能し、
実装の実体は `lib/widgets/settings/` の各ファイルに分割されている。

| ファイル                           | 役割                                                           | Widget 種別              |
| ---------------------------------- | -------------------------------------------------------------- | ------------------------ |
| `auth_status_panel.dart`           | 認証状態表示パネル                                             | `ConsumerWidget`         |
| `firestore_sync_status_panel.dart` | Firestore 同期状態表示                                         | `ConsumerWidget`         |
| `app_mode_switcher_panel.dart`     | アプリモード切替（リスト ⇄ TODO）                              | `ConsumerWidget`         |
| `purchase_plan_panel.dart`         | 課金プラン表示・購入UIパネル（比較表・購入ボタン・復元ボタン） | `ConsumerStatefulWidget` |
| `notification_settings_panel.dart` | 通知設定                                                       | `ConsumerWidget`         |
| `privacy_settings_panel.dart`      | プライバシー設定（プライバシーポリシー/利用規約リンク）        | `StatelessWidget`        |
| `whiteboard_settings_panel.dart`   | ホワイトボードカラー設定                                       | `ConsumerWidget`         |
| `feedback_section.dart`            | フィードバックフォームリンク                                   | `StatefulWidget`         |
| `feedback_debug_section.dart`      | フィードバックデバッグ情報（dev のみ）                         | `StatefulWidget`         |
| `developer_tools_section.dart`     | 開発者ツールパネル（dev のみ）                                 | `ConsumerWidget`         |
| `data_maintenance_section.dart`    | データクリーンアップ・マイグレーション（dev のみ）             | `ConsumerStatefulWidget` |
| `account_deletion_section.dart`    | アカウント削除（認証済みのみ）                                 | `ConsumerStatefulWidget` |

### ルール

- 新しい設定機能は `settings_page.dart` に直接書かず、`lib/widgets/settings/` に専用ファイルを作成すること
- `dev` 専用 UI は `if (F.appFlavor == Flavor.dev) ...` ブロックで囲む
- `AccountDeletionSection` は `User user`（non-nullable）を受け取る
- `DataMaintenanceSection` / `DeveloperToolsSection` は `User? user` を受け取る

---

## 7. 禁止事項

- サインアウト前に Hive / SharedPreferences をクリアしないまま Auth を解除する
- Firestore 同期前に「グループ0件」と確定してページ遷移・UI 構築する
- アカウント削除を再認証なしで実行する
- Batch 分割なしにサブコレクションと親を同時削除する
- 設定機能のロジックを `settings_page.dart` 本体に直接書く（→ `lib/widgets/settings/` に分割する）
- **`createNewGroup()` 呼び出し後に `allGroupsProvider.future` を await する**
  - `createNewGroup()` は完了時に `allGroupsProvider` の state を直接更新する
  - この更新で `SharedGroupPage` が再ビルドされ、ダイアログ等のウィジェットが破棄される可能性がある
  - 破棄後に `future` の await が再開すると `_dependents.isEmpty: is not true` アサーションでクラッシュする
  - ✅ 代替: `ref.read(allGroupsProvider).valueOrNull ?? []` で同期的に現在値を取得する
  - ✅ 代替: 非同期処理の前に必要な `ref.read()` をすべて取得しておく

---

## 8. アプリ内課金（In-App Purchase）

### 課金タイプ（`lib/models/purchase_type.dart`）

| enum 値                  | Firestore 値  | 広告制御                           | 価格               |
| ------------------------ | ------------- | ---------------------------------- | ------------------ |
| `PurchaseType.free`      | `'free'`      | バナー・インタースティシャルあり   | 無料               |
| `PurchaseType.subscribe` | `'subscribe'` | **全広告非表示**                   | Premium月額（日本: ¥200/月、その他: おおむねUS$2/月） |
| `PurchaseType.purchase`  | `'purchase'`  | **インタースティシャルのみ非表示** | 旧買い切りプラン（新規販売なし） |

### 有効なPremium商品ID

| 商品ID                    | 種別     | 価格       |
| ------------------------- | -------- | ---------- |
| `goshopping_premium_monthly` | 自動更新サブスクリプション | ストアのローカル価格を表示。未取得時は日本語で¥200/月、その他でUS$2/月 |

- `PurchaseService` は現在、上記の月額SKUだけを商品情報取得の対象にする。
- `goshopping_subscribe`、`goshopping_onetime_1000`、`goshopping_premium_yearly` はレガシーまたは将来用の定義であり、新規購入UIには表示しない。

### Firestore スキーマ（`/users/{uid}`）

```
purchaseType: 'free' | 'subscribe' | 'purchase'  // 課金タイプ（デフォルト: omitted → free）
```

### 課金フロー

1. Android / iOSではアプリ起動直後に `PurchaseService.initialize()` を実行し、購入ストリームを購読する。設定画面を開くまで購読を遅延させない。
2. 認証済みユーザーの設定画面に `PurchasePlanPanel` を表示し、ストア利用可否と月額SKUの商品情報を反映する。
3. 「Premiumを有効化」で `PurchaseService.buyPremiumMonthly()` が `PurchaseParam` を使ってストア購入UIを開く。購入開始だけではMultiモードへ切り替えない。
4. 購入または復元の完了後、`_handlePurchase()` がストアの検証データを `verifyPurchase` Callableへ送る。
5. FunctionsがGoogle Play Developer APIまたはApple署名済みStoreKit 2取引を検証し、成功時だけAdmin SDKで `purchaseType: subscribe` を保存する。
6. Google PlayはFunctions側でacknowledgeする。App Storeは検証成功後にクライアントが取引をfinishする。
7. `purchaseTypeProvider`（`StreamProvider`）がFirestore変化を検知してUIを自動更新する。
8. `purchaseSyncProvider` がHiveの `SubscriptionState` へ反映し、`isPremiumActiveProvider`、Free/Premiumの上限、広告表示を更新する。Firestoreの明示的な `free` は、有効な無料体験中を除いてローカルにも即時反映する。
9. 「購入を復元」は `PurchaseService.restorePurchases()` を実行し、復元取引も同じCallableで再検証する。

### クライアント側の課金状態管理

- Firestoreの `purchaseType` を課金権限の正とし、SharedPreferencesのキャッシュで明示的な `free` を上書きしない。
- 認証状態の変更時は `purchaseTypeProvider` が購読対象ユーザーを切り替える。
- 月額PremiumはHiveに35日間のオフライン猶予として保存し、Firestoreから有料状態を受信するたびに期限を更新する。
- 購入UIは `pending` / `purchased` / `restored` / `canceled` / `error` を表示し、処理中の多重操作を禁止する。

### 広告チェックの原則

- `shouldShowSignInAd()`: 課金チェック → testingStatus確認 → インストール90日猶予 → 日次上限・間隔チェック
- `shouldShowBannerAd()`: 課金チェックのみ（`hidesBannerAds`）
- `hidesInterstitialAds` が `true`（subscribe/purchase）→ インタースティシャルをスキップ
- `hidesBannerAds` が `true`（subscribe のみ）→ バナーをスキップ
- **`FeedbackPromptService.isTestingActive()` が `true`（Firestore `testingStatus/active.isTestingActive`）のとき、90日猶予チェックをスキップする**（開発・テスト用バイパス）

### 広告テストバイパスの手順

1. Firestore コンソール → `testingStatus/active` ドキュメント → `isTestingActive: true` に設定
2. アプリでサインイン → インタースティシャル広告が表示されることを確認
3. 確認後は必ず `isTestingActive: false` に戻す（本番ユーザーへの影響防止）

### セキュリティ注意事項

- `purchaseType` / `purchaseVerification` はSecurity Rulesでクライアント書き込みを禁止し、検証済みFunctionsのAdmin SDKだけが更新する。
- raw purchase token / StoreKit JWSはFirestoreへ保存しない。SHA-256指紋だけを保存し、同じ購入の別Firebaseユーザーへの使い回しを拒否する。
- `verifyPurchase` CallableはFirebase AuthとApp Checkを必須とする。
- Functions側では初回検証だけでなく、Google Play RTDN / App Store Server Notificationsによる更新、解約、返金、猶予期間、保留、失効の反映も行う。
