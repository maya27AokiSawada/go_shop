# 開発日報 - 2026年04月24日

## 📅 本日の目標

- [x] AppUIMode（single / multi）実装
- [x] Hive UserSettings null安全対応（appUIMode field 9）
- [x] testingStatus=Active 時のインタースティシャル広告テスト確認用バイパス実装

---

## ✅ 完了した作業

### 1. AppUIMode（single / multi）実装 ✅

**Purpose**: シングルグループ向けのシンプルUI（single）と、従来の複数グループUI（multi）を切り替えられる AppUIMode 機能を追加する

**Background**:
家族単位のシンプル利用（グループ1つ、固定リスト）をターゲットとした UI モードを提供したい。単身・カップル向けに「複雑なグループ操作なしで買い物リストだけ使える」体験を提供する。

**実装内容**:

#### AppUIMode 定義（新規）

```dart
// lib/config/app_ui_mode_config.dart
enum AppUIMode { single, multi }

class AppUIModeSettings {
  static AppUIMode _currentMode = AppUIMode.single;
  static AppUIMode get currentMode => _currentMode;
  static void setMode(AppUIMode mode) { _currentMode = mode; }
}
```

#### Hive UserSettings に永続化（HiveField 9）

```dart
// lib/models/user_settings.dart
@HiveField(9)
final int appUIMode; // 0=single, 1=multi
```

#### Provider

```dart
// lib/providers/app_ui_mode_provider.dart
final appUIModeProvider = StateProvider<AppUIMode>((ref) {
  return AppUIModeSettings.currentMode;
});
```

#### 設定画面（プレミアムゲート付き）

- `lib/widgets/settings/app_ui_mode_switcher_panel.dart`（新規）
  - single → multi: `isPremiumActiveProvider` + `purchaseTypeProvider` によるゲート
  - multi → single: 確認ダイアログ
  - `_saveMode()`: Hive + SharedPrefs + Firestore + static + provider の5箇所に保存

#### シングルモード UI 制御

| ファイル                                     | 変更内容                                                                    |
| -------------------------------------------- | --------------------------------------------------------------------------- |
| `lib/pages/shared_group_page.dart`           | `isSingle` のとき FAB（グループ追加）を非表示                               |
| `lib/widgets/shared_list_header_widget.dart` | `isSingle` のとき DropdownButton → Text（固定表示）、add/deleteボタン非表示 |

#### サインアップ後のシングルモードウィザード

- `lib/widgets/single_group_creation_dialog.dart`（新規）
  - サインアップ成功後、AppUIMode = single の場合にグループ名入力ダイアログを表示
  - `allGroupsProvider.notifier.createNewGroup()` → デフォルトリスト「買い物リスト」作成 → カレントリスト設定

#### 起動時の初期化・同期

- `lib/widgets/app_initialize_widget.dart`: 起動時 Hive → AppUIModeSettings → appUIModeProvider 初期化
- `lib/services/user_initialization_service.dart`: `_syncUserProfile()` に appUIMode の Firestore ↔ SharedPrefs 双方向同期追加

**Modified Files**:

- `lib/config/app_ui_mode_config.dart`（新規）
- `lib/providers/app_ui_mode_provider.dart`（新規）
- `lib/widgets/settings/app_ui_mode_switcher_panel.dart`（新規）
- `lib/widgets/single_group_creation_dialog.dart`（新規）
- `lib/models/user_settings.dart`（`appUIMode` HiveField 9 追加）
- `lib/models/user_settings.freezed.dart`（再生成）
- `lib/models/user_settings.g.dart`（再生成）
- `lib/forms/sign_up_form.dart`（サインアップ後 SingleGroupCreationDialog 表示）
- `lib/pages/shared_group_page.dart`（FAB 制御）
- `lib/pages/settings_page.dart`（AppUIModeSwicherPanel 追加）
- `lib/screens/home_screen.dart`（appUIModeProvider watch 追加）
- `lib/services/user_initialization_service.dart`（appUIMode Firestore同期）
- `lib/services/user_preferences_service.dart`（getAppUIMode / saveAppUIMode 追加）
- `lib/widgets/app_initialize_widget.dart`（起動時初期化）
- `lib/widgets/shared_list_header_widget.dart`（DropdownButton → Text固定表示）
- `lib/widgets/settings/app_mode_switcher_panel.dart`（AppUIModeSwicherPanel参照を追加）

**Commit**: `529663f`
**Status**: ✅ 完了・build_runner 179 outputs 成功・Android APK ビルド確認済み

---

### 2. Hive UserSettings null安全対応（appUIMode field 9）✅

**Purpose**: 既存ユーザーが AppUIMode 追加前のデータを持つ場合に `Null is not a subtype of int` クラッシュが発生するため、null安全に読み取るよう修正する

**Root Cause**:

```dart
// ❌ 問題: build_runner 生成コード（既存ユーザーのデータに fields[9] が存在しない）
appUIMode: fields[9] as int,  // → null as int でクラッシュ
```

**Solution**:

```dart
// ✅ 修正: 両ファイルで null-aware cast に変更
// lib/models/user_settings.g.dart
appUIMode: fields[9] as int? ?? 0,

// lib/adapters/user_settings_adapter_override.dart
appUIMode: (fields[9] as int?) ?? 0, // 🔥 NEW: 存在しない場合はsingle(0)
```

**備考**:

- `UserSettingsAdapterOverride`（typeId=6）が main.dart で優先登録されるため、こちらが実際に使用される
- `user_settings.g.dart` も修正して build_runner 再実行後も安全にしておく

**Modified Files**:

- `lib/adapters/user_settings_adapter_override.dart`（fields 7,8,9 の null安全読み取り + write 全10フィールド対応）
- `lib/models/user_settings.g.dart`（`fields[9] as int? ?? 0` に修正）

**Commit**: `bd1d2ee`
**Status**: ✅ 完了

---

### 3. testingStatus=Active 時のインタースティシャル広告90日停止バイパス ✅

**Purpose**: Firestore の `testingStatus/active.isTestingActive` が `true` のとき、インタースティシャル広告の「インストールから90日間は表示しない」制限をスキップし、広告の表示確認ができるようにする

**Background**:
インタースティシャル広告の動作確認をしたいが、開発端末はインストールから90日未満のため通常は広告が表示されない。テスト環境（testingStatus=Active）に限定してこの制限をバイパスする。

**Solution**:

```dart
// ❌ Before: 無条件に90日チェック
final installTime = prefs.getInt(_installDateKey) ?? 0;
final daysSinceInstall = ...;
if (daysSinceInstall < _installGraceDays) {
  return false;
}

// ✅ After: testingStatus=Active なら90日チェックをスキップ
final isTestingActive = await FeedbackPromptService.isTestingActive();
if (!isTestingActive) {
  final installTime = prefs.getInt(_installDateKey) ?? 0;
  final daysSinceInstall = DateTime.now()
      .difference(DateTime.fromMillisecondsSinceEpoch(installTime))
      .inDays;
  if (daysSinceInstall < _installGraceDays) {
    Log.info('🚫 インタースティシャル広告スキップ（インストール${daysSinceInstall}日未満）');
    return false;
  }
} else {
  Log.info('🧪 testingStatus=Active: 90日間停止を無効化');
}
```

**テスト手順**:

1. Firestoreコンソール → `testingStatus/active` → `isTestingActive: true` に設定
2. アプリでサインイン → インタースティシャル広告が表示されることを確認
3. 確認後は `isTestingActive: false` に戻す

**Modified Files**:

- `lib/services/ad_service.dart`（`shouldShowSignInAd()` に testingActive チェック追加、`feedback_prompt_service.dart` import 追加）

**Commit**: `e9e4927`
**Status**: ✅ 完了

---

## 🐛 発見された問題

### Hive appUIMode フィールド null クラッシュ（修正済み）✅

- **症状**: 既存ユーザーが AppUIMode 追加後のアプリを初起動したとき `type 'Null' is not a subtype of type 'int'` でクラッシュ
- **原因**: `build_runner` 生成アダプタが `fields[9] as int` を実行するが、既存データに field 9 が存在しない
- **対処**: `user_settings.g.dart` と `user_settings_adapter_override.dart` 両方を `(fields[9] as int?) ?? 0` に修正
- **状態**: ✅ 修正完了

---

## 📊 バグ対応進捗

### 完了 ✅

1. ✅ Hive appUIMode null クラッシュ修正（2026-04-24）
2. ✅ AppUIMode single/multi UI 実装（2026-04-24）

### 翌日継続 ⏳

- ⏳ インタースティシャル広告の実機動作確認（testingStatus=Active で実際に広告が出るか確認）
- ⏳ AppUIMode single モードの実機UXテスト

---

## 💡 技術的学習事項

### Hive フィールド追加時の後方互換性

**問題パターン**:

```dart
// build_runner 生成コードは型キャストが strict
appUIMode: fields[9] as int,  // 既存データに field がない → null → クラッシュ
```

**正しいパターン**:

```dart
// UserSettingsAdapterOverride で null-aware に読み取る
appUIMode: (fields[9] as int?) ?? 0,
```

**教訓**: Hive に新フィールドを追加するたびに、`UserSettingsAdapterOverride` の `read()` と `write()` を更新する。`build_runner` の生成ファイルも同様に修正し、後方互換性を常に確保する。

### testingStatus パターン（広告・機能のテストバイパス）

**教訓**: `FeedbackPromptService.isTestingActive()` は Firestore `testingStatus/active.isTestingActive` を参照するテスト制御フラグ。このパターンを広告・フィードバック以外のテスト制御にも横展開できる。

---

## 🗓 翌日（2026年04月25日）の予定

1. インタースティシャル広告の実機動作確認
2. AppUIMode single モードの実機UXテスト（サインアップ後ダイアログ、リスト固定表示）
3. iOS xcarchive のコード署名対応（Apple Developer Program 有効後）

---

## 📝 ドキュメント更新

| ドキュメント                           | 更新内容                                                                                 |
| -------------------------------------- | ---------------------------------------------------------------------------------------- |
| `instructions/50_user_and_settings.md` | AppUIMode (single/multi) セクション追加、広告チェック原則に testingStatus バイパスを記載 |
