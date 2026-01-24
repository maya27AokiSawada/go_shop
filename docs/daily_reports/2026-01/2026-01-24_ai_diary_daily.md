# 日報: AI Diary 新プロジェクト (2026-01-24)

## 概要

Flutter で AI アシスタント付き日記アプリの初期セットアップを開始。最小構成でローカル保存(Hive)＋簡易AI支援(Mock)を動かす土台を作成。

## 実施内容

- プロジェクト作成: `ai_diary/` を `go_shop` ワークスペース下に作成
- 依存追加: Riverpod, Hive, Hive Flutter, uuid, intl, http を `pubspec.yaml` に追加
- モデル作成: `lib/models/diary_entry.dart`
  - `DiaryEntry` モデル (title/content/timestamps/tags) と `TypeAdapter` 実装
- AIサービス: `lib/services/ai_assistant_service.dart`
  - `AiAssistantService` 抽象 + `MockAiAssistantService` (提案/要約の仮実装)
- 画面/UI:
  - `lib/pages/home_page.dart` で一覧・新規作成・遷移
  - `lib/pages/editor_page.dart` で編集＋AIヒント挿入（既存ファイルを更新）
- 今後の初期化: `main.dart` に Hive 初期化 + Riverpod ProviderScope の導入予定

## 変更ファイル

- `ai_diary/lib/models/diary_entry.dart`
- `ai_diary/lib/services/ai_assistant_service.dart`
- `ai_diary/lib/pages/home_page.dart`
- `ai_diary/lib/pages/editor_page.dart`
- `ai_diary/pubspec.yaml` (依存追加)

## 現状の動作方針

- Box名: `entries`
- 一覧から新規作成→編集画面→保存→戻る までの流れを想定
- AI は Mock 実装で提案/要約を返す (将来、外部API差し替え可)

## 未着手/次の予定

- `main.dart` に Hive 初期化 + Adapter 登録 + ProviderScope 導入
- Windows 実行テスト (`flutter run`) と最低限の動作確認
- タグ/検索/並び替え、日別ビュー、バックアップ/エクスポート機能の検討
- 実運用AI(推敲/要約/感情分類)のAPI選定と安全設計

## メモ

- 今日はリポジトリへの push は行わず、ローカル commit のみ。
- UI/文言は後日調整。最小動作を優先。
