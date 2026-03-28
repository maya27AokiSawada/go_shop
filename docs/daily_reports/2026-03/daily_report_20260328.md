# 開発日報 - 2026年03月28日

## 📅 本日の目標

- [x] 実機総合テスト セクション2（重点確認項目）を完走する
- [x] テストチェックリスト 2.4 をオフラインキャッシュ実装の現状に合わせて修正する
- [x] オフラインテスト（2.4）の logcat を分析し、動作を正確に理解する
- [ ] 実機総合テスト セクション3〜8 を実施する（→ 来週に持ち越し）

---

## ✅ 完了した作業

### 1. テストチェックリスト 2.4 の修正（3回改訂） ✅

**Purpose**: テスト項目 2.4 がオフラインキャッシュ（`PersonalWhiteboardCacheService`）の実際の実装と乖離していたため修正する

**Background**:
旧 2.4 は「保存失敗時にキャッシュへ退避」という誤った前提で書かれていた。
実際の実装では `PersonalWhiteboardCacheService`（SharedPreferences）が常時キャッシュを保持し、
Firestore への書き込みは `unawaited`（fire-and-forget）のため、オフライン中でも
Firestore ローカルキャッシュへの書き込みは即時成功して「保存しました」が表示される。

**Problem（改訂1 → 2 → 3 の経緯）**:

- **改訂1**: タイトルと説明を直したが、シナリオの順序が誤っていた
- **改訂2**: ユーザー指摘「ローカルキャッシュに書き込んだらユーザーには保存成功って出すようになってる」→ fire-and-forget で「保存しました」が即時表示されるシナリオに修正
- **改訂3**: ユーザー指摘「編集画面を閉じるときは保存することにしたはず」→ `_navigateToGroupDetail` 内の自動保存について、オフライン時はオフラインチェックでブロックされる点を明記したサブシナリオを追加

**Final State（正しい仕様）**:

```
メインシナリオ:
  ネットワーク切断中でも「保存しました」が即時表示される
  → unawaited (fire-and-forget) により Firestore ローカルキャッシュへの書き込みが即時成功
  → ネットワーク回復後に Firestore SDK が自動でサーバー同期

サブシナリオ（画面を閉じる場合）:
  _navigateToGroupDetail → _saveWhiteboard(silent: true) を実行
  NetworkMonitor がオフラインを検知していれば「ネットワーク障害のため保存できません」でスキップ
  Network Monitor の検知より前に auto-save が走った場合は fire-and-forget が成功
  → 実テストでは後者（仕様通りの動作）
```

**Modified Files**:

- `docs/daily_reports/2026-03/device_test_checklist_20260327~28.md`（2.4 全面書き直し）

**Status**: ✅ 完了

---

### 2. 実機テスト セクション2 完走 ✅

**Purpose**: 2026-03-25〜26 に実装した strokes サブコレクション化・fire-and-forget 保存・全消去同期修正・ネット障害後の再入保存修正を実機で検証する

**Background**: セクション 2.1〜2.3 は 2026-03-27（昨日）に完了済み。本日は 2.4〜2.6 を実施。

| テスト項目                                                        | 端末                   | 結果           |
| ----------------------------------------------------------------- | ---------------------- | -------------- |
| 2.4 fire-and-forget + Firestoreオフライン永続化（メインシナリオ） | Pixel 9（まや）        | OK             |
| 2.4 サブシナリオ（閉じる → 再入）                                 | Pixel 9（まや）        | OK（仕様通り） |
| 2.5 AppBar タイトル「○○さんのボード」                             | すもも / まや / しんや | OK             |
| 2.6 初回読み込みスピナー                                          | Pixel 9（まや）        | OK             |

**2.4 メインシナリオ logcat（抜粋）**:

```
✅ [SAVE] ローカル書き込み発火: ...
# ❌ [SAVE] バックグラウンド保存エラー は出ず
```

**2.4 サブシナリオ logcat 分析**:

```
14:23:58  ✅ [SAVE] ローカル書き込み発火  ← auto-save が fire-and-forget で成功
14:24:02  [SAVE] 未保存ストローク数: 0個 → 新しいストロークなし、保存をスキップ
14:28:58  Firestore WatchStream UNAVAILABLE (java.net.UnknownHostException)
          ← NetworkMonitor がオフライン検知したのはここ（約5分後）
```

**分析結論**: 閉じる操作時に NetworkMonitor はまだオフラインを検知しておらず、
auto-save fire-and-forget が Firestore ローカルキャッシュへの書き込みに成功し
`_unsavedStrokeIds` がクリアされた。
再入後は未保存ストロークが 0 件のため保存ボタンが無反応になったが、**仕様通りの正常動作**。
`PersonalWhiteboardCacheService` の pending 復元パスは NetworkMonitor がオフライン検知済みの状態でのみ発動するフォールバック設計であり、今回の挙動はその外側にある。

**Modified Files**:

- `docs/daily_reports/2026-03/device_test_checklist_20260327~28.md`（2.4〜2.6 結果記録）

**Commit**: `f256532`
**Status**: ✅ 完了・検証済み

---

### 3. WillPopScope → PopScope 移行（Flutter API マイグレーション） ✅

**Purpose**: 廃止予定の `WillPopScope` を `PopScope` に移行し、Flutter 最新 API への準拠を確立する

**Background**: `whiteboard_editor_page.dart` にて `WillPopScope` が使われていた。
`PopScope` は Flutter 3.20 以降で推奨される代替 API。

**Solution**:

```dart
// ❌ Before: WillPopScope（廃止予定）
WillPopScope(
  onWillPop: () async {
    await _navigateToGroupDetail();
    return false;
  },
  child: Scaffold(...),
)
```

```dart
// ✅ After: PopScope
PopScope(
  canPop: false,
  onPopInvoked: (didPop) async {
    if (didPop) return;
    await _navigateToGroupDetail();
  },
  child: Scaffold(...),
)
```

**挙動変化**: なし（終了時自動保存のロジックは同一）

**Modified Files**:

- `lib/pages/whiteboard_editor_page.dart`（`WillPopScope` → `PopScope` 移行）

**Commit**: `f256532`
**Status**: ✅ 完了

---

## 🐛 発見された問題

（なし）

---

## 📊 バグ対応進捗

### 完了 ✅

1. ✅ fire-and-forget 保存 + strokes サブコレクション化（2026-03-25）
2. ✅ 全消去の他端末反映修正（2026-03-25）
3. ✅ ネット障害後の再入保存修正（2026-03-26）
4. ✅ Pixel 9（まや）個人ボードが開かない問題（2026-03-27）
5. ✅ 初回読み込みスピナー（2026-03-27）
6. ✅ WillPopScope → PopScope マイグレーション（2026-03-28）

### 翌週継続 ⏳

- ⏳ 実機総合テスト セクション3〜8（3.1〜3.4, 4.1〜4.3, 5.1〜5.2, 6.1〜6.2, 7, 8）

---

## 💡 技術的学習事項

### Firestore fire-and-forget とオフライン永続化の組み合わせ

**問題パターン**:
「ネット断中に保存したのに、保存成功のメッセージが出た」という動作を「バグ」と誤解しやすい。

**正しい理解**:

```dart
// unawaited = Firestore SDK に発火するだけでレスポンスを待たない
// Firestore のオフライン永続化により、ローカルキャッシュへの書き込みは常に即時成功
unawaited(
  repository.addStrokesToSubcollection(...).catchError((e) {
    // このエラーが発生するのはキャッシュ書き込み自体が失敗するような
    // 重大なエラー時のみ（通常のオフライン操作では発生しない）
    if (mounted) SnackBarHelper.showError(context, '保存に失敗しました');
  }),
);
```

**教訓**: fire-and-forget + Firestore オフライン永続化の組み合わせでは、
「保存成功 UI 表示 = Firestore ローカルキャッシュへの書き込み成功」であり、
サーバー同期の完了ではない。これは意図した設計。

### NetworkMonitor の検知ラグ

**観察**: ネットワーク切断後、NetworkMonitor が `isOffline = true` を返すまでに数秒〜数分のラグがある。
Firestore の WatchStream UNAVAILABLE（java.net.UnknownHostException）が実際のオフライン信号。

**教訓**: オフラインテストでは「ネットワーク切断後すぐに操作する」と NetworkMonitor を回避して
fire-and-forget が成功することがある。これはバグではなく、検知ラグの仕様。

---

## 🗓 翌週（2026-03-31）の予定

1. 実機総合テスト セクション3.1〜3.4（ホワイトボード機能回帰テスト）
2. 実機総合テスト セクション4.1〜4.3（基本機能テスト）
3. 実機総合テスト セクション5.1〜5.2（通知システム）
4. 実機総合テスト セクション6.1〜6.2（データ同期）
5. 実機総合テスト セクション7（ニュース表示）
6. 実機総合テスト セクション8（iOS・ネットワーク監視バナー）

### テスト継続時の注意事項

- グループ共通ホワイトボードは廃止済み → 関連テスト項目はスキップ
- ビルドコマンド: `flutter build apk --debug --flavor prod` + `adb install`
- ログ監視: `adb -s 51040DLAQ001K0 logcat -d 2>&1 | Select-String "WATCH_STROKES|SAVE|REPO|LISTENER|MERGE|DELETE|PERSONAL_WB"`
- Git push: `git push origin future:oneness`（`git push origin oneness` は non-fast-forward になる場合がある）

---

## 📝 ドキュメント更新

| ドキュメント                                                      | 更新内容                                                                                                                   |
| ----------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------- |
| `docs/daily_reports/2026-03/device_test_checklist_20260327~28.md` | 2.4 シナリオ全面書き直し、2.4〜2.6 テスト結果記録                                                                          |
| 指示書更新: なし                                                  | 理由: 今日の作業（テスト実施・API マイグレーション）は仕様変更ではなく、`instructions/30_whiteboard.md` の内容はすでに正確 |
