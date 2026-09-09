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

### Phase 1: 全経路をコーデックへ差し替え（暗号化はまだ OFF）✅ 完了

各サイトの手組み `{'name': ..., 'contact': ...}` / `ownerName` / `ownerEmail` を
`SharedGroupFirestoreCodec`（`cipher: null`）経由に置換した。**挙動不変**
（`encryptGroup` / `decryptGroup` は cipher なしなら同一インスタンスを返す）。

コーデックの共通取得口: `sharedGroupFirestoreCodec()`（`shared_group_firestore_codec.dart`
の module-level）。Phase 3 で `configureSharedGroupCodec(...)` に cipher 付きを渡すと
全サイトが一括で暗号化へ切り替わる。DI していないサイトもこれで対応。

書き込みサイト向けフック:
- `codec.encryptGroup(SharedGroup) -> SharedGroup` … owner/members を暗号化した写し
- `codec.encryptMembers(members, groupId:) -> List<SharedGroupMember>` … 独自マップ形状用

読み出しサイト向けフック:
- `codec.decryptGroup(SharedGroup) -> SharedGroup`
- `codec.decryptMembers(members, groupId:)`

対象と対応:

- [x] `firestore_shared_group_repository.dart`: `_groupToFirestore` / `_groupFromFirestore` を
      `codec.groupToFirestore` / `codec.groupFromDoc` に委譲。旧 `_memberToFirestore` /
      `_memberFromFirestore` / `_parseDateTime*` を撤去
- [x] `sync_service.dart`: 読み 2 箇所に `decryptGroup`、`_uploadGroupToFirestore` に `encryptGroup`
- [x] `user_initialization_service.dart`: 書き込み 2 箇所に `encryptGroup`、Firestore→Hive 反映に `decryptGroup`
- [x] `notification_service.dart`: 招待受諾時のメンバー追記 write に `encryptMembers`
      （L1033 / L1533 の read は `memberId` / `allowedUid` しか見ないので変更不要）
- [x] `firestore_migration_service.dart`: `_groupToFirestore` に `encryptGroup`
- [x] `firestore_group_sync_service.dart`: `watchUserGroups`（`SharedGroups` 監視）に `decryptGroup`。
      `groups`（旧コレクション）系の `_fetchUserGroups` / `syncGroup` / `saveGroupToFirestore` は対象外
- [x] `firestore_helper.dart`: `fetchGroup` / `fetchUserGroups` に `decryptGroup`
- [x] `enhanced_invitation_service.dart`: `SharedGroup.fromJson` 3 箇所に `decryptGroup`、
      `updatedGroup.toJson()` 2 箇所に `encryptGroup`
- [x] `firestore_shared_group_adapter.dart`: レガシー・未参照。ヘッダーコメントで明示（未対応）
- [x] `hybrid_shared_group_repository.dart`: 直接 Firestore を読まず `_firestoreRepo` 経由なので変更不要

変更不要と確認したもの:

- `qr_invitation_service.dart`: `SharedGroups` へのアクセスは `invitations` サブコレクションと
  `ownerUid` の読みのみ。members 名/連絡先には触れない
- `invitation_monitor_service.dart`: `ownerUid` 読み + `allowedUid` 更新のみ
- `notification_service.dart` の 2 つの read（一斉通知 / ホワイトボード通知）

### Phase 2: 復号を先行有効化（decrypt-only リリース）

- コーデックに常に cipher を注入する（`configureSharedGroupCodec`）。
- cipher アダプターには **`ref.read(groupKeyExchangeServiceProvider)` のシングルトン**を渡す。
  `GroupKeyServiceFieldCipher(GroupKeyExchangeService())` のように `new` すると別インスタンス＝
  別 `_groupKeyCache` になり、アイテム名側で温めた鍵が効かない（現状の
  `group_field_cipher.dart` の例はこの誤りなので Phase 2 で修正）。
- **書き込みは平文のまま**（`encryptGroup` / `memberToMap` の暗号化を feature フラグで OFF、
  または段階を分ける）。`_dec` は平文パススルーなので無害。
- 目的: 全クライアントが「暗号文が来ても復号できる」状態を先に配る。

#### Phase 2 の必須要件：鍵の取得タイミング（2026-09-09 の設計議論）

「参加時＋鍵更新通知受信時」だけでは**不十分**。鍵マテリアルを受け取るタイミングとしては
正しいが、復号を成立させるには以下が必要（アイテム名暗号化が既にやっていることと同じ）。

1. **グループ読みの choke point で毎回ローカル永続鍵をキャッシュへ再ロードする**
   `GroupKeyExchangeService._groupKeyCache` はプロセス内のみ。アプリ再起動で空になる。
   鍵が SharedPreferences に残っていても `getPersistedGroupKey(groupId:)` を呼ぶまで
   キャッシュに載らない。`decryptGroup()` は現在**同期**でキャッシュ直読みのため、
   再起動後の最初の読みは空鍵→ keyless フォールバックも失敗→暗号文が UI に出る。
   - 対応案: `decryptGroup` の**非同期版**を用意し、内部で
     `await keyService.getPersistedGroupKey(groupId:)` を先に呼ぶ。または
     `firestore_group_sync_service.watchUserGroups` /
     `user_initialization_service`（Firestore→Hive）/ `firestore_helper` /
     `enhanced_invitation_service` のループで groupId ごとに 1 回 prime する。

2. **メンバー情報の最初の表示入口（グループ一覧 / メンバー管理画面ロード）でも鍵解決を呼ぶ**
   現状の鍵解決（`resolveGroupKeyForMember` / `hasUsableGroupKey` /
   `shouldRefreshGroupKey`）は主に `shared_list_page.dart`（共有リストを開いたとき）と
   通知受信時（`notification_service.dart:638`）。グループ一覧・メンバー管理画面は
   それより手前でメンバー `name` / `contact` を表示するため、そこでも解決が要る。

3. **読み時の世代チェックで自己修復**
   オフライン中に鍵更新通知を取りこぼすとローカル鍵が旧世代。読み時に
   フィンガープリント / `keyVersion` 不一致を検出して再取得する
   （アイテムの `_reencryptAllItemsIfKeyChanged` / `shouldRefreshGroupKey` 相当）。

4. **2 台目の端末 / 再インストール**
   参加操作は端末 A で発生済みのため端末 B に永続鍵がない。`resolveGroupKeyForMember`
   （recovery envelope）で取り直しが必要だが、それは端末 B で「どこか」が呼ばないと
   走らない。上記 1・2 の prime 経路がこれも兼ねる。

現状の鍵取得ポイント（参考）:

| タイミング | 処理 | 場所 |
|---|---|---|
| 参加（受諾） | 鍵交換で取得・永続化 | `handleAcceptedInvitation` |
| 通知受信 | `shouldRefreshGroupKey` → `resolveGroupKeyForMember` | `notification_service.dart:638` |
| 共有リスト画面を開く | `hasUsableGroupKey` / `resolveGroupKeyForMember`（世代チェック） | `shared_list_page.dart` |
| アイテムを読むたび | `getPersistedGroupKey` でキャッシュ再ロード | `_decryptListForRead` |

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

- ✅ Phase 0 完了（暗号プリミティブ + コーデック + 単体テスト）
- ✅ Phase 1 完了（全 `SharedGroups` 読み書き経路をコーデック経由に統一。cipher なし＝挙動不変。
  `flutter analyze lib/` で新規警告なし、`flutter test test/datastore/` ほか 173 件緑）
- ✅ Phase 2 の設計方針を確定（鍵取得タイミング。上記 5.Phase 2 に反映）
- ⏳ Phase 2 実装〜Phase 5 未着手
- 次アクション: Phase 2 実装
  1. `group_field_cipher.dart` を provider シングルトンの `GroupKeyExchangeService` を
     受け取る形に修正
  2. `decryptGroup` の非同期版（内部で `getPersistedGroupKey` を prime）を追加
  3. `firestore_group_sync_service` / `user_initialization_service` / `firestore_helper` /
     `enhanced_invitation_service` の read 経路を非同期 prime 版へ差し替え
  4. グループ一覧 / メンバー管理画面ロードで鍵解決を呼ぶ
  5. `configureSharedGroupCodec` をアプリ初期化で 1 回呼ぶ（decrypt-only）

### Phase 1 の残注意点

- `sharedGroupFirestoreCodec()` は module-level のミュータブル状態。テスト分離のため
  `resetSharedGroupCodec()` を用意済み。
- Phase 3 で cipher を注入する箇所（アプリ初期化のどこで `configureSharedGroupCodec` を呼ぶか、
  グループ鍵キャッシュの temperature 管理）は Phase 2/3 で設計する。
