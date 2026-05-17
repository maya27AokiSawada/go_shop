# 開発日報 - 2026年5月17日

## 📅 本日の目標

- [x] 初回グループ作成時の赤画面（`_dependents.isEmpty`）を根本解消
- [x] シングルモードでグループ1件以上のときFABをグレーアウト

---

## ✅ 完了した作業

### 1. InitialSetupWidget廃止 — 初回グループ作成の赤画面を根本解消 ✅

**Purpose**: サインアップ後の最初のグループ作成時に発生する `_dependents.isEmpty` 赤画面を根本から解消する

**Background**:

`SharedGroupPage` はシングルモードでグループ0件のとき `InitialSetupWidget` を表示し、グループ作成後に `GroupListWidget` へ切り替えるパターンを採用していた。この「特殊ダイアログ → 通常リスト」への急速なウィジェットツリー置換が Riverpod の依存関係クリーンアップタイミングと衝突し、assertion error を引き起こしていた。

```
Failed assertion: line 6268 pos 12: '_dependents.isEmpty': is not true
```

**Solution**:

`InitialSetupWidget` を `SharedGroupPage` から完全に削除し、グループ数に関わらず常に `GroupListWidget` を表示する方針に転換。空状態の案内テキスト（グループ作成 or QRコードスキャンを促すUI）は `GroupListWidget` 内が既に担当しているため追加実装不要。

```dart
// ❌ 旧実装: isSingle分岐でInitialSetupWidgetを表示（赤画面の原因）
if (isSingle) {
  body = groupsAsync.when(
    data: (groups) => groups.isEmpty
        ? const InitialSetupWidget()   // ← ウィジェットツリー急速置換でクラッシュ
        : const SafeArea(child: GroupListWidget()),
    ...
  );
}

// ✅ 新実装: 常にGroupListWidget（空状態はWidget内テキストで案内）
return Scaffold(
  body: const SafeArea(
    child: Padding(padding: EdgeInsets.all(16.0), child: GroupListWidget()),
  ),
  ...
);
```

**効果**:

- `InitialSetupWidget` の import・使用箇所を完全削除
- `isSingle` 分岐 50行超を削除してコードをシンプル化（76行削除・30行追加）
- ウィジェットツリーの急速置換がなくなり赤画面が発生しない

**Modified Files**:

- `lib/pages/shared_group_page.dart`（InitialSetupWidget完全削除・体全体を簡素化）

**Commit**: `f1f2e02`
**Status**: ✅ 完了

---

### 2. シングルモードでグループ1件以上のときFABをグレーアウト ✅

**Purpose**: シングルモードでは1グループのみ使用するため、グループが存在する状態での追加作成・QRスキャン参加を UI レベルで抑制する

**Problem**:

`InitialSetupWidget` 廃止に伴い、シングルモードでも FAB（グループ作成・QRスキャン）が常時表示されるようになった。グループ0件のときは操作を促すべきだが、1件以上あるときは操作できないことを明示する必要がある。

**Solution**:

`allGroupsProvider` と `appUIModeProvider` を監視し、`isSingle && groupCount >= 1` のとき `onPressed: null`（Flutter の標準無効化）と色の明示変更でグレーアウトを実装。

```dart
final isSingle = ref.watch(appUIModeProvider) == AppUIMode.single;
final groupCount = ref.watch(allGroupsProvider).valueOrNull?.length ?? 0;
final fabDisabled = isSingle && groupCount >= 1;

FloatingActionButton(
  onPressed: fabDisabled ? null : () { /* QRスキャン */ },
  ...
),
FloatingActionButton.extended(
  onPressed: fabDisabled ? null : () => _showCreateGroupDialog(context),
  backgroundColor: fabDisabled ? Colors.grey.shade300 : Colors.blue,
  foregroundColor: fabDisabled ? Colors.grey.shade500 : Colors.white,
  ...
),
```

**動作まとめ**:

| 状態 | FAB |
|---|---|
| シングルモード・グループ0件 | ✅ 有効（青・タップ可） |
| シングルモード・グループ1件以上 | 🔘 グレーアウト・タップ不可 |
| マルチモード | ✅ 常時有効 |

**Modified Files**:

- `lib/pages/shared_group_page.dart`（FABグレーアウトロジック追加）

**Commit**: `426ceff`
**Status**: ✅ 完了

---

## 🐛 発見された問題

（なし）

---

## 📊 バグ対応進捗

### 完了 ✅

1. ✅ QR招待クロスデバイス参加バグ（2026-05-14）
2. ✅ iOS prod Firebase プロジェクトID不一致（2026-05-15）
3. ✅ グループ作成時のwidgetライフサイクルエラー・createNewGroup重複追加（2026-05-15）
4. ✅ アカウント削除スピナー残留・再認証ダイアログオーバーフロー（2026-05-16）
5. ✅ 初回グループ作成の赤画面（`_dependents.isEmpty`）根本解消（2026-05-17）

### 対応中 🔄

（なし）

### 翌日継続 ⏳

- ⏳ QRクロスデバイス招待フロー実機テスト（iOS prod → Android prod）

---

## 💡 技術的学習事項

### InitialSetupWidget → GroupListWidget 空状態への移行パターン

**問題パターン**: 特殊ウィジェット（InitialSetupWidget）と通常ウィジェット（GroupListWidget）をプロバイダ値の変化で切り替えると、Riverpod の依存関係クリーンアップタイミングとウィジェットツリー置換が衝突してクラッシュする。

**正しいパターン**: 空状態UIを表示するウィジェット（GroupListWidget）に内包させ、**常に同じウィジェットを表示する**。ウィジェットツリーの構造が変わらないためクラッシュしない。

**教訓**: `when(data: (items) => items.isEmpty ? WidgetA() : WidgetB())` パターンは、WidgetA→WidgetB 切り替え時に widget scope assertion error を引き起こす可能性がある。空状態テキストは表示し続けるウィジェット内に持たせること。

---

## 🗓 翌日（2026-05-18）の予定

1. QRクロスデバイス招待フロー実機テスト（iOS prod → Android prod）
2. 問題があればデバッグ・修正
