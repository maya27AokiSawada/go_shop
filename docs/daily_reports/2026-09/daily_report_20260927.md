# 開発日報 - 2026年09月27日

## 📅 本日の目標

- [x] 紹介動画（基本機能・招待機能）のリンクを README / GitHub Pages に挿入する
- [x] `emulator-5554` の Firebase App Check デバッグトークンを特定する
- [x] 上記トークン登録によりサインインできることを確認する
- [x] 本日の作業を日報にまとめて `sumomo-planning` へコミット・プッシュする

---

## ✅ 完了した作業

### 1. 紹介動画（基本機能・招待機能）のリンク挿入 ✅

**Purpose**: 限定公開の紹介動画2本（基本機能／招待機能）を README と GitHub Pages
ドキュメントサイトの適切な場所で表示させる。

**対応**:

- [`README.md`](../../../README.md): GitHub.com 上の Markdown レンダラーは `<iframe>`
  を除去するため、YouTube サムネイル画像 + リンク（`[![...](thumbnail)](url)`）形式で
  「紹介動画」セクションを追加。
- [`docs/index.md`](../../index.md): GitHub Pages は `.github/workflows/jekyll-gh-pages.yml`
  により `sumomo-planning` ブランチの `docs/` を Jekyll でビルドしてデプロイする構成
  であることを確認。この経路では raw HTML がそのままレンダリングされるため、
  `<iframe>` 埋め込みで実際に再生可能な動画プレーヤーとして表示されるようにした。

追加した動画:

- 基本機能紹介動画: `https://youtu.be/AZOzcONX_iM`
- 招待機能紹介動画: `https://youtu.be/qPNgUP1KEJo`

**Status**: ✅ 完了。

---

### 2. `emulator-5554` の App Check デバッグトークン特定・登録 ✅

**Purpose**: サインインが Firestore への `PERMISSION_DENIED` で失敗していた件について、
Android エミュレーターの Firebase App Check デバッグトークンをログから特定する。

**対応**: この環境にはローカル `PATH` に `adb` が無かったため、
`~/Library/Android/sdk/platform-tools/adb` を直接指定して `emulator-5554` に接続。
`adb logcat -d` のバッファから
`com.google.firebase.appcheck.debug.internal.DebugAppCheckProvider` のログ行を抽出し、
以下を確認した。

- デバッグトークン: （シークレットのため日報には記載しない。作業ログ参照）
- プロジェクト: `goshopping-48db9`
- App ID: `1:101786579290:android:4d3bc00c5ccb80b8a78363`

ログには登録前の `Failed to exchange debug token` / Firestore `403 blocked` エラーが
出ていたため、Firebase Console（App Check → Apps）または
`firebase appcheck:debugtokens:create` での登録が必要であることを案内。

**結果**: ユーザーが Firebase Console でトークンを登録し、サインインに成功したことを確認。

**Status**: ✅ 完了。

---

## 🗓 次回の予定（引き継ぎ）

特になし。次回作業時に追記。

---

## 📝 ドキュメント / 変更ファイル一覧

| ファイル | 更新内容 |
|---|---|
| `README.md` | 「紹介動画」セクションを追加（基本機能・招待機能、サムネイル+リンク形式） |
| `docs/index.md` | 「紹介動画」セクションを追加（基本機能・招待機能、`<iframe>` 埋め込み） |
| `docs/daily_reports/2026-09/daily_report_20260927.md` | 本日の日報（新規） |

### 未追跡・本コミット対象外

- `.vscode/settings.json`: エディタ側のローカル設定差分。本日の作業と無関係のため据え置き
- `pubspec.lock`: ローカル環境での依存解決差分。本日の作業と無関係のため据え置き
- `.artifacts/`: 追跡対象外の作業ディレクトリ。本日の作業と無関係のため据え置き
