# GoShopping - 買い物リスト共有アプリ

## Recent Implementations (2026-01-31)

### Windows版ホワイトボード保存クラッシュ完全解決 ✅

**Problem**: Windows版でホワイトボード保存時に`abort()`によるC++ネイティブクラッシュが発生

**Root Cause**: Firestore Windows SDKの`runTransaction()`に重大なバグ（`abort()`呼び出し）

**Solution Implemented**:

#### Platform-Specific Save Strategy

```dart
// whiteboard_repository.dart
if (Platform.isWindows) {
  // Windows: 通常のupdate()（トランザクションなし）
  await _addStrokesWithoutTransaction(...);
} else {
  // Android/iOS: runTransaction()（同時編集対応）
  await _firestore.runTransaction((transaction) async { ... });
}
```

**Benefits**:

- ✅ Windows版でクラッシュしない（トランザクション回避）
- ✅ Android/iOS版は従来通り（トランザクションで同時編集対応）
- ✅ 重複チェックは全プラットフォームで維持

**Additional Fixes**:

- 古い`editLocks`コレクション削除処理を無効化（permission-denied回避）
- 論理削除アイテムクリーンアップを無効化（クラッシュ対策）
- 詳細デバッグログ追加（問題箇所の特定）

**Modified Files**:

- `lib/datastore/whiteboard_repository.dart` - Windows専用保存メソッド追加
- `lib/services/whiteboard_edit_lock_service.dart` - レガシークリーンアップ無効化
- `lib/widgets/app_initialize_widget.dart` - アイテムクリーンアップ無効化
- `lib/utils/drawing_converter.dart` - エラーハンドリング強化
- `lib/pages/whiteboard_editor_page.dart` - デバッグログ追加

**Commits**:

- TBD（本日退勤前にコミット予定）

---

## Recent Implementations (2026-01-30)

### 🔥 CRITICAL BUG修正: 3番目メンバー招待時の既存メンバー同期バグ ✅

**Problem**: グループに3人目のメンバーを招待した際、既存メンバーの端末で新メンバーが表示されない重大バグ

**Root Cause**:

1. `notification_service.dart`の`_handleNotification`メソッドで`groupMemberAdded`通知のcaseが欠落
2. `_addMemberToGroup`メソッドで既存メンバー全員への通知送信が未実装

**Solution Implemented**:

#### 1. `groupMemberAdded`通知ハンドラー追加

```dart
case NotificationType.invitationAccepted:
case NotificationType.groupUpdated:
case NotificationType.groupMemberAdded:  // 🔥 追加
  await userInitService.syncFromFirestoreToHive(currentUser);
  _ref.invalidate(allGroupsProvider);
  break;
```

#### 2. 既存メンバー全員への通知送信

```dart
// 新メンバー追加後、既存メンバー全員に通知
final existingMemberIds = currentGroup.allowedUid
    .where((uid) => uid != acceptorUid)
    .toList();

for (final memberId in existingMemberIds) {
  await sendNotification(
    targetUserId: memberId,
    type: NotificationType.groupMemberAdded,
    message: '$finalAcceptorName さんが「${currentGroup.groupName}」に参加しました',
  );
}
```

**Expected Flow (After Fix)**:

```
すもも（招待元）→ まや（3人目）を招待
  ↓
まや: QR受諾 → すももに通知送信
  ↓
すもも: メンバー追加処理 → しんや（既存メンバー）に通知送信 ← 🔥 追加
  ↓
しんや: 通知受信 → Firestore同期 → まやが表示される ← 🔥 修正完了
```

**Modified Files**:

- `lib/services/notification_service.dart` - 通知ハンドラー＋既存メンバー通知送信追加
- `docs/daily_reports/2026-01/20260130_bug_fix_third_member_sync.md` - 完全な修正レポート

**Test Status**: ⏳ 次回セッションで実機テスト予定

**Commits**:

- `14155c2` - "fix: 3番目メンバー招待時の既存メンバー同期バグ修正"
- (本コミット) - "fix: groupName変数未定義エラー修正 & 日報更新"

---

## Recent Implementations (2026-01-29)

### 1. フィードバック催促機能の実装 ✅

**Purpose**: クローズドテスト版アプリにユーザーフィードバック機能を追加

**Implementation**:

#### サービス層

- **AppLaunchService** - アプリ起動回数を SharedPreferences で記録
- **FeedbackStatusService** - フィードバック送信済み状態を SharedPreferences で管理
- **FeedbackPromptService** - Firestore の `isTestingActive` フラグと起動回数から催促表示判定

#### UI 統合

- **HomePage**: initState で起動回数をインクリメント
- **NewsWidget**: 条件満たした場合に紫色グラデーション催促カードを表示
- **SettingsPage**: フィードバック送信セクション（全ユーザー・全環境で表示）＋デバッグパネル

#### Google Forms 連携

- フォーム URL: `https://forms.gle/wTvWG2EZ4p1HQcST7`
- 催促表示条件: `(isTestingActive && launchCount >= 5 && !isFeedbackSubmitted) OR (launchCount >= 20)`

#### Firestore セキュリティルール

- `/testingStatus/{document=**}` コレクション追加
- 認証済みユーザーのみ読み取り・書き込み許可

**Next Steps**:

1. `firebase deploy --only firestore:rules` でルールをデプロイ
2. Firebase Console で `/testingStatus/active` ドキュメント作成: `isTestingActive: true`
3. アプリ再起動して動作確認

**Status**: ✅ 実装完了 | ⏳ デプロイ・動作確認保留中

---

## Recent Implementations (2026-01-27)

### 1. ホワイトボード編集ロック機能 UI/UX完全改善 ✅

**Purpose**: ユーザーフレンドリーな編集ロック体験とお絵描きチャット機能対応

#### 問題解決：テスト環境改善

**Problem**: 編集ロック機能が動作しない（ロックアイコン非表示、同時描画可能）

**Root Cause**:

- 同一ユーザー（fatima.sumomo）で Pixel・SH54D 両端末ログイン
- システム仕様：同一ユーザー複数端末間では編集ロック非適用
- テスト環境設定不適切

**Solution**: 別ユーザーでのマルチアカウント テスト環境構築 → ✅ 正常動作確認

#### UI/UX大幅改善

**1. ロックエラーダイアログ簡潔化**

```diff
- 「編集中です」 + 残り時間表示 + 有効期限表示（技術詳細）
+ 「編集中です」 + 「編集が終わるまでお待ちください」（ユーザーフレンドリー）
```

**Rationale**: ロック有効期限は万が一の保険機能。正常系は描画終了で自動解除

**2. キャンバスオーバーレイ控えめ化**

```diff
- 画面全体を覆う大きなオーバーレイ（視覚的負荷大）
+ 右上角の軽量なバッジ表示（視覚的負荷小）

- Icons.lock（ロックイメージ）
+ Icons.edit（編集イメージ、アクティブ感）

- 複数行テキスト（技術詳細）
+ 「○○○ 編集中」（シンプル）
```

**Design Details**:

- Background: `Colors.orange.withOpacity(0.85)` ピル型
- Border Radius: `BorderRadius.circular(20)` 角丸ピル
- Position: `top: 60, right: 16` 右上隅（キャンバス邪魔しない）
- Shadow: `blurRadius: 3` 軽い影で奥行き表現

**Benefits**:

- ✅ お絵描きチャット機能対応（描画エリア遮蔽なし）
- ✅ 視覚的負荷軽減（ユーザー集中度向上）
- ✅ 協調編集環境での使いやすさ向上
- ✅ モバイル画面対応（右上は邪魔しない位置）

#### Technical Implementation

**Modified File**: `lib/pages/whiteboard_editor_page.dart`

**1. モード切り替え時のロック制御**

```dart
// スクロールモード → 描画モード: ロック取得
if (!_isScrollLocked) {
  if (widget.whiteboard.isGroupWhiteboard) {
    final success = await _acquireEditLock();
    if (!success && mounted) {
      AppLogger.warning('❌ [MODE_TOGGLE] ロック取得失敗 - モード切り替えをキャンセル');
      if (_isEditingLocked && _currentEditor != null) {
        _showEditingInProgressDialog();
      }
      return; // モード切り替えをキャンセル
    }
  }
}

// 描画モード → スクロールモード: ロック解除
if (_isScrollLocked) {
  _captureCurrentDrawing(); // 現在の描画を保存
  await _releaseEditLock();
}
```

**2. ロック状態バッジ表示**

```dart
Positioned(
  top: 60,
  right: 16,
  child: Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: Colors.orange.withOpacity(0.85),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.edit, color: Colors.white, size: 16),
        Text('${editorName} 編集中', style: TextStyle(fontSize: 12)),
      ],
    ),
  ),
)
```

**Test Results**:

- ✅ 別ユーザーログインで編集ロック正常動作確認
- ✅ モード切り替え（パン⇄描画）でロック制御正常
- ✅ 控えめなUI表示でチャット機能対応確認
- ✅ キャンバス描画エリア遮蔽なし確認
- ✅ マルチユーザー同時編集環境で正常動作

## Recent Implementations (2026-01-26)

### 1. ホワイトボード競合解決システム実装 ✅

**Purpose**: マルチユーザー環境での安全な同時編集を実現

#### 差分ストローク追加機能

**Problem**: 複数ユーザー同時編集でlast-writer-winsによるデータロス

**Solution**: Firestore transactionベースの差分追加

- `WhiteboardRepository.addStrokesToWhiteboard()`: 新規ストロークのみ追加
- 重複検出・排除（ストロークIDベース）
- 編集時の自動差分保存

**Key Code**:

```dart
await _firestore.runTransaction((transaction) async {
  final existingStrokes = List<DrawingStroke>.from(doc.data()['strokes']);
  final filteredStrokes = newStrokes.where((stroke) =>
    !existingStrokes.any((existing) => existing.id == stroke.id)
  ).toList();

  transaction.update(whiteboardRef, {
    'strokes': [...existingStrokes, ...filteredStrokes],
  });
});
```

#### 編集ロック機能統合

**Architecture Change**: editLocksコレクション → whiteboardドキュメント内統合

- **Before**: `/SharedGroups/{groupId}/editLocks/{whiteboardId}`
- **After**: `/SharedGroups/{groupId}/whiteboards/{whiteboardId}` 内の `editLock` フィールド

**Benefits**:

- Firestore読み取り回数削減（1回でホワイトボード+ロック情報取得）
- セキュリティルール統一・データ一貫性向上
- 1時間自動期限切れ・リアルタイム監視

#### 強制ロッククリア機能

**Purpose**: 古い編集ロック表示問題の解決

- `forceReleaseEditLock()`: 緊急時の強制ロック削除
- 2段階確認ダイアログ・自動マイグレーション処理
- 古いeditLocksコレクション完全クリーンアップ

#### キャンバスサイズ統一

- **統一サイズ**: 1280×720（16:9比率）
- 全コンポーネント対応（エディター・プレビュー・モデル）
- Transform.scale による拡大縮小対応

**Status**: 基盤機能完成、編集制限機能は次回実装予定

**Modified Files**:

- `lib/services/whiteboard_edit_lock_service.dart` (編集ロック統合)
- `lib/datastore/whiteboard_repository.dart` (差分追加)
- `lib/pages/whiteboard_editor_page.dart` (UI統合・強制クリア)
- `lib/models/whiteboard.dart` (キャンバスサイズ統一)

---

## Recent Implementations (2026-01-24)

### 1. 共有グループ同期問題修正とホワイトボードUI改善 ✅

**Purpose**: Firestore全グループ同期とズーム機能の座標変換実装

#### 共有グループ同期問題の修正

**Problem**: しんやさんのPixel9に「すもも共有グループ」が表示されない

**Root Cause**: `createDefaultGroup()`がデフォルトグループのみFirestoreから同期

**Solution**: 全グループをループで同期

```dart
// 🔥 FIX: 全てのグループをHiveに同期
bool defaultGroupExists = false;
for (final doc in groupsSnapshot.docs) {
  final firestoreGroup = SharedGroup(...);
  await hiveRepository.saveGroup(firestoreGroup);

  if (doc.id == defaultGroupId) {
    defaultGroupExists = true;
  }
}
```

**Result**: allowedUidに含まれる全グループが初回サインイン時に同期される

#### ホワイトボード機能改善

**1. グリッド表示修正**

- 画面サイズ依存 → キャンバス固定サイズ（1280x720）
- ズーム倍率対応（`gridSize: 50.0 * _canvasScale`）

**2. ズーム機能の座標変換実装**

**Problem**: ズーム0.5で描画領域が左上のみ

**Solution**:

- Container直接サイズ指定（Transform.scale削除）
- ペン幅スケーリング対応（`_strokeWidth * _canvasScale`）
- 座標変換処理実装（`drawing_converter.dart`に`scale`パラメータ追加）

```dart
// 座標をスケーリング前の座標系に変換
currentStrokePoints.add(DrawingPoint(
  x: point.offset.dx / scale,
  y: point.offset.dy / scale,
));
```

**3. プレビューのアスペクト比対応**

- 固定height: 120 → AspectRatio(16/9)
- タブレット対応（maxHeight: 200px）

**4. カスタム色設定の不具合修正**

- ref.watch() → ref.read()（initStateでキャッシュ）
- 色比較ロジック修正（インスタンス比較 → 色値比較）

**Modified Files**:

- `lib/providers/purchase_group_provider.dart`
- `lib/pages/whiteboard_editor_page.dart`
- `lib/utils/drawing_converter.dart`
- `lib/widgets/whiteboard_preview_widget.dart`
- `debug_shinya_groups.dart` (new)

**Commit**: `2bc2fe1`

---

## Recent Implementations (2026-01-21)

### 1. ホワイトボードツールバーUI完全改善 ✅

**Purpose**: スマホ縦横両方で全ツールバーアイコンを表示可能にする

**Problem**:

- 縦画面・横画面で一部アイコンが画面外に隠れる
- ゴミ箱アイコン（下段右端）が見えない
- 設定ページの色プリセット（色5・色6）が反映されない

**Solution**:

#### 上段ツールバー（色選択）

- ✅ **6色対応**: 黒、赤、緑、黄、色5カスタム、色6カスタム
- ✅ **設定連携**: `_getCustomColor5()`, `_getCustomColor6()`で設定ページの色プリセット反映
- ✅ **横スクロール対応**: `SingleChildScrollView`でラップ
- ✅ **左寄せ**: `mainAxisAlignment: MainAxisAlignment.start`
- ✅ **固定幅スペース**: `Spacer()` → `SizedBox(width: 16)`

#### 下段ツールバー（太さ・ズーム・消去）

- ✅ **横スクロール対応**: `SingleChildScrollView`でラップ
- ✅ **左寄せ**: `mainAxisAlignment: MainAxisAlignment.start`
- ✅ **固定幅スペース**: `Spacer()` → `SizedBox(width: 16)`
- ✅ **ゴミ箱アイコン常時表示**: 狭い画面でもスクロールで到達可能

#### 実装パターン

```dart
// 共通パターン（上段・下段）
SingleChildScrollView(
  scrollDirection: Axis.horizontal,
  child: Row(
    mainAxisSize: MainAxisSize.min,
    mainAxisAlignment: MainAxisAlignment.start, // 左寄せ
    children: [
      // ボタン群
      _buildColorButton(Colors.black),
      _buildColorButton(Colors.red),
      _buildColorButton(Colors.green),
      _buildColorButton(Colors.yellow),
      _buildColorButton(_getCustomColor5()), // 設定から取得
      _buildColorButton(_getCustomColor6()), // 設定から取得
      const SizedBox(width: 16), // Spacerの代わりに固定幅
      // モード切替アイコン
    ],
  ),
)
```

#### 色プリセット連携

```dart
// 設定ページから色5・色6を取得
Color _getCustomColor5() {
  final settings = ref.watch(userSettingsProvider).value;
  if (settings != null && settings.whiteboardColor5 != 0) {
    return Color(settings.whiteboardColor5);
  }
  return Colors.blue; // デフォルト
}

Color _getCustomColor6() {
  final settings = ref.watch(userSettingsProvider).value;
  if (settings != null && settings.whiteboardColor6 != 0) {
    return Color(settings.whiteboardColor6);
  }
  return Colors.orange; // デフォルト
}
```

**Test Results**:

- ✅ AIWAタブレット（横長）: 全アイコン表示確認
- ✅ SH54D横持ち: ゴミ箱アイコン表示確認
- ✅ SH54D縦持ち: モード切替アイコン表示確認
- ✅ 色プリセット連携動作確認

**Modified Files**:

- `lib/pages/whiteboard_editor_page.dart` (683行)
  - Lines 404-421: 上段ツールバー（6色＋左寄せ＋横スクロール）
  - Lines 441-493: 下段ツールバー（左寄せ＋横スクロール）
  - Lines 516-530: 色プリセット取得メソッド

**Commits**: 本セッションでコミット予定

---

## Recent Implementations (2026-01-20)

### 1. UI/UX改善とサインイン必須仕様への最適化 ✅

**Purpose**: アプリの使いやすさ向上と未認証時の無駄な処理削除

**Completed**:

#### ホワイトボード設定パネルの修正

- ✅ `userSettingsProvider`と`userSettingsRepositoryProvider`のimport追加
- ✅ 色プリセット数を8色→6色に削減（画面からはみ出し解消）
- ✅ ツールバーの縦幅をコンパクト化
  - パディング削減: `all(8)` → `symmetric(horizontal: 8, vertical: 4)`
  - 段間スペース削減: 8 → 4
  - 色ボタンサイズ縮小: 36×36 → 32×32
  - IconButtonコンパクト化: `padding: EdgeInsets.zero` + `size: 20`

#### 未認証時の処理最適化

- ✅ `createDefaultGroup()`に未認証チェック追加
- ✅ `user == null`の場合は早期リターン
- ✅ 無駄なFirestore接続試行を回避

#### ホーム画面の改善

- ✅ アプリタイトルを「GoShopping」に統一
- ✅ パスワードリセットリンクを復活
  - サインイン時にパスワード入力欄下に配置
  - メールアドレス入力済みでリセットメール送信可能
- ✅ アプリバーで認証状態を表示
  - 未認証時: 「未サインイン」
  - 認証済み時: 「○○ さん」

**Modified Files**:

- `lib/pages/settings_page.dart`
- `lib/providers/purchase_group_provider.dart`
- `lib/pages/home_page.dart`
- `lib/widgets/common_app_bar.dart`
- `lib/pages/whiteboard_editor_page.dart`

**Commits**: `23dda63`, `a88d1f6`

---

## Recent Implementations (2026-01-19)

### 1. ホワイトボードエディターUI大幅改善 ✅

**Purpose**: スマホ縦画面でのツールバー表示問題を解決し、操作性を向上

**Problem**:

- 縦画面（スマホ）でツールバーアイコンが画面外に隠れて見えない
- スクロール/描画モード切替アイコンが見えず、描画不可能に見える
- ズーム機能が視覚的に動作しない（スクロール範囲が変わらない）

**Solution**:

#### ツールバー2段構成の最適化

- **上段**: 色選択（4色）+ Spacer + モード切替アイコン
  - 色削減: 黒、赤、緑、黄色のみ（青、オレンジ、パープル削除）
  - モード切替を右端配置→縦画面でも常に見える
- **下段**: 線幅5段階 + ズーム（±ボタン） + Spacer + 消去

#### アイコンデザイン改善

- スクロールロック → モード別アイコンに変更
  - 描画モード: `Icons.brush`（青）
  - スクロールモード: `Icons.open_with`（灰）
- 直感的なUI/UX実現

#### ペン太さUI改善

- スライダー（連続値） → 5段階ボタン（1.0, 2.0, 4.0, 6.0, 8.0）
- 円形アイコン、サイズで太さを視覚化
- タッチ操作に最適化

#### ズーム機能の実装改善

- ドロップダウン → ±ボタン（0.5刻み調整）
- **SizedBox + Transform.scale** による正しいスクロール実装

  ```dart
  SizedBox(
    width: screenWidth * _canvasScale,
    height: screenHeight * _canvasScale,
    child: Transform.scale(
      scale: _canvasScale,
      alignment: Alignment.topLeft,
      child: Container(...),
    ),
  )
  ```

**Test Results**:

- ✅ 縦画面で全アイコン表示確認
- ✅ 描画/スクロールモード切替正常動作
- ✅ ズーム機能正常動作（スクロール範囲も拡大）
- ✅ 5段階ペン太さ正常動作

**Modified Files**:

- `lib/pages/whiteboard_editor_page.dart` (607→613行)
- `docs/specifications/terms_of_service.md` (Go Shop → GoShopping)

**Commits**: `d202aa3`

---

## Recent Implementations (2026-01-16)

### 1. ホワイトボード機能完全実装＋バグ修正 ✅

**Purpose**: クローズドテスト準備完了

**Completed Features**:

#### スクロール可能キャンバス

- ✅ 拡張可能なキャンバスサイズ（1x～4x）
- ✅ 縦横両方向のスクロールバー
- ✅ スクロールロック機能（描画モード⇄スクロールモード切替）
- ✅ グリッド線表示（50px間隔）

#### マルチカラー描画

- ✅ 8色カラーピッカー
- ✅ 線幅調整スライダー（1.0～10.0）
- ✅ レイヤーシステム（CustomPaint + Signature）
- ✅ 自動ストローク分割（30px閾値）

#### 閲覧・編集権限

- ✅ グループ共有ホワイトボード
- ✅ 個人用ホワイトボード
- ✅ 閲覧専用モード（他メンバーのホワイトボード）
- ✅ 編集可能/不可の視覚的フィードバック

#### 通知システム

- ✅ ホワイトボード更新通知
- ✅ バッチ通知送信（グループメンバー全員）
- ✅ 通知受信ハンドラー（将来のリアルタイム更新用）

**Bug Fixes**:

- ✅ グループ可視性問題（Crashlytics無効化）
- ✅ AppBarタイトル表示バグ（Firestore nullクエリ対応）
- ✅ サインアップ時のユーザー名保存タイミング修正

**Test Documentation**:

- ✅ `test_procedures_v2.md` - 29テストプロシージャ
- ✅ `test_checklist_template.md` - 41項目チェックリスト

**Commits**: `2bae86a`, `d6fe034`, `de72177`, `1825466`, `e26559f`

**Status**: 🚀 クローズドテスト開始準備完了

---

## Recent Implementations (2026-01-15)

### 1. 手書きホワイトボード機能完全実装（future ブランチ） ✅

**Purpose**: グループ共有・個人用ホワイトボード機能を差別化機能として実装

**Key Achievements**:

- ✅ signature ^5.5.0 パッケージ統合（flutter_drawing_board から移行）
- ✅ レイヤーシステム実装（CustomPaint + Signature）
- ✅ マルチカラー描画対応（8色）
- ✅ 自動ストローク分割（30px閾値）
- ✅ 2段構成ツールバー（狭い画面対応）
- ✅ Firestore + Hive 同期対応

**Implementation Highlights**:

```dart
// レイヤーシステム
Stack(
  children: [
    CustomPaint(painter: DrawingStrokePainter(_workingStrokes)), // 背景
    Signature(controller: _controller, backgroundColor: Colors.transparent), // 前景
  ],
)
```

**Files**:

- `lib/pages/whiteboard_editor_page.dart` - エディター（415行）
- `lib/utils/drawing_converter.dart` - 変換ロジック
- `lib/models/whiteboard.dart` - データモデル（Hive typeId: 15-17）

**Commits**: 4a6c1e2, 314771a, 540b835, 67a90a1, 0b4a6c9

---

## Recent Implementations (2026-01-12)

### 1. Firebase設定のパッケージ名統一 ✅

**Purpose**: プロジェクト名が`go_shop`と`goshopping`で混在していた問題を解消

**Modified Files**:

- `pubspec.yaml`: `name: go_shop` → `name: goshopping`
- `google-services.json`:
  - prod: `net.sumomo_planning.goshopping`
  - dev: `net.sumomo_planning.go_shop.dev`
- `android/app/build.gradle.kts`: `namespace = "net.sumomo_planning.goshopping"`
- `android/app/src/main/AndroidManifest.xml`: パッケージ名とラベルを統一
- 全importパス修正: `package:go_shop/` → `package:goshopping/` (15ファイル)
- `android/app/src/main/kotlin/.../MainActivity.kt`: パッケージ名を`goshopping`に統一

**Commit**: `0fe085f` - "fix: Firebase設定のパッケージ名を正式名称に統一"

### 2. アイテムタイル操作機能の改善 ✅

**Problem**: ダブルタップ編集機能が動作しなくなっていた

**Root Cause**:

- `GestureDetector`の子要素が`ListTile`だったため、ListTile内部のインタラクティブ要素（Checkbox、IconButton）がタップイベントを優先処理

**Solution**:

- `GestureDetector` → `InkWell`に変更
- `onDoubleTap`: アイテム編集ダイアログ表示
- `onLongPress`: アイテム削除（削除権限がある場合のみ）

**Modified File**: `lib/pages/shared_list_page.dart`

**Usage Pattern**:

```dart
InkWell(
  onDoubleTap: () => _showEditItemDialog(),
  onLongPress: canDelete ? () => _deleteItem() : null,
  child: ListTile(...),
)
```

### 3. Google Play Store公開準備 ✅

**Status**: 70%完了

**Completed**:

- ✅ プライバシーポリシー: `docs/specifications/privacy_policy.md`
- ✅ 利用規約: `docs/specifications/terms_of_service.md`
- ✅ Firebase設定完了
- ✅ パッケージ名統一: `net.sumomo_planning.goshopping`
- ✅ `.gitignore`でkeystore保護
- ✅ 署名設定実装

**File Structure**:

```
android/
├── app/
│   └── upload-keystore.jks  # リリース署名用（未配置）
├── key.properties           # 署名情報（未作成）
└── key.properties.template  # テンプレート
```

**Remaining Tasks**:

- [ ] keystoreファイル配置（作業所PCから）
- [ ] key.properties作成
- [ ] AABビルドテスト
- [ ] プライバシーポリシー公開URL取得
- [ ] Play Consoleアプリ情報準備

**Build Commands**:

```bash
# リリースAPK
flutter build apk --release --flavor prod

# Play Store用AAB
flutter build appbundle --release --flavor prod
```

---

## Recent Implementations (2026-01-07)

### 1. エラー履歴機能実装 ✅

**Purpose**: ユーザーの操作エラー履歴をローカルに保存し、トラブルシューティングを支援

**Implementation Files**:

- **New Service**: `lib/services/error_log_service.dart`
  - SharedPreferencesベースの軽量エラーログ保存
  - 最新20件のみ保持（FIFO方式）
  - 5種類のエラータイプ対応（permission, network, sync, validation, operation）
  - 既読管理機能

- **New Page**: `lib/pages/error_history_page.dart`
  - エラー履歴表示画面
  - エラータイプ別アイコン・色表示
  - 時間差表示（たった今、3分前、2日前など）
  - 既読マーク・一括削除機能

- **Modified**: `lib/widgets/common_app_bar.dart`
  - 三点メニューに「エラー履歴」項目追加

**特徴**:

- ✅ SharedPreferencesのみ使用（Firestore不使用、コストゼロ）
- ✅ 最新20件自動保存
- ✅ ローカル完結（通信なし、即座に表示）
- ✅ 将来のジャーナリング機能への統合を考慮した設計

**Commit**: `7044e0c`

### 2. グループ・リスト作成時の重複名チェック実装 ✅

**Purpose**: 同じ名前のグループ・リストの作成を防止

**Implementation Files**:

- **Modified**: `lib/widgets/shared_list_header_widget.dart`
  - リスト作成時に同じグループ内の既存リスト名をチェック
  - 重複があればエラーログに記録

- **Modified**: `lib/widgets/group_creation_with_copy_dialog.dart`
  - グループ作成時に既存グループ名をチェック
  - バリデーション失敗時にエラーログ記録

**エラーメッセージ**:

- リスト: 「〇〇という名前のリストは既に存在します」
- グループ: 「〇〇という名前のグループは既に存在します」

**Commits**: `8444977`, `16485de`, `909945f`, `1e4e4cd`, `df84e44`

---

## Recent Implementations (2025-12-25)

### 1. Riverpodベストプラクティス確立 ✅

**Purpose**: LateInitializationError対応パターンの文書化とAI Coding Agent指示書整備

**Implementation Files**:

- **New Document**: `docs/riverpod_best_practices.md` (拡充)
  - セクション4追加: build()外でのRefアクセスパターン
  - `late final Ref _ref`の危険性を明記
  - `Ref? _ref` + `_ref ??= ref`パターンの説明
  - 実例（SelectedGroupNotifier）を追加
  - AsyncNotifier.build()の複数回呼び出しリスクを解説

- **Modified**: `.github/copilot-instructions.md`
  - Riverpod修正時の必須参照指示を追加
  - `docs/riverpod_best_practices.md`参照の強制化
  - `late final Ref`使用禁止の警告

**Key Pattern**:

```dart
// ❌ 危険: late final Ref → LateInitializationError
class MyNotifier extends AsyncNotifier<Data> {
  late final Ref _ref;

  @override
  Future<Data> build() async {
    _ref = ref;  // 2回目の呼び出しでエラー
    return fetchData();
  }
}

// ✅ 安全: Ref? + null-aware代入
class MyNotifier extends AsyncNotifier<Data> {
  Ref? _ref;

  @override
  Future<Data> build() async {
    _ref ??= ref;  // 初回のみ代入
    return fetchData();
  }
}
```

**Commits**: `f9da5f5`, `2e12c80`

### 2. 招待受諾バグ完全修正 ✅

**Background**: QRコード招待受諾時に通知送信は成功するが、UI・Firestoreに反映されない問題を段階的に修正

#### Phase 1: デバッグログ強化

**Modified**: `lib/services/notification_service.dart`

- `sendNotification()`に詳細ログ追加
- `_handleNotification()`に処理追跡ログ追加
- Firestore保存成功確認ログ追加

#### Phase 2: 構文エラー修正

**Problem**: if-elseブロックのインデントエラー

**Solution**: UI更新処理をifブロック内に移動

**Commit**: `38a1859`

#### Phase 3: permission-deniedエラー修正

**Problem**: 受諾者がまだグループメンバーではないのに招待使用回数を更新しようとした

**Solution**:

- **受諾側**: `_updateInvitationUsage()`削除（通知送信のみ）
- **招待元側**: メンバー追加後に`_updateInvitationUsage()`実行
- 理由: 受諾者はまだグループメンバーではない → Firestore Rules違反

**Commit**: `f2be455`

#### Phase 4: Firestoreインデックスエラー修正

**Problem**: 通知リスナーが`userId + read + timestamp`の3フィールドクエリを実行するが、インデックスが`userId + read`の2フィールドしかなかった

**Solution**: `firestore.indexes.json`に`timestamp`フィールドを追加

**Before**:

```json
{
  "collectionGroup": "notifications",
  "fields": [
    { "fieldPath": "userId", "order": "ASCENDING" },
    { "fieldPath": "read", "order": "ASCENDING" }
  ]
}
```

**After**:

```json
{
  "collectionGroup": "notifications",
  "fields": [
    { "fieldPath": "userId", "order": "ASCENDING" },
    { "fieldPath": "read", "order": "ASCENDING" },
    { "fieldPath": "timestamp", "order": "DESCENDING" } // ← 追加
  ]
}
```

**Deployment**:

```bash
$ firebase deploy --only firestore:indexes
✔ firestore: deployed indexes successfully
```

**Commit**: `b13c7b7`

#### 修正後の期待動作

```
1. Pixel（まや）: QRコード受諾
   ✅ acceptQRInvitation()
   ✅ sendNotification() → Firestore保存成功

2. SH54D（すもも）: 通知受信 ← 修正後はこれが動作する！
   ✅ 通知リスナー起動（インデックスエラー解消）
   ✅ _handleNotification() 実行
   ✅ SharedGroups更新（allowedUid + members）
   ✅ _updateInvitationUsage() 実行（招待元権限で）
   ✅ UI反映（グループメンバー表示）
```

**Status**: 理論上完全修正 ⏳ 次回セッションで動作確認予定

**検証手順**:

1. 両デバイス再起動（Firestoreインデックス反映確認）
2. 通知リスナー起動確認（SH54Dログ: "✅ [NOTIFICATION] リスナー起動完了！"）
3. 招待受諾テスト（エンドツーエンド動作確認）
4. エラーログ確認（問題がないか最終確認）

---

## プロジェクト概要

GoShopping は家族・グループ向けの買い物リスト共有 Flutter アプリです。Firebase Auth（ユーザー認証）と Cloud Firestore（データベース）を使用し、Hive をローカルキャッシュとして併用する**Firestore-first ハイブリッドアーキテクチャ**を採用しています。

**Current Status (December 2025)**: 認証必須アプリとして、全データレイヤー（Group/List/Item）で Firestore 優先＋効率的な差分同期を実現。

## 主要機能

### ✅ 実装済み機能

1. **グループ管理**
   - グループ作成・編集・削除
   - メンバー招待（QR コード）
   - デフォルトグループ（個人専用）

2. **リスト管理**
   - リスト作成・編集・削除
   - リアルタイム同期

3. **アイテム管理**
   - アイテム追加・編集・削除
   - 購入状態トグル（全メンバー可能）
   - 削除権限チェック（登録者・オーナーのみ）
   - 期限設定（バッジ表示）
   - 定期購入設定（自動リセット）

4. **通知システム**
   - リスト作成・削除・名前変更の通知送信
   - 通知履歴表示（未読/既読管理）
   - マルチデバイス対応（同一ユーザーへの通知送信）
   - リアルタイム通知受信（Firestore Snapshots）

5. **エラー管理**
   - エラー履歴表示
   - AppBar 未確認エラーアイコン
   - 確認ボタンでアイコン消去

### 🔨 今後の実装予定

- アイテム編集機能の UI 改善
- カテゴリタグ
- 価格トラッキング

## アーキテクチャ

### 🔥 Firestore-First Hybrid Pattern（2025 年 12 月実装）

全 3 つのデータレイヤーで Firestore を優先：

1. **SharedGroup** (グループ)
2. **SharedList** (リスト)
3. **SharedItem** (アイテム) - **差分同期で 90%データ削減**

```dart
// ✅ 正しいパターン: Firestore優先、Hiveキャッシュ
if (F.appFlavor == Flavor.prod && _firestoreRepo != null) {
  try {
    // 1. Firestoreから取得（常に最新）
    final firestoreData = await _firestoreRepo!.getData();

    // 2. Hiveにキャッシュ
    await _hiveRepo.saveData(firestoreData);

    return firestoreData;
  } catch (e) {
    // Firestoreエラー → Hiveフォールバック
    return await _hiveRepo.getData();
  }
}
```

### ⚡ 差分同期（Differential Sync）

**SharedItem は Map 形式で単一アイテムのみ送信**：

```dart
// ❌ 従来: リスト全体送信（10アイテム = ~5KB）
final updatedItems = {...currentList.items, newItem.itemId: newItem};
await repository.updateSharedList(currentList.copyWith(items: updatedItems));

// ✅ 現在: 単一アイテム送信（1アイテム = ~500B）
await repository.addSingleItem(currentList.listId, newItem);
await repository.updateSingleItem(currentList.listId, updatedItem);
await repository.removeSingleItem(currentList.listId, itemId); // 論理削除
```

**パフォーマンス**:

- データ転送量: **90%削減**
- 同期速度: < 1 秒
- ネットワーク効率: 大幅改善

### 状態管理 - Riverpod

```dart
// AsyncNotifierProviderパターン
final sharedListRepositoryProvider = Provider<SharedListRepository>((ref) {
  if (F.appFlavor == Flavor.prod) {
    return HybridSharedListRepository(ref); // Firestore + Hiveキャッシュ
  } else {
    return HiveSharedListRepository(ref); // 開発環境
  }
});
```

⚠️ **重要**: Riverpod Generator は無効（バージョン競合）。従来の Provider 構文のみ使用。

## 開発環境セットアップ

### 必要な環境

- Flutter SDK: 3.27.2 以降
- Dart SDK: 3.6.1 以降
- Firebase CLI: 最新版

### 初期セットアップ

```bash
# 依存パッケージのインストール
flutter pub get

# コード生成（Hiveアダプター、Freezedクラス）
dart run build_runner build --delete-conflicting-outputs

# Firebase設定の生成
flutterfire configure
```

### ビルドコマンド

```bash
# 開発環境（Hiveのみ、高速テスト用）
flutter run --flavor dev

# 本番環境（Firestore + Hiveハイブリッド）
flutter run --flavor prod

# Androidデバッグビルド
cd android
./gradlew assembleDebug --no-daemon

# リリースビルド
flutter build apk --release --flavor prod
```

## プロジェクト構成

### 主要ディレクトリ

```
lib/
├── adapters/              # Hive TypeAdapter（カスタム）
│   ├── shopping_item_adapter_override.dart
│   └── user_settings_adapter_override.dart
├── config/                # アプリ設定
│   └── app_mode_config.dart
├── datastore/             # データレイヤー
│   ├── *_repository.dart           # 抽象インターフェース
│   ├── firestore_*_repository.dart # Firestore実装
│   ├── hive_*_repository.dart      # Hive実装
│   └── hybrid_*_repository.dart    # ハイブリッド実装
├── models/                # データモデル（Freezed + Hive）
├── pages/                 # 画面
├── providers/             # Riverpodプロバイダー
│   ├── error_notifier_provider.dart # エラー管理
│   ├── auth_provider.dart
│   ├── purchase_group_provider.dart
│   └── shared_list_provider.dart
├── services/              # ビジネスロジック
│   ├── qr_invitation_service.dart
│   ├── sync_service.dart
│   └── periodic_purchase_service.dart
├── utils/                 # ユーティリティ
│   └── app_logger.dart    # ログ管理
└── widgets/               # 再利用可能ウィジェット
```

### 重要ファイル

- **main.dart**: アプリエントリーポイント、Hive 初期化
- **flavors.dart**: 環境切り替え（dev/prod）
- **firebase_options.dart**: Firebase 設定
- **firestore.rules**: Firestore セキュリティルール

## 認証フロー

### サインアップ処理順序（重要！）

```dart
// 1. ローカルデータクリア（Firebase Auth登録前）
await UserPreferencesService.clearAllUserInfo();
await SharedGroupBox.clear();
await sharedListBox.clear();

// 2. Firebase Auth新規登録
await ref.read(authProvider).signUp(email, password);

// 3. displayName設定（SharedPreferences + Firebase Auth）
await UserPreferencesService.saveUserName(userName);
await user.updateDisplayName(userName);
await user.reload();

// 4. プロバイダー無効化
ref.invalidate(allGroupsProvider);

// 5. Firestore→Hive同期
await ref.read(forceSyncProvider.future);
```

### サインイン処理

```dart
// 1. Firebase Authサインイン
await ref.read(authProvider).signIn(email, password);

// 2. Firestoreからユーザー名取得
final firestoreUserName = await FirestoreUserNameService.getUserName();
await UserPreferencesService.saveUserName(firestoreUserName);

// 3. ネットワーク安定化待機
await Future.delayed(const Duration(seconds: 1));

// 4. Firestore→Hive同期
await ref.read(forceSyncProvider.future);
ref.invalidate(allGroupsProvider);
```

### サインアウト処理

```dart
// 1. ローカルデータクリア
await SharedGroupBox.clear();
await sharedListBox.clear();
await UserPreferencesService.clearAllUserInfo();

// 2. プロバイダー無効化
ref.invalidate(allGroupsProvider);

// 3. Firebase Authサインアウト
await ref.read(authProvider).signOut();
```

## デフォルトグループシステム

**デフォルトグループ** = ユーザー専用のプライベートグループ

### 識別ルール

```dart
bool isDefaultGroup(SharedGroup group, User? currentUser) {
  // Legacy対応
  if (group.groupId == 'default_group') return true;

  // 正式仕様
  if (currentUser != null && group.groupId == currentUser.uid) return true;

  return false;
}
```

### 特徴

- **groupId**: `user.uid`（ユーザー固有）
- **syncStatus**: `SyncStatus.local`（Firestore に同期しない）
- **削除保護**: UI/Repository/Provider の 3 層で保護
- **招待不可**: 招待機能は無効化

### 🔥 Firestore 優先チェック（サインイン時）

```dart
// サインイン状態ではFirestoreを最初にチェック
if (user != null && F.appFlavor == Flavor.prod) {
  try {
    // Firestoreから既存デフォルトグループ確認
    final groupsSnapshot = await firestore
        .collection('SharedGroups')
        .where('allowedUid', arrayContains: user.uid)
        .get();

    final defaultGroupDoc = groupsSnapshot.docs.firstWhere(
      (doc) => doc.id == user.uid,
      orElse: () => throw Exception('デフォルトグループなし'),
    );

    // 存在すればHiveに同期
    final firestoreGroup = SharedGroup.fromFirestore(defaultGroupDoc);
    await hiveRepository.saveGroup(firestoreGroup);

    // Hiveクリーンアップ実行
    await _cleanupInvalidHiveGroups(user.uid, hiveRepository);

    return;
  } catch (e) {
    // Firestoreにない → 新規作成
  }
}
```

### Hive クリーンアップ

**目的**: 他ユーザーのグループを Hive から削除

```dart
Future<void> _cleanupInvalidHiveGroups(
  String currentUserId,
  HiveSharedGroupRepository hiveRepository,
) async {
  final allHiveGroups = await hiveRepository.getAllGroups();

  for (final group in allHiveGroups) {
    if (!group.allowedUid.contains(currentUserId)) {
      await hiveRepository.deleteGroup(group.groupId); // ⚠️ Hiveのみ削除
    }
  }
}
```

⚠️ **重要**: Firestore は削除しない（他ユーザーが使用中の可能性）

## QR 招待システム

### データ構造（Firestore）

```dart
/invitations/{invitationId}
{
  'invitationId': String,
  'groupId': String,
  'groupName': String,
  'invitedBy': String,
  'inviterName': String,
  'securityKey': String,
  'maxUses': 5,
  'currentUses': 0,
  'usedBy': [],
  'status': 'pending',
  'expiresAt': DateTime,
}
```

### 招待作成

```dart
await _firestore.collection('invitations').doc(invitationId).set({
  ...invitationData,
  'maxUses': 5,
  'currentUses': 0,
  'usedBy': [],
});
```

### 招待受諾（アトミック更新）

```dart
await _firestore.collection('invitations').doc(invitationId).update({
  'currentUses': FieldValue.increment(1),
  'usedBy': FieldValue.arrayUnion([acceptorUid]),
  'lastUsedAt': FieldValue.serverTimestamp(),
});
```

## エラー管理システム（2025 年 12 月 23 日実装）

### エラー履歴プロバイダー

```dart
// lib/providers/error_notifier_provider.dart
class ErrorEntry {
  final DateTime timestamp;
  final String message;
  final String? stackTrace;
  final String? source;
  final bool isConfirmed; // 確認済みフラグ
}

class ErrorNotifier extends StateNotifier<List<ErrorEntry>> {
  void addError(String message, {String? stackTrace, String? source});
  void confirmAllErrors(); // 全エラーを確認済みに
  void clearErrors();

  int get unconfirmedErrorCount; // 未確認エラー件数
  bool get hasUnconfirmedErrors; // 未確認エラー存在
}
```

### UI 統合

**AppBar**:

- 未確認エラー時のみ×アイコン表示（バッジ付き）
- タップでエラー履歴ダイアログ表示

**スリードットメニュー**:

- エラー履歴表示（件数付き）
- エラー履歴クリア

**エラーダイアログ**:

- 「確認」ボタン → 全エラーを確認済みに変更 → ×アイコン消える
- 「クリア」ボタン → 履歴完全削除
- 未確認エラーは赤い背景で表示

### エラー記録統合箇所

```dart
// アイテム追加エラー
catch (e, stackTrace) {
  ref.read(errorNotifierProvider.notifier).addError(
    'アイテム追加失敗: $e',
    stackTrace: stackTrace.toString(),
    source: '買い物リスト - アイテム追加',
  );
}

// 購入状態変更エラー
catch (e, stackTrace) {
  ref.read(errorNotifierProvider.notifier).addError(
    '購入状態更新失敗: $e',
    stackTrace: stackTrace.toString(),
    source: '買い物リスト - 購入状態変更',
  );
}

// アイテム削除エラー
catch (e, stackTrace) {
  ref.read(errorNotifierProvider.notifier).addError(
    'アイテム削除失敗: $e',
    stackTrace: stackTrace.toString(),
    source: '買い物リスト - アイテム削除',
  );
}
```

## プライバシー保護

### ログマスキング

```dart
// 個人情報を自動マスキング
AppLogger.maskUserId(userId);        // abc*** （最初3文字のみ）
AppLogger.maskName(name);            // すも*** （最初2文字のみ）
AppLogger.maskItem(itemName, itemId); // 牛乳*** (itemId)
```

### SecretMode（実装済み）

- シークレットモード ON: 全データ非表示
- デフォルト OFF

## 開発ルール

### Git Push ポリシー

```bash
# 通常: onenessブランチのみ
git push origin oneness

# 明示的指示がある場合のみ: mainブランチにも
git push origin oneness
git push origin oneness:main
```

### コーディング規約

1. **Firestore 優先**: 常に Firestore から読み取り、Hive はキャッシュ
2. **差分同期**: `addSingleItem()`, `updateSingleItem()`, `removeSingleItem()`を使用
3. **プロパティ名**: `memberId`（`memberID`ではない）
4. **Riverpod Generator 禁止**: 従来構文のみ
5. **ログマスキング**: 個人情報は`AppLogger.mask*()`で必ずマスク

### エラーハンドリング

```dart
try {
  // 処理
} catch (e, stackTrace) {
  Log.error('❌ エラーメッセージ: $e', stackTrace);

  // エラー履歴に追加
  ref.read(errorNotifierProvider.notifier).addError(
    'ユーザー向けメッセージ: $e',
    stackTrace: stackTrace.toString(),
    source: '画面名 - 操作名',
  );
}
```

## トラブルシューティング

### ビルドエラー

```bash
# Riverpod Generatorインポートを削除
# 伝統的なProvider構文のみ使用

# コード生成
dart run build_runner build --delete-conflicting-outputs

# 静的解析
flutter analyze
```

### Hive データエラー

```bash
# Hiveボックスクリア
await SharedGroupBox.clear();
await sharedListBox.clear();

# アダプター登録順序確認
# UserSettingsAdapterOverride → その他のアダプター
```

### Firestore 同期エラー

```bash
# セキュリティルール確認
firebase deploy --only firestore:rules

# allowedUid配列に現在ユーザーが含まれるか確認
```

## Known Issues

- **TBA1011 Firestore 接続問題**: 特定デバイスで`Unable to resolve host firestore.googleapis.com`エラー（モバイル通信で回避可能）

## Recent Updates（2025 年 12 月 23 日）

### 1. エラー管理システム実装 ✅

- ErrorNotifier プロバイダー作成
- AppBar に未確認エラーアイコン表示
- エラー履歴ダイアログ（確認・クリアボタン付き）
- 全 CRUD 操作にエラー記録統合

### 2. アイテム削除権限チェック ✅

- **削除**: アイテム登録者・グループオーナーのみ
- **購入状態変更**: 全メンバー可能
- UI でボタン無効化＋ツールチップ表示

### 3. 個人情報マスキング ✅

- ログ出力を`AppLogger.maskItem()`でマスキング
- アイテム名を最初の 2 文字＋itemId のみ記録

## ライセンス

MIT License

## 開発者

- Owner: maya27AokiSawada
- Branch: oneness（開発ブランチ）
- Main: 安定版リリースブランチ
