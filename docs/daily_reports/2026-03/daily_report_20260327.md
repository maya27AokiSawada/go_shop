# 開発日報 - 2026年03月27日

## 📅 本日の目標

- [x] Pixel 9（まや）で個人ボードが開かない問題を調査・修正する
- [x] 読み込み中にスピナーを表示する
- [x] 終了時自動保存を全プラットフォームに拡張する
- [x] 自動保存実装により不要になったコードを削除する
- [x] 問題別にコミットする
- [ ] テスト 2.4 の再テスト（明日に持ち越し）

---

## ✅ 完了した作業

### 1. 個人ボードが開かない問題の調査 ✅

**Purpose**: Pixel 9（まや）で個人ホワイトボードが全く開けない原因を特定する

**Background**: まやに割り当てられた Pixel 9 で「まや0324午後グループ」の個人ボードをタップしても開かなかった。Firestore 上のドキュメントは正常に1件だけ存在することはユーザーが確認済み。

**Root Cause**:

`adb logcat` で調査したところ、14:01:11〜14:01:14 の間に `_openPersonalWhiteboard` が **4回並列で呼ばれ**、全て 10 秒タイムアウトで失敗していた。

```
❌ 個人用ホワイトボード取得タイムアウト  # × 4件
```

多重タップ防止フラグがなく、並列 Firestore リクエストがそれぞれタイムアウトしてしまう構造だった。また、フォールバック用ローカルキャッシュも活用されていなかった。

**Status**: ✅ 完了（修正済み）

---

### 2. 多重タップ防止 + タイムアウト延長 + ローディングスピナー ✅

**Purpose**: タップ連打による並列リクエストを防止し、読み込み待ち中に視覚フィードバックを提供する

**Solution**:

```dart
// ❌ Before: ConsumerWidget、多重タップ防止なし、10秒 timeout、trailing 固定アイコン
const _personalWhiteboardFetchTimeout = Duration(seconds: 10);

onTap: () => _openPersonalWhiteboard(...),

trailing: const Icon(Icons.arrow_forward_ios, size: 16),
```

```dart
// ✅ After: ConsumerStatefulWidget、_isOpening フラグ、20秒 timeout、スピナー切り替え
const _personalWhiteboardFetchTimeout = Duration(seconds: 20);

bool _isOpening = false;

onTap: _isOpening ? null : () => _openPersonalWhiteboard(...),

trailing: _isOpening
    ? const SizedBox(width: 20, height: 20,
        child: CircularProgressIndicator(strokeWidth: 2))
    : const Icon(Icons.arrow_forward_ios, size: 16),

Future<void> _openPersonalWhiteboard(...) async {
  if (_isOpening) return;
  setState(() => _isOpening = true);
  try {
    // ... Firestore からボード取得 ...
  } finally {
    if (mounted) setState(() => _isOpening = false);
  }
}
```

**Modified Files**:

- `lib/widgets/member_tile_with_whiteboard.dart`

**Commit**: `9e07e37`
**Status**: ✅ 完了

---

### 3. 終了時自動保存（全プラットフォーム対応） ✅

**Purpose**: ホワイトボード編集画面を閉じる際に、キャンバス上のすべての描画を自動保存してから終了する

**Background**: 以前は Windows 限定で自動保存していた。Android でも「描いて保存ボタンを押さずに戻る」ケースで描画が失われる問題があった。

**Solution**:

```dart
// ❌ Before: Windows のみ
if (Platform.isWindows && canEdit) {
  debugPrint('🪟 [WINDOWS] 戻る前に自動保存を実行');
  await _saveWhiteboard();
}

// _saveWhiteboard は無条件でスナックバーを表示
void _saveWhiteboard() async {
  // ...
  if (mounted) SnackBarHelper.showSuccess(context, '保存しました');
}
```

```dart
// ✅ After: 全プラットフォーム + silent パラメータ
if (canEdit) {
  debugPrint('💾 [AUTO_SAVE] 終了時自動保存を実行');
  await _saveWhiteboard(silent: true);  // スナックバー非表示
}

// silent: true のとき「保存しました」を出さない
Future<void> _saveWhiteboard({bool silent = false}) async {
  // ...
  if (mounted && !silent) SnackBarHelper.showSuccess(context, '保存しました');
}
```

**Modified Files**:

- `lib/pages/whiteboard_editor_page.dart`
- `lib/services/personal_whiteboard_cache_service.dart`（`clearWhiteboard` メソッド追加）

**Commit**: `b06f370`
**Status**: ✅ 完了

---

### 4. 自動保存実装により不要になったコードの削除 ✅

**Purpose**: 終了時自動保存が実装されたため、`member_tile_with_whiteboard.dart` に残っていた「未保存 strokeId をキャッシュから復元する」処理を削除してコードを簡素化する

**Background**: もともと、ネット障害時に保存できなかった strokeId を SharedPreferences にキャッシュし、次回ボード再入時に復元する仕組みがあった。終了時自動保存により「閉じる前に必ず保存を試みる」設計に変わったため、この復元処理は不要になった。

**削除した処理**:

- `loadPendingStrokeIds()` の呼び出しと `cachedPendingStrokeIds` 変数
- `canReuseCachedStrokes` ブロック（キャッシュ再利用判断）
- stale キャッシュ削除の `else if` ブロック
- `!isCurrentUser` パスでのキャッシュストローク復元処理

**Modified Files**:

- `lib/widgets/member_tile_with_whiteboard.dart`

**Commit**: `9e07e37`（Commit 2 と同一ファイルのため同一コミットに含む）
**Status**: ✅ 完了

---

### 5. WhiteboardRepository エラーハンドリング改善 ✅

**Purpose**: ストローク取得エラーを握りつぶして空配列を返す実装を `rethrow` に変更し、上位で適切にハンドルできるようにする

```dart
// ❌ Before: エラーを握りつぶして空配列を返す（エラーが上流に届かない）
} catch (e, stack) {
  AppLogger.error('❌ [GET_STROKES] サブコレクション取得エラー: $e\n$stack');
  return <DrawingStroke>[];
}

// ✅ After: rethrow で上流に再スロー
} catch (e, stack) {
  AppLogger.error('❌ [GET_STROKES] サブコレクション取得エラー: $e\n$stack');
  rethrow;
}
```

**Modified Files**:

- `lib/datastore/whiteboard_repository.dart`（`dart:io` の不要 import も同時削除）

**Commit**: `ad812fe`
**Status**: ✅ 完了

---

## 🐛 発見された問題

### ネット切断時も「保存できました」が表示される ⚠️ 調査中

- **症状**: WiFi をオフにした状態で保存ボタンを押しても「保存しました」スナックバーが表示される
- **原因**: Firestore オフライン永続化により、ローカルへの書き込み（`unawaited`）は即時完了として処理されるため。`NetworkMonitorService` がオフライン検知前に fire-and-forget が走った可能性も。
- **対処**: テスト 2.4 で詳細を確認中（明日再テスト）
- **状態**: 仕様範囲内の動作の可能性あり。調査継続

### ネット回復後に空キャンバスになる ⚠️ 調査中

- **症状**: ネット切断→回復のタイミングで、ホワイトボードが空になる。閉じて再度開くと正しく表示される
- **原因**: `watchStrokesSubcollection` がオフライン→オンライン切り替え時に空スナップショットを流す可能性がある
- **対処**: テスト 2.4 再テストで確認予定
- **状態**: 調査中

---

## 📊 バグ対応進捗

### 完了 ✅

1. ✅ strokes サブコレクション化 + fire-and-forget 保存（完了: 2026-03-26）
2. ✅ watchStrokesSubcollection の hasPendingWrites フィルター・orderBy 廃止（完了: 2026-03-26）
3. ✅ 全消去の他端末反映修正（完了: 2026-03-26）
4. ✅ 個人ボードの多重タップ防止・タイムアウト延長・スピナー表示（完了: 2026-03-27）
5. ✅ 終了時自動保存（全プラットフォーム, silent モード）（完了: 2026-03-27）
6. ✅ 不要な pendingStrokes 復元処理の削除（完了: 2026-03-27）
7. ✅ WhiteboardRepository エラーを rethrow に変更（完了: 2026-03-27）

### 調査中 🔄

1. 🔄 ネット切断時の保存ダイアログ表示（テスト 2.4 で確認中・Priority: Medium）
2. 🔄 ネット回復後の空キャンバス問題（テスト 2.4 で確認中・Priority: Medium）

### 翌日継続 ⏳

- ⏳ テスト 2.4（ネット障害後の再入保存）再テスト
- ⏳ テスト 2.5〜2.6 以降（AppBar タイトル変更、初回読み込みスピナー）

---

## 💡 技術的学習事項

### Firestore オフライン永続化と fire-and-forget 保存の組み合わせ

**問題パターン**:

```dart
// unawaited で fire-and-forget → ネット切断中でもローカル書き込みは即時完了
unawaited(
  repository.addStrokesToSubcollection(...).catchError((e) {
    if (mounted) SnackBarHelper.showError(context, '保存に失敗しました');
  }),
);
// 「保存しました」を表示
SnackBarHelper.showSuccess(context, '保存しました');
```

**観察**:

- Firestore のオフライン永続化が有効な場合、`unawaited` の書き込みは **ネット切断中でもローカルに即時書き込まれる**
- `catchError` の `showError` は呼ばれず、スナックバーは「保存しました」になる
- サーバー同期はネット回復後にバックグラウンドで行われる（アプリが起動していなくても）

**教訓**: fire-and-forget 保存は「ネット切断中でも成功に見える」仕様であることを仕様として明記し、テスト期待値に含めること。

---

### ConsumerWidget → ConsumerStatefulWidget 変換パターン

**問題パターン**:

```dart
// ❌ ConsumerWidget は State を持てない → _isOpening 等のフラグを追加できない
class MemberTileWithWhiteboard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) { ... }
}
```

**正しいパターン**:

```dart
// ✅ ConsumerStatefulWidget + State でフラグ管理
class MemberTileWithWhiteboard extends ConsumerStatefulWidget {
  @override
  ConsumerState<MemberTileWithWhiteboard> createState() =>
      _MemberTileWithWhiteboardState();
}

class _MemberTileWithWhiteboardState
    extends ConsumerState<MemberTileWithWhiteboard> {
  bool _isOpening = false;
  // ...
}
```

**教訓**: ウィジェットにローカル状態（ローディングフラグ等）が必要になったら `ConsumerStatefulWidget` に変換する。

---

## 🗓 翌日（2026-03-28）の予定

1. テスト 2.4（ネット障害後の再入保存）再テスト ← **最優先**
2. テスト 2.5 AppBar タイトル変更の確認
3. テスト 2.6 初回読み込みスピナーの確認
4. テスト 3.x〜4.x（回帰テスト）の実施

---

## 📝 ドキュメント更新

| ドキュメント                    | 更新内容                                                                                                                                                                         |
| ------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `instructions/30_whiteboard.md` | セクション 3-4 を更新：終了時自動保存により pendingStrokes 復元処理が不要になったことを反映。セクション 5 の自動保存をプラットフォーム差異から削除（全プラットフォーム共通化）。 |
