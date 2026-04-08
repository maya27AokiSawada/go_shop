# Jekyll / GitHub Pages 利用ガイド

**最終更新日**: 2026-04-08

GoShoppingの `docs/` フォルダは GitHub Pages で公開されています。
構成を変更する際に知っておくべき制約と注意点をまとめます。

---

## 環境

| 項目 | 値 |
| --- | --- |
| Jekyll バージョン | 3.10.0（github-pages v232 固定） |
| テーマ | jekyll-theme-primer |
| ソースディレクトリ | `docs/` |
| 公開URL | https://maya27aokisawada.github.io/go_shop/ |
| ワークフロー | `.github/workflows/jekyll-gh-pages.yml` |

---

## ⚠️ よくある落とし穴

### 1. `${{ }}` は Liquid タグとして解釈される

GitHub Actions の式（`${{ secrets.XXX }}` など）はそのままMarkdownに書くとJekyllのLiquidエンジンがクラッシュする。

**現在の対処**:
- `_config.yml` に `liquid: error_mode: lax` を設定（警告扱いにしてビルド継続）
- `daily_reports/` は `defaults` で `render_with_liquid: false` を指定しLiquid処理を無効化
- 他のファイルで `${{ }}` を使いたい場合はファイルのfrontmatterに `render_with_liquid: false` を追加する

```yaml
---
render_with_liquid: false
---
```

### 2. YAMLフロントマターの `---` は必ず閉じる

ファイルが `---` で始まるのに閉じる `---` がない場合、Jekyll がその行以降を YAML としてパースしようとしてクラッシュする。

**悪い例（クラッシュする）**:
```
---
# タイトル
本文...
```

**良い例**:
```
---
title: タイトル
---
# タイトル
本文...
```

または frontmatter を使わない（`#` ヘッダーから始める）。

> **実例**: `knowledge_base/firestore_data_clear_guide.md` が `---` 1行だけで始まっていたため、Generating フェーズでクラッシュ → "EntryFilter: excluded /daily_reports" の後で止まるエラーが発生（2026-04-08修正済み）。

### 3. ディレクトリのインデックスには `README.md` が必要

`README.md` または `index.md` がないディレクトリのURLは 404 になる。

**必要なもの**:

```
docs/
  knowledge_base/
    README.md     ← これがないと /knowledge_base/ が404
    guide.md
  troubleshooting/
    README.md     ← 同様
    network_issues.md
```

### 4. `theme: minima` はサポート外（SCSSエラー）

github-pages v232 環境では `theme: minima` を `_config.yml` に書くと SCSS コンパイルエラーでクラッシュする。

- 現在は `jekyll-theme-primer`（GitHub デフォルト）を使用
- `_config.yml` に `theme:` は書かない

---

## `_config.yml` 現在の設定

```yaml
title: GoShopping
description: 家族の買い物リストを共有するアプリ
lang: ja

liquid:
  error_mode: lax

defaults:
  - scope:
      path: "daily_reports"
    values:
      render_with_liquid: false
```

---

## ワークフロー（`jekyll-gh-pages.yml`）の要点

- `source: ./docs` — `docs/` フォルダのみJekyllに渡す
- `destination: ./_site` — リポジトリルートからの相対パス（`docs/` を source にするとパスが狂うため注意）
- `verbose: true` — ビルドログを詳細出力（エラー調査用）

---

## 新しいフォルダ・ファイルを追加するには

1. `docs/新フォルダ/README.md` を作成（インデックスページになる）
2. `docs/index.md` のリンク一覧に追加
3. `${{ }}` を含む可能性があるファイルには frontmatter で `render_with_liquid: false` を付ける
