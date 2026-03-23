# models — ファイル一覧と役割

Freezed・Hive・Firestore の 3 つのアノテーションを組み合わせたデータモデルを格納するフォルダです。

---

## Hive TypeId 一覧

| TypeId | クラス名                   |
| ------ | -------------------------- |
| 0      | `SharedGroupRole`（enum）  |
| 1      | `SharedGroupMember`        |
| 2      | `SharedGroup`              |
| 3      | `SharedItem`               |
| 4      | `SharedList`               |
| 6      | `UserSettings`             |
| 7      | `AcceptedInvitation`       |
| 8      | `InvitationStatus`（enum） |
| 9      | `InvitationType`（enum）   |
| 10     | `SyncStatus`（enum）       |
| 11     | `GroupType`（enum）        |
| 12     | `ListType`（enum）         |
| 15     | `DrawingStroke`            |
| 16     | `DrawingPoint`             |
| 17     | `Whiteboard`               |

> **空き番号**: 5、13、14、18 以降

---

## ファイル一覧

### ソースファイル

| ファイル名                                                 | 主なクラス                                                        | HiveTypeId                 | 役割                                                                                                                                                                                                                                                                                                        |
| ---------------------------------------------------------- | ----------------------------------------------------------------- | -------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [shared_group.dart](shared_group.dart)                     | `SharedGroup` / `SharedGroupMember` / `SharedGroupRole` / 各 enum | 0〜2、8〜11                | グループの中核モデル。`SharedGroup` はグループ ID・名前・オーナー UID・`allowedUid` リスト・メンバーリスト・同期状態・グループ種別を保持する。`SharedGroupMember` は 1 名分のメンバー情報（ID・名前・ロール・招待状態・タイムスタンプ）を保持する。                                                         |
| [shared_list.dart](shared_list.dart)                       | `SharedList` / `SharedItem` / `ListType`                          | 3、4、12                   | リストとアイテムのモデル。`SharedItem` は名前・数量・購入済みフラグ・論理削除フィールド（`isDeleted` / `deletedAt`）・UUID `itemId` などを持つ。`SharedList` はアイテムを `Map<String, SharedItem>` として保持し差分同期を可能にする。`activeItems` ゲッターで論理削除済みを除外できる。                    |
| [user_settings.dart](user_settings.dart)                   | `UserSettings`                                                    | 6                          | ユーザーローカル設定。ユーザー名・ID・メール・最終使用グループ／リスト ID・アプリモード（0=買い物/1=TODO）・通知設定・ホワイトボードカスタムカラー（ARGB int） を Hive に永続化する。                                                                                                                       |
| [accepted_invitation.dart](accepted_invitation.dart)       | `AcceptedInvitation` / `FirestoreAcceptedInvitation`              | 7                          | 招待受諾レコード。Hive 保存用の `AcceptedInvitation`（Freezed）と Firestore パス `/users/{inviterUid}/acceptedInvitations/{acceptorUid}` 読み書き用の `FirestoreAcceptedInvitation`（通常クラス）の 2 つを定義する。                                                                                        |
| [invitation.dart](invitation.dart)                         | `Invitation`                                                      | なし（Firestore のみ）     | QR 招待トークンのモデル。Firestore パス `/invitations/{token}` に保存する。`groupId` / `groupName` / `inviterName` / `createdAt` / `expiresAt` / `maxUses` / `currentUses` / `usedBy` / `securityKey` を持ち、QR バリデーションに使用する。`remainingUses` / `isValid` / `isExpired` のゲッターを提供する。 |
| [whiteboard.dart](whiteboard.dart)                         | `Whiteboard` / `DrawingStroke` / `DrawingPoint`                   | 15〜17                     | ホワイトボード機能の 3 層モデル。`DrawingPoint`（座標）→ `DrawingStroke`（点の集合＋色・太さ・作者情報）→ `Whiteboard`（ストローク一覧＋共有／個人判定）の入れ子構造。`ownerId == null` でグループ共有、値ありで個人用を表す。                                                                              |
| [permission.dart](permission.dart)                         | `Permission`                                                      | なし（静的ユーティリティ） | 8 ビットビットマスクによる権限管理。`READ` / `DONE` / `COMMENT` / `ITEM_CREATE` / `LIST_CREATE` / `MEMBER_INVITE` / `ADMIN` などのフラグ定数と、`VIEWER` / `CONTRIBUTOR` / `EDITOR` / `MANAGER` / `FULL` のプリセットを提供する。`hasPermission` / `canXxx()` などの操作メソッドを持つ。                    |
| [group_structure_config.dart](group_structure_config.dart) | `GroupStructureConfig` / `OrganizationConfig` / `GroupConfig` 等  | なし（JSON のみ）          | グループ階層の宣言的設定モデル。`GroupStructureConfig` → `OrganizationConfig` → `GroupConfig` → `MemberConfig` / `ListConfig` / `ItemConfig` の入れ子で構成され、JSON からロードしてデフォルト権限などを定義する。                                                                                          |
| [app_news.dart](app_news.dart)                             | `AppNews`                                                         | なし（in-memory のみ）     | アプリ内ニュース表示用のシンプルなモデル。Firestore から取得したタイトル・本文・日時・画像 URL・アクション URL・`isActive` フラグを保持する。`Timestamp` / エポックミリ秒 / `DateTime` を統一パースする `_parseDateTime` ヘルパーを内包する。                                                               |
| [firestore_shared_list.dart](firestore_shared_list.dart)   | `FirestoreSharedList`                                             | なし（Firestore のみ）     | Hive / Freezed を使わない軽量な Firestore 専用リストモデル。`ownerUid` / `groupId` / `listName` / 生アイテム `List<Map>` / `metadata` を保持し、`fromFirestore` / `toFirestore` / `addItem` / `updateItem` を提供する。現在は主に互換・ブリッジ用途。                                                       |

---

### 自動生成ファイル（編集不要）

Freezed コード生成（`dart run build_runner build`）によって生成されます。直接編集しないでください。

| ファイル名       | 説明                                                                      |
| ---------------- | ------------------------------------------------------------------------- |
| `*.freezed.dart` | Freezed が生成する `copyWith` / `==` / `toString` 等の実装。              |
| `*.g.dart`       | `json_serializable` と Hive が生成する JSON・バイナリシリアライズコード。 |

---

## モデルの依存関係

```
SharedGroup
  └─ SharedGroupMember (List<SharedGroupMember>)
  └─ SharedGroupRole (enum)
  └─ InvitationStatus (enum)
  └─ SyncStatus (enum)
  └─ GroupType (enum)

SharedList
  └─ SharedItem (Map<String, SharedItem>)
  └─ ListType (enum)

Invitation  ←→  AcceptedInvitation  (招待フロー)

Whiteboard
  └─ DrawingStroke (List<DrawingStroke>)
      └─ DrawingPoint (List<DrawingPoint>)

GroupStructureConfig
  └─ OrganizationConfig
      └─ GroupConfig
          └─ MemberConfig / ListConfig / ItemConfig
          └─ Permission (8-bit int)
```

---

## コード生成の実行

モデルを変更した場合は以下を実行して生成ファイルを更新してください。

```bash
dart run build_runner build --delete-conflicting-outputs
```
