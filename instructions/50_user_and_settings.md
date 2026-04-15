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
   - Batch 2: 親グループ削除 + メンバー離脱 + 通知 + 招待 + user プロファイル削除 → commit

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

## 5. DeviceIdService

- プレフィックスは **SharedPreferences に永続化**する（再生成禁止）
- Android ID が 8 文字未満でも安全に処理する
- iOS の `identifierForVendor` は null になりうる → フォールバック UUID を使う

---

## 6. 設定画面のウィジェット構成

`lib/pages/settings_page.dart` は薄いオーケストレーターとして機能し、
実装の実体は `lib/widgets/settings/` の各ファイルに分割されている。

| ファイル                           | 役割                                                                                       | Widget 種別              |
| ---------------------------------- | ------------------------------------------------------------------------------------------ | ------------------------ |
| `auth_status_panel.dart`           | 認証状態表示パネル                                                                         | `ConsumerWidget`         |
| `firestore_sync_status_panel.dart` | Firestore 同期状態表示                                                                     | `ConsumerWidget`         |
| `app_mode_switcher_panel.dart`     | アプリモード切替（リスト ⇄ TODO）                                                          | `ConsumerWidget`         |
| `purchase_plan_panel.dart`         | 課金プラン表示・購入UIパネル（比較表・購入ボタン・復元ボタン）                             | `ConsumerStatefulWidget` |
| `notification_settings_panel.dart` | 通知設定                                                                                   | `ConsumerWidget`         |
| `privacy_settings_panel.dart`      | プライバシー設定（シークレットモード切替・プライバシーポリシー/利用規約/データ削除リンク） | `ConsumerStatefulWidget` |
| `whiteboard_settings_panel.dart`   | ホワイトボードカラー設定                                                                   | `ConsumerWidget`         |
| `feedback_section.dart`            | フィードバックフォームリンク                                                               | `StatefulWidget`         |
| `feedback_debug_section.dart`      | フィードバックデバッグ情報（dev のみ）                                                     | `StatefulWidget`         |
| `developer_tools_section.dart`     | 開発者ツールパネル（dev のみ）                                                             | `ConsumerWidget`         |
| `data_maintenance_section.dart`    | データクリーンアップ・マイグレーション（dev のみ）                                         | `ConsumerStatefulWidget` |
| `account_deletion_section.dart`    | アカウント削除（認証済みのみ）                                                             | `ConsumerStatefulWidget` |

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

---

## 8. アプリ内課金（In-App Purchase）

### 課金タイプ（`lib/models/purchase_type.dart`）

| enum 値                  | Firestore 値  | 広告制御                           | 価格               |
| ------------------------ | ------------- | ---------------------------------- | ------------------ |
| `PurchaseType.free`      | `'free'`      | バナー・インタースティシャルあり   | 無料               |
| `PurchaseType.subscribe` | `'subscribe'` | **全広告非表示**                   | ¥200/3ヶ月         |
| `PurchaseType.purchase`  | `'purchase'`  | **インタースティシャルのみ非表示** | ¥1,000（買い切り） |

### Google Play 商品ID

| 商品ID                    | 種別     | 価格       |
| ------------------------- | -------- | ---------- |
| `goshopping_subscribe`    | 定期購読 | ¥200/3ヶ月 |
| `goshopping_onetime_1000` | 非消費型 | ¥1,000     |

### Firestore スキーマ（`/users/{uid}`）

```
purchaseType: 'free' | 'subscribe' | 'purchase'  // 課金タイプ（デフォルト: omitted → free）
```

### 課金フロー

1. `PurchasePlanPanel` でユーザーが購入ボタンをタップ
2. `PurchaseService.buySubscription()` / `buyOneTimePurchase()` → Google Play 購入UI表示
3. 購入完了後 `_handlePurchase()` が `FirestoreUserNameService.savePurchaseType()` を呼ぶ
4. `purchaseTypeProvider`（`StreamProvider`）が Firestore 変化を検知してUIを自動更新
5. `AdService.shouldShowSignInAd()` / `shouldShowBannerAd()` が次回以降の広告表示を制御

### 広告チェックの原則

- `shouldShowSignInAd()`: 課金チェック → インストール90日猶予 → 日次上限・間隔チェック
- `shouldShowBannerAd()`: 課金チェックのみ（`hidesBannerAds`）
- `hidesInterstitialAds` が `true`（subscribe/purchase）→ インタースティシャルをスキップ
- `hidesBannerAds` が `true`（subscribe のみ）→ バナーをスキップ

### セキュリティ注意事項

- `purchaseType` の書き込みは **購入確認後のみ**行う（`PurchaseStatus.purchased` / `restored` のみ）
- クライアントから `purchaseType: 'subscribe'` を任意に書き込めてしまうため、**本番では Cloud Functions でレシート検証**を行うことが推奨（現在は Google Play ストリームのみで判定）
