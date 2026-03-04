# 開発日報 - 2026年03月04日

## 📅 本日の目標

- [x] NetworkMonitorService 実機6テスト検証（2026-03-03から継続）
- [x] グループがFirestoreに保存されないバグの調査・修正
- [x] 総合実機テストチェックリスト セクション1・2 実施

---

## ✅ 完了した作業

### 1. NetworkMonitorService 実機テスト 全6項目 PASS ✅

**Background**: 前日（2026-03-03）にFIX 1〜4（Riverpod assertionエラー修正）をデプロイ済み

**実施テスト（SH-54D）**:

| テスト | 内容                              | 結果                     |
| ------ | --------------------------------- | ------------------------ |
| Test 1 | オンライン時の通常起動            | ✅ PASS                  |
| Test 2 | オフライン時の起動バナー表示      | ✅ PASS                  |
| Test 3 | Firestore接続成功後のバナー消去   | ✅ PASS                  |
| Test 4 | リトライボタン動作                | ✅ PASS                  |
| Test 5 | グループ作成成功後のバナー消去    | ✅ PASS（FIX 5-6適用後） |
| Test 6 | 継続的なオンライン/オフライン切替 | ✅ PASS                  |

**FIX 5-6（本日適用）**:

- グループ作成成功後に`reportFirestoreSuccess()`を呼び出していなかったためバナーが消えない問題を修正
- `lib/providers/purchase_group_provider.dart` AllGroupsNotifier.createNewGroup()に追加
- `lib/services/network_monitor_service.dart` reportFirestoreSuccess()メソッド追加

**テスト結果文書**: `docs/daily_reports/2026-03/network_monitor_test_20260304.md`

---

### 2. FIX 7: HybridSharedGroupRepository Firestore再初期化バグ修正 ✅

**Purpose**: グループ作成時にFirestoreに保存されず、Hive-onlyになる問題を修正

**発見経緯**: セクション1テスト中に「グループがFirestoreに保存されません」と判明

**Root Cause（起動時タイミング競合）**:

```
アプリ起動
  ↓
HybridSharedGroupRepository コンストラクタ
  ↓
_safeAsyncFirestoreInitialization() 非同期実行
  ↓
FirebaseAuth.instance.currentUser == null （← Firebase Authがセッション未復元）
  ↓
_firestoreRepo = null
_isInitialized = true  ← ここが問題！永続的にtrueになる
  ↓
Firebase Authが認証状態を復元（遅延）
  ↓
しかし _isInitialized = true のためリトライ機構が一切発動しない
  ↓
以降すべてのCRUD操作がHive-onlyパスに流れる ❌
```

**なぜ他のFirestore操作は成功していたか**:

- `UserInitializationService`は`HybridSharedGroupRepository`を使わず独自でFirestore接続を確立
- 同期処理はUserInitializationService経由のため問題なかった
- CRUDのみが影響を受けていた

**Solution (FIX 7)** (`lib/datastore/hybrid_purchase_group_repository.dart`):

```dart
// waitForSafeInitialization() 末尾に追加
// 🔥 FIX 7: アプリ起動時タイミング問題対策
// _firestoreRepo=null で初期化完了した場合でも、
// 現在認証済みであればFirestoreを再初期化する
if (_firestoreRepo == null) {
  final currentUser = FirebaseAuth.instance.currentUser;
  if (currentUser != null) {
    AppLogger.info('🔄 [HYBRID_REPO] 認証復帰検出 - Firestore再初期化試行');
    _isInitializing = false; // ガードリセット
    _isInitialized = false;  // 初期化完了フラグリセット
    await _safeAsyncFirestoreInitialization();
  }
}
```

**検証結果** (logcat):

```
🌐 [HYBRID_REPO] Firestore統合有効化完了 - ハイブリッドモード開始
🔥 [HYBRID_REPO] Firestore優先モード - Firestoreに作成
✅ [SYNC] Firestore→Hive同期完了: 2 同期, 0 スキップ
```

**Modified Files**:

- `lib/datastore/hybrid_purchase_group_repository.dart` (waitForSafeInitialization() 末尾)

**Status**: ✅ 修正完了・実機検証済み

---

### 3. 総合実機テストチェックリスト 作成 + セクション1・2 実施 ✅

**チェックリスト**: `docs/daily_reports/2026-03/final_device_test_checklist_20260304.md`（168項目・12セクション）

**セクション1（認証・アカウント管理 / 14項目）**:

- 合格: 13/14
- 確認事項: SharedPreferencesはサインアウト時にクリア不要（メールアドレス保存等のため）→ 仕様として許容

**セクション2（ホーム画面 / 8項目）**:

- 合格: 6/8
- ⚠️ アプリ起動時間: Firebase初期化3秒待機のため3秒以内は達成困難 → 仕様として許容
- ⚠️ オフラインバナー: 起動後に機内モードにした場合はFirestoreアクセスが発生するまで検出されない → データ不要時に余計なアクセス不要として許容

---

## 🐛 発見された問題

### FIX 7 発見済み・修正済み ✅

- **症状**: グループ作成後Firestoreに保存されない
- **原因**: HybridSharedGroupRepository起動時タイミング競合
- **対処**: waitForSafeInitialization()末尾に再初期化チェック追加
- **状態**: 修正・検証完了

---

## 📊 バグ対応進捗

### 完了 ✅

1. ✅ NetworkMonitorService FIX 1-4（Riverpod assertionエラー）- 2026-03-04
2. ✅ NetworkMonitorService FIX 5-6（グループ作成後バナー消えない）- 2026-03-04
3. ✅ FIX 7: HybridSharedGroupRepository Firestore再初期化 - 2026-03-04
4. ✅ QRスキャナー122pxオーバーフロー修正（検証完了: 2026-03-03）
5. ✅ ホワイトボードプレビュー継続監視バグ（2026-03-02）
6. ✅ 同一ユーザー他デバイス同期バグ（2026-03-02）

### 翌日継続 ⏳

- ⏳ 総合実機テストチェックリスト セクション3〜12（グループ管理〜）

---

## 📝 技術的学習事項

### Firebase Auth + Riverpod Provider の起動タイミング問題

**問題パターン**:

```dart
// コンストラクタで非同期初期化 → FirebaseAuthがまだ復元されていない
class HybridRepo {
  HybridRepo() {
    _safeAsyncFirestoreInitialization(); // currentUser == null の可能性大
  }
}
```

**正しい対策パターン**:

```dart
// 実際に使用するタイミングで再確認する
Future<void> waitForSafeInitialization() async {
  // ... 既存の初期化待機処理 ...

  // 末尾で認証状態を再確認
  if (_firestoreRepo == null && FirebaseAuth.instance.currentUser != null) {
    _isInitializing = false;
    _isInitialized = false;
    await _safeAsyncFirestoreInitialization(); // 再試行
  }
}
```

**教訓**: Providerのシングルトンは一度作成されると再利用されるため、起動時タイミング問題の影響が永続する。`waitForSafeInitialization()`などの「使用直前チェック」で補完する設計が安全。

---

## 🗓 翌日（2026-03-05）の予定

1. 総合実機テストチェックリスト セクション3〜12 実施
   - セクション3: グループ管理（22項目）
   - セクション4: 買い物リスト管理（20項目）
   - セクション5〜12: アイテム管理、QR招待、マルチデバイス、ホワイトボード等
2. テスト結果に応じたバグ修正対応
