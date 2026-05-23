# 開発日報 - 2026年5月23日

## 📅 本日の目標

- [x] Android prod の Firebase プロジェクト設定不一致を切り分ける
- [x] 配布運用（Internal testing）の取り扱い方針を確認する
- [x] ビルド番号を `16` へ更新して反映する
- [ ] サインイン後の current group / current list 未選択不具合を修正する（明日対応）

---

## ✅ 完了した作業

### 1. Android prod Firebase 設定の差分確認 ✅

**Purpose**: Windows 環境と Mac 環境で Android prod が参照する Firebase Project ID の一致状況を確認する

**Background**:

QR 招待やデータ参照不整合の再発防止のため、prod 環境の Firebase 接続先を再点検した。

**Problem / Root Cause**:

```json
// ❌ Mac 側で確認された内容（ユーザー提供）
"project_id": "goshopping-48db9"
```

Windows 側の `prod` は `go-shopping-61515` を参照しており、環境間で不一致だった。

**Solution**:

- Windows 側の `prod` 設定を確認し、`go-shopping-61515` であることを再確認
- Mac 側は `goshopping-48db9` が残存していると判明し、差し替え対象を明確化

**検証結果**:

| 確認項目                                | 結果                |
| --------------------------------------- | ------------------- |
| Windows Android prod `project_id`       | `go-shopping-61515` |
| Mac 側（ユーザー提供 JSON）`project_id` | `goshopping-48db9`  |
| 判定                                    | 環境不一致を確認    |

**Modified Files**:

- なし（本作業は切り分け・確認のみ）

**Status**: ✅ 完了（原因切り分けまで）

---

### 2. Internal testing 配布の運用確認 ✅

**Purpose**: 誤設定ビルドを Internal testing に上げた場合のリカバリ方針を整理する

**Background**:

Play Console は同一 versionCode の再アップロード不可であるため、再配布の手順確認が必要だった。

**Solution**:

- 既存公開の完全取り消しではなく、`build-number` を上げた新規 AAB で置き換える運用が必要と確認
- GitHub Actions 側は本日ユーザーが修正済みである前提を確認

**Modified Files**:

- なし（方針確認のみ）

**Status**: ✅ 完了

---

### 3. ビルド番号更新（`1.1.0+16`）✅

**Purpose**: Internal testing への再アップロードに必要な build number 更新を反映する

**Solution**:

```yaml
# ✅ pubspec.yaml
version: 1.1.0+16
```

- `pubspec.yaml` のバージョンを `1.1.0+15` から `1.1.0+16` に更新
- コミットおよび `future` へのプッシュを実施

**Modified Files**:

- `pubspec.yaml`

**Commit**: `61b6345` (`chore: bump build number to 16`)
**Status**: ✅ 完了・プッシュ済み

---

## 🐛 発見された問題

### 既存アカウント・既存グループでサインイン時に current group / current list が未選択になる ⚠️

- **症状**: 既にアカウントとグループが存在する状態でサインインすると、カレントグループとカレントリストが選択されない
- **原因**: 調査中（本日は実装停止）
- **対処**: 明日、サインイン後の初期選択処理（group/list 選択ロジック）の呼び出し経路を調査予定
- **状態**: 未着手（報告のみ）

---

## 📊 バグ対応進捗

### 完了 ✅

1. ✅ ビルド番号更新（`1.1.0+16`）反映（完了日: 2026-05-23）

### 対応中 🔄

1. 🔄 既存データありサインイン時の current group / current list 未選択（Priority: High）

### 翌日継続 ⏳

- ⏳ サインイン後の初期選択フローの再現・原因特定・修正方針確定

---

## 💡 技術的学習事項

### Play Internal testing の復旧は versionCode 増分が前提

**問題パターン**:

```text
同じ versionCode で再アップロードしようとして失敗する
```

**正しいパターン**:

```text
build-number (Android versionCode) を増やして新しいAABを作成し、トラックを置き換える
```

**教訓**: 配布後の差し替え前提運用では、ビルド番号管理を先に確定してから再配布する。

---

## 🗓 翌日（2026-05-24）の予定

1. 既存アカウント/既存グループ状態でのサインイン再現テスト（ログ採取）
2. current group / current list 初期選択処理の呼び出し順を確認
3. 修正方針を確定し、最小変更で対応を実施

---

## 📝 ドキュメント更新

| ドキュメント                                          | 更新内容                                                                  |
| ----------------------------------------------------- | ------------------------------------------------------------------------- |
| `docs/daily_reports/2026-05/daily_report_20260523.md` | 本日の作業日報を新規作成                                                  |
| （更新なし）                                          | 理由: 仕様変更や実装変更は最小（`pubspec.yaml` の build number 更新のみ） |
