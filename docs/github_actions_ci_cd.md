# GitHub Actions CI/CD 設定ガイド

## 概要

このドキュメントでは、Go Shop アプリの GitHub Actions による自動ビルド設定について説明します。

## 実装日

2026-01-06

## ワークフロー設定

### トリガー

- ブランチ: `oneness` への push 時に自動実行
- ファイル: `.github/workflows/flutter-ci.yml`

### ランナー環境

```yaml
runs-on: ubuntu-latest
```

**⚠️ 重要**: `windows-latest` ではなく `ubuntu-latest` を使用すること

**理由**:
- Flutter の CI/CD では ubuntu-latest が最も安定している
- GitHub Actions のデフォルトシェルが bash であるため
- PowerShell 構文が使えないため、bash 構文での実装が必須

## GitHub Secrets 設定

以下の 3 つの Secret を GitHub リポジトリに設定する必要があります。

### 1. GOOGLE_SERVICES_JSON

Firebase の Android 設定ファイル（`google-services.json` の内容全体）

**設定場所**: `android/app/google-services.json`

### 2. FIREBASE_OPTIONS_DART

Firebase の Flutter 設定ファイル（`firebase_options.dart` の内容全体）

**設定場所**: `lib/firebase_options.dart`

### 3. DOT_ENV

環境変数ファイル（`.env` の内容全体）

**設定場所**: `.env`

## シェル構文の注意点

### ❌ 間違った実装（PowerShell構文）

```yaml
- name: Create google-services.json
  run: |
    $content = @'
    ${{ secrets.GOOGLE_SERVICES_JSON }}
    '@
    $content | Out-File -FilePath "android/app/google-services.json" -Encoding UTF8
```

**問題点**: ubuntu-latest では bash が使われるため、PowerShell 構文はエラーになる

### ✅ 正しい実装（bash Here-Document構文）

```yaml
- name: Create google-services.json
  run: |
    cat << 'EOF' > android/app/google-services.json
    ${{ secrets.GOOGLE_SERVICES_JSON }}
    EOF
```

**ポイント**:
1. `cat << 'EOF' > filename` でファイル作成開始
2. シングルクォート `'EOF'` で変数展開を防止（Secret 内のシングルクォートが破損しない）
3. 最後の `EOF` でファイル作成終了

## Flavor の指定

このプロジェクトには `dev` / `prod` の flavor が設定されているため、ビルド時に明示的な指定が必須です。

### ❌ 間違った実装

```yaml
- name: Build Android APK
  run: flutter build apk --release
```

**問題点**: flavor が未指定のため、APK ファイルが生成されない、またはファイル名が一致しない

### ✅ 正しい実装

```yaml
- name: Build Android APK (dev flavor)
  run: flutter build apk --release --flavor dev

- name: Upload APK
  uses: actions/upload-artifact@v4
  with:
    name: release-apk-dev
    path: build/app/outputs/flutter-apk/app-dev-release.apk
```

**ポイント**:
1. `--flavor dev` を明示的に指定
2. APK ファイル名は `app-dev-release.apk` になる（flavor名が含まれる）
3. アーティファクト名も flavor を含めて明確化

### APK ファイル名の規則

| Flavor | Build Type | ファイル名 |
|--------|-----------|----------|
| dev    | debug     | `app-dev-debug.apk` |
| dev    | release   | `app-dev-release.apk` |
| prod   | debug     | `app-prod-debug.apk` |
| prod   | release   | `app-prod-release.apk` |

## ビルドステップ

### 1. リポジトリチェックアウト

```yaml
- uses: actions/checkout@v3
```

### 2. Flutter SDK セットアップ

```yaml
- uses: subosito/flutter-action@v2
  with:
    channel: "stable"
```

**注意**: `flutter-version: "stable"` ではなく `channel: 'stable'` を使用

### 3. Secret ファイル作成

GitHub Secrets から 3 つのファイルを作成（上記参照）

### 4. 依存関係取得

```yaml
- name: Get dependencies
  run: flutter pub get
```

### 5. APK ビルド

```yaml
- name: Build Android APK (dev flavor)
  run: flutter build apk --release --flavor dev
```

### 6. アーティファクトアップロード

```yaml
- name: Upload APK
  uses: actions/upload-artifact@v4
  with:
    name: release-apk-dev
    path: build/app/outputs/flutter-apk/app-dev-release.apk
```

**注意**: `upload-artifact@v4` を使用（v3 は非推奨）

## トラブルシューティング

### エラー: "command not found"

**症状**: `$content = @'` の行で "command not found" エラー

**原因**: PowerShell 構文を bash 環境で実行しようとしている

**解決策**: bash の Here-Document 構文に変更する

### エラー: "Gradle build failed to produce an .apk file"

**症状**: ビルドは成功するが APK ファイルが見つからない

**原因**: flavor が未指定、またはファイルパスが間違っている

**解決策**:
1. `--flavor dev` を追加
2. ファイルパスを `app-dev-release.apk` に修正

### エラー: シングルクォートが破損する

**症状**: Secret 内のシングルクォート（`'`）が正しく保存されない

**原因**: Here-Document の EOF がダブルクォートまたはクォートなし

**解決策**: `'EOF'` のようにシングルクォートで囲む

## ベストプラクティス

1. **環境**: 必ず `ubuntu-latest` を使用
2. **シェル**: bash の構文（Here-Document）を使用
3. **Flavor**: 明示的に指定する
4. **ファイル名**: flavor に応じた正確なパスを指定
5. **Secret 管理**: 本番用の機密情報は必ず GitHub Secrets に保存
6. **アーティファクト**: v4 を使用し、名前を明確にする

## 参考リンク

- [GitHub Actions - Flutter](https://docs.github.com/en/actions/automating-builds-and-tests/building-and-testing-java-with-gradle)
- [subosito/flutter-action](https://github.com/subosito/flutter-action)
- [Bash Here-Documents](https://www.gnu.org/software/bash/manual/html_node/Redirections.html)

## 関連コミット

- `bd9e793`: 初期 CI/CD 設定
- `dbec044`: ubuntu-latest に変更
- `06c8a20`: bash 構文に修正
- `1e365fa`: flavor 指定追加

## 次のステップ

### prod flavor ビルドの追加

本番環境用の APK ビルドを追加する場合:

```yaml
- name: Build Android APK (prod flavor)
  run: flutter build apk --release --flavor prod

- name: Upload APK (prod)
  uses: actions/upload-artifact@v4
  with:
    name: release-apk-prod
    path: build/app/outputs/flutter-apk/app-prod-release.apk
```

### Google Play へのデプロイ

自動デプロイを追加する場合は、以下のアクションを検討:
- `r0adkll/upload-google-play`
- `wzieba/Firebase-Distribution-Github-Action`
