# Go Shop 開発計画

**最終更新**: 2026-02-17
**現在のバージョン**: 1.1.0+2

## 開発フェーズ

### Phase 1: 基盤整備 ✅ (完了: 2025-12)

**目標**: エラー修正とアプリの基本動作確保

#### 完了済み

- ✅ プロジェクト構成・依存関係設定
- ✅ データモデル設計（Freezed + Hive）
- ✅ 認証必須システム（Firebase Auth）
- ✅ Repository パターン実装（Hive/Firestore/Hybrid）
- ✅ 基本UI レイアウト
- ✅ 買い物リスト永続化バグ修正（2件）
  - 混在キー戦略の統一
  - マイグレーション再実行バグ修正
- ✅ **Firestore-first Architecture実装** (2025-12-17/18)
  - 全3層（Group/List/Item）でFirestore優先読み込み
  - HybridRepositoryパターン確立
  - Hiveキャッシュによるオフラインフォールバック
- ✅ 招待機能実装（完了 2025-12-25）
  - モデル層（Invitation with Freezed + Firestore）
  - リポジトリ層（FirestoreInvitationRepository）
  - プロバイダー層（Riverpod状態管理）
  - UI層（QR生成・スキャン、手動入力）
  - **QRコードv3.1軽量版**（Firestore連携パターン）
  - 招待受諾バグ完全修正（通知システム統合）
- ✅ Firebase環境構築
  - プロジェクト: gotoshop-572b7
  - Firestoreインデックス定義・デプロイ
  - Firebase CLI設定
  - Firestore Security Rules設定
- ✅ **GitHub Actions CI/CD構築** (2026-01-06)
  - ubuntu-latest環境でのAndroid APKビルド
  - bash Here-Document構文採用
  - mainブランチpush時の自動ビルド

### Phase 2: 機能拡張 ✅ (完了: 2025-12)

**目標**: 基本機能の完全実装とマルチユーザー対応

#### 完了済み

- ✅ メンバー招待システム（2025-11 ~ 2025-12）
  - QRコード生成・スキャン機能
  - 手動トークン入力
  - 期限付き招待（24時間）
  - 使用回数制限（5人まで）
  - **QRコードv3.1軽量版**（75%サイズ削減）
  - 招待受諾完全動作確認済み
- ✅ **SharedList リアルタイム同期** (2025-11-22)
  - Firestore `snapshots()` 実装
  - StreamBuilder統合
  - デバイス間同期確認済み（< 1秒）
- ✅ **差分同期実装** (2025-12-18)
  - Map<String, SharedItem>型への移行
  - addSingleItem/updateSingleItem/removeSingleItem実装
  - **90%ネットワーク削減達成**
- ✅ **通知システム実装** (2025-12-24)
  - Firestoreベースのアプリ間通知
  - リアルタイムリスナー実装
  - グループ削除通知対応
  - 通知履歴画面実装
- ✅ **UI/UX改善**
  - 二重送信防止機能
  - ローディング表示統一
  - エラーハンドリング強化
- ✅ **ドキュメント整理** (2026-01-06)
  - 77ファイルを3カテゴリに分類
  - プライバシーポリシー・利用規約作成
  - GitHub Actions CI/CDセットアップガイド

### Phase 3: 本番対応 ✅ (完了: 2026-01)

**目標**: プロダクションレディ状態

#### 完了済み ✅

- ✅ Firestore Repository実装（Hybrid対応）
- ✅ 本番Firebase設定
- ✅ セキュリティルール設定
- ✅ パフォーマンス最適化（差分同期実装）
- ✅ エラー監視システム（Firebase Crashlytics + Sentry）
- ✅ ログ収集システム（プライバシー保護対応）
- ✅ ドキュメント完成（specifications整備）
- ✅ CI/CD構築（GitHub Actions）
- ✅ 複数デバイステスト（Pixel 9, SH 54D, Windows）
- ✅ フィードバック催促機能実装（Google Forms連携）

### Phase 4: セキュリティ対応＆拡張機能 ✅ (完了: 2026-02-17)

**目標**: セキュリティ強化とホワイトボード機能実装

#### 完了済み ✅

- ✅ **Git履歴クリーンアップ**（BFG Repo-Cleaner使用）
  - firebase_options_goshopping.dart 完全削除
  - firestore-send-email.env 完全削除
  - GoogleService-Info.plist 完全削除
  - 全ブランチ（main/future/oneness）に強制プッシュ完了
- ✅ **Gmail appパスワードローテーション**
  - 旧パスワード無効化
  - 新パスワード発行・設定完了
- ✅ **Firebase API Key制限設定**
  - Android/iOS アプリ制限適用
  - Google Cloud Console設定完了
- ✅ **Sentry セキュリティ設定**
  - Spike Protection有効化
  - Data Scrubbing設定完了
- ✅ **ホワイトボード機能実装**
  - signature パッケージ使用
  - ペン/消しゴム/色選択
  - undo/redo機能
  - スクロールモード対応
  - 編集ロック機能（協調編集）
  - Firestore リアルタイム同期
  - 通知システム統合（whiteboardUpdated）
- ✅ **3番目メンバー招待バグ修正**
  - 既存メンバーへの通知送信実装
  - groupMemberAdded ハンドラー追加
- ✅ **多言語対応システム実装**
  - l10n ディレクトリ構築
  - 日本語モジュール完成（160項目）
  - グローバルショートカット実装
- ✅ **デバイスIDプレフィックス機能実装**（2026-02-13）
  - device_info_plusパッケージ統合
  - プラットフォーム別ID自動生成（Android/iOS/Windows/Linux/macOS）
  - グループID衝突防止（デバイスID\_タイムスタンプ形式）
  - リストID トレーサビリティ向上（デバイスID_UUID形式）
  - SharedPreferences永続化・メモリキャッシュ
- ✅ **Copilot開発ガイドライン作成**（2026-02-17）
  - 機密情報取り扱い規則明文化
  - commit/push前チェックリスト
  - .gitignore必須パターン定義
  - セキュリティベストプラクティス

#### 残作業 📋

- ⏳ Google Playクローズドベータテスト実施
- ⏳ ユーザーフィードバック収集・反映
- ⏳ E2Eテスト実装

## 技術的課題と解決策

### 1. Riverpod Generator 不安定性（解決済み）✅

**問題**: バージョン3.0.0-dev.11で生成エラー
**解決策**:

- ✅ 従来のProvider構文で実装完了
- Generator無効化で安定動作
- 将来的に安定版移行を検討

### 2. Firestoreインデックス管理（完全対応）✅

**問題**: 複合クエリにインデックスが必要
**解決策**:

- ✅ `firestore.indexes.json` でインデックス定義
- ✅ Firebase CLI でデプロイ自動化
- ✅ プロジェクト: gotoshop-572b7
- ✅ 通知用3フィールドインデックス構築完了（userId + read + timestamp）

### 3. データレイヤー設計（Firestore-first実装完了）✅

**問題**: Hive⇔Firestore切り替え
**解決策**:

- ✅ **Firestore-first Hybrid Pattern実装**（2025-12-17/18）
- ✅ Repository パターンで抽象化完了（3実装：Hybrid/Firestore/Hive）
- ✅ Flavor による環境切り替え実装済み
- ✅ 認証必須アプリ化（常にオンライン前提）
- ✅ Hiveクリーンアップ機能（他ユーザーのキャッシュ削除）

### 4. 状態管理複雑性（簡素化完了）✅

**問題**: 複数のプロバイダー間の依存関係
**解決策**:

- ✅ プロバイダー階層の明確化
- ✅ Family Providerによるグループ別状態管理
- ✅ AsyncNotifierProvider パターンの統一
- ✅ StreamBuilderとRiverpodの統合パターン確立

### 5. ネットワーク効率（90%削減達成）✅

**問題**: 全リスト送信による帯域幅浪費
**解決策** (2025-12-18):

- ✅ **差分同期実装**（Map<String, SharedItem>型）
- ✅ 単一アイテム送信（addSingleItem/updateSingleItem/removeSingleItem）
- ✅ Before: ~5KB/操作 → After: ~500B/操作
- ✅ **90%ネットワーク削減達成** 🎉

### 6. CI/CDパイプライン構築（完了）✅

**問題**: 手動ビルドの手間とミス
**解決策** (2026-01-06):

- ✅ GitHub Actions導入
- ✅ ubuntu-latest環境でのAndroid APKビルド
- ✅ bash Here-Document構文採用
- ✅ mainブランチpush時の自動ビルド
- ✅ Kotlin 2.1.0更新（非推奨警告対応）## アーキテクチャ決定記録

### ADR-001: Riverpod 採用理由

- **決定**: Riverpod 3.0 を状態管理ライブラリとして採用
- **理由**:
  - Provider の進化版
  - Compile-time safety
  - Code generation対応
  - Null safety完全対応
- **代替案**: Bloc, Provider, GetX
- **結果**: コード生成エラーにより一部従来手法に回帰

### ADR-002: Repository Pattern 採用

- **決定**: データアクセス層にRepository Pattern導入
- **理由**:
  - データソース（Hive/Firestore）の切り替え容易性
  - テスタビリティ向上
  - 関心事の分離
- **代替案**: 直接データアクセス
- **結果**: 開発・本番環境の切り替えが容易

### ADR-003: Freezed + Hive 組み合わせ

- **決定**: Freezedでイミュターブルクラス、Hiveでローカル永続化
- **理由**:
  - 型安全性
  - コード生成による生産性
  - ローカルファーストアーキテクチャ
- **代替案**: JSON + SharedPreferences, Sqflite
- **結果**: 開発体験良好、型安全性確保

### ADR-004: QRコード招待システム採用（2025-11-07）

- **決定**: QRコード + 手動入力の2方式による招待システム
- **理由**:
  - ユーザビリティ（QRスキャンは直感的）
  - オフライン対応（手動入力で代替可能）
  - セキュリティ（UUID v4 + 期限付きトークン）
- **実装**:
  - パッケージ: qr_flutter 4.1.0, mobile_scanner 5.2.3, uuid 4.5.1
  - 有効期限: 24時間
  - 最大使用回数: 5人/招待
- **代替案**: メール招待、SMS、ディープリンク
- **結果**: 実装完了、動作テスト待ち

### ADR-005: Firebase CLI によるインフラ管理

- **決定**: Firebase CLI を使用したインフラストラクチャコード管理
- **理由**:
  - バージョン管理可能（firestore.indexes.json等）
  - デプロイ自動化
  - チーム開発対応
- **ツール**: Node.js + firebase-tools
- **結果**: インデックス定義の Git 管理とデプロイ自動化達成

### ADR-006: Firestore-first Hybrid Architecture (2025-12-17/18)

- **決定**: 全データ層でFirestore優先読み込み + Hiveキャッシュパターン採用
- **理由**:
  - 認証必須アプリ → ユーザーは常にオンライン
  - Firestoreが真の情報源（Source of Truth）
  - Hiveはキャッシュ層として最適
  - デバイス間同期の一貫性確保
- **実装範囲**: SharedGroup/SharedList/SharedItem全層
- **パターン**: Firestore取得 → Hiveキャッシュ → エラー時Hiveフォールバック
- **結果**: データ整合性向上、同期バグの構造的解消

### ADR-007: Map-based Differential Sync (2025-12-18)

- **決定**: SharedItemをMap<String, SharedItem>型に変更し、差分同期実装
- **理由**:
  - リスト全体送信（~5KB）の非効率性
  - モバイルネットワーク帯域幅の節約
  - リアルタイム同期のパフォーマンス向上
- **実装**: addSingleItem/updateSingleItem/removeSingleItem
- **結果**: 90%ネットワーク削減達成（~5KB → ~500B）
- **副次効果**: コンフリクト解決が容易、論理削除の実装

### ADR-008: GitHub Actions CI/CD (2026-01-06)

- **決定**: GitHub Actionsによる自動Android APKビルド導入
- **理由**:
  - 手動ビルドの手間削減
  - ビルドエラーの早期発見
  - リリースプロセスの標準化
- **選択肢**: ubuntu-latest（PowerShell構文の問題で変更）
- **結果**: mainブランチpush時の自動ビルド確立

## 品質目標

### パフォーマンス

- アプリ起動時間: 3秒以内
- リスト表示: 1秒以内（100アイテム）
- データ同期: 5秒以内

### 可用性

- オフライン機能: 基本操作100%対応
- エラー回復: 自動リトライ実装
- データ整合性: conflict resolution実装

### セキュリティ

- 認証: Firebase Auth使用
- データ暗号化: Firestore標準暗号化
- プライバシー: ローカルデータ暗号化

## リリース計画

### v0.9.0 - 招待機能ベータ版 ✅

**リリース**: 2025年12月完了
**機能**:

- ✅ ユーザー認証（必須サインイン）
- ✅ グループ作成・管理
- ✅ メンバー管理
- ✅ 買い物リスト永続化
- ✅ QR/手動招待システム（v3.1軽量版）
- ✅ Firestoreインデックス構築完了
- ✅ 通知システム実装

### v1.0.0 - フル機能版 ✅

**リリース**: 2025年12月完了
**機能**:

- ✅ ユーザー認証（Firebase Auth）
- ✅ グループ作成・管理
- ✅ メンバー管理・招待（QRコードv3.1）
- ✅ 買い物リスト（Map型差分同期）
- ✅ Firestore-first同期
- ✅ リアルタイム更新（StreamBuilder）
- ✅ エラー監視（Firebase Crashlytics）
- ✅ ログ収集（プライバシー保護対応）
- ✅ CI/CD（GitHub Actions）

### v1.1.0+2 - セキュリティ対応版（現在）✅

**リリース**: 2026年2月17日完了
**状況**: 本番運用中
**機能**:

- ✅ v1.0.0の全機能
- ✅ プライバシーポリシー・利用規約
- ✅ 自動APKビルド（GitHub Actions）
- ✅ セキュリティ対応完了（Git履歴クリーンアップ、API Key制限、パスワードローテーション）
- ✅ ホワイトボード機能（signature使用、リアルタイム同期、編集ロック）
- ✅ デバイスIDプレフィックス（ID衝突防止）
- ✅ 多言語対応システム（l10nディレクトリ）
- ✅ フィードバック催促機能（Google Forms連携）
- 🔄 クローズドベータテスト（5-10名）- 準備中
- 🔄 ユーザーフィードバック収集 - 継続中

### v1.2.0 - 機能拡張版

**リリース予定**: 2026年Q2
**機能**:

- メンバー伝言メッセージ機能拡張
- 定期購入機能UI実装
- パフォーマンス最適化
- UI/UX改善
- プッシュ通知（FCM統合検討）

### v2.0.0 - 高機能版

**リリース予定**: 2026年Q3-Q4
**機能**:

- 高度なフィルタリング
- 統計機能
- データエクスポート機能
- 多言語対応（英語版）
- プッシュ通知（FCM統合）
- テーマカスタマイズ

## 開発リソース

### 必要スキル

- Flutter/Dart（必須）
- Firebase（必須）
- 状態管理（Riverpod）
- データベース設計
- UI/UX デザイン

### 開発環境

- VS Code + Flutter拡張
- Android Studio（テスト用）
- Firebase Console
- Git/GitHub

### テスト環境

- Android Emulator
- Android実機（SH 54D, Android 15） ✅
- iOS Simulator（将来）
- 実機テスト（複数デバイス対応）

### 開発ツール追加（2025-11-07）

- Node.js (Chocolatey経由)
- Firebase CLI (npm)
- Git/GitHub
- ワイヤレスADB接続

## 現在の優先タスク（2026-01-07更新）

### Phase 3: 本番対応 🔄

#### 完了済み ✅

1. **Firestore-first Architecture実装** (2025-12-17/18)
   - 全3層でFirestore優先読み込み実装
   - HybridRepositoryパターン確立
   - 90%ネットワーク削減達成

2. **リアルタイム同期実装** (2025-11-22)
   - Firestore `snapshots()` 統合
   - StreamBuilder + Riverpod統合パターン確立
   - デバイス間同期確認済み（< 1秒）

3. **通知システム完全実装** (2025-12-24/25)
   - Firestoreベースのアプリ間通知
   - グループ削除通知対応
   - 招待受諾バグ完全修正
   - 通知履歴画面実装

4. **ドキュメント整備** (2026-01-06)
   - 77ファイル整理（daily_reports/knowledge_base/specifications）
   - プライバシーポリシー・利用規約作成
   - CI/CDセットアップガイド

5. **CI/CD構築** (2026-01-06)
   - GitHub Actions導入（ubuntu-latest）
   - mainブランチpush時の自動APKビルド
   - bash Here-Document構文採用

#### 進行中 🔄

1. **Google Playクローズドベータテスト準備** (P0)
   - [ ] Play Consoleアプリ登録
   - [ ] スクリーンショット撮影（5-8枚）
   - [ ] アプリ説明文作成
   - [ ] ベータテスター募集（5-10名）

2. **本番デバイステスト** (P1)
   - [ ] 複数Android端末での動作確認
   - [ ] Firestore同期パフォーマンス計測
   - [ ] バッテリー消費テスト

#### 次回タスク 📋

1. **クローズドベータテスト開始** (P0 - 2026年1月中旬)
   - テスター招待
   - フィードバック収集フォーム作成
   - 週次レポート作成体制

2. **ユーザーフィードバック反映** (P1 - 2026年2月)
   - UI/UX改善項目の洗い出し
   - バグ修正優先度付け
   - 機能追加要望の整理

3. **パフォーマンスチューニング** (P2)
   - 実データでのパフォーマンス計測
   - ボトルネック特定と改善
   - メモリ使用量最適化

### Phase 4: 拡張機能開発（2026年Q2予定）

- メンバー伝言メッセージ機能（設計書作成済み）
- ホワイトボード機能（スケッチ共有）
- 定期購入機能UI実装
- 自動テスト実装（E2Eテスト）

---

_最終更新: 2026年1月7日_
_この開発計画は進捗に応じて随時更新されます。_
