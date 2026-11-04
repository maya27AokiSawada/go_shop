# 開発日報 - 2026年11月4日

## 📅 本日の目標

- [x] AAB のリリースビルドのエラーを調査する
- [x] ビルド `1.2.0+48` 向けの開発に入る
- [x] 繁体中国語に対応する

---

## ✅ 完了した作業

### 1. ビルド `1.2.0+47` を急遽リリース ✅

**Purpose**: Google から、セキュリティパッチを当てるため Flutter SDK をアップグレードするよう求められた。

**Note**:

- Flutter SDK を 3.47.9（Dart 3.13.7）に上げ、予定していた修正（繁体中国語）を待たずに `1.2.0+47` をリリースした。
- アップグレードにより `pubspec.lock` の依存パッケージが更新された（`cloud_firestore` 6.10.0 → 6.10.2、`cloud_functions` 6.5.0 → 6.5.1 など）。この差分は今回コミットした。
- 繁体中国語は +48 で対応する。

---

### 2. AAB のリリースビルドのエラーを調査 ✅

**Problem**: `flutter build appbundle --release --flavor prod` が `:app:packageProdReleaseBundle` で失敗した。

```text
java.util.zip.ZipException: invalid entry crc-32 (expected 0x3f47731b but got 0xf0ad0377)
```

**Root Cause**: AAB を組み立てるときに読んだ中間ファイルのチェックサムが合わなかった。コードや Gradle 設定の問題ではない。同じ `build/` フォルダに対して別のビルドが同時に動いていた可能性が高い（調査のために Claude Code がリリースビルドを実行した時間と重なった可能性がある）。ほかに、ウイルス対策ソフトのスキャンや、中断したビルドの残骸でも起きる。

**Solution**: ほかのビルドが動いていない状態でビルドし直して成功した。

**Note**: 再発したら `flutter clean` → `flutter pub get` → ビルドの順に実行する。繰り返すようなら `build` フォルダと `%USERPROFILE%\.gradle` を Defender の除外に入れる。

---

### 3. バージョンを `1.2.0+48` に更新 ✅

- `pubspec.yaml` の `version` を `1.2.0+48` に、`AGENTS.md` の「現在のビルド目標バージョン」も `1.2.0+48` に更新した。

---

### 4. 繁体中国語（台湾）に対応 ✅

**Purpose**: 繁体中国語圏（台湾・香港）のユーザー向けに、設定画面で「中文（繁體）」を選べるようにする。

**Solution**:

- `lib/l10n/app_texts_zh_hant.dart`（`AppTextsZhHant`）を追加した。簡体字版の全 704 キーを OpenCC の台湾向け変換（s2twp）で繁体字にし、台湾の UI として不自然な用語を直した。
  - 例: 專案 → 項目、二維碼 → QR碼、賬號 → 帳號、郵箱 → 電子郵件、退出登入 → 登出、套餐 → 方案、恢復購買 → 回復購買、列表 → 清單、撤銷 → 復原、稽核 → 審核、引用符は「」
- 言語コードは `zh_Hant`。既存の `zh`（簡体字）は保存済みの設定を壊さないため変更していない。
- `AppLocalizations` の `setLanguage()` / `currentLanguageCode` / `supportedLanguages` / `getLanguageName()` と `l10n.dart` の export に追加した。

**Note**: 機械変換をもとにしているため、ネイティブの方に一度見てもらいたい。

---

### 5. 日本語以外の言語ではニュース・法的リンク・日付を英語版にする ✅

**Problem**: `AppLocalizations.currentLanguageCode` が、ポルトガル語・簡体字・繁体字を選んでいても `'en'` を返していた。これらのクラスは `AppTextsEn` を継承しているのに、`is AppTextsEn` を先に判定していたため。

- 起動直後は `'en'` 扱いなのでニュースなどが英語版で表示されていたが、設定画面で言語を切り替えた直後は `'zh'` などが渡され、ニュースが日本語版になっていた。

**Solution**:

- `currentLanguageCode` で、サブクラス（pt / zh / zh_Hant）を `AppTextsEn` より先に判定するようにした。
- 日本語版と英語版しかないコンテンツは「日本語以外は英語版」とする方針にし、判定用に `AppLocalizations.usesJapaneseContent()` / `isJapaneseContent` を追加した。
  - ニュース（`FirestoreNewsService`）: 日本語以外は `current_news_eng`。取得失敗時の既定ニュースも同じ言語で返すようにした。
  - 法的リンク（`CommonAppBar`）: 日本語以外は英語版のページ。
  - ニュースの日付書式（`NewsWidget`）: 日本語以外は英語形式。
- ルールを `instructions/00_project_common.md` の「8. 多言語対応（l10n）ルール」に追記した。

**Test**: `test/l10n/app_localizations_test.dart` を追加（全言語の言語コードの往復、日本語以外は英語版のコンテンツ、`zh_Hant` / `zh` の切り替え）。

---

## 📝 今後の予定

- ビルド `1.2.0+48` を作成し、内部テストに出す。

---

## 🔄 継続・確認事項

- 実機で「中文（繁體）」に切り替え、主要画面の表示（文字の欠け・はみ出し）を確認する。
- ポルトガル語・中国語に切り替えたとき、ニュースと三点メニューの法的リンクが英語版になることを実機で確認する。
- 繁体字の文言をネイティブの方に確認してもらう。
