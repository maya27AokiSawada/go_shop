# 開発日報 - 2026年08月29日

## 📅 本日の目標

- [x] 鍵ローテーションがブロックされた際の通知色を改善する
- [x] Free / Premiumの利用上限を安全な値へ整理する
- [x] 将来のBusinessプラン導入予定をUIへ表示する
- [x] 通知履歴・エラー履歴の記録漏れを監査する
- [x] Premiumサブスクリプションのクライアントライフサイクルを堅牢化する
- [x] FunctionsによるGoogle Play / App Store購入検証を実装する
- [ ] Google Play RTDN / App Store Server Notificationsによる失効同期を実装する
- [ ] ストアのサンドボックス環境で購入・復元・解約をE2E確認する

---

## ✅ 完了した作業

### 1. 鍵ローテーション拒否時のSnackBar改善 ✅

**Purpose**: 再暗号化完了待ちで鍵ローテーションを拒否したことを、エラーとして明確に伝える。

**Problem / Root Cause**:

```dart
// ❌ 背景色未指定で通常通知と区別しにくい
const SnackBar(
  content: Text('再暗号化が完了するまで鍵ローテーションは実行できません'),
)
```

**Solution**:

```dart
// ✅ ブロック通知を赤色で表示
const SnackBar(
  content: Text('再暗号化が完了するまで鍵ローテーションは実行できません'),
  backgroundColor: Colors.red,
)
```

**Modified Files**:

- `lib/pages/group_member_management_page.dart`

**Commit**: `7b391b6`
**Status**: ✅ 完了・検証済み

---

### 2. Premium利用上限とBusinessプラン予告 ✅

**Purpose**: Premiumでも過剰利用を防ぎ、将来の法人向け上位プランを案内できるようにする。

**Solution**:

- Free: 最大3グループ、1グループ最大10人を維持
- Premium: 最大20グループ、1グループ最大50人へ変更
- `SubscriptionLimits`へ上限値を集約
- グループ作成と2つのメンバー追加経路で同じ上限を適用
- 設定画面とアプリ内ヘルプへBusinessプラン導入予定を表示

**Modified Files**:

- `lib/config/subscription_limits.dart`
- `lib/providers/shared_group_provider.dart`
- `lib/pages/group_member_management_page.dart`
- `lib/widgets/settings/purchase_plan_panel.dart`
- `lib/pages/help_page.dart`
- `test/config/subscription_limits_test.dart`
- `instructions/20_groups_lists_items.md`
- `docs/knowledge_base/user_guide.md`

**Commit**: `7b391b6`
**Status**: ✅ 完了・検証済み

---

### 3. UIモードとPremium課金状態の分離 ✅

**Purpose**: UIモード変更によって購入状態が変更・破壊されないようにする。

**Problem / Root Cause**:

```dart
// ❌ MultiからSingleへ変更するだけで課金状態をFreeへ戻していた
await ref.read(subscriptionProvider.notifier).resetToFree();
```

**Solution**:

```dart
// ✅ UIモードだけを保存し、課金状態には触れない
await _saveMode(ref, AppUIMode.single);
```

- Free / Premium共通でSingle / Multiを選択可能に変更
- Premium購入表示と起動時課金ログを現仕様へ整理
- 2026-08-26の日報を追加

**Commit**: `1fd21d4`
**Status**: ✅ 完了・検証済み

---

### 4. 通知履歴・エラー履歴の監査 ✅

**Purpose**: ユーザー向け履歴へ記録されない処理と、再送不能になる通知経路を特定する。

**確認結果**:

- `ErrorHandler`は`AppLogger`だけを呼び、エラー履歴へ保存しない
- グループ作成、鍵ローテーション、グループ削除・離脱、ロール変更などに履歴漏れ候補がある
- `sendNotificationToGroup()`が例外を握り潰すため、バッチ通知が失敗してもキューを消去する可能性がある
- 手動メンバー追加、グループ名変更、ロール変更、鍵ローテーションは通知履歴を生成しない
- アイテムバッチ通知のmetadataと通知履歴画面が期待するキーに不一致がある
- `ErrorLogService`と通知履歴メッセージ生成の直接テストが不足している

**Status**: ✅ 監査完了・修正は翌日以降へ継続

---

### 5. Premiumサブスクリプションライフサイクルの堅牢化 ✅

**Purpose**: 失効、購入監視、アカウント切替、購入確定順序、状態表示を本番運用可能な形へ近づける。

**Problem / Root Cause**:

```dart
// ❌ Firestoreがfreeでも古い有料キャッシュを優先
if (cachedType != PurchaseType.free) {
  return cachedType;
}

// ❌ 権限保存の成否に関係なく購入をcomplete
await savePurchaseType(type);
await completePurchase(purchase);
```

**Solution**:

```dart
// ✅ Firestoreを課金権限の正として失効を反映
if (purchaseType == PurchaseType.free) {
  await notifier.resetToFree();
}

// ✅ 権限反映成功後だけ取引を完了
final verification = await verifyPurchaseWithServer(purchase);
if (!verification.storeAcknowledged) {
  await completePurchase(purchase);
}
```

- アプリ起動直後から購入ストリームを監視
- 初期化の多重実行・二重購読を防止
- 認証ユーザー変更時に課金購読を切り替え
- `pending` / 成功 / 復元 / キャンセル / エラーを設定画面へ表示
- 月額Premiumを35日間のオフライン猶予として管理
- 未知の商品IDへ権限を付与しない

**Modified Files**:

- `lib/services/purchase_service.dart`
- `lib/providers/purchase_type_provider.dart`
- `lib/providers/purchase_sync_provider.dart`
- `lib/providers/subscription_provider.dart`
- `lib/widgets/app_initialize_widget.dart`
- `lib/widgets/settings/purchase_plan_panel.dart`
- `test/services/purchase_service_test.dart`
- `test/providers/subscription_lifecycle_test.dart`

**Commit**: `7ee587c`
**Status**: ✅ 完了・全402テスト成功

---

### 6. Functionsレシート検証 ✅

**Purpose**: クライアントの購入申告を信頼せず、ストア検証済みの場合だけPremium権限を付与する。

**Implementation**:

- Auth / App Check必須の`verifyPurchase` Callableを追加
- Google Play Subscriptions v2 APIで商品、状態、有効期限を確認
- Google Playは「検証 → Firestore権限保存 → acknowledge」の順で処理
- Apple公式ライブラリでStoreKit 2 JWS、証明書チェーン、Bundle ID、商品、有効期限、取消状態を確認
- raw purchase token / JWSを保存せずSHA-256指紋だけを保存
- 同じ購入tokenとlinked purchase tokenの別Firebaseユーザーへの使い回しを拒否
- Firestore Rulesで`purchaseType` / `purchaseVerification`のクライアント書き込みを禁止
- Flutter購入処理をCallableへ接続
- Functions設定テンプレートとデプロイ手順を追加

**検証結果**:

| テスト | 結果 |
|---|---|
| Functions Node単体テスト | 10件成功 |
| Flutter全テスト | 403件成功 |
| Functions Emulator定義読み込み | 成功 |
| Firestore Rules Emulatorコンパイル | 成功 |
| Node構文チェック | 成功 |
| Dart / JavaScript診断 | エラーなし |
| `git diff --check` | 成功 |
| npm audit | high / critical 0件、moderate 7件 |

**Modified Files**:

- `functions/receipt_verification.js`
- `functions/index.js`
- `functions/package.json`
- `functions/package-lock.json`
- `functions/test/receipt_verification.test.js`
- `functions/.env.example`
- `functions/.gitignore`
- `lib/services/purchase_service.dart`
- `firestore.rules`
- `pubspec.yaml`
- `pubspec.lock`
- `SETUP.md`
- `instructions/50_user_and_settings.md`
- `instructions/90_testing_and_ci.md`

**Commit**: `0ca7706`
**Status**: ✅ 実装・ローカル検証完了、デプロイとストア実機確認は未実施

---

## 🐛 発見された問題

### サブスク失効がクライアントへ反映されない問題 ✅

- **症状**: FirestoreがFreeになってもPremium権限が残る可能性があった
- **原因**: ローカル有料キャッシュの優先と、HiveをFreeへ戻さない同期処理
- **対処**: Firestoreを権限の正とし、明示的なFreeをローカルへ反映
- **状態**: ✅ 修正完了

### 購入権限保存前のacknowledge問題 ✅

- **症状**: 権限保存失敗時に支払い済み・Free状態となる可能性があった
- **原因**: 購入完了処理と権限保存の順序が保証されていなかった
- **対処**: Functions内で検証・権限保存後にGoogle Playをacknowledge
- **状態**: ✅ 修正完了

### ストア失効通知の未連携 ⚠️

- **症状**: 更新、解約、返金、保留、失効を即時反映できない
- **原因**: Google Play RTDN / App Store Server Notificationsが未実装
- **対処**: 通知受信後にストアAPIを再照会してFirestore権限を更新する
- **状態**: ⏳ 未着手

### Functions依存のmoderate脆弱性 ⚠️

- **症状**: `npm audit`でmoderate 7件が報告される
- **原因**: 現行`firebase-admin`依存チェーンの`uuid`に対する報告
- **対処**: high / criticalはSDK更新で解消。`npm audit fix --force`は旧SDKへの破壊的ダウングレードとなるため未適用
- **状態**: 🔄 上流更新を継続監視

---

## 📊 バグ対応進捗

### 完了 ✅

1. ✅ 鍵ローテーション拒否通知の赤色化（2026-08-29）
2. ✅ Premium利用上限の設定（2026-08-29）
3. ✅ UIモードと課金状態の分離（2026-08-29）
4. ✅ サブスク失効・購入監視・購入確定順序の修正（2026-08-29）
5. ✅ Functionsレシート検証（2026-08-29）

### 対応中 🔄

1. 🔄 Functions依存のmoderate脆弱性監視（Priority: Medium）
2. 🔄 通知履歴・エラー履歴の記録漏れ修正（Priority: Medium）

### 未着手 ⏳

1. ⏳ Google Play RTDN連携（Priority: High）
2. ⏳ App Store Server Notifications連携（Priority: High）
3. ⏳ ストアサンドボックスE2E確認（Priority: High）

### 翌日継続 ⏳

- ⏳ Google Play ConsoleでFunctions実行サービスアカウントへAndroid Publisher権限を付与
- ⏳ Functionsパラメータを設定し、FunctionsとFirestore Rulesを同時デプロイ
- ⏳ RTDN / App Store Server Notificationsを実装
- ⏳ 通知履歴・エラー履歴の高優先度漏れを修正

---

## 💡 技術的学習事項

### 購入検証とacknowledgeの順序

**問題パターン**:

```javascript
// ❌ 権限保存より先にacknowledgeすると、保存失敗時に復旧できない
await acknowledgePurchase(token);
await grantPremium(uid);
```

**正しいパターン**:

```javascript
// ✅ 検証し、権限を永続化してからacknowledge
const verification = await verifyPurchase(token);
await persistVerifiedEntitlement(uid, verification);
await acknowledgePurchase(token);
```

**教訓**: 支払い処理の完了通知は、権限の永続化が成功した後に行う。token自体は保存せず指紋で所有者を拘束する。

---

## 🗓 翌日（2026-08-30）の予定

1. Google Play RTDN / App Store Server Notificationsの実装
2. ストアコンソールとFunctions IAM・パラメータ設定
3. サンドボックス購入・復元・キャンセル・期限切れのE2E確認
4. 通知履歴・エラー履歴の記録漏れ修正

---

## 📝 ドキュメント更新

| ドキュメント | 更新内容 |
|---|---|
| `instructions/20_groups_lists_items.md` | Free / Premium上限と共通上限定義を更新 |
| `instructions/50_user_and_settings.md` | Functionsレシート検証とサブスクライフサイクルを更新 |
| `instructions/90_testing_and_ci.md` | Functions / Rulesのテスト手順を追加 |
| `docs/knowledge_base/user_guide.md` | Premium上限を更新 |
| `SETUP.md` | Functions検証のパラメータ、IAM、デプロイ手順を追加 |
