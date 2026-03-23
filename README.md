# GoShopping

家族・グループ向けの買い物リスト共有 Flutter アプリです。
Firebase Auth と Cloud Firestore を中心に、Hive をローカルキャッシュとして併用する構成で、複数デバイス間のリアルタイム共有を前提にしています。

## 現在の状態

- 現在のアプリバージョンは `1.1.0+4` です。
- 認証前提アプリです。主要機能はサインイン後に利用します。
- データの正本は Firestore です。Hive はキャッシュおよびローカル保持に使います。
- `Flavor.dev` と `Flavor.prod` はどちらも Firebase を使用します。
- Firebase プロジェクトは dev / prod で分かれています。
- デフォルトグループの特別扱いは廃止済みです。グループ 0 件時は空状態 UI を表示します。
- 現行コードのリスト系命名は `shopping_list` から `shared_list` に統一済みです。

## Firebase プロジェクト

### Production

- Project ID: `goshopping-48db9`
- Usage: `Flavor.prod`

### Development

- Project ID: `gotoshop-572b7`
- Usage: `Flavor.dev`

Firebase の切り替えは `lib/firebase_options.dart` と `lib/flavors.dart` の構成に従います。

## 主な特徴

- グループ共有の買い物リスト
- Firestore 優先のリアルタイム同期
- Hive キャッシュによるローカル保持
- QR 招待によるグループ参加
- ホワイトボード共有機能
- オフライン時も Firestore SDK の永続化機能を活かした動作
- Riverpod ベースの状態管理

## アーキテクチャ概要

### データ方針

- 認証済み時の正本は Firestore
- Hive は表示高速化と一時保持のためのキャッシュ
- SharedItem / SharedList は差分同期を重視
- 失敗時は Hive フォールバックを持つが、基本方針は Firestore-first

### レイヤー構成

- `lib/models/`: Freezed + Hive モデル
- `lib/datastore/`: Repository 層
- `lib/providers/`: Riverpod の状態管理
- `lib/services/`: 同期、通知、初期化などの業務ロジック
- `lib/widgets/`, `lib/pages/`: UI
  - `lib/widgets/settings/`: 設定画面のセクション別ウィジェット群（settings_page.dart から抽出済み）

### 主要な技術要素

- Flutter
- Riverpod（traditional syntax、generator 不使用）
- Firebase Auth
- Cloud Firestore
- Hive
- Freezed

## ディレクトリの見どころ

- `lib/datastore/hybrid_purchase_group_repository.dart`
  - グループの Firestore-first / Hive cache 制御
- `lib/datastore/hybrid_shared_list_repository.dart`
  - 共有リストと差分同期の中心
- `lib/providers/purchase_group_provider.dart`
  - グループ一覧・選択・同期の主要状態管理
- `lib/pages/home_page.dart`
  - 認証後導線、ホーム画面の主要挙動
- `lib/pages/whiteboard_editor_page.dart`
  - ホワイトボード編集 UI
- `lib/pages/settings_page.dart`
  - 設定画面の薄いオーケストレーター（169 行）
- `lib/widgets/settings/`
  - 設定画面の機能別ウィジェット分割（11 ファイル）
  - `auth_status_panel`, `app_mode_switcher_panel`, `privacy_settings_panel`,
    `whiteboard_settings_panel`, `developer_tools_section`,
    `data_maintenance_section`, `account_deletion_section` など

## セットアップ

機密ファイルの配置や Firebase 設定値の投入は [SETUP.md](SETUP.md) を参照してください。

必要になる代表的なファイル:

- `android/app/google-services.json`
- `ios/GoogleService-Info-dev.plist`
- `ios/GoogleService-Info-prod.plist`
- `lib/firebase_options.dart`
- 各種 `.env` / 機密設定ファイル

## 開発環境セットアップ

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

## 実行例

### Windows

```bash
flutter run -d windows
```

### Android

```bash
flutter run
```

### Android flavor 指定例

```bash
flutter run --flavor prod
flutter run --flavor dev
```

### iOS flavor

iOS は flavor 対応済みです。詳細は [docs/knowledge_base/ios_flavor_setup.md](docs/knowledge_base/ios_flavor_setup.md) を参照してください。

```bash
flutter run --flavor dev -d <ios-device-id>
flutter run --flavor prod -d <ios-device-id>
```

## ビルド例

```bash
flutter build windows
flutter build apk --debug --flavor prod
flutter build apk --release --flavor prod
flutter build web
```

## テストと確認

### Unit Test

```bash
flutter test
```

### Analyzer

```bash
flutter analyze
```

### 直近の実装で重視している確認項目

- Firestore 初期化タイミング競合
- サインイン後のグループ同期
- オフライン / 再接続時の UI 挙動
- NetworkMonitor の一時失敗でオフラインバナーを誤表示しないこと
- 再インストール直後の初回起動とバージョンキー初期化
- 削除済みグループが回復同期で復活しないこと
- QR 招待受諾フロー
- ホワイトボード同期
- 個人用ホワイトボードの `isPrivate` スイッチが切り替え後に正しい値を維持すること
- `watchWhiteboard()` の pending write フィルターが保存直後の自己反映を防いでいること
- 個人用ホワイトボードの編集可 / 編集不可が一覧と editor に即時反映されること
- 同一ユーザー別端末でもホワイトボードのペンモード占有が正しく判定されること（userId + deviceId 両方で判定）
- ペンモード OFF 後に Android / Windows が編集可能状態へ正しく復帰すること
- アイテム連続追加時の操作テンポ
- ペンモードを繰り返し ON/OFF しても詰まらないこと（`_isTogglingMode` フラグ・ウォッチドッグタイマー）
- 同一ユーザー別端末の stale ロックが強制引き継ぎされること
- acquireEditLock が 8 秒以内にタイムアウトしスピナーが解除されること
- タイムアウト / ネットワーク問題時でも楽観的 UI でペンモードに入れること

実機テストの詳細は `docs/daily_reports/` 配下を参照してください。

## 開発ルールの要点

- Firestore-first を維持する
- Riverpod Generator は使わない
- 既存メソッドのシグネチャ変更は影響確認なしで行わない
- 実機依存のバグは日報・仕様書へ記録を残す
- write 操作では Firestore SDK のオフライン永続化を尊重する

## ドキュメント案内

### まず読むと良いもの

- [SETUP.md](SETUP.md)
- [docs/README.md](docs/README.md)
- [docs/specifications/network_failure_handling_flow.md](docs/specifications/network_failure_handling_flow.md)
- [docs/specifications/data_classes_reference.md](docs/specifications/data_classes_reference.md)
- [docs/specifications/widget_classes_reference.md](docs/specifications/widget_classes_reference.md)
- [docs/specifications/page_widgets_reference.md](docs/specifications/page_widgets_reference.md)

### 実機テスト・変更履歴

README には長い変更履歴を持たせず、日々の修正や検証ログは `docs/daily_reports/` に集約しています。

例:

- [docs/daily_reports/2026-03/final_device_test_checklist_20260304.md](docs/daily_reports/2026-03/final_device_test_checklist_20260304.md)

## 既知の注意点

- Firebase Auth と Repository 初期化のタイミング競合に注意が必要です
- サインイン直後の Firestore 復元は、`SharedGroups` / `sharedLists` / `userSettings` の Hive Box が open 済みであることを前提にする必要があります
- `data_version` / `hive_schema_version` の未保存状態は旧版ではなく初回起動として扱う必要があります
- Firestore 書き込みに安易に `.timeout()` を付けると、SDK のオフラインキュー挙動を阻害します
- `watchWhiteboard()` / `watchEditLock()` は `.where((s) => !s.metadata.hasPendingWrites)` で pending write スナップショットをスキップしないと、保存直後に古いデータで UI が上書きされることがあります
- ホワイトボード編集ロックの deviceId ロードと `_watchEditLock()` 起動は直列にしないと (`deviceId == null` のまま lock 判定が走ると)、自端末の lock を他端末のものと誤認します
- 削除済みグループは回復同期時に通常更新より優先して扱い、復活させない前提で確認が必要です
- Riverpod の `AsyncNotifier.build()` 内では依存関係追跡を壊さないよう実装方針に注意が必要です
- 反復操作の成功スナックバーは長すぎると UX を悪化させるため、短時間表示を前提に設計した方が安全です
- ホワイトボードのストローク分割は独自の距離しきい値ではなく、`signature` パッケージの `PointType` 境界を使う方が端末差に強いです
- 個人用ホワイトボードの privacy 切り替えは `toggle` ではなく `Switch` の目標値をそのまま保存する方が race を避けやすいです
- ホワイトボード編集ロックは `userId` だけでなく `deviceId` も含めて扱わないと、同一ユーザー別端末を自分自身の編集中と誤認しやすいです
- ペンモード終了はリモート lock 解除完了を待ってから UI を戻すのではなく、ローカル UI を先に戻す方が端末差に強いです
- Firestore / gRPC の `Failed to resolve name` は単発なら一時的な名前解決失敗のことがあるため、即 offline 判定せず再試行を挟む方が実運用に合います
- 実機・ネットワーク環境依存の挙動差があるため、重要な変更は実機確認が前提です

## 最近の主な成果

- 再インストール直後の誤マイグレーション表示修正
- 回復同期における削除済みグループ優先の整備
- 実機向け重点チェックリストの整理
- Hybrid Repository の DI 対応とユニットテスト整備
- Firestore 再初期化まわりの起動競合修正
- ネットワーク障害時フローの整理
- ネットワーク監視バナー誤検知の緩和
- 個人用ホワイトボードの即時反映経路改善
- ホワイトボードのペンモード編集ロック安定化と deviceId ベース所有判定導入
- 実機テストで見つかった複数の UI / 同期バグ修正
- iOS flavor 対応の整備

詳細な経緯は `docs/daily_reports/` を参照してください。

## ライセンス

社内・個人開発用途の前提で管理されています。必要に応じて別途ライセンス方針を定義してください。
