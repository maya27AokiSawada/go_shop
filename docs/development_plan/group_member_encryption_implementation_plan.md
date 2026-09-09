# グループメンバー情報 暗号化 実装計画

## 1. 目的

`SharedGroups/{groupId}` ドキュメントに平文で保存されているメンバーの
**氏名（`members[].name`）と連絡先（`members[].contact`）**、および
それらの重複であるトップレベルの **`ownerName` / `ownerEmail`** を、
既存のグループ共通鍵で暗号化する。共有アイテム名（`SharedLists.items[].name`）と
同じ仕組みを踏襲する。

## 2. 決定事項（2026-09-09）

| 論点 | 決定 |
|---|---|
| 暗号化対象フィールド | `members[].name`、`members[].contact`、トップレベル `ownerName`、`ownerEmail` |
| 進め方 | 先に Firestore シリアライズを1コーデックへ一元化し、その1点に暗号化を差し込む |
| 鍵スキーム | グループ共通秘密（`groupId + groupKey` 由来、`memberUid` を含めない）。全メンバーが相互に読めるようにするため |
| `memberEmails` 配列 | 対象外（`firestore_shared_group_adapter.dart` のみが使用。現行の主経路では未使用） |
| `invitations` コレクションの `inviteeEmail` / `inviterName` | 対象外（別コレクション・別課題） |

## 3. 影響しないもの（調査結果）

- **Firestore セキュリティルール**: アクセス制御は `allowedUid`（UID 配列）ベース。
  メンバー名・連絡先は参照していないため暗号化しても影響なし。
- **招待メール**: クライアント側の `mailto:` 起動。宛先・氏名は `invitations`
  コレクションにあり、`SharedGroups.members[]` は参照しない。
- **バックアップ / リストア（`functions/`）**: `collectAllData` は中身をそのまま
  保存し、`restoreUser` は `ownerUid` のみで判定。暗号文でも問題なし。

## 4. アーキテクチャ

### 4.1 暗号プリミティブ（実装済み）

`GroupKeyExchangeService` に追加済み:

- `encryptGroupField({plaintext, groupId, groupKey?})` → 暗号エンベロープ（Base64）
- `decryptGroupField({ciphertext, groupId, groupKey?})` → 平文。新方式で失敗したら
  keyless 秘密でフォールバック
- `isEncryptedGroupField(value)` → エンベロープ判定（アイテム名と共通形式）
- `_deriveGroupFieldSecret({groupId, groupKey})` … seed = `group-field-v1:$groupId:$groupKey`

暗号エンベロープ（`{version, ciphertext, tag}` の JSON を Base64 化）はアイテム名と
共通なので、平文/暗号文の判別が確実に行える。

### 4.2 シリアライズの一元化（実装済み）

`lib/datastore/shared_group_firestore_codec.dart`:

- `GroupFieldCipher`（interface: encrypt / decrypt / isEncrypted）
- `SharedGroupFirestoreCodec({cipher})`
  - `memberToMap` / `memberFromMap` / `membersToMaps` / `membersFromMaps`
  - `groupToFirestore` / `groupFromMap` / `groupFromDoc`
  - `decryptGroup`（既に組み立て済みの `SharedGroup` を後段で復号するフック）
  - `cipher == null` なら平文のまま（既存挙動と等価）
  - 書き込み時: 空文字・暗号化済みはスキップ（二重暗号化防止）
  - 読み出し時: 暗号エンベロープでない値はそのまま返す（移行期の平文フォールバック）、
    復号失敗も生値を返す

`lib/datastore/group_field_cipher.dart`:

- `GroupKeyServiceFieldCipher` … `GroupKeyExchangeService` を `GroupFieldCipher` に適合させるアダプター

### 4.3 読み出しチョークポイントが無い問題（要注意）

グループの読み出しはリポジトリだけでなく、以下が **直接 `SharedGroups` を読んで**
`SharedGroup` を組み立てている:

- `lib/datastore/firestore_shared_group_repository.dart`（主経路）
- `lib/services/firestore_group_sync_service.dart`（×3 箇所）
- `lib/services/sync_service.dart`
- `lib/services/user_initialization_service.dart`（×2 箇所）
- `lib/services/notification_service.dart`
- `lib/services/firestore_migration_service.dart`（移行用・一過性）
- `lib/datastore/firestore_shared_group_adapter.dart`（レガシー・未使用想定）

そのため **復号を一斉に全読み出し経路へ入れないと、UI にメンバー名が暗号文で出る**。
部分導入は不可。

## 5. 実装フェーズ

### Phase 0: 基盤（✅ 完了）

- `encryptGroupField` / `decryptGroupField` / `isEncryptedGroupField`
- `SharedGroupFirestoreCodec` + `GroupKeyServiceFieldCipher`
- 単体テスト（`test/datastore/shared_group_firestore_codec_test.dart`,
  `test/services/group_key_exchange_field_test.dart`）15 件

### Phase 1: 全経路をコーデックへ差し替え（暗号化はまだ OFF）

各サイトの手組み `{'name': ..., 'contact': ...}` / `ownerName` / `ownerEmail` を
`SharedGroupFirestoreCodec`（`cipher: null`）経由に置換する。**この時点では挙動不変**。

対象:

- [ ] `firestore_shared_group_repository.dart`: `_groupToFirestore` / `_memberToFirestore` /
      `_groupFromFirestore` / `_memberFromFirestore` をコーデック委譲に
- [ ] `firestore_group_sync_service.dart`: 3 箇所の読み書き
- [ ] `sync_service.dart`: `members` 書き込み
- [ ] `user_initialization_service.dart`: 2 箇所（Hive→Firestore push）
- [ ] `notification_service.dart`: `members` 更新（L828 付近）
- [ ] `firestore_migration_service.dart`: 読み書き
- [ ] `firestore_shared_group_adapter.dart`: 委譲 or 明示的に非対応コメント
- [ ] `hybrid_shared_group_repository.dart`: Firestore 由来結果に `codec.decryptGroup` を通す

コーデックの provider を用意（`sharedGroupFirestoreCodecProvider`）。DI していない
サイトは `GroupKeyExchangeService()` から直接生成でも可（アイテム名実装と同様）。

### Phase 2: 復号を先行有効化（decrypt-only リリース）

- コーデックに常に cipher を注入する。
- **書き込みは平文のまま**（`groupToFirestore` の暗号化を feature フラグで OFF、または
  段階を分ける）。`_dec` は平文パススルーなので無害。
- 目的: 全クライアントが「暗号文が来ても復号できる」状態を先に配る。

### Phase 3: 書き込み暗号化を有効化

- `groupToFirestore` / `memberToMap` の暗号化を ON。
- 以後の書き込みは暗号文。既存ドキュメントは平文のまま（読みは Phase 2 で平文対応済み）。

### Phase 4: 既存データの再暗号化

アイテム名の `_reencryptAllItemsIfKeyChanged` に相当する処理を
`hybrid_shared_group_repository` に追加:

- グループ読み出し時、`members[].name` / `contact` / `ownerName` / `ownerEmail` に
  平文が混じっていて鍵が利用可能なら、暗号化して書き戻す。
- 鍵フィンガープリント変化時は全メンバー再暗号化（鍵ローテーション対応）。
- 再暗号化中フラグ（`keyReencryptionInProgress` / `keyRotationStatus`）は既存を流用。

### Phase 5: バリデーション

- `ValidationService.validateMemberName` / `validateMemberEmail` は既存メンバーとの
  重複チェックを行う。呼び出し前に**復号済みの `members`** を渡す（コーデック経由で
  読めば復号済みになる）。ロジック自体は変更不要の見込み。

## 6. 鍵の可用性（前提）

暗号化・復号ともローカルキャッシュ済みのグループ鍵を参照する。呼び出し前に
`GroupKeyExchangeService.getPersistedGroupKey(groupId: ...)` でキャッシュを温めること
（アイテム名暗号化と同じ）。鍵未設定のグループは平文のまま（`GroupKeyMode.plaintext`）。

- 招待中（pending）メンバーの行はオーナーが書く。オーナーは鍵を持つので暗号化可能。
- 参加直後で鍵交換未完のメンバーは、鍵取得までメンバー名が暗号文で見える可能性。
  → アイテム名と同じ既知の制約として許容。

## 7. テスト計画

- 単体（✅ 一部済み）: コーデックの往復、二重暗号化防止、平文フォールバック、
  復号失敗フォールバック、`ownerName/ownerEmail` 暗号化、`allowedUid` 非暗号化。
- 単体（追加）: 各サイト置換後、既存の repo テスト（`shared_group_repository_test.dart`,
  `hybrid_shared_group_repository_test.dart`, `integration_crud_test.dart`）が緑。
- 結合: 2 端末で グループ作成 → 招待 → 受諾 → メンバー一覧に平文表示、Firestore 上は暗号文。
- 移行: 平文メンバーを含む既存グループを開く → 再暗号化 → Firestore 値が暗号文へ、
  UI は平文表示。
- 鍵ローテーション後にメンバー欄が新鍵で再暗号化される。

## 8. リスク

| リスク | 対策 |
|---|---|
| 読み出し経路の取りこぼしで UI に暗号文 | Phase 1 で全経路をコーデック委譲。grep チェックリストで網羅確認 |
| 部分デプロイで旧クライアントが暗号文を読めない | Phase 2（decrypt-only）を必ず先に配布してから Phase 3 |
| 鍵未取得時の表示崩れ | 既知制約。復号失敗は生値表示にフォールバック（クラッシュしない） |
| `firestore_shared_group_adapter.dart` が実は生きている経路だった | 置換前に参照元を再確認。生きていれば委譲、死んでいれば削除 |
| バックアップに暗号文が入り復元後に鍵喪失で読めない | 鍵のバックアップ/復旧（`keyRecoveryEnvelopes`）は別途担保済み。要確認 |

## 9. 現在の状況（2026-09-09）

- ✅ Phase 0 完了（暗号プリミティブ + コーデック + 単体テスト 15 件）
- ⏳ Phase 1〜5 未着手
- 次アクション: Phase 1（`firestore_shared_group_repository.dart` から着手し、
  既存 repo テストが緑のまま委譲できることを確認 → 残りサイトへ展開）
