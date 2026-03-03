## QRスキャナーオーバーフロー修正検証結果

**テスト日時**: 2026-03-03 10:05
**テストデバイス**: AS10L (OS: Android15)
**ビルドフレーバー**: prod

### 結果サマリー

- [x] ✅ **PASS** - AS10Lでオーバーフローエラー完全解消を確認

### 詳細チェック

- [ ] AppBar表示: ✅
- [ ] カメラプレビュー表示: ✅
- [ ] スキャンエリア白枠表示: ✅
- [ ] オーバーフローエラー: なし✅
- [ ] スキャンエリアサイズ: 適切✅
- [ ] 縦向き動作: ✅
- [ ] 横向き動作: ✅
- [ ] QRコード検出: ✅

### スクリーンショット

<AS10Lスキャナー画面のスクリーンショットを添付>
[スキャナー画面](file:image_20260303_1036.png)

### 備考

<気づいた点があれば記載>
Pixel 9の招待を受ける際にスキャナーの白枠が大きすぎるかな？
ピント合わせるにはかなり小さめの画角にしないと参加確認ダイアログが表示されない

---

## NetworkMonitorService重大バグ修正とデプロイ

**作業時刻**: 2026-03-03 14:00-17:00
**テストデバイス**: SH54D (359705470227530) - USB接続、サインイン済み
**ビルドフレーバー**: prod

### 問題発覚

前セッションで実装したオフライン処理をコミット・プッシュ後、実機テストで以下の問題を確認：

1. **グループ作成成功してもバナー消えない**
2. **リトライボタンが機能しない**
3. **permission-deniedエラー発生**（サインイン済みにも関わらず）

### 根本原因の特定

詳細ログ分析により3つの重大なバグを発見：

#### Bug #1: 初回接続チェック未実行

- **原因**: `NetworkMonitorService()`コンストラクタで`checkFirestoreConnection()`を呼び出していない
- **影響**: サービス初期化時に実接続チェックが実行されず、常に`online`状態のまま
- **結果**: 実際はオフラインでもバナーが表示されない

#### Bug #2: 自動リトライトリガー欠落

- **原因**: `_updateStatus()`メソッドで`offline`検出時に`startAutoRetry()`を呼び出していない
- **影響**: ネットワーク復帰時に自動的に再接続を試みない
- **結果**: ユーザーが手動でリトライボタンを押す必要がある（しかしボタンも機能しない）

#### Bug #3: Permission-deniedエラー

- **原因**: `SharedGroups.where(...).limit(1)`でlistクエリ実行 → メンバーシップチェック必須
- **影響**: サインイン済みでも認証チェック前にクエリ実行 → permission-denied発生
- **結果**: 接続チェックが常に失敗し、online状態に遷移できない

### 修正内容

#### Fix #1 - 初回接続チェック実装

**ファイル**: `lib/services/network_monitor_service.dart` Lines 35-43

```dart
NetworkMonitorService() {
  _statusController.add(_currentStatus);
  AppLogger.info('🌐 [NETWORK_MONITOR] 初期化完了 - 初期状態: $_currentStatus');

  // 🔥 FIX #1: 初期化後に接続チェック実行
  Future.microtask(() async {
    AppLogger.info('🔍 [NETWORK_MONITOR] 初回接続チェック開始');
    await checkFirestoreConnection();
  });
}
```

**効果**:

- サービス初期化直後に実際のネットワーク状態を検出
- アプリ起動時にオフラインなら即座にバナー表示
- オンラインなら正常に接続確立を確認

#### Fix #2 - 自動リトライトリガー追加

**ファイル**: `lib/services/network_monitor_service.dart` Lines 220-223

```dart
void _updateStatus(NetworkStatus status) {
  if (_currentStatus != status) {
    final oldStatus = _currentStatus;
    _currentStatus = status;
    _statusController.add(status);
    AppLogger.info('📡 [NETWORK_MONITOR] 状態変更: $oldStatus → $status');

    // 🔥 FIX #2: offline検出時に自動リトライ開始
    if (status == NetworkStatus.offline) {
      AppLogger.info('🔄 [NETWORK_MONITOR] オフライン検出 → 自動リトライ開始');
      startAutoRetry();
    }
  }
}
```

**効果**:

- `offline`状態になった瞬間に自動的に30秒ごとのリトライ開始
- ネットワーク復帰時に自動的に接続再試行
- 手動リトライボタンに依存しない動作

#### Fix #3 - Permission-deniedエラー修正

**ファイル**: `lib/services/network_monitor_service.dart` Lines 66-107

```dart
Future<bool> checkFirestoreConnection() async {
  AppLogger.info('🔍 [NETWORK_MONITOR] Firestore接続チェック開始');
  _updateStatus(NetworkStatus.checking);
  _lastCheckTime = DateTime.now();

  try {
    AppLogger.info('🔍 [NETWORK_MONITOR] Firestoreクエリ実行中...');

    final currentUser = FirebaseAuth.instance.currentUser;
    final DocumentSnapshot snapshot;

    if (currentUser != null) {
      // 🔥 FIX #3: 認証済み → users/{uid}ドキュメントをクエリ（オーナー常に読取可）
      AppLogger.info('🔍 [NETWORK_MONITOR] 認証済み - ユーザードキュメントで接続チェック: ${AppLogger.maskUserId(currentUser.uid)}');
      snapshot = await FirebaseFirestore.instance
          .doc('users/${currentUser.uid}')
          .get(const GetOptions(source: Source.server))
          .timeout(connectionTimeout);
    } else {
      // 未認証 → furestorenewsコレクションをクエリ（誰でも読取可）
      AppLogger.info('🔍 [NETWORK_MONITOR] 未認証 - 公開ニュースで接続チェック');
      final querySnapshot = await FirebaseFirestore.instance
          .collection('furestorenews')
          .limit(1)
          .get(const GetOptions(source: Source.server))
          .timeout(connectionTimeout);
      snapshot = querySnapshot.docs.isNotEmpty
          ? querySnapshot.docs.first
          : throw Exception('No documents');
    }

    AppLogger.info('✅ [NETWORK_MONITOR] Firestore接続成功 - ドキュメント存在: ${snapshot.exists}');
    _updateStatus(NetworkStatus.online);
    stopAutoRetry();
    return true;
  } on TimeoutException catch (e) {
    // ... エラーハンドリング
  }
}
```

**効果**:

- 認証済みユーザー: 自分のユーザードキュメントをクエリ（permission-denied回避）
- 未認証ユーザー: 公開ニュースをクエリ（誰でもアクセス可）
- 権限エラー完全解消

### デプロイ時のトラブル

#### Syntax Error #1 - 重複の閉じ括弧

**箇所**: Line 108
**エラー**: "Type 'on' not found" + 15+のエラー連鎖

```dart
// ❌ BEFORE (Line 107-108):
      }

      }  // ← 重複でtry-catch構造破壊

// ✅ AFTER (Line 107):
      }

      // 接続成功
```

**影響**:

- try-catchブロックが途中で閉じられ、exception handlerが孤立
- "Type 'on' not found"エラー（onキーワードがクラス外で使用されたように見える）
- メソッド未定義エラーが15+連鎖

**修正**: 重複の`}`を削除（260行 → 259行）

#### Syntax Error #2 - Final修飾子

**箇所**: Line 48
**エラー**: "The setter '\_currentStatus' isn't defined for the type 'NetworkMonitorService'"

```dart
// ❌ BEFORE (Line 48):
final NetworkStatus _currentStatus = NetworkStatus.online;

// ✅ AFTER (Line 48):
NetworkStatus _currentStatus = NetworkStatus.online;
```

**問題の発生経緯**:

1. Syntax Error #1修正後に再ビルド開始
2. コンパイル時に新しいエラー発見
3. Line 214の`_currentStatus = status;`が失敗
4. 原因: `_currentStatus`が`final`宣言されているため状態変更不可

**影響**:

- `_updateStatus()`メソッドで状態変更ができない
- すべてのネットワーク状態遷移がブロックされる
- Fix #2（自動リトライトリガー）が機能しない

**修正**: `final`キーワードを削除（259行 → 258行）

### デプロイ結果

**ビルド時間**: 124秒（Gradle assembleProdDebug）

**結果**:

- ✅ **コンパイル成功** - 全構文エラー解消
- ✅ **SH54Dへのインストール完了**
- ✅ **アプリ起動確認済み**（ユーザー確認: "起動しました"）
- 📅 **機能検証は翌日実施予定**（時間切れのため）

### 未検証項目（明日実施予定）

以下の項目は修正コードがデプロイされたが、動作確認は翌日実施：

- [ ] Fix #1: 初回接続チェック実行確認
- [ ] Fix #2: offline検出時の自動リトライ動作
- [ ] Fix #3: permission-deniedエラー解消確認
- [ ] バナー自動表示/非表示の動作確認
- [ ] グループ作成成功後のバナー消失確認
- [ ] 機内モードサイクルテスト（on→off→on）
- [ ] 手動リトライボタンの動作確認
- [ ] ログ出力内容の確認（全修正のログ検証）

### 技術的教訓

#### 複数バグの連鎖発見

1. **詳細ログ追加**: 実行フローを可視化することが重要
2. **ログ分析**: 「何が実行されているか」ではなく「何が実行されていないか」に注目
3. **段階的修正**: 1つずつバグを修正し、ビルド確認してから次へ

#### 構文エラーの連鎖

1. **重複括弧エラー**: try-catch編集時は括弧対応を慎重に確認
2. **final修飾子エラー**: mutableな状態フィールドには`final`使用不可
3. **複数エラーの隠蔽**: 1つ目のエラー修正後に2つ目が発覚することがある

#### ビルド時間の異常

- 通常60秒のビルドが124秒に延長
- 原因: 複数回の失敗ビルドでGradleキャッシュが不安定化
- 対策: 必要に応じて`flutter clean`実行を検討

### 変更ファイル

#### 主要変更

- `lib/services/network_monitor_service.dart` (226行 → 258行)
  - Bug #1-#3修正（3箇所）
  - Syntax Error #1-#2修正（2箇所）
  - 合計5箇所の修正

#### 補助変更

- `lib/widgets/network_status_banner.dart` (前セッションでログ強化済み)

### コミット情報

**コミットメッセージ（予定）**:

```
fix: NetworkMonitorService重大バグ修正3件 + 構文エラー修正2件

問題:
1. グループ作成成功後もオフラインバナーが消えない
2. リトライボタンが機能しない
3. SharedGroupsクエリでpermission-deniedエラー発生
4. デプロイ時にコンパイルエラー2件

修正内容:
- Fix #1: コンストラクタにFuture.microtask()追加（初回接続チェック）
- Fix #2: _updateStatus()にstartAutoRetry()呼び出し追加
- Fix #3: クエリ先をusers/{uid}に変更（permission-denied回避）
- Syntax Fix #1: 重複の'}'削除（try-catch構造修復）
- Syntax Fix #2: _currentStatusのfinal修飾子削除（状態変更可能に）

テスト結果: SH54Dでアプリ起動確認、機能検証は翌日実施
```

**ブランチ**: future
**関連コミット**: 4489b28, 93faa31（前セッションのオフライン処理実装）
