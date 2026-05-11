# 開発日報 - 2026年5月11日

## 📅 本日の目標

- [x] プライバシーポリシー・利用規約を現仕様に同期（位置情報廃止・クローズドベータ削除・英語版修正）
- [x] CI/CD 失敗の原因調査と修正
- [x] Crashlytics ログ（4/29）の解決状況確認

---

## ✅ 完了した作業

### 1. プライバシーポリシー・利用規約の現仕様同期 ✅

**Purpose**: 実装から乖離していた法的ドキュメントを現状に合わせる

**Background**:

- `geolocator` による位置情報収集は `7c2aabe` で廃止済みだが、プライバシーポリシーには収集項目として残存
- クローズドベータテスト条項が正式公開後も残存
- 英語版が日本語版（2026-04-09）より古く、Sentry・TODOリストモード・Ansize 名義の統一が未反映

**Changes**:

日本語版：

- §1.4 位置情報セクション全削除
- §2.3「地域に関連する広告の表示」→「広告の表示」
- 最終更新日 → 2026年5月11日
- 第6条2・3項（位置情報最適化広告）削除
- 第9条5項（クローズドベータ）削除

英語版（日本語版に同期）：

- Last Updated → May 11, 2026
- Operator → Ansize Co., Ltd. / Lead Developer: maya27AokiSawada
- §1.2 TODO list mode 追記
- §1.4 Location Information セクション削除
- §3.1 Sentry (Windows crash reports) 追記
- §4.4 Sentry セクション追加
- Article 5.2「free plan with ads will also continue」追加
- Article 6 位置情報最適化条項削除
- Article 9 item 5（closed beta）削除

**Modified Files**:

- `docs/specifications/privacy_policy.md`
- `docs/specifications/terms_of_service.md`

**Commit**: `ff7ca9b` — docs: プライバシーポリシー・利用規約を現仕様に同期
**Status**: ✅ 完了・future + main にプッシュ済み

---

### 2. CI/CD 失敗修正: `F.appFlavor` セッター追加 ✅

**Purpose**: CI でコンパイルエラーになっていたテストコードを修正

**Problem / Root Cause**:

テストコードが `F.appFlavor = Flavor.dev;` のようにセッターで Flavor を上書きしていたが、`flavors.dart` の `F.appFlavor` はゲッターのみで定義されていた。

```dart
// ❌ ゲッターのみ → テストでのセット不可
class F {
  static Flavor get appFlavor { ... }
}
```

エラー:

```
test/datastore/hybrid_shared_list_repository_test.dart:579:7:
Error: Setter not found: 'appFlavor'.
    F.appFlavor = Flavor.dev;
```

**Solution**:

```dart
// ✅ テスト用のセッターを追加（本番動作は --dart-define から取得）
class F {
  static Flavor? _override;

  // ignore: avoid_setters_without_getters
  static set appFlavor(Flavor flavor) => _override = flavor;

  static Flavor get appFlavor {
    if (_override != null) return _override!;
    switch (_flavorFromEnv) { ... }
  }
}
```

**Modified Files**:

- `lib/flavors.dart` — `_override` フィールドとセッター追加

**Commit**: `747a946` — fix: F.appFlavorにテスト用セッターを追加
**Status**: ✅ 完了・future + main にプッシュ済み

---

### 3. テスト失敗修正: `Whiteboard.canEdit()` バグ ✅

**Purpose**: CI でテスト失敗していた `canEdit` ロジックを修正

**Problem / Root Cause**:

`canEdit()` が個人用ホワイトボード（`ownerId != null`）と判定した場合に `isPrivate` に関係なく常にオーナーのみ編集可としていた。
テストは `isPrivate=false` なら他ユーザーも編集可能を期待していた。

```dart
// ❌ 個人用の場合に isPrivate を無視していた
bool canEdit(String userId) {
  if (isPersonalWhiteboard) return ownerId == userId; // ← isPrivate 無視
  if (!isPrivate) return true;
  return ownerId == userId;
}
```

失敗テスト:

- `whiteboard_integration_test.dart: 個人用ホワイトボードのアクセス権限`
- `whiteboard_repository_test.dart: Whiteboard - canEdit判定（個人用）`

**Solution**:

```dart
// ✅ isPrivate のみで判定に統一
bool canEdit(String userId) {
  if (!isPrivate) return true;
  return ownerId == userId;
}
```

**Modified Files**:

- `lib/models/whiteboard.dart` — `canEdit()` を `isPrivate` 基準に統一

**Commit**: `f35c468` — fix: canEditをisPrivateで統一（個人用/グループ共通の区別を廃止）
**Status**: ✅ 完了・future + main にプッシュ済み

---

### 4. Crashlytics ログ（4/29）の解決状況確認 ✅

**Purpose**: `debug_info/26-04-29/` のログが未解決でないか確認

**Crash概要**:

- Version: 1.1.0 (build 8)
- エラー: `RenderFlex overflowed by 8.6 pixels on the right`
- 場所: `Row ← Padding ← DecoratedBox ← Container ← Column ← IntrinsicWidth ← ...`（メンバー情報ダイアログ）

**Status**: ✅ **解決済み**

- クラッシュ発生: 11:21
- 同日 11:28 のコミット `fa99b34`「fix: ロール変更ダイアログのオーバーフロー修正」で修正済み
- 修正内容: `member_tile_with_whiteboard.dart` の Row 内の子を `Expanded` でラップ、`TextOverflow.ellipsis` を適用

---

## 🐛 発見された問題

### CI/CD 失敗: F.appFlavor セッターなし ✅

- **症状**: テストファイルが `F.appFlavor = Flavor.dev` とセットしていたがコンパイルエラー
- **原因**: `flavors.dart` にセッターが未定義
- **対処**: セッター追加（本番動作に影響なし）
- **状態**: 修正完了

### テスト失敗: canEdit 判定バグ ✅

- **症状**: 個人用ホワイトボードで `isPrivate=false` でも `canEdit('other-user')` が `false`
- **原因**: 個人用/グループ共通で判定ロジックが分岐していた
- **対処**: `isPrivate` のみで統一
- **状態**: 修正完了

---

## 📊 バグ対応進捗

### 完了 ✅

1. ✅ RenderFlex オーバーフロー（メンバーダイアログ）（修正日: 2026-04-29）
2. ✅ F.appFlavor セッターなし → CI コンパイルエラー（修正日: 2026-05-11）
3. ✅ canEdit 個人用ホワイトボード判定バグ（修正日: 2026-05-11）

### 翌日継続 ⏳

- なし

---

## 💡 技術的学習事項

### `static get` だけのグローバル設定値はテストで上書きできない

**問題パターン**:

```dart
class F {
  static Flavor get appFlavor { /* --dart-define から取得 */ }
}
// テストで F.appFlavor = Flavor.dev; → コンパイルエラー
```

**正しいパターン**:

```dart
class F {
  static Flavor? _override;
  static set appFlavor(Flavor v) => _override = v;
  static Flavor get appFlavor => _override ?? /* 本番ロジック */;
}
```

**教訓**: テストで値を差し替えたいクラス変数には `_override` パターンでセッターを用意する。`setUp()` で `F.appFlavor = X;` と設定し、グループごとに明示的に上書きする。

---

### `canEdit` は isPrivate の単一フラグで制御する

個人用かグループ共通かで分岐するとテストと実装の認識がズレやすい。
ホワイトボードのアクセス制御は `isPrivate` のみで判断する。

```dart
// ❌ 個人用/グループ共通で分岐
bool canEdit(String userId) {
  if (isPersonalWhiteboard) return ownerId == userId;
  if (!isPrivate) return true;
  return ownerId == userId;
}

// ✅ isPrivate のみで判断
bool canEdit(String userId) {
  if (!isPrivate) return true;
  return ownerId == userId;
}
```

---

## 🗓 翌日（2026-05-12）の予定

1. CI 結果の確認（全テスト通過を確認）
2. App Store Connect の主な言語を英語(米国)に変更（日本語のフィールドに英語テキストが入っている状態の是正）

---

## 📝 ドキュメント更新

| ドキュメント                        | 更新内容                                             |
| ----------------------------------- | ---------------------------------------------------- |
| `instructions/30_whiteboard.md`     | `canEdit` の正しい仕様（isPrivate のみで判定）を明記 |
| `instructions/90_testing_and_ci.md` | `F.appFlavor` テスト用セッターパターンを追記         |
