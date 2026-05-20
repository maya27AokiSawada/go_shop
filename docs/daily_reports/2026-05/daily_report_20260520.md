# 開発日報 - 2026年5月20日

## 📅 本日の目標

- [x] サインアップ後のデフォルトリスト名を英語モードで適切に表示する
- [x] デフォルトリストが二重作成される不具合を解消する
- [x] GitHub Actions の build number 採番仕様を確認する
- [x] Play Console 自動アップロード（`PLAY_SERVICE_ACCOUNT_JSON`）の設定手順を整理する

---

## ✅ 完了した作業

### 1. 英語モード時のデフォルトリスト名をローカライズ ✅

**Purpose**: 英語UIで新規作成されるデフォルトリスト名を日本語固定から英語表示に修正する

**Background**:

サインアップ直後に作成されるデフォルトリスト名が、英語モードでも `買い物リスト` のままになっていた。

**Problem / Root Cause**:

```dart
// ❌ 問題: デフォルト名がローカライズされず、実質ハードコード扱い
final defaultListName = '買い物リスト';
```

**Solution**:

```dart
// ✅ 修正: l10nキー経由で言語に応じた名前を取得
final defaultListName = texts.defaultShoppingListName;
```

- `AppTexts` 抽象クラスに `defaultShoppingListName` を追加
- 日本語/英語実装をそれぞれ追加
  - ja: `買い物リスト`
  - en: `Shopping list`

**Modified Files**:

- `lib/l10n/app_texts.dart`（`defaultShoppingListName` 追加）
- `lib/l10n/app_texts_ja.dart`（日本語文言追加）
- `lib/l10n/app_texts_en.dart`（英語文言追加）

**Status**: ✅ 完了・静的解析エラーなし

---

### 2. デフォルトリスト二重作成バグの解消 ✅

**Purpose**: サインアップ後に同じグループへデフォルトリストが2件作成される問題を防止する

**Background**:

デフォルトリスト生成が複数経路（初期作成ダイアログとフォールバック処理）に存在し、同時実行タイミングで重複し得る状態だった。

**Problem / Root Cause**:

```dart
// ❌ 問題: 経路ごとに新規作成しうるため、二重作成の可能性
await listRepo.createSharedList(...);
```

**Solution**:

```dart
// ✅ 修正: 既存チェック + 決定的IDで冪等化
final existingLists = await listRepo.getSharedListsByGroup(newGroupId);
final targetList = existingDefault ??
    (existingLists.isNotEmpty
        ? existingLists.first
        : await listRepo.createSharedList(
            ownerUid: uid,
            groupId: newGroupId,
            listName: defaultListName,
            customListId: 'default_$newGroupId',
          ));
```

- 作成前にグループ内既存リストをチェック
- 決定的ID `default_$groupId` を付与して冪等性を強化
- 既存リストがある場合は再利用し、新規作成を抑止

**Modified Files**:

- `lib/widgets/single_group_creation_dialog.dart`（初期作成フロー冪等化）
- `lib/pages/shared_list_page.dart`（フォールバック作成処理の統一）

**Commit**: `2009c9e`
**Status**: ✅ 完了・`oneness` へ push 済み

---

### 3. GitHub Actions の build number 運用確認 ✅

**Purpose**: CI/CDの build number が `pubspec.yaml` とどう連動するかを明確化する

**確認内容**:

- `main-release.yml` の `prepare` ジョブで以下を算出

```bash
echo "value=$((10000 + GITHUB_RUN_NUMBER))" >> "$GITHUB_OUTPUT"
```

- downstream ジョブで `--build-number="$BUILD_NUMBER"` を指定
- `pubspec.yaml` の `+14` はローカル既定値であり、Actions実行時は上書きされる

**Status**: ✅ 理解・運用方針を確定

---

### 4. Play Console 自動アップロード設定の整理 ✅

**Purpose**: `PLAY_SERVICE_ACCOUNT_JSON` を使った internal track 自動配布の前提を整える

**実施内容**:

- Play Console のユーザー/権限設定を確認
- サービスアカウントが有効状態であることを確認
- 必要権限の妥当性を確認（internal track向け）
- 組織ポリシー `Disable service account key creation` により JSON鍵発行がブロックされるケースの対処手順を整理

**Status**: ✅ 方針確定（鍵発行ポリシーの解除/管理者対応が次アクション）

---

## 🐛 発見された問題

### サービスアカウント鍵(JSON)作成が組織ポリシーでブロック ⚠️

- **症状**: `Disable service account key creation` により鍵作成不可
- **原因**: 組織レベル制約 `constraints/iam.disableServiceAccountKeyCreation` が有効
- **対処**: 対象プロジェクトで一時的に `Not enforced` にするか、管理者に鍵作成を依頼
- **状態**: 対応方針は確定、実作業は継続中

---

## 📊 バグ対応進捗

### 完了 ✅

1. ✅ QR招待クロスデバイス参加バグ（2026-05-14）
2. ✅ iOS prod Firebase プロジェクトID不一致（2026-05-14）
3. ✅ watchUserGroups 旧コレクション名参照（2026-05-14）
4. ✅ ウィジェットライフサイクルエラー・createNewGroup 重複追加（2026-05-15）
5. ✅ アカウント削除スピナー残留・再認証ダイアログオーバーフロー（2026-05-16）
6. ✅ 初回グループ作成の赤画面（`_dependents.isEmpty`）根本解消（2026-05-17）
7. ✅ シングルモードグループ作成後デフォルトリスト未作成（2026-05-18）
8. ✅ 英語モードでのデフォルトリスト名不一致（2026-05-20）
9. ✅ デフォルトリスト二重作成（2026-05-20）

### 対応中 🔄

1. 🔄 Play Console 連携用サービスアカウント鍵の発行（組織ポリシー調整待ち）

### 翌日継続 ⏳

- ⏳ `PLAY_SERVICE_ACCOUNT_JSON` を GitHub Environment Secret（`production-release`）へ登録
- ⏳ `main` push で `Main Release (Pages + Stores)` の Android upload 成功を確認

---

## 💡 技術的学習事項

### デフォルトデータ生成は「決定的ID + 既存チェック」で冪等化する

**問題パターン**:

```dart
// ❌ 複数経路から単純createすると重複しやすい
await repo.createSharedList(...);
```

**正しいパターン**:

```dart
// ✅ 既存確認 + customListId固定で重複を防ぐ
final existing = await repo.getSharedListsByGroup(groupId);
if (existing.isEmpty) {
  await repo.createSharedList(customListId: 'default_$groupId', ...);
}
```

**教訓**: 初期化系処理は再実行される前提で設計し、作成API呼び出しは必ず冪等化する。

---

## 🗓 翌日（2026-05-21）の予定

1. 組織ポリシー調整後にサービスアカウントJSON鍵を発行
2. `PLAY_SERVICE_ACCOUNT_JSON` を `production-release` に登録
3. `main` ブランチで GitHub Actions を実行し internal track アップロードを検証
4. 失敗時は Play Console 権限と track 設定を再点検

---

## 📝 ドキュメント更新

| ドキュメント                                          | 更新内容                                                                                           |
| ----------------------------------------------------- | -------------------------------------------------------------------------------------------------- |
| `docs/daily_reports/2026-05/daily_report_20260520.md` | 本日の作業日報を新規作成                                                                           |
| 指示書更新                                            | なし（理由: 本日の変更は既存仕様の不具合修正・運用確認が中心で、共通ルールの新設までは不要と判断） |
