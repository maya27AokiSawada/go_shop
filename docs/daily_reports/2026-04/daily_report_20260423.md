# 開発日報 - 2026年04月23日

## 📅 本日の目標

- [x] Firebase 料金プランの整理・確認

---

## ✅ 完了した作業

### 1. Firebase Spark プラン可否の調査・整理 ✅

**Purpose**: このアプリが Firebase Spark プラン（無料）で運用できるか確認する

**Background**:
ストア公開を視野に入れ、Firebase の料金プランと課金リスクを事前に把握したい。

**調査結果**:

| Firebase サービス | 使用状況                           | Spark プラン  |
| ----------------- | ---------------------------------- | ------------- |
| Firebase Auth     | ✅ 使用中                          | ✅ 無料       |
| Cloud Firestore   | ✅ 使用中                          | ✅ 無料枠あり |
| Crashlytics       | ✅ 使用中                          | ✅ 無料       |
| App Check         | ✅ 使用中                          | ✅ 無料       |
| Cloud Functions   | ✅ `functions/index.js` に実装済み | ❌ Blaze 必須 |
| Cloud Storage     | Functions 経由でバックアップ用途   | ❌ Blaze 必須 |

**結論**:

- `functions/index.js` に `scheduledFirestoreBackup`（毎日JST0時）、`listBackups`（Callable）、ユーザーデータリストア（Callable）の3関数が実装されており、**Functions をデプロイする限り Blaze プランが必要**
- Functions をデプロイしなければ、クライアント機能（認証・Firestore・Crashlytics）は Spark プランで動作可能

**Status**: ✅ 調査完了

---

### 2. Spark プランでのストア公開における課金リスク整理 ✅

**Purpose**: Functions を無効化して Spark プランにした場合のリスクを明確化する

**結論**:

| 状況                             | 課金リスク           |
| -------------------------------- | -------------------- |
| 家族・知人限定（〜10人）         | ほぼゼロ             |
| クローズドテスト（〜数十人）     | 低い                 |
| ストア公開・一般公開（制限なし） | **超過の可能性あり** |

- Firestore 無料枠：読み取り 50,000回/日。`snapshots()` リスナーを多用しているため**50人同時利用でも超過リスクあり**
- 超過後は課金されるのではなく**アクセスがブロックされてアプリが動作しなくなる**

**推奨**: Blaze プランにして予算アラートを $1〜5 に設定するのが最も安全。実際のコストは小規模運用なら月ほぼ $0。

**Status**: ✅ 調査完了

---

### 3. 緊急時アクセス制限手順の整理 ✅

**Purpose**: バズって課金リスクが発生した場合の対処手順を把握する

**手順（優先順位順）**:

1. **Firebase Console 予算アラート設定（事前）** - Billing → Budgets & alerts → $1/$5/$10 で通知
2. **Firestore セキュリティルール変更（最速）** - `firebase deploy --only firestore:rules` でアプリ更新不要、即時反映
3. **Firebase Authentication 新規登録無効化** - コンソールで操作、既存ユーザーはログイン継続可
4. **Functions 削除** - `firebase functions:delete scheduledFirestoreBackup listBackups restoreUserData`

**Status**: ✅ 整理完了

---

### 4. メンテナンスフラグ実装方針の策定 ✅

**Purpose**: コードを変えずに緊急停止できる仕組みの設計

**方針**:

Firestore に `/config/maintenance` ドキュメントを作成し、フラグを切り替えるだけでアプリの動作を制御する。

```
/config/maintenance
{
  "enabled": false,          // true → アプリ全体を止める（起動時ブロック）
  "signup_disabled": false,  // true → サインアップだけ止める
  "message": "現在混雑のため新規登録を一時停止しています"
}
```

**実装箇所（翌日実装予定）**:

- **パターンA（全体停止）**: `app_initialize_widget.dart` の `_performAppInitialization()` 先頭でフラグ確認
- **パターンB（サインアップのみ停止）**: `auth_panel_widget.dart` の `performSignUp` 呼び出し直前でフラグ確認

**Status**: ✅ 設計完了・実装は翌日

---

## 🐛 発見された問題

（なし）

---

## 📊 バグ対応進捗

### 翌日継続 ⏳

- ⏳ メンテナンスフラグ実装（`app_initialize_widget.dart` + `auth_panel_widget.dart`）

---

## 💡 技術的学習事項

### Firebase Spark プランの落とし穴

**問題パターン**: Spark プランで超過するとエラーになると思っていた

**正しい理解**: Spark プランで無料枠を超過すると**課金されるのではなく、アクセスがブロックされてアプリが動作しなくなる**。ユーザー体験が最悪になるため、公開後は Blaze プラン＋予算アラートが現実的。

**教訓**: 小規模運用でも Blaze プランにして上限アラートを設定するのが安全かつ実際の課金リスクも低い。

---

## 🗓 翌日（2026-04-24）の予定

1. メンテナンスフラグ実装（`app_initialize_widget.dart` + `auth_panel_widget.dart`）
2. Firestore に `/config/maintenance` ドキュメントを手動作成

---

## 📝 ドキュメント更新

| ドキュメント | 更新内容                                               |
| ------------ | ------------------------------------------------------ |
| （更新なし） | 理由: ソースコード変更なし。設計・調査のみのセッション |
