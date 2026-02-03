# GoShopping - AI Coding Agent Instructions

## Recent Implementations (2026-02-03)

### 1. フィードバック催促機能の動作確認と原因調査 ✅

**Purpose**: 「フィードバック催促機能が動作しない」報告を受け、原因を特定

**Investigation Process**:

#### 1. コードレビュー結果

**✅ すべて正常に実装されていることを確認**:

- `home_page.dart`: `initState`で`_incrementAppLaunchCount`が正しく呼び出し
- `AppLaunchService.dart`: SharedPreferencesで起動回数を正確にカウント
- `FeedbackPromptService.dart`: 催促表示条件ロジックが正確に実装
  - 条件1: Firestore `testingStatus/active`の`isTestingActive`が`true`
  - 条件2: 起動回数が5回、または20回ごと（25回、45回...）

#### 2. デバッグログ強化

**追加したログ** (`lib/services/feedback_prompt_service.dart`):

```dart
static Future<bool> isTestingActive() async {
  try {
    AppLogger.info('🧪 [FEEDBACK] isTestingActive() 呼び出し');
    final doc = await _firestore.doc(_testStatusPath).get();

    if (!doc.exists) {
      AppLogger.warning('⚠️ [FEEDBACK] testingStatus/active ドキュメントが見つかりません');
      return false;
    }

    final data = doc.data();
    AppLogger.info('🧪 [FEEDBACK] Firestoreから取得したデータ: $data'); // 🔥 追加

    final isActive = data?['isTestingActive'] as bool? ?? false;
    AppLogger.info('🧪 [FEEDBACK] isTestingActive フラグの値: $isActive'); // 🔥 追加

    return isActive;
  } catch (e) {
    AppLogger.error('❌ [FEEDBACK] テストステータス確認エラー: $e');
    return false;
  }
}
```

**Key Patterns**:

1. **前提条件の完全確認**: 機能不全を疑う前に、動作条件をすべて確認
2. **詳細デバッグログ**: リモート環境での問題特定を加速
3. **段階的ログ出力**: Firestoreデータ取得→解析→判定のすべてをログに記録

**Modified Files**:

- `lib/services/feedback_prompt_service.dart` - デバッグログ追加

---

### 2. ホワイトボードUndo/Redo機能実装 ✅

**Purpose**: 手書きホワイトボードに履歴スタックベースのundo/redo機能を追加

**Architecture**:

#### 履歴スタック実装

```dart
// lib/pages/whiteboard_editor_page.dart
class _WhiteboardEditorPageState extends ConsumerStatefulWidget {
  final List<List<DrawingStroke>> _history = [];
  int _historyIndex = -1;

  void _saveToHistory() {
    // Redo用の未来の履歴削除
    if (_historyIndex < _history.length - 1) {
      _history.removeRange(_historyIndex + 1, _history.length);
    }

    // 現在の状態を保存
    _history.add(List<DrawingStroke>.from(_workingStrokes));
    _historyIndex = _history.length - 1;

    // 履歴サイズ制限（最大50ステップ）
    if (_history.length > 50) {
      _history.removeAt(0);
      _historyIndex--;
    }
  }

  void _undo() {
    if (!_canUndo()) return;
    _historyIndex--;
    _workingStrokes.clear();
    _workingStrokes.addAll(_history[_historyIndex]);
    setState(() {});
  }

  void _redo() {
    if (!_canRedo()) return;
    _historyIndex++;
    _workingStrokes.clear();
    _workingStrokes.addAll(_history[_historyIndex]);
    setState(() {});
  }

  bool _canUndo() => _historyIndex > 0;
  bool _canRedo() => _historyIndex < _history.length - 1;
}
```

#### Critical Pattern: 履歴保存のタイミング

**⚠️ CRITICAL**: 以下の**すべての箇所**で`_saveToHistory()`を呼び出す必要がある

```dart
// 1. ホワイトボード保存完了後
Future<void> _saveWhiteboard() async {
  try {
    // Firestore保存処理...
    _workingStrokes.clear();
    _workingStrokes.addAll(newStrokes);
    _saveToHistory(); // ← 必須！
  } catch (e) {
    // エラーハンドリング
  }
}

// 2. Firestoreリアルタイム更新時
void _startWhiteboardListener() {
  _whiteboardSubscription = repository
      .watchWhiteboard(widget.groupId, widget.whiteboardId)
      .listen((latest) {
    if (latest != null) {
      _currentWhiteboard = latest;
      _workingStrokes..clear()..addAll(latest.strokes);
      _saveToHistory(); // ← 必須！
    }
  });
}

// 3. 全クリア時
void _clearWhiteboard() {
  _workingStrokes.clear();
  _history.clear();
  _historyIndex = -1;
  setState(() {});
}
```

**Anti-Pattern**: 履歴保存忘れ

```dart
// ❌ Wrong: 状態変更後に履歴保存しない
_workingStrokes.clear();
_workingStrokes.addAll(newStrokes);
setState(() {}); // Undo/Redoが壊れる

// ✅ Correct: 状態変更とセットで履歴保存
_workingStrokes.clear();
_workingStrokes.addAll(newStrokes);
_saveToHistory(); // 必須
setState(() {});
```

#### UI改善パターン

**ペン太さボタン**: 5段階 → 3段階に簡素化

```dart
// Before: 5レベル（1.0, 2.0, 4.0, 6.0, 8.0）
_buildStrokeWidthButton(1.0, 1),
_buildStrokeWidthButton(2.0, 2),
_buildStrokeWidthButton(4.0, 3),
_buildStrokeWidthButton(6.0, 4),
_buildStrokeWidthButton(8.0, 5),

// After: 3レベル（2.0, 4.0, 6.0）with ラベル
_buildStrokeWidthButton(2.0, 1, label: '細'),
_buildStrokeWidthButton(4.0, 2, label: '中'),
_buildStrokeWidthButton(6.0, 3, label: '太'),
```

**Undo/Redoボタン**: 有効/無効切り替え

```dart
IconButton(
  icon: Icon(Icons.undo),
  onPressed: _canUndo() ? _undo : null, // ← null時は無効化
  tooltip: 'Undo',
),
IconButton(
  icon: Icon(Icons.redo),
  onPressed: _canRedo() ? _redo : null, // ← null時は無効化
  tooltip: 'Redo',
),
```

**Modified Files**:

- `lib/pages/whiteboard_editor_page.dart` - undo/redo実装、履歴保存バグ修正

---

### 3. Timestampクラッシュ修正（Firestoreデータnullセーフティ）✅

**Problem**: Windows版でホワイトボード描画中にクラッシュ

**Error Message**:

```
type 'Null' is not a subtype of type 'Timestamp' in type cast
#0 new Whiteboard.fromFirestore (whiteboard.dart:106)
```

**Root Cause**: Firestoreから取得したホワイトボードデータに`createdAt`/`updatedAt`がnullの場合があった

**Critical Pattern**: Firestore Timestampのnullセーフ処理

```dart
// ❌ Wrong: nullの場合クラッシュ
createdAt: (data['createdAt'] as Timestamp).toDate(),
updatedAt: (data['updatedAt'] as Timestamp).toDate(),

// ✅ Correct: nullable型 + null coalescing
createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
```

**General Pattern**: Firestore型キャスト

```dart
// String型
final name = data['name'] as String? ?? '';

// int型
final count = data['count'] as int? ?? 0;

// bool型
final isActive = data['isActive'] as bool? ?? false;

// List型
final items = (data['items'] as List<dynamic>?)?.cast<String>() ?? [];

// Map型
final metadata = data['metadata'] as Map<String, dynamic>? ?? {};

// Timestamp型（最も重要）
final timestamp = (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
```

**Modified Files**:

- `lib/models/whiteboard.dart` - Timestamp nullチェック追加（`as Timestamp?`パターン）

---

### 4. Sentry統合実装（Windows/Linux/macOS対応クラッシュレポート）✅

**Purpose**: Firebase Crashlytics非対応のデスクトッププラットフォームにクラッシュレポート機能を追加

**Architecture**: Platform-Specific Crash Reporting

```dart
// lib/main.dart
import 'dart:io' show Platform;
import 'package:sentry_flutter/sentry_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Platform判定による初期化分岐
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    // デスクトップ: Sentry統合
    await SentryFlutter.init(
      (options) {
        options.dsn = 'https://9aa7459e94ab157f830e81c9f1a585b3@o4510820521738240.ingest.us.sentry.io/4510820522786816';
        options.debug = kDebugMode;
        options.environment = kDebugMode ? 'development' : 'production';

        // パフォーマンストレース（50%サンプリング）
        options.tracesSampleRate = kDebugMode ? 1.0 : 0.5;
        options.enableAutoPerformanceTracing = true;

        // スクリーンショット自動添付
        options.attachScreenshot = true;
        options.screenshotQuality = SentryScreenshotQuality.medium;

        // プライバシー保護: ユーザーID自動マスキング
        options.beforeSend = (event, hint) {
          if (event.user?.id != null) {
            event = event.copyWith(
              user: event.user?.copyWith(
                id: AppLogger.maskUserId(event.user?.id), // abc*** 形式
              ),
            );
          }
          return event;
        };
      },
      appRunner: () => _initializeApp(),
    );
  } else {
    // モバイル: Firebase Crashlytics（既存コード維持）
    await _initializeApp();
  }
}

Future<void> _initializeApp() async {
  // 既存の初期化コード...

  // Platform別クラッシュハンドラー設定
  if (Platform.isAndroid || Platform.isIOS) {
    FlutterError.onError = (errorDetails) {
      FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  }
  // Windows/Linux/macOS: Sentryがmain()で初期化済み

  runApp(const ProviderScope(child: MyApp()));
}
```

#### エラー送信パターン（コンテキスト情報付き）

```dart
// lib/pages/whiteboard_editor_page.dart
try {
  // ホワイトボード保存処理
} catch (e, stackTrace) {
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    // Desktop: Sentryにエラー送信
    await Sentry.captureException(
      e,
      stackTrace: stackTrace,
      hint: Hint.withMap({
        'whiteboard_id': _currentWhiteboard.whiteboardId,
        'group_id': widget.groupId,
        'stroke_count': _workingStrokes.length,
        'is_group_whiteboard': _currentWhiteboard.isGroupWhiteboard,
        'platform': Platform.operatingSystem,
      }),
    );
  } else {
    // Mobile: Firebase Crashlyticsにエラー送信
    FirebaseCrashlytics.instance.recordError(e, stackTrace);
  }

  AppLogger.error('❌ [WHITEBOARD] 保存エラー: $e');
  rethrow;
}
```

#### プライバシー保護パターン

**ユーザーID自動マスキング**:

```dart
// lib/main.dart (beforeSendフック)
options.beforeSend = (event, hint) {
  if (event.user?.id != null) {
    event = event.copyWith(
      user: event.user?.copyWith(
        id: AppLogger.maskUserId(event.user?.id), // abc123def456 → abc***
      ),
    );
  }
  return event;
};
```

**AppLogger.maskUserId()実装** (`lib/utils/app_logger.dart`):

```dart
static String maskUserId(String? userId) {
  if (userId == null || userId.isEmpty) return '***';
  if (userId.length <= 3) return '***';
  return '${userId.substring(0, 3)}***';
}
```

#### Sentry DSN設定

**pubspec.yaml**:

```yaml
dependencies:
  sentry_flutter: ^8.9.0 # Windows/Linux/macOS対応
```

**DSN取得手順**:

1. [sentry.io](https://sentry.io/)でアカウント作成
2. プロジェクト作成（Flutter選択）
3. DSN（Data Source Name）をコピー
4. `lib/main.dart`の`options.dsn`に設定

**動作確認**:

```dart
// テスト用クラッシュ
ElevatedButton(
  onPressed: () {
    throw Exception('Sentry動作確認テスト');
  },
  child: Text('テストクラッシュ'),
);
```

#### Critical Patterns

1. **Platform判定は初期化時に行う**（main()関数で分岐）
2. **Firebase不要**（Sentryは独立したサービス）
3. **プライバシー優先**（beforeSendフックで自動マスキング）
4. **コンテキスト情報を豊富に**（Hint.withMapでメタデータ追加）

**Modified Files**:

- `pubspec.yaml` - `sentry_flutter: ^8.9.0`追加
- `lib/main.dart` - Sentry初期化、Platform判定実装
- `lib/pages/whiteboard_editor_page.dart` - エラー送信実装
- `docs/sentry_setup.md` - セットアップガイド作成

---

**Key Learnings**:

1. **Firestore nullセーフティ**: すべてのデータ取得で`as Type?`パターンを使用
2. **Undo/Redo実装**: 状態変更の**全箇所**で履歴保存必須
3. **Platform判定**: `dart:io Platform`で自動サービス切り替え
4. **Sentry活用**: デスクトップ向けクラッシュレポートの決定版

**Status**: ✅ 調査完了 | 機能正常動作確認済み

---

## Recent Implementations (2026-01-29)

### 1. フィードバック催促機能の実装 ✅

**Purpose**: クローズドテスト版でユーザーフィードバックを簡単に収集

**Architecture**:

#### 3つのサービス層

1. **AppLaunchService** (`lib/services/app_launch_service.dart`)
   - SharedPreferences でアプリ起動回数を記録
   - `incrementLaunchCount()`, `getLaunchCount()`, `resetLaunchCount()`
   - 起動回数は累積（リセット時のみ初期化）

2. **FeedbackStatusService** (`lib/services/feedback_status_service.dart`)
   - SharedPreferences でユーザーのフィードバック送信済み状態を管理
   - `markFeedbackSubmitted()`: フォーム開封時に true 設定
   - `isFeedbackSubmitted()`: 催促表示判定時に参照
   - `resetFeedbackStatus()`: デバッグ用リセット

3. **FeedbackPromptService** (`lib/services/feedback_prompt_service.dart`)
   - Firestore `/testingStatus/active` から `isTestingActive` フラグを読み込み
   - 表示条件をまとめて管理
   - **表示ロジック**:
     ```
     shouldShow = (isTestingActive && launchCount >= 5 && !isFeedbackSubmitted)
              OR (launchCount >= 20)
     ```

#### UI 統合

**HomePage** (`lib/pages/home_page.dart`)

```dart
@override
void initState() {
  super.initState();
  _incrementAppLaunchCount(); // 毎起動時に カウント
}
```

**NewsWidget** (`lib/widgets/news_widget.dart`)

```dart
FutureBuilder<bool>(
  future: FeedbackPromptService.shouldShowFeedbackPrompt(),
  builder: (context, snapshot) {
    if (snapshot.data == true) {
      return _buildFeedbackPromptCard(); // 紫色グラデーション催促カード
    }
    // その他の news/ads 表示
  },
)
```

**SettingsPage** (`lib/pages/settings_page.dart`)

```dart
// フィードバック送信セクション（全ユーザー・全環境で表示）
Card(
  child: ElevatedButton.icon(
    onPressed: _openFeedbackForm, // Google Forms URL を開く
    label: Text('アンケートに答える'),
  ),
)

// 開発環境のみ：デバッグパネル
if (F.appFlavor == Flavor.dev) {
  // 起動回数表示・リセット
  // フィードバック送信状態表示・リセット
  // テスト実施フラグ表示・トグル
}
```

#### Firestore セキュリティルール

**firestore.rules** に追加:

```javascript
match /testingStatus/{document=**} {
  allow read: if request.auth != null;
  allow write: if request.auth != null;
}
```

#### デバッグ・テスト方法

**1. Firestore ルールデプロイ**

```bash
firebase deploy --only firestore:rules
```

**2. テスト用フラグ有効化（Firebase Console で手動作成）**

```
Collection: testingStatus
Document: active
Field: isTestingActive (boolean) = true
```

**3. またはアプリ内デバッグ（dev flavor）**

- Settings → 開発者ツール → フィードバック催促（デバッグ）
- 「Test ON」ボタンで Firestore に `isTestingActive: true` を設定

**4. 起動回数カウント**

- 5 回起動でテスト中に催促表示
- 20 回起動で常に催促表示

**Known Issues**:

- ⏳ フィードバック催促表示が表示されていない（Firestore ルール未デプロイが原因の可能性）
- 次のステップ: ルールデプロイ → テストフラグ有効化 → アプリ再起動

---

## Recent Implementations (2026-01-30)

### 1. 買い物リスト削除時のUI同期バグ修正 ✅

**Purpose**: リスト削除時に、削除されたリストが他ユーザーのUIに残る問題を解決

**Background**: リスト削除通知受信後、リスト一覧は削除されるが、削除されたリスト内のアイテムが1つUIに残る現象が発生

**Root Cause**:

- `NotificationType.listDeleted`ハンドラが`allGroupsProvider`のみを無効化
- 削除されたリストが現在選択中の場合、`currentListProvider`がクリアされない
- 結果: リスト一覧は更新されるが、UI表示の`currentListProvider`は古い値のまま

#### 修正内容

**1. 削除されたリストIDの取得と比較**

```dart
// lib/services/notification_service.dart
case NotificationType.listDeleted:
  AppLogger.info('🗑️ [NOTIFICATION] リスト削除通知受信');

  // 削除されたリストのIDを取得
  final deletedListId = notification.metadata?['listId'] as String?;
  AppLogger.info('🗑️ [NOTIFICATION] 削除されたリストID: $deletedListId');

  // 削除されたリストが現在選択中の場合、currentListProviderをクリア
  if (deletedListId != null) {
    final currentList = _ref.read(currentListProvider);
    if (currentList?.listId == deletedListId) {
      AppLogger.info('🗑️ [NOTIFICATION] 選択中のリストが削除されたため、クリア実行');
      await _ref.read(currentListProvider.notifier).clearListForGroup(
            notification.groupId,
          );
    }
  }

  // グループのリスト一覧を更新
  _ref.invalidate(allGroupsProvider);
  break;
```

**2. インポート追加**

```dart
import '../providers/current_list_provider.dart'; // currentListProvider
```

#### 修正ポイント

- **リストID比較**: `currentList?.listId == deletedListId`で削除リストが選択中か確認
- **StateNotifier呼び出し**: `clearListForGroup()`メソッドで SharedPreferences＋state をクリア
- **順序**: リストクリア → プロバイダー無効化で確実なUI更新

#### 動作確認予定

- リスト削除時に他ユーザー端末のUIから完全に削除されるか確認
- リスト削除後の自動リスト選択機能が動作するか確認

---

## Recent Implementations (2026-01-29)

### 1. ホワイトボードFirestore保存の完全修正 ✅

**Purpose**: 描画データの永続化とマルチデバイス同期の確実な動作

**Background**: ゴミ箱アイコン（全消去）や描画モード切り替え時にFirestore保存がなく、ボードが消えたり復活したりする問題が発生

#### 修正内容

**1. ゴミ箱アイコン全消去のFirestore保存実装**

- 従来: ローカル`_workingStrokes.clear()`のみ → Firestoreに反映されない
- 修正: 確認ダイアログ → `clearWhiteboard()` → Firestore空配列保存
- `WhiteboardRepository.clearWhiteboard()`メソッド実装

**2. 描画モード切り替え時の自動保存**

- 従来: `_captureCurrentDrawing()`のみ（ローカルキャッシュ）
- 修正: `_saveWhiteboard()`呼び出しでFirestore保存
- 描画モード → スクロールモード時に確実にデータ永続化

**3. リポジトリメソッド追加**

```dart
// lib/datastore/whiteboard_repository.dart
Future<void> clearWhiteboard({
  required String groupId,
  required String whiteboardId,
}) async {
  await _collection(groupId).doc(whiteboardId).update({
    'strokes': [],  // ストローク全削除
    'updatedAt': FieldValue.serverTimestamp(),
  });
}
```

#### 動作確認結果

- ✅ Pixel9 ⇄ SH54D 双方向同期正常動作
- ✅ ゴミ箱全消去が両端末に即座に反映
- ✅ 描画モード切り替え後も描画データ保持
- ✅ 編集ロック機能正常動作（異なるユーザー間）

#### 今後の改善案（Future Enhancements）

1. **ストロークごとのリアルタイム同期**
   - 現状: 保存ボタン押下時またはモード切り替え時に一括同期
   - 改善案: 各ストローク描画完了時に即座にFirestore送信
   - メリット: よりリアルタイムな「お絵描きチャット」体験

2. **Undo/Redo機能実装**
   - ストロークごとの履歴管理
   - Ctrl+Z / Ctrl+Shift+Z ショートカット対応
   - UI上に戻る/進むボタン配置

**Modified Files**:

- `lib/pages/whiteboard_editor_page.dart` (+58 lines)
  - `_showDeleteConfirmationDialog()`: 全消去確認ダイアログ
  - `_clearWhiteboard()`: Firestore全消去処理
  - モード切り替え時の`_saveWhiteboard()`呼び出し
- `lib/datastore/whiteboard_repository.dart` (+18 lines)
  - `clearWhiteboard()`: ストローク全削除メソッド

**Commits**: `47f978a` - "fix: ホワイトボードFirestore保存の改善（ゴミ箱全消去・描画モード切り替え時保存）"

---

## Recent Implementations (2026-01-27)

### 1. ホワイトボード編集ロック機能 UI/UX改善 ✅

**Purpose**: 編集ロック機能のユーザビリティ向上とお絵描きチャット対応

#### 🔍 Critical Issue Resolution

**Problem**: 編集ロック機能が完全に動作しない報告

- ロックアイコンが表示されない
- 複数端末での同時描画が可能
- UI上でロック状態が見えない

**Root Cause Analysis**: テスト環境の問題

- Pixel・SH54D両端末が同一ユーザーでログイン
- システム仕様: 同一ユーザーの複数端末間では編集ロックは適用されない（セルフロック防止）

**Resolution**: 異なるユーザーでテスト → 編集ロック機能正常動作確認

#### 🎨 UI/UX Major Improvements

**1. Lock Error Dialog Simplification**

**Before**:

```dart
content: Column(children: [
  Text('${editorName} が編集中です'),
  Text('編集ロック: $remainingTime'),  // ❌ 技術詳細
  Text('他のユーザーが編集を完了するまでお待ちください。'),
]),
```

**After**:

```dart
content: Column(children: [
  Text('${editorName} が編集中です'),
  // ❌ 残り時間表示削除
  Text('編集が終わるまでお待ちください。'),  // ✅ シンプル
]),
```

**Rationale**: ロック有効時間は万が一の保険機能。正常時は描画終了で自動解除されるため、残り時間は不要

**2. Canvas Overlay Redesign**

**Before**: 画面全体を覆う大きなオーバーレイ

```dart
Positioned.fill(
  child: Container(
    color: Colors.black.withOpacity(0.1),  // 全画面背景
    child: Center(
      child: Container(
        padding: EdgeInsets.all(16),
        child: Column(children: [
          Icon(Icons.lock, size: 32),  // 大きなロックアイコン
          Text('編集中', fontSize: 16),
          Text('${userName} が編集中です'),
          Text(remainingTimeText),  // 残り時間表示
        ]),
      ),
    ),
  ),
)
```

**After**: 右上角の軽量バッジ

```dart
Positioned(
  top: 60, right: 16,  // ✅ 右上角のみ
  child: Container(
    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: Colors.orange.withOpacity(0.85),  // ✅ 透明度調整
      borderRadius: BorderRadius.circular(20),  // ✅ ピル型
    ),
    child: Row(children: [
      Icon(Icons.edit, size: 16),  // ✅ 小さな編集アイコン
      Text('${userName} 編集中', fontSize: 12),  // ✅ 簡潔
    ]),
  ),
)
```

#### 🎯 Critical Pattern for AI Agents

**Edit Lock Testing**: 同一ユーザー複数端末では機能しない

```dart
// ❌ Wrong: Same user testing
Device1: user123@example.com
Device2: user123@example.com
// Result: No lock applied (by design)

// ✅ Correct: Different users testing
Device1: user123@example.com
Device2: user456@example.com
// Result: Lock applied correctly
```

**UI Philosophy**:

- 技術詳細 < ユーザー体験
- 全画面オーバーレイ < 控えめな通知
- 単機能ツール < 多目的対応（お絵描きチャット）

**Modified Files**:

- `lib/pages/whiteboard_editor_page.dart`:
  - `_showEditingInProgressDialog()`: 残り時間削除、メッセージ簡潔化
  - Canvas overlay: `Positioned.fill` → `Positioned(top: 60, right: 16)`

## Recent Implementations (2026-01-26)

### 1. ホワイトボード競合解決システム完全実装 ✅

**Purpose**: マルチユーザー環境での安全な同時編集システム構築

**Critical Pattern**: Firestore-first + Transaction-based differential updates

#### 差分ストローク追加システム

**Problem**: 複数ユーザー同時編集でlast-writer-winsによるデータロス発生

**Solution**: Transaction-based differential stroke addition

**Key Implementation**:

```dart
// lib/datastore/whiteboard_repository.dart
Future<void> addStrokesToWhiteboard(String groupId, String whiteboardId, List<DrawingStroke> newStrokes) async {
  await _firestore.runTransaction((transaction) async {
    final whiteboardRef = _whiteboardsCollection(groupId).doc(whiteboardId);
    final snapshot = await transaction.get(whiteboardRef);

    final existingStrokes = List<DrawingStroke>.from(snapshot.data()!['strokes']);

    // 重複ストローク除外（IDベース）
    final filteredStrokes = newStrokes.where((stroke) =>
      !existingStrokes.any((existing) => existing.id == stroke.id)
    ).toList();

    // 差分のみ追加
    transaction.update(whiteboardRef, {
      'strokes': [...existingStrokes, ...filteredStrokes],
      'updatedAt': FieldValue.serverTimestamp(),
    });
  });
}
```

**Usage in Editor**:

```dart
// lib/pages/whiteboard_editor_page.dart
Future<void> _captureCurrentDrawing() async {
  final newStrokes = DrawingConverter.captureFromSignatureController(...);

  if (newStrokes.isNotEmpty) {
    // 差分追加（全ストローク置き換えではない）
    await repository.addStrokesToWhiteboard(
      widget.groupId,
      widget.whiteboard.whiteboardId,
      newStrokes,
    );
  }
}
```

#### 編集ロック機能の統合実装

**Architecture Change**: Separate collection → Document field integration

**Before**: `/SharedGroups/{groupId}/editLocks/{whiteboardId}` (separate collection)
**After**: `/SharedGroups/{groupId}/whiteboards/{whiteboardId}` 内の `editLock` field

**Benefits**:

- ✅ Firestore読み取り回数削減（1回でホワイトボード+ロック情報取得）
- ✅ セキュリティルール統一（既存whiteboardsルール適用）
- ✅ データ一貫性向上（同一ドキュメント内管理）

**New Document Structure**:

```json
{
  "groupId": "...",
  "strokes": [...],
  "canvasWidth": 1280,
  "canvasHeight": 720,
  "editLock": {
    "userId": "abc123",
    "userName": "すもも",
    "createdAt": "2026-01-26T10:30:00Z",
    "expiresAt": "2026-01-26T11:30:00Z"
  }
}
```

**Key Service Methods**:

```dart
// lib/services/whiteboard_edit_lock_service.dart

// ロック取得（1時間有効）
Future<bool> acquireEditLock({
  required String groupId,
  required String whiteboardId,
  required String userId,
  required String userName,
}) async {
  return await _firestore.runTransaction<bool>((transaction) async {
    final whiteboardDocRef = _whiteboardsCollection(groupId).doc(whiteboardId);

    transaction.update(whiteboardDocRef, {
      'editLock': {
        'userId': userId,
        'userName': userName,
        'createdAt': FieldValue.serverTimestamp(),
        'expiresAt': Timestamp.fromDate(DateTime.now().add(Duration(hours: 1))),
      },
    });
  });
}

// リアルタイム監視
Stream<EditLockInfo?> watchEditLock({
  required String groupId,
  required String whiteboardId,
}) {
  return _whiteboardsCollection(groupId).doc(whiteboardId).snapshots().map((snapshot) {
    final editLock = snapshot.data()?['editLock'] as Map<String, dynamic>?;
    return editLock != null ? EditLockInfo.fromMap(editLock) : null;
  });
}
```

#### 強制ロッククリア機能

**Purpose**: 古い編集ロック表示問題の緊急解決

**UI Integration**:

```dart
// ツールバーに統合
Widget _buildEditLockStatus() {
  return Row(
    children: [
      // ロック状態表示
      Container(...),
      // 強制クリアボタン
      if (_currentEditor != null)
        IconButton(
          icon: Icon(Icons.close, size: 12),
          onPressed: _forceReleaseEditLock,
        ),
    ],
  );
}

Future<void> _forceReleaseEditLock() async {
  // 2段階確認ダイアログ
  final confirmed = await showDialog<bool>(...);

  if (confirmed == true) {
    await lockService.forceReleaseEditLock(...);
    // 新旧両方のロック情報をクリア
  }
}
```

**Migration Support**:

```dart
// 古いeditLocksコレクションの完全削除
Future<int> cleanupLegacyEditLocks({required String groupId}) async {
  final legacyCollection = _firestore.collection('SharedGroups').doc(groupId).collection('editLocks');
  final allLocks = await legacyCollection.get();

  for (final doc in allLocks.docs) {
    await doc.reference.delete();
  }

  return allLocks.docs.length;
}
```

#### キャンバスサイズ完全統一

**Standard Size**: 1280×720（16:9比率）

**Components Updated**:

- `lib/models/whiteboard.dart`: Default canvas size
- `lib/pages/whiteboard_editor_page.dart`: Fixed canvas constants
- `lib/widgets/whiteboard_preview_widget.dart`: AspectRatio compliance
- `lib/utils/drawing_converter.dart`: Scale-aware coordinate transformation

**Critical Pattern**:

```dart
// 固定キャンバスサイズ（全コンポーネント統一）
static const double _fixedCanvasWidth = 1280.0;
static const double _fixedCanvasHeight = 720.0;

// Transform.scale + SizedBoxによる拡大縮小
SizedBox(
  width: _fixedCanvasWidth * _canvasScale,
  height: _fixedCanvasHeight * _canvasScale,
  child: Transform.scale(
    scale: _canvasScale,
    alignment: Alignment.topLeft,
    child: Container(
      width: _fixedCanvasWidth,
      height: _fixedCanvasHeight,
      // ...
    ),
  ),
)
```

#### Known Issues (継続対応必要)

**⚠️ 編集制限機能未完成**:

- ロック取得は成功するが実際の描画制限が動作しない
- SignatureController.onDrawStartが期待通りに機能していない
- 要調査: 描画イベント阻止の適切な実装方法

**Next Implementation Priority**:

1. onDrawStartコールバックの詳細調査
2. SignatureController無効化手法の実装
3. 制限中の視覚的フィードバック強化

---

## Recent Implementations (2026-01-24)

### 1. 共有グループ同期問題修正とホワイトボードUI改善 ✅

**Purpose**: Firestore全グループ同期とズーム機能の座標変換実装

#### 共有グループ同期問題の修正

**Problem**: しんやさんのPixel9に「すもも共有グループ」が表示されない

- Firebaseコンソールでは存在し、allowedUidにしんやのUIDが含まれている
- 原因: `createDefaultGroup()`がデフォルトグループのみFirestoreから同期

**Solution**: 全グループを同期

```dart
// ❌ Before: デフォルトグループのみ同期
final defaultGroupDoc = groupsSnapshot.docs.firstWhere(
  (doc) => doc.id == defaultGroupId,
  orElse: () => throw Exception('デフォルトグループなし'),
);
await hiveRepository.saveGroup(firestoreGroup);

// ✅ After: 全グループをループで同期
bool defaultGroupExists = false;
for (final doc in groupsSnapshot.docs) {
  final firestoreGroup = SharedGroup(...);
  await hiveRepository.saveGroup(firestoreGroup);

  if (doc.id == defaultGroupId) {
    defaultGroupExists = true;
  }
}
```

#### ホワイトボードグリッド表示修正

**Problem**: グリッドが画面サイズ分しか表示されない

**Solution**: キャンバス固定サイズ（1280x720）に変更

```dart
// ❌ Before: 画面サイズ依存
_buildGridOverlay(constraints.maxWidth, constraints.maxHeight)

// ✅ After: キャンバスサイズ + ズーム対応
CustomPaint(
  painter: GridPainter(
    gridSize: 50.0 * _canvasScale,
    color: Colors.grey.withOpacity(0.2),
  ),
)
```

#### ズーム機能の座標変換実装

**Problem**: ズーム0.5で描画領域が左上のみ

**Solution**: 座標変換処理実装

1. **Container直接サイズ指定**（Transform.scale削除）

```dart
Container(
  width: _fixedCanvasWidth * _canvasScale,
  height: _fixedCanvasHeight * _canvasScale,
  child: Stack(
    children: [
      // 背景レイヤー
      Transform.scale(
        scale: _canvasScale,
        alignment: Alignment.topLeft,
        child: CustomPaint(
          size: const Size(_fixedCanvasWidth, _fixedCanvasHeight),
          painter: DrawingStrokePainter(_workingStrokes),
        ),
      ),
      // 前景レイヤー
      SizedBox(
        width: _fixedCanvasWidth * _canvasScale,
        height: _fixedCanvasHeight * _canvasScale,
        child: Signature(controller: _controller!),
      ),
    ],
  ),
)
```

2. **ペン幅のスケーリング対応**

```dart
_controller = SignatureController(
  penStrokeWidth: _strokeWidth * _canvasScale, // スケーリング考慮
  penColor: _selectedColor,
);
```

3. **座標変換処理** (`drawing_converter.dart`)

```dart
static List<DrawingStroke> captureFromSignatureController({
  double scale = 1.0, // スケーリング係数
}) {
  // 座標をスケーリング前の座標系に変換
  currentStrokePoints.add(DrawingPoint(
    x: point.offset.dx / scale,
    y: point.offset.dy / scale,
  ));
}
```

#### ホワイトボードプレビューのアスペクト比対応

**Problem**: 固定height: 120でアスペクト比が無視される

**Solution**: AspectRatio + ConstrainedBox

```dart
ConstrainedBox(
  constraints: const BoxConstraints(maxHeight: 200),
  child: AspectRatio(
    aspectRatio: 16 / 9, // 1280:720
    child: Stack(...),
  ),
)
```

#### カスタム色設定の不具合修正

**Problem**: 設定変更時に色が初期値に戻る（ref.watch()使用）

**Solution**: initStateでキャッシュ

```dart
// ❌ Before: ref.watch()で都度取得
Color _getCustomColor5() {
  final settings = ref.watch(userSettingsProvider).value;
  return Color(settings.whiteboardColor5);
}

// ✅ After: initStateで1回のみ読み込み
late Color _customColor5;

@override
void initState() {
  super.initState();
  _customColor5 = _loadCustomColor5();
}

Color _loadCustomColor5() {
  final settings = ref.read(userSettingsProvider).value;
  return Color(settings?.whiteboardColor5 ?? 0xFF2196F3);
}

Color _getCustomColor5() => _customColor5;
```

**Modified Files**:

- `lib/providers/purchase_group_provider.dart` (全グループ同期)
- `lib/pages/whiteboard_editor_page.dart` (ズーム座標変換、カスタム色キャッシュ)
- `lib/utils/drawing_converter.dart` (スケーリング係数追加)
- `lib/widgets/whiteboard_preview_widget.dart` (アスペクト比16:9)
- `debug_shinya_groups.dart` (デバッグスクリプト追加)

**Commit**: `2bc2fe1` - "fix: 共有グループ同期とホワイトボードUI改善"

---

## Recent Implementations (2026-01-20)

### 1. UI/UX改善とサインイン必須仕様への最適化 ✅

**Purpose**: ユーザビリティ向上と認証必須アプリとしての最適化

**Key Changes**:

#### ホワイトボードUI改善

- **ツールバーコンパクト化**: 縦幅を約40%削減
  - パディング: `all(8)` → `symmetric(horizontal: 8, vertical: 4)`
  - 段間スペース: 8 → 4
  - 色ボタン: 36×36 → 32×32
  - IconButton: `padding: EdgeInsets.zero` + `size: 20`
- **色プリセット削減**: 8色 → 6色（teal、brownを削除）
- **横向き対応**: 十分なスペースがある場合は全アイコンを表示

#### 認証フロー最適化

- **未認証時の無駄な処理を削除**:
  - `createDefaultGroup()`に未認証チェック追加
  - `user == null`の場合は早期リターン
  - Firestore接続試行、Hive初期化待機を回避
- **アプリバー表示改善**:
  - 未認証時: 「未サインイン」と表示
  - 認証済み時: 「○○ さん」と表示

#### ホーム画面改善

- **アプリ名統一**: 「Go Shop」 → 「GoShopping」
- **パスワードリセット復活**: サインイン画面にリンク追加

**Modified Files**:

- `lib/pages/whiteboard_editor_page.dart` (ツールバーコンパクト化)
- `lib/pages/settings_page.dart` (プロバイダーimport追加)
- `lib/providers/purchase_group_provider.dart` (未認証チェック)
- `lib/pages/home_page.dart` (タイトル変更、パスワードリセット)
- `lib/widgets/common_app_bar.dart` (認証状態表示)

**Pattern**:

```dart
// ✅ 未認証チェックパターン
Future<void> createDefaultGroup(User? user) async {
  if (user == null) {
    Log.info('⚠️ 未認証状態のためデフォルトグループ作成をスキップ');
    return;
  }
  // 以降の処理...
}

// ✅ アプリバー表示パターン
Future<String> _buildTitle(user) async {
  if (showUserName) {
    if (user == null) {
      return '未サインイン';
    }
    final userName = await UserPreferencesService.getUserName();
    return userName != null ? '$userName さん' : 'ホーム';
  }
  // ...
}
```

---

## Recent Implementations (2026-01-16)

### 1. 手書きホワイトボード機能完全実装（future ブランチ） ✅

**Purpose**: 差別化機能として、グループ共有・個人用ホワイトボードを実装

**Implementation Architecture**:

- **Package**: `signature: ^5.5.0` - 描画 UI
- **Drawing Engine**: SignatureController + CustomPaint レイヤーシステム
- **Storage**: Hybrid approach（カスタムモデル + Firestore JSON）
- **Sync**: Firestore `whiteboards` collection
- **Hive TypeID**: 15-17（DrawingStroke, DrawingPoint, Whiteboard）

**Key Features**:

- ✅ スクロール可能キャンバス（1x ～ 4x）
- ✅ スクロールロック機能（描画モード ⇄ スクロールモード切替）
- ✅ 複数色対応（8 色カラーピッカー）
- ✅ 線幅調整（1.0 ～ 10.0）
- ✅ グループ共有ホワイトボード
- ✅ 個人用ホワイトボード
- ✅ 閲覧専用モード（他メンバーのホワイトボード）
- ✅ ホワイトボード更新通知システム

**Key Files**:

#### Data Models

- `lib/models/whiteboard.dart` - 3 つの Freezed モデル（DrawingStroke, DrawingPoint, Whiteboard）
- `lib/models/shared_group.dart` - グループ階層フィールド追加（parentGroupId, childGroupIds, memberPermissions）
- `lib/models/permission.dart` - 8 ビット権限システム

#### Repository & Provider

- `lib/datastore/whiteboard_repository.dart` - Firestore CRUD
- `lib/providers/whiteboard_provider.dart` - StreamProvider でリアルタイム更新

#### UI Components

- `lib/pages/whiteboard_editor_page.dart` - フルスクリーンエディター（スクロール可能、レイヤーシステム）
- `lib/widgets/whiteboard_preview_widget.dart` - プレビュー表示
- `lib/widgets/member_tile_with_whiteboard.dart` - メンバータイル＋個人ホワイトボードアクセス

**Commits**: `2bae86a`, `d6fe034`, `de72177`, `1825466`, `e26559f`

---

### 2. ホワイトボード更新通知システム実装 ✅

**Purpose**: ホワイトボード保存時にグループメンバーへ自動通知

**Implementation**:

- `lib/services/notification_service.dart`: `NotificationType.whiteboardUpdated` 追加
- `sendWhiteboardUpdateNotification()`: バッチ通知送信
- `_handleWhiteboardUpdated()`: 通知受信ハンドラー
- `lib/pages/whiteboard_editor_page.dart`: 保存時に通知送信

**Commit**: `de72177`

---

### 3. テストドキュメント作成 ✅

**Purpose**: クローズドテスト準備

**Created Files**:

- `docs/knowledge_base/test_procedures_v2.md` - 29 テストプロシージャ
- `docs/knowledge_base/test_checklist_template.md` - 41 項目チェックリスト

**Commit**: `1825466`

---

### 4. サインアップ時のユーザー名保存タイミング修正 ✅

**Problem**: ディスプレイ名入力後、メールアドレスの前半が使われる

**Root Cause**: Firebase Auth 登録時に`authStateChanges`発火 →`createDefaultGroup()`実行 →Preferences 未保存

**Solution**:

- Firebase Auth 登録**前**に Preferences へユーザー名を保存
- 保存順序: Preferences クリア → ユーザー名事前保存 → Hive クリア → Auth 登録

**Modified Files**:

- `lib/pages/home_page.dart` - 保存タイミング移動
- `lib/services/firestore_user_name_service.dart` - デバッグログ強化

**Commit**: `e26559f`

---

## Recent Implementations (2026-01-01)

### 1. Windows デスクトップサポート追加 ✅

**Purpose**: Windows 版アプリのビルドを可能にする

**Implementation**:

- `flutter config --enable-windows-desktop` で Windows デスクトップを有効化
- `flutter create --platforms=windows,android,web,ios,linux .` で全プラットフォームサポートを追加
- ビルドタスクを `.vscode/tasks.json` に追加
  - Build Windows
  - Build Android (APK/Debug APK)
  - Build Web
  - Build All Platforms

**Generated Folders**:

- `windows/` - CMake 設定、C++ソースコード
- `linux/` - Linux デスクトップサポート
- `web/` - Web アプリサポート

### 2. Firebase 設定ファイル生成 ✅

**Problem**: `lib/firebase_options.dart` が存在せずビルドエラー

**Solution**:

- FlutterFire CLI で自動生成: `flutterfire configure --project=gotoshop-572b7`
- 全プラットフォーム対応の Firebase App ID を登録

**Registered Platforms**:

- Windows: `1:895658199748:web:6833ceb2b8f29b0518d791`
- Android: `1:895658199748:android:9bc037ca25d380a018d791`
- iOS: `1:895658199748:ios:bfaf69f877e39c6418d791`
- Web: `1:895658199748:web:d24f3552522ea53318d791`

**Generated File**: `lib/firebase_options.dart`

### 3. CMake 設定の更新 ✅

**Problem**: Firebase C++ SDK の CMake 互換性エラー

**Solution**:

- `windows/CMakeLists.txt` の CMake 最小バージョンを `3.14` → `3.15` に更新
- `CMAKE_POLICY_VERSION_MINIMUM` を `3.15` に設定

### 4. リスト作成の二重送信防止 ✅

**Problem**: リスト作成ボタンの複数回タップで重複作成される可能性

**Implementation** (`lib/widgets/shopping_list_header_widget.dart`):

- `StatefulBuilder` でダイアログの状態管理
- `isSubmitting` フラグで処理中を制御
- 処理中はボタン無効化＋ローディングスピナー表示
- バリデーションエラー時は `isSubmitting` をリセット

**Pattern**:

```dart
bool isSubmitting = false;

StatefulBuilder(
  builder: (context, setDialogState) => AlertDialog(
    actions: [
      ElevatedButton(
        onPressed: isSubmitting ? null : () async {
          if (isSubmitting) return;
          setDialogState(() { isSubmitting = true; });

          try {
            // 処理
            await repository.createSharedList(...);
          } catch (e) {
            setDialogState(() { isSubmitting = false; });
          }
        },
        child: isSubmitting
            ? CircularProgressIndicator(strokeWidth: 2)
            : Text('作成'),
      ),
    ],
  ),
)
```

**Note**: グループ作成（`group_creation_with_copy_dialog.dart`）は既に `_isLoading` で二重送信防止済み

---

## 🚀 Quick Start for AI Agents (January 2026)

**Naming Conventions**:

- Use `sharedGroup`, `sharedList`, and `sharedItem` for models and related components.
- The refactoring from `shoppingList` and `shoppingItem` is mostly complete. Ensure new code follows the `shared` naming convention.

**Hive TypeIDs**:

- 0: SharedGroupRole
- 1: SharedGroupMember
- 2: SharedGroup
- 3: SharedItem
- 4: SharedList
- 6: UserSettings

**Architecture**:

- The app uses a hybrid repository pattern (Hive for local cache, Firestore for remote).
- Data is read from Hive first (cache-first), then synced from Firestore.
- UI-related logic should be in the `pages` and `widgets` directories.
- Business logic is managed by Riverpod `Notifier` classes in the `providers` directory.
- Data access is handled by repositories in the `datastore` directory.
