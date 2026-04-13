# 開発日報 - 2026年04月13日

## 📅 本日の目標

- [x] ビルド番号を7にカウントアップしてPlay Store用AABをビルドする
- [x] クローズドテストの審査申請を行う
- [x] Pixel 9でのサインイン失敗を調査する
- [ ] Pixel 9でのPlay Store版サインイン問題を解決する（調査中）

---

## ✅ 完了した作業

### 1. バージョン番号カウントアップ & Play Store AABビルド ✅

**Purpose**: バージョン 1.1.0+7 のリリースAABをGoogle Play Store向けにビルドする

**Background**:

- 前回セッションでFirebase App Check対応・フィーチャーグラフィック作成が完了
- 今回はビルド番号インクリメントとPlay Store提出用ビルドが目的

**Solution**:

```yaml
# ✅ pubspec.yaml
# ❌ Before
version: 1.1.0+6

# ✅ After
version: 1.1.0+7
```

ビルドコマンド:

```bash
flutter build aab --release --flavor prod
```

**検証結果**:

```
✓ Built build\app\outputs\bundle\prodRelease\app-prod-release.aab (61.7MB)
ビルド時間: 477.9秒
```

**Modified Files**:

- `pubspec.yaml` - version: 1.1.0+6 → 1.1.0+7

**Status**: ✅ 完了・検証済み

---

### 2. Google Play クローズドテスト審査申請 ✅

**Purpose**: 1.1.0+7 をクローズドテストトラックで審査に提出する

**Background**:

- ストア掲載情報（アイコン・スクリーンショット・説明文・フィーチャーグラフィック）を整備
- 広告ID利用目的：「広告またはマーケティング」「分析」を設定
- 国/地域：日本を追加

**Solution**:

- Play Console → クローズドテスト → 「21件の変更を審査に送信」を実行
- 審査通過確認: `App Bundle: 7 (1.1.0)` 配信状態 = **Install time / すべての対応デバイスに配信可能**

**検証結果**:

| 項目           | 状態                        |
| -------------- | --------------------------- |
| 審査           | ✅ 通過                     |
| 配信状態       | Install time（配信可能）    |
| インストール数 | 0（テスター未インストール） |

**Status**: ✅ 完了・検証済み

---

## 🐛 発見された問題

### Play Store版でサインイン失敗（App Check 403エラー）⚠️ 調査中

- **症状**: Pixel 9でPlay Store経由のクローズドテスト版（1.1.0+7）にてサインインが失敗
- **エラーログ**:
  ```
  W/LocalRequestInterceptor: Error getting App Check token; code: 403
  body: Requests from this Android client application net.sumomo_planning.goshopping are blocked.
  ```
- **調査内容**:
  1. SHA証明書フィンガープリント確認 → Firebase ConsoleにPlay App Signing KeyのSHA-1・SHA-256両方登録済み ✅
  2. Google Cloud Console → Play Integrity API 有効化確認 ✅（prodプロジェクト）
  3. Firebase Console → App Check → GoShopping (android) → **Play Integrity 登録済み** ✅
  4. App Check設定（SHA-256登録）を保存し忘れていた → 保存を実行 ✅
- **根本原因**: 未特定（設定は正しいが反映待ちの可能性）
- **状態**: 🔄 調査中 - Firebase設定反映待ち（10〜15分）で改善するか確認中

### Firebase Console App Check SHA不足（修正済み）✅

- **症状**: Play Store経由インストール → Play Integrityが失敗
- **原因**: Google Play App Signing（再署名）によりFirebaseに登録済みのSHAと不一致
- **対処**:
  - Play Console → 設定 → アプリの整合性 → アプリ署名キー証明書からSHA取得
  - Firebase ConsoleにPlay App Signing KeyのSHA-1（`13:9C:E4:...`）とSHA-256（`52:94:8C:...`）を追加
- **状態**: ✅ Firebase設定修正済み（効果確認待ち）

---

## 📊 バグ対応進捗

### 完了 ✅

1. ✅ Firebase App Check 初期化コード実装（2026-04-10）
2. ✅ Play Store App Signing Key SHA をFirebaseに登録（2026-04-13）
3. ✅ バージョン1.1.0+7 ビルド・審査通過（2026-04-13）

### 対応中 🔄

1. 🔄 Play Store版 App Check 403エラー解消（Priority: High）

### 翌日継続 ⏳

- ⏳ Pixel 9でPlay Store版サインイン成功確認
- ⏳ GoShoppingClosedTestメーリングリストのテスター（5名）へ参加URL共有
- ⏳ クローズドテスト 12人以上のテスター集め（本番公開要件）

---

## 💡 技術的学習事項

### Google Play App Signing とFirebase SHA証明書

**問題パターン**:
AABをPlay Storeにアップロードすると、GoogleがApp Signing Key（Gogoleのサーバーで管理）で再署名する。
この再署名後の署名がFirebaseに登録されていないと、Firebase AuthのreCAPTCHA検証やApp CheckのPlay Integrity検証が失敗する。

**正しいパターン**:

1. Play Console → 設定 → アプリの整合性 → **アプリ署名キーの証明書** からSHA-1・SHA-256を取得
2. Firebase Console → プロジェクト設定 → Androidアプリ → **フィンガープリントを追加** に登録
3. App Check → AndroidアプリをPlay Integrityで登録し保存

**教訓**: アップロードキーとApp Signing Keyは別物。Play Storeはアップロードキーを受け取り、配信時にApp Signing Keyで再署名する。Firebaseには両方のSHAを登録する必要がある。

### クローズドテストの本番公開要件（2023年以降の新規アプリ）

- 12人以上のテスターにオプトインしてもらう
- 14日間以上テストを実施する
- 上記を満たしてから「本番環境へのアクセスを申請」ボタンが有効になる

---

## 🗓 翌日（2026-04-14）の予定

1. Pixel 9でPlay Store版サインイン成功確認
2. GoShoppingClosedTestテスター5名へ参加リンクを送付
3. 追加テスター（12人まで）の募集検討
4. サインイン問題が継続する場合：App Check設定の詳細デバッグ

---

## 📝 ドキュメント更新

| ドキュメント | 更新内容                                                                              |
| ------------ | ------------------------------------------------------------------------------------- |
| （更新なし） | 理由: コード変更は軽微（バージョン番号・App Check初期化）のみ。アーキテクチャ変更なし |
