# クローズドテスト用フィードバック機能 実装完了

## 実装内容

### 1. **新規サービス作成**

#### `lib/services/app_launch_service.dart`

- アプリ起動回数をカウント（SharedPreferences保存）
- `incrementLaunchCount()`: 起動回数をインクリメント
- `getLaunchCount()`: 現在の起動回数を取得
- `resetLaunchCount()`: デバッグ用にリセット

#### `lib/services/feedback_status_service.dart`

- フィードバック送信状態を管理（SharedPreferences保存）
- `markFeedbackSubmitted()`: 送信済みにマーク
- `isFeedbackSubmitted()`: 送信状態を確認
- `resetFeedbackStatus()`: デバッグ用にリセット

#### `lib/services/feedback_prompt_service.dart`

- Firestore の `/testingStatus/active` からテスト実施フラグを確認
- `isTestingActive()`: テスト実施中かどうかを確認
- `shouldShowFeedbackPrompt()`: 催促表示の判定ロジック
- `setTestingActive()`: デバッグ用にテスト状態を設定

### 2. **ホーム画面統合**

#### `lib/pages/home_page.dart`

- `initState()` で `_incrementAppLaunchCount()` を実行
- アプリ起動時に自動的に起動回数をカウント

### 3. **ニュースパネルに催促表示**

#### `lib/widgets/news_widget.dart`

- フィードバック催促カードを実装
- `_shouldShowFeedbackPrompt()`: 非同期で催促条件を判定
- `_buildFeedbackPromptCard()`: 紫色のプロモーションカードを表示
- Google フォームのリンクを開く機能

#### 催促表示条件（Firestore テストステータスを確認してから実行）

- **テスト実施中でない（isTestingActive = false）**: 催促なし
- **5回起動＆未フィードバック**: 未送信ユーザーに催促
- **20回起動**: 全員に催促

### 4. **設定ページにリンク追加**

#### `lib/pages/settings_page.dart`

- 認証済みユーザーに「フィードバック送信」セクションを追加
- `_openFeedbackForm()`: Google フォームを開く
- フォーム開封後に自動で「送信済み」フラグを設定

### 5. **デバッグツール（開発環境のみ）**

#### `lib/pages/settings_page.dart` - フィードバック催促デバッグセクション

- 起動回数の表示・リセット
- フィードバック送信状態の表示・リセット
- テスト実施状態の表示・ON/OFF切り替え

### 6. **Firestore セキュリティルール更新**

#### `firestore.rules`

```javascript
match /testingStatus/{document=**} {
  // 読み取り：認証済みユーザーのみ
  allow read: if request.auth != null;
  // 書き込み：管理者のみ（Console から管理）
  allow write: if false;
}
```

---

## 使用方法

### テスト運用時

1. **Google フォーム作成** ✅
   - Google フォームを作成
   - リンクを取得: `https://forms.gle/wTvWG2EZ4p1HQcST7`

2. **リンク設定** ✅
   - `lib/widgets/news_widget.dart` Line 72
   - `lib/pages/settings_page.dart` Line 1172
   - リンク設定完了

3. **テスト状態をオンに設定** ⏳
   - Firestore Console で `/testingStatus/active` ドキュメント作成
   - `isTestingActive: true` フィールドを追加

### デバッグ方法（開発環境）

1. **設定ページ** → 「フィードバック催促（デバッグ）」セクション
2. 以下の操作が可能：
   - 起動回数のリセット
   - フィードバック状態のリセット
   - テスト状態の ON/OFF 切り替え

### 催促ロジックの動作確認

```dart
// パターン1: 5回起動＆未フィードバック
// アプリを5回起動 → ホーム画面にフィードバック催促カードが表示

// パターン2: 20回起動
// アプリを20回起動 → 全員にフィードバック催促が表示

// パターン3: テスト実施中ではない
// テスト状態を OFF に → 催促は表示されない
```

---

## ファイル一覧

**新規作成**:

- `lib/services/app_launch_service.dart`
- `lib/services/feedback_status_service.dart`
- `lib/services/feedback_prompt_service.dart`

**修正**:

- `lib/pages/home_page.dart`: 起動カウント統合
- `lib/widgets/news_widget.dart`: 催促カード実装
- `lib/pages/settings_page.dart`: フィードバック送信＋デバッグツール
- `firestore.rules`: testingStatus コレクションルール追加

---

## 実装のポイント

### 1. **Google フォーム版を選択した理由**

- 実装が簡単（10分で統合可能）
- クローズドテスト段階では十分
- 後から Firestore に移行可能

### 2. **Firestore テストフラグの利点**

- 管理者がテスト実施状態をリアルタイム制御可能
- 催促の表示・非表示を即座に切り替え可能
- 複数アプリ版やグローバル展開時に活用可能

### 3. **SharedPreferences の使用**

- ローカルキャッシュで高速化
- Firestore クエリ削減
- オフライン環境でも動作

### 4. **デバッグツールの重要性**

- テスト期間中の動作検証が容易
- 催促ロジックのデバッグが効率化
- チーム内での共有・検証が簡単

---

## 次のステップ

- [ ] Google フォーム作成
- [ ] リンク設定（feedback_prompt_service.dart, news_widget.dart）
- [ ] Firestore に `/testingStatus/active` ドキュメント作成
- [ ] クローズドテスト実施
- [ ] テスター返却フィードバックの分析
- [ ] 必要に応じて Firestore コレクション版に拡張

---

## トラブルシューティング

### Q: フィードバック催促が表示されない

A: 以下を確認してください：

- Firestore の `/testingStatus/active` の `isTestingActive` が `true` か
- アプリを5回以上起動したか（未送信時）
- 開発ツールでテスト状態を確認

### Q: Google フォームが開かない

A: `url_launcher` パッケージの権限を確認してください：

- Android: `AndroidManifest.xml` に `INTERNET` 権限
- iOS: `Info.plist` に `LSApplicationQueriesSchemes` 設定

### Q: フィードバック状態がリセットできない

A: 開発環境（`Flavor.dev`）で実行してください。設定ページのデバッグセクションが表示されます。
