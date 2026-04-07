# 開発日報 - 2026年04月07日

## 📅 本日の目標

- [x] AdMob本番ID（バナー・インタースティシャル）をコードに設定
- [x] Play Store提出用アセット作成（アイコン・フィーチャーグラフィック）
- [x] `google-services-my.json` のAPIキーローテーション＆gitignore追加
- [x] futureブランチの内容をmainブランチにプッシュ（機密情報チェック済み）
- [x] GitHub Pages（Jekyll）設定
- [x] Play Consoleに関するQ&A（金融取引申告・カテゴリ・データ削除URL・タブレット対応）

---

## ✅ 完了した作業

---

### 1. AdMob本番ID設定 ✅

**Purpose**: AdMobコンソールで発行した本番Ad Unit IDをコードに反映する

**Background**: 前回セッションでApp IDは `~2053597705` に更新済み。本日ユーザーよりAd Unit IDが発行された。

**Solution**:

| 種別                 | ID                                       |
| -------------------- | ---------------------------------------- |
| バナー               | `ca-app-pub-7163325066755382/8580515011` |
| インタースティシャル | `ca-app-pub-7163325066755382/4071987466` |

```dart
// ✅ 修正後: lib/services/ad_service.dart
String get _bannerAdUnitId {
  if (F.appFlavor == Flavor.prod) {
    return dotenv.env['ADMOB_BANNER_AD_UNIT_ID'] ??
        'ca-app-pub-3940256099942544/6300978111';
  } else {
    return dotenv.env['ADMOB_TEST_BANNER_AD_UNIT_ID'] ??
        'ca-app-pub-3940256099942544/6300978111';
  }
}

String get _interstitialAdUnitId {
  if (F.appFlavor == Flavor.prod) {
    return dotenv.env['ADMOB_INTERSTITIAL_AD_UNIT_ID'] ??
        'ca-app-pub-3940256099942544/1033173712';
  } else {
    return dotenv.env['ADMOB_TEST_BANNER_AD_UNIT_ID'] ??
        'ca-app-pub-3940256099942544/1033173712';
  }
}
```

**Modified Files**:

- `.env` : `ADMOB_APP_ID` 更新（`~9574681576` → `~2053597705`）、`ADMOB_BANNER_AD_UNIT_ID` 更新、`ADMOB_INTERSTITIAL_AD_UNIT_ID` 追加
- `android/app/src/main/AndroidManifest.xml` : App ID更新
- `lib/services/ad_service.dart` : prod/dev分岐・`.env`読み込みに整理、TODOコメント削除
- `.env.example` : `ADMOB_INTERSTITIAL_AD_UNIT_ID` キー追加

**Commit**: `4d600c2`
**Status**: ✅ 完了。AABビルド済み（61.2MB, v1.1.0+6）

---

### 2. Play Store用アセット生成 ✅

**Purpose**: Play Console登録に必要なアイコン・フィーチャーグラフィックを生成する

**Background**: iOSアセットの1024×1024はデフォルトFlutterアイコンのままで使用不可。Androidのxxxhdpiアイコン（192×192）をソースに、PowerShellのSystem.Drawingでネイティブ描画。

**Solution**:

| ファイル                         | サイズ            | 内容                                             |
| -------------------------------- | ----------------- | ------------------------------------------------ |
| `play_store_icon.png`            | 512×512 (10.5KB)  | ピンク円＋白チェック＋緑葉をネイティブ描画       |
| `play_store_feature_graphic.png` | 1024×500 (70.7KB) | グラデーション背景＋アイコン＋テキスト＋機能ピル |

フィーチャーグラフィック構成:

- 背景: マゼンタ→ダークパープルのグラデーション
- 左: アイコン（280px）
- 右: アプリ名「GoShopping」、日本語キャッチコピー、英語サブコピー
- 機能ピル: `✓ リアルタイム同期` / `✓ QR招待` / `✓ ホワイトボード`

**Commit**: `2450a1d`
**Status**: ✅ 完了・futureブランチにプッシュ済み

---

### 3. google-services-my.json APIキーローテーション＆gitignore追加 ✅

**Purpose**: `google-services-my.json`（dev用Firebase設定）がgitignore対象外のままAPIキーが含まれており、mainプッシュ前に対処が必要だった

**Problem / Root Cause**:

- `.gitignore` に `google-services.json` は記載されていたが `google-services-my.json` は未記載
- dev用Firebase APIキー `AIzaSyDr5dg16s59EO1CuBTHAyfXxr1TVYiRlSo` がfutureブランチのコミット履歴に存在

**Solution**:

1. Google Cloud Console（プロジェクト: `gotoshop-572b7`）でAPIキーを再生成
2. `google-services-my.json` の `current_key` を新キーに更新
3. `.gitignore` に `google-services-my.json` を追加
4. `git rm --cached` でgitトラッキングから除外

```diff
# .gitignore
 google-services.json
+google-services-my.json
 GoogleService-Info.plist
```

**Modified Files**:

- `.gitignore` : `google-services-my.json` 追加
- `android/app/google-services-my.json` : APIキーローテーション（gitから除外済み）

**Commit**: `b419cea`
**Status**: ✅ 完了・旧キーは無効化済み

---

### 4. GitHub Pages（Jekyll）設定 ✅

**Purpose**: プライバシーポリシー・利用規約をWebで公開し、Play Consoleのデータ削除URLに登録できるようにする

**Solution**:

- `.github/workflows/jekyll-gh-pages.yml` を作成
  - `source: ./docs` に設定（`docs/` 配下のみ公開）
  - mainブランチへのpushで自動デプロイ
- `docs/_config.yml` を作成（Jekyllテーマ・タイトル設定）

公開後のURL:

```
https://maya27aokisawada.github.io/go_shop/specifications/privacy_policy
```

**Modified Files**:

- `.github/workflows/jekyll-gh-pages.yml` : 新規作成
- `docs/_config.yml` : 新規作成

**Commit**: `b3e9cad`
**Status**: ✅ mainにプッシュ済み。GitHub Actionsでデプロイ中

---

### 5. mainブランチへのプッシュ ✅

**Purpose**: futureブランチの蓄積コミット（395件）をmainに反映する

**Background**: 機密情報チェックを実施してから実行。`google-services-my.json` の問題を発見・対処後にプッシュ。

**検証結果**:

```
git diff main..future --name-only | Select-String "google-services|firebase_options|\.env$|secret"
→ android/app/google-services-my.json のみ検出 → 対処済み後にプッシュ
```

**Status**: ✅ future・main両ブランチに最新状態を反映済み

---

## 🐛 発見された問題

### google-services-my.json がgitignore対象外だった ✅ 修正済み

- **症状**: `git diff main..future` でAPIキーを含むファイルが差分に存在
- **原因**: `.gitignore` に `google-services.json` のみ記載、`-my.json` variant が未記載
- **対処**: APIキーローテーション＋gitignore追加＋git rm --cached
- **状態**: 修正完了（`b419cea`）

---

## 📊 バグ対応進捗

### 完了 ✅

1. ✅ google-services-my.json gitignore漏れ（完了日: 2026-04-07）

### 翌日継続 ⏳

- ⏳ Play Console: AABアップロード（クローズドテストトラック登録）
- ⏳ Play Console: データ削除URL登録（GitHub Pages公開後）
- ⏳ 利用規約第9条5項削除（正式リリース直前）
- ⏳ in_app_purchase SDK統合（正式リリース前）

---

## 💡 技術的学習事項

### AdMob App IDとAd Unit IDの違い

**問題パターン**: App ID（`~` チルダ区切り）とAd Unit ID（`/` スラッシュ区切り）を混同しやすい

```
App ID     : ca-app-pub-7163325066755382~2053597705  ← AndroidManifest.xml
Ad Unit ID : ca-app-pub-7163325066755382/8580515011  ← コード内
```

**教訓**: AndroidManifest.xmlに設定するのはApp ID（チルダ）のみ。Ad Unit IDはコード/envで管理。

### gitignoreのvariantファイル漏れパターン

**問題パターン**: `google-services.json` を除外しても `google-services-my.json` は別エントリが必要

**教訓**: 機密ファイルをgitignoreする際はバリアント名（`-dev`, `-my`, `.backup`等）も明示的に追加する。

---

## 🗓 翌日（2026-04-08）の予定

1. Play Console: クローズドテストAABアップロード（v1.1.0+6）
2. GitHub Pages公開確認 → データ削除URL・プライバシーポリシーURL登録
3. Work≠Buildテスター招待設定
4. 正式リリースに向けた残タスク確認

---

## 📝 ドキュメント更新

| ドキュメント | 更新内容                                                                                                     |
| ------------ | ------------------------------------------------------------------------------------------------------------ |
| （更新なし） | 理由: 本日の作業はPlay Store提出準備・セキュリティ対処が主であり、アプリのアーキテクチャ・機能仕様に変更なし |
