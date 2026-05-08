# 開発日報 - 2026年5月8日

## 📅 本日の目標

- [x] macOS Firebase Auth keychain-error の検証・クローズ
- [x] Android Firebase 初期化の固定ウェイト（3秒）を指数バックオフに変更
- [x] ネットワークバナー UX 改善（初回非表示・AppBar アイコン追加）
- [x] TestFlight 用 IPA ビルド（ビルド番号 +9）・配信完了
- [x] 不要依存パッケージ削除（`flutter_drawing_board`）
- [x] フレーバー管理の起動引数一本化・ハードコード除去

---

## ✅ 完了した作業

### 1. macOS Firebase Auth keychain-error — 解決確認 ✅

**Purpose**: 5/5 より継続調査していた macOS でのサインイン時 keychain エラーを正式にクローズする

**Background**:
5/7 日報では「翌日継続」と記載していたが、修正コード（`setSettings(userAccessGroup: "")`）は既に `main.dart` / `main_prod.dart` に実装済みであり、ビルドも成功していることを確認した。コードと日報の状態が乖離していたため、本日正式に解決済みとしてクローズする。

**Root Cause**:

macOS の Firebase Auth は起動時にシステム keychain へのアクセスを試みるが、`userAccessGroup` が設定されていない場合、App Sandbox 環境で `errSecInternalComponent` が発生することがある。

**Solution**:

Firebase 初期化直後、macOS 環境に限定して `setSettings(userAccessGroup: '')` を呼び出すことで keychain アクセスグループを明示的にリセットし、エラーを回避する。

```dart
// lib/main.dart / lib/main_prod.dart（Firebase.initializeApp() 直後）
if (defaultTargetPlatform == TargetPlatform.macOS) {
  try {
    await FirebaseAuth.instance.setSettings(userAccessGroup: '');
    AppLogger.info('✅ macOS: setSettings(userAccessGroup: "") 設定完了');
  } catch (e) {
    AppLogger.warning('⚠️ macOS: setSettings エラー（無視）: $e');
  }
}
```

**検証結果**: macOS 版でサインイン後のアイテム追加が待機なく即座に動作することを確認済み。

**Modified Files**:

- `lib/main.dart`（実装済み・変更なし）
- `lib/main_prod.dart`（実装済み・変更なし）

**Status**: ✅ 完了・検証済み（実装は 5/5 完了、本日正式クローズ）

---

### 2. TestFlight 用ビルド番号カウントアップ ✅

**Purpose**: TestFlight は同一ビルド番号の IPA を拒否するため、`+8` → `+9` にカウントアップ

**Solution**:

```yaml
# pubspec.yaml
version: 1.1.0+9 # +8 → +9
```

**Modified Files**:

- `pubspec.yaml`

**Commit**: `fc5cb43`
**Status**: ✅ 完了

---

### 3. 不要依存パッケージ削除（`flutter_drawing_board`）✅

**Purpose**: 実際には使用されていない `flutter_drawing_board` を依存から除去し、ビルドの健全性を高める

**Background**:
`flutter_drawing_board: ^1.0.1+1` は 2026-01-14 に追加されたが、描画不具合により `signature` パッケージへの移行が完了していた。`lib/` 内でのインポートが 0 件であることを確認した上で削除。コメントにも「問題あり - signature 移行予定」と残っていた。

**Root Cause**: 移行完了後に `pubspec.yaml` から削除が漏れていた。

**Solution**:

```yaml
# ❌ Before
# Drawing / Whiteboard
flutter_drawing_board: ^1.0.1+1 # 手書きホワイトボード機能（問題あり - signature移行予定）
signature: ^5.5.0

# ✅ After
# Drawing / Whiteboard
signature: ^5.5.0 # 手書き署名・描画機能（安定版）
```

**検証結果**: `flutter pub get` 成功、コンパイルエラーなし

**Modified Files**:

- `pubspec.yaml`

**Commit**: `3e2b8cc`
**Status**: ✅ 完了・検証済み

---

### 4. フレーバー管理の起動引数一本化・ハードコード除去 ✅

**Purpose**: Dart 側フレーバーを `--dart-define=FLAVOR=dev/prod` に統一し、`F.appFlavor` へのハードコード代入を全廃する

**Background**:
従来の構造では `main_dev.dart` に `F.appFlavor = Flavor.dev`、`main_prod.dart` / `main.dart` に `F.appFlavor = Flavor.prod` がハードコードされていた。しかし `launch.json` で `--flavor dev` を指定しても実際に呼ばれるエントリーポイントは常に `main.dart` であったため、**`--flavor dev` で起動しても Dart 側は常に `Flavor.prod`** という状態だった。

**Root Cause**:

```dart
// ❌ main.dart（--flavor dev でも prod になっていた）
F.appFlavor = Flavor.prod;  // ハードコード

// ❌ main_dev.dart（実際には呼ばれていなかった）
F.appFlavor = Flavor.dev;
```

**Solution**:

`flavors.dart` で `const String.fromEnvironment('FLAVOR', defaultValue: 'prod')` を使い、`F.appFlavor` を読み取り専用 getter に変更。

```dart
// ✅ lib/flavors.dart
const _flavorFromEnv = String.fromEnvironment('FLAVOR', defaultValue: 'prod');

class F {
  static Flavor get appFlavor {
    switch (_flavorFromEnv) {
      case 'dev':    return Flavor.dev;
      case 'staging': return Flavor.staging;
      default:       return Flavor.prod;
    }
  }
  // ...
}
```

`main.dart` / `main_dev.dart` / `main_prod.dart` からハードコード代入行を削除。

`launch.json` と `tasks.json` の全構成に `--dart-define=FLAVOR=dev/prod` を追加。

```json
// ✅ .vscode/launch.json（dev 設定例）
{
  "name": "go_shop (dev)",
  "args": ["--flavor", "dev", "--dart-define=FLAVOR=dev"]
}
```

**検証結果**: コンパイルエラーなし。`flutter analyze` 相当の IDE エラー 0 件。

**Modified Files**:

- `lib/flavors.dart` — `appFlavor` を getter 化、`_flavorFromEnv` 定数を追加
- `lib/main.dart` — ハードコード行削除
- `lib/main_dev.dart` — ハードコード行削除
- `lib/main_prod.dart` — ハードコード行削除
- `.vscode/launch.json` — 全 8 構成に `--dart-define=FLAVOR=...` 追加
- `.vscode/tasks.json` — dev/prod ランタスク・ビルドタスクに `--dart-define=FLAVOR=...` 追加

**Commit**: `bc67968`（Dart コード） / `6a0301f`（VS Code 設定）
**Status**: ✅ 完了・検証済み

---

### 5. Android Firebase 初期化の固定ウェイトを指数バックオフに変更 ✅

**Purpose**: 起動時に Android DNS 解決を待つための固定 3 秒ウェイト（`_androidFirebaseWarmupDelay`）を廃止し、指数バックオフによるリトライに置き換える

**Root Cause**:
Android 初回起動時に DNS 解決が間に合わず Firebase 初期化が失敗するケースへの保険として 3 秒固定ウェイトが入っていたが、ベストケースでも 3 秒ロスしていた。

**Solution**:

```dart
// lib/main.dart / main_dev.dart / main_prod.dart
Future<void> _initFirebaseWithBackoff() async {
  const maxRetries = 4;
  var delay = const Duration(milliseconds: 500);
  for (var attempt = 1; attempt <= maxRetries; attempt++) {
    try {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
      AppLogger.info('✅ Firebase.initializeApp() 完了（試行 $attempt 回目）');
      return;
    } on Exception catch (e) {
      if (e.toString().contains('duplicate-app')) { return; }
      if (attempt == maxRetries) rethrow;
      await Future.delayed(delay);
      delay = delay * 2; // 500ms → 1s → 2s → 4s
    }
  }
}
```

**効果**: ベストケース（即時成功）で起動が最大 3 秒短縮。ネットワーク不安定時もクラッシュせずリトライ。

**Modified Files**:

- `lib/main.dart`
- `lib/main_dev.dart`
- `lib/main_prod.dart`

**Commit**: `c6a7035`
**Status**: ✅ 完了・検証済み

---

### 6. ネットワークバナー UX 改善 ✅

**Purpose**: アプリ起動時にオレンジバナーが一瞬出る UX 問題を解消し、AppBar アイコンでオフライン状態を常時把握できるようにする

**Background**:
従来は `NetworkStatus.offline` 検出直後にバナーを表示していたため、起動時の一時的オフライン検出でも毎回バナーが出ていた。

**Solution**:

- `NetworkMonitorService`: `retryAttemptCount` ゲッターを追加
- `NetworkStatusBanner`: `checking` 中・初回 `offline`（`retryAttemptCount == 0`）はバナー非表示。リトライ 1 回以上失敗時のみ表示
- `CommonAppBar`: `networkStatusStreamProvider` を watch し、ネットワーク状態をアイコンで常時表示
  - `offline` → `wifi_off`（オレンジ）
  - `checking` → `wifi_tethering`（ブルー）
  - `online` → 通常の同期アイコン

**Modified Files**:

- `lib/services/network_monitor_service.dart`
- `lib/widgets/network_status_banner.dart`
- `lib/widgets/common_app_bar.dart`

**Commit**: `8f8d383`
**Status**: ✅ 完了・検証済み

---

### 7. iOS IPA ビルド・TestFlight 配信完了 ✅

**Purpose**: ビルド 9 を TestFlight に配信し、内部テスターが最新版を検証できる状態にする

**Background**:
前日まで `flutter build ipa` コマンドが Distribution 証明書不足で失敗していたため、`xcodebuild -archive` → `xcodebuild -exportArchive` の 2 ステップに切り替えた。

**Solution**:

1. `flutter build ios --release --flavor prod --dart-define=FLAVOR=prod --no-codesign` でビルド
2. `xcodebuild -workspace ios/Runner.xcworkspace -scheme prod -configuration Release-prod -archivePath build/ios/archive/Runner.xcarchive archive` でアーカイブ（518 MB）
3. `ExportOptions.plist`（method: app-store, signingStyle: automatic, teamID: 9A34XAPY8W）を作成し scp で Mac に転送
4. `xcodebuild -exportArchive` で IPA export → `go_shop.ipa`（49 MB）生成
5. Transporter / TestFlight でアップロード後、グループ `GoShoppingTesters01` に追加

**トラブル発生と解決**:

- ビルド 8 を先に期限切れにした状態でビルド 9 を追加したため、TestFlight アプリ側でアップデートが表示されなかった
- テスターをグループから一度削除して再招待したところ正常にアップデート可能になった
- **次回対策**: 新ビルドをグループに追加してから古いビルドを期限切れにする（順序を守る）

**Modified Files**: なし（ビルド作業のみ）

**Status**: ✅ 配信完了（ビルド 9「テスト中」確認済み）

---

## 🐛 発見された問題

### macOS Firebase Auth keychain-error（解決済み）✅

- **症状**: macOS でサインイン後、アイテム追加まで待機が発生
- **原因**: Firebase Auth が App Sandbox keychain アクセスに失敗（`errSecInternalComponent`）
- **対処**: `setSettings(userAccessGroup: '')` を Firebase 初期化直後に呼び出し
- **状態**: 修正完了 ✅（実装済み・動作確認済み）

---

## 📊 バグ対応進捗

### 完了 ✅

1. ✅ iOS アイコンのアルファチャンネルエラー（完了日: 2026-05-07）
2. ✅ 英語 UI 対応 — 設定・フィードバック・ホワイトボード（完了日: 2026-05-07）
3. ✅ SelectedGroupNotifier.build() Firestore I/O 除去（完了日: 2026-05-07）
4. ✅ macOS Firebase Auth keychain-error（完了日: 2026-05-08 正式クローズ、実装: 2026-05-05）
5. ✅ フレーバー管理ハードコードバグ（`--flavor dev` でも prod 扱いになっていた）（完了日: 2026-05-08）
6. ✅ Android 起動時 3 秒固定ウェイト（指数バックオフに変更）（完了日: 2026-05-08）
7. ✅ ネットワークバナー起動時誤表示（retryAttemptCount で制御）（完了日: 2026-05-08）

### 対応中 🔄

（なし）

---

## 💡 技術的学習事項

### Flutter フレーバー管理 — `--flavor` と Dart 側の乖離に注意

**問題パターン**:

```dart
// ❌ main.dart にハードコード → --flavor dev でも prod になる
F.appFlavor = Flavor.prod;
```

`--flavor` はネイティブビルド（Android productFlavor / iOS scheme）を切り替えるものであり、Dart 側の変数には自動伝播しない。

**正しいパターン**:

```dart
// ✅ コンパイル時定数で受け取る
const _flavorFromEnv = String.fromEnvironment('FLAVOR', defaultValue: 'prod');
```

起動コマンド・launch.json 両方に `--dart-define=FLAVOR=dev` を必ず付与すること。

**教訓**: `--flavor` と `--dart-define=FLAVOR` は別々に渡す必要がある。片方だけでは Dart/ネイティブ双方に伝わらない。

---

### `pubspec.yaml` の依存クリーンアップは定期的に実施する

移行完了後のパッケージが残り続けるとビルド時間増加・バージョン競合リスクになる。
`lib/` 全体を `grep` して import 0 件のパッケージは積極的に削除すること。

---

## 🗓 翌日（2026-05-09）の予定

1. UIテキストの完全 `l10n.dart` 対応
   - ハードコードされた日本語・英語文字列を `lib/l10n/` の ARB ファイル経由に統一
   - `AppLocalizations.current.xxx` を使っていない全ウィジェットを洗い出し移行
   - 対応完了後コミット・プッシュ

---

## 📝 ドキュメント更新

| ドキュメント                                          | 更新内容                                                                                    |
| ----------------------------------------------------- | ------------------------------------------------------------------------------------------- |
| `docs/daily_reports/2026-05/daily_report_20260508.md` | Firebase backoff・ネットワークバナー・IPA/TestFlight 配信を追記。翌日予定を l10n 対応に更新 |
