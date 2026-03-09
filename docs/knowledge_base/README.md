# GoShopping - Knowledge Base

このフォルダには、現行実装の理解や保守に役立つ技術ガイド、アーキテクチャ解説、運用メモをまとめています。

## 配置ルール

- 残すもの: 現在も参照価値があるガイド、設計解説、運用手順、再利用するテスト手順
- 移すもの: 日付付きの実装レポート、単発のデバッグ結果、引継ぎ、テスト実行ログ
- 棚上げ資料: 将来再検討の可能性があるが、現行仕様ではないもの

履歴性の強い資料は `../daily_reports/` に移しています。

## 主なカテゴリ

### アーキテクチャ・分析

- [authentication_flow_analysis.md](authentication_flow_analysis.md)
- [crud_workflow_architecture.md](crud_workflow_architecture.md)
- [firestore_architecture.md](firestore_architecture.md)
- [shopping_list_realtime_sync_design.md](shopping_list_realtime_sync_design.md)
- [signin_state_analysis.md](signin_state_analysis.md)
- [sync_architecture.md](sync_architecture.md)
- [sync_confirmation_system.md](sync_confirmation_system.md)
- [refactoring_analysis_step1.md](refactoring_analysis_step1.md)

### セットアップ・運用ガイド

- [email_delivery_verification_guide.md](email_delivery_verification_guide.md)
- [error_fixing_guide.md](error_fixing_guide.md)
- [firebase_index_fix.md](firebase_index_fix.md)
- [firebase_trigger_email_setup_guide.md](firebase_trigger_email_setup_guide.md)
- [firestore_data_clear_guide.md](firestore_data_clear_guide.md)
- [firestore_debug_checklist.md](firestore_debug_checklist.md)
- [github_actions_ci_cd.md](github_actions_ci_cd.md)
- [ios_flavor_setup.md](ios_flavor_setup.md)
- [privacy_protection.md](privacy_protection.md)
- [riverpod_best_practices.md](riverpod_best_practices.md)
- [sakura_smtp_setup_guide.md](sakura_smtp_setup_guide.md)
- [signup_widget_usage.md](signup_widget_usage.md)
- [user_guide.md](user_guide.md)

### テスト・検証メモ

- [hybrid_mode_offline_verification.md](hybrid_mode_offline_verification.md)
- [test_checklist_template.md](test_checklist_template.md)
- [test_procedures_v2.md](test_procedures_v2.md)
- [ui_integration_test_checklist.md](ui_integration_test_checklist.md)
- [widget_test_gestures.md](widget_test_gestures.md)

### 棚上げ・将来検討

- [member_message_feature_shelved.md](member_message_feature_shelved.md)
- [refactoring_session_summary.md](refactoring_session_summary.md)

## 2026-03-09 に整理して移動した資料

- 2025-10 の招待・メール・QR・ビルド・引継ぎ・ハイブリッド同期レポート
- 2025-11 の削除バグ修正・リファクタリング計画・エラーハンドリング標準化レポート
- 2025-12 の単発テストチェックシート

これらは月別の `../daily_reports/` にアーカイブしています。
