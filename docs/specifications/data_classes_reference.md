# データクラス リファレンス

GoShoppingアプリで使用されるデータクラスの一覧。アルファベット順に整理。

## 凡例

- 📦 Freezedクラス
- 🗃️ Hiveストレージ対応
- ☁️ Firestore連携
- 🔢 Enum型

---

## A

### AcceptedInvitation 📦🗃️☁️

**ファイル**: `lib/models/accepted_invitation.dart`
**HiveType**: typeId: 7

**目的**: 招待受諾データを管理。招待元ユーザーが招待受諾を追跡するために使用。

**Firestoreパス**: `/users/{inviterUid}/acceptedInvitations/{acceptorUid}`

**主要フィールド**:

- 受諾者情報（UID、メール、表示名）
- 対象グループ・リストID
- 招待時のロール
- 受諾・処理済み日時

---

### AppNews

**ファイル**: `lib/models/app_news.dart`

**目的**: アプリ内ニュース・お知らせの表示用データモデル。

**主要フィールド**:

- タイトル、コンテンツ
- 作成・更新日時
- 公開状態（isActive）
- オプション：画像URL、アクションURL・テキスト

**特徴**: Firestore Timestampとミリ秒の両方に対応した日時パース処理を実装。

---

## D

### DrawingPoint 📦🗃️

**ファイル**: `lib/models/whiteboard.dart`
**HiveType**: typeId: 16

**目的**: ホワイトボード上の描画座標を表現。

**主要フィールド**:

- x座標、y座標（double）

**拡張機能**: Flutter `Offset`型との相互変換メソッド提供。

---

### DrawingStroke 📦🗃️☁️

**ファイル**: `lib/models/whiteboard.dart`
**HiveType**: typeId: 15

**目的**: ホワイトボード上の1本の線（ストローク）を表現。

**主要フィールド**:

- strokeId（固有ID）
- points（DrawingPointリスト）
- 色・線幅
- 作成日時、作成者情報

---

## F

### FirestoreAcceptedInvitation

**ファイル**: `lib/models/accepted_invitation.dart`

**目的**: AcceptedInvitationのFirestore専用バージョン。ドキュメントID管理用。

**特徴**: 通常の`AcceptedInvitation`にドキュメントID（`id`）フィールドを追加。

---

### FirestoreSharedList

**ファイル**: `lib/models/firestore_shared_list.dart`

**目的**: SharedListのFirestore簡素化版。サブコレクション形式での保存用。

**主要フィールド**:

- ドキュメントID
- オーナーUID、グループID
- リスト名、アイテムリスト（Map形式のリスト）
- メタデータ（拡張可能）

**特徴**: 権限管理はSharedGroupから取得する設計。

---

## G

### GroupConfig 📦

**ファイル**: `lib/models/group_structure_config.dart`

**目的**: 組織構造設定ファイル内のグループ設定データ。

**主要フィールド**:

- グループID・名前
- 親グループID（階層構造用）
- メンバーリスト、デフォルト権限
- リストリスト

**使用シーン**: JSON設定ファイルからのグループ一括作成。

---

### GroupInvitedUser

**ファイル**: `lib/models/firestore_shared_group.dart`

**目的**: SharedGroup用の招待ユーザー情報管理。

**主要フィールド**:

- 招待メールアドレス
- 確定UID（ログイン後）
- 招待日時、確定済みフラグ
- 役割

**ライフサイクル**: メール招待 → ログイン → UID確定 → isConfirmed=true

---

### GroupStructureConfig 📦

**ファイル**: `lib/models/group_structure_config.dart`

**目的**: 組織全体の構造設定ファイルのルートデータモデル。

**主要フィールド**:

- OrganizationConfig（組織設定）
- InheritanceRules（継承ルール、オプション）

**使用シーン**: JSONファイルからの組織一括セットアップ。

---

### GroupType 🔢

**ファイル**: `lib/models/shared_group.dart`
**HiveType**: typeId: 11

**目的**: グループの用途タイプを定義。

**値**:

- `shopping`: 買い物リストグループ（デフォルト）
- `todo`: TODOタスク管理グループ

**使用シーン**: アプリモード（買い物/TODO）の切り替え。

---

## I

### Invitation 📦☁️

**ファイル**: `lib/models/invitation.dart`

**目的**: QR招待システムの招待トークン情報。

**Firestoreパス**: `/invitations/{token}`

**主要フィールド**:

- トークン（UUID v4形式）
- 招待先グループID・名前
- 招待元ユーザー情報
- 有効期限、最大・現在使用回数
- 使用済みユーザーリスト
- セキュリティキー

**特徴**:

- 複数回使用可能（maxUses: デフォルト5回）
- Firestore Timestamp自動変換対応
- QR検証用セキュリティキー

**ゲッターメソッド**:

- `remainingUses`: 残り使用可能回数
- `isValid`: 有効期限・使用回数チェック
- `isExpired`: 有効期限切れ判定
- `isMaxUsesReached`: 使用回数上限判定

---

### InvitationStatus 🔢

**ファイル**: `lib/models/shared_group.dart`
**HiveType**: typeId: 8

**目的**: メンバーの招待状態を定義。

**値**:

- `self`: 自分（招待ではない）
- `pending`: 招待中
- `accepted`: 受諾済み
- `deleted`: アカウント削除済み

---

### InvitationType 🔢

**ファイル**: `lib/models/shared_group.dart`
**HiveType**: typeId: 9

**目的**: 招待タイプを定義。

**値**:

- `individual`: 個別グループ招待
- `partner`: パートナー招待（全グループへの管理者アクセス）

---

## L

### ListConfig 📦

**ファイル**: `lib/models/group_structure_config.dart`

**目的**: 組織構造設定ファイル内のリスト設定データ。

**主要フィールド**:

- リストID・名前
- 説明文
- リストタイプ

**使用シーン**: JSON設定ファイルからのリスト一括作成。

---

### ListType 🔢

**ファイル**: `lib/models/shared_list.dart`
**HiveType**: typeId: 12

**目的**: リストの用途タイプを定義。

**値**:

- `shopping`: 買い物リスト（デフォルト）
- `todo`: TODOタスクリスト

---

## M

### MemberConfig 📦

**ファイル**: `lib/models/group_structure_config.dart`

**目的**: 組織構造設定ファイル内のメンバー設定データ。

**主要フィールド**:

- ユーザーUID
- 権限レベル（Permission）
- カスタム権限設定

**使用シーン**: JSON設定ファイルからのメンバー一括登録。

---

## O

### OrganizationConfig 📦

**ファイル**: `lib/models/group_structure_config.dart`

**目的**: 組織全体の基本設定データ。

**主要フィールド**:

- 組織名
- グループリスト（GroupConfig配列）

**使用シーン**: JSON設定ファイルからの組織構造読み込み。

---

## P

### Permission

**ファイル**: `lib/models/permission.dart`

**目的**: 8ビットフラグによる権限管理システム。

**基本権限（個別ビット）**:

- `NONE` (0x00): アクセス不可
- `READ` (0x01): 閲覧
- `DONE` (0x02): 完了チェック
- `COMMENT` (0x04): コメント追加
- `ITEM_CREATE` (0x08): アイテム追加
- `ITEM_EDIT` (0x10): アイテム編集
- `LIST_CREATE` (0x20): リスト作成
- `MEMBER_INVITE` (0x40): メンバー招待
- `ADMIN` (0x80): 管理者権限

**プリセット権限**:

- `VIEWER` (0x03): 閲覧者
- `CONTRIBUTOR` (0x0B): 貢献者
- `EDITOR` (0x1B): 編集者
- `MANAGER` (0x3B): マネージャー
- `FULL` (0xFF): 全権限

**主要メソッド**:

- `hasPermission()`: 権限チェック
- `addPermission()`: 権限追加
- `removePermission()`: 権限削除
- `togglePermission()`: 権限トグル
- 個別チェックメソッド（canRead, canEditItem等）
- `toPermissionString()`: 人間可読文字列変換
- `getPresetName()`: プリセット名取得

**特徴**: ビット演算による高速な権限チェックと柔軟な権限組み合わせ。

---

## S

### SharedGroup 📦🗃️☁️

**ファイル**: `lib/models/shared_group.dart`
**HiveType**: typeId: 2

**目的**: 買い物リストまたはTODOタスクを共有するグループの管理。

**主要フィールド**:

- グループID・名前
- オーナーUID、メンバーリスト
- アクセス許可UIDリスト（allowedUid）
- グループタイプ、同期ステータス
- 階層構造（親グループID、子グループIDリスト）
- 権限設定（メンバー権限マップ、デフォルト権限）
- リスト継承設定

**特徴**:

- Hive + Firestore ハイブリッド同期
- グループ階層構造サポート
- 細粒度権限管理（Permissionビットフラグ）
- SafeAreaモード対応

**重要メソッド**:

- `addMember()`: メンバー追加（allowedUid同時更新）
- `removeMember()`: メンバー削除（allowedUid同時更新）

---

### SharedGroupMember 📦🗃️

**ファイル**: `lib/models/shared_group.dart`
**HiveType**: typeId: 1

**目的**: SharedGroup内のメンバー情報。

**主要フィールド**:

- メンバーID（注：`memberId`、`memberID`ではない）
- 名前、連絡先（メールまたは電話番号）
- 役割（SharedGroupRole）
- サインイン状態
- 招待管理（招待状態、セキュリティキー、招待・受諾日時）

**ファクトリーメソッド**:

- `SharedGroupMember.create()`: memberIdを自動生成（UUID v4）

**注意**: 旧フィールド（isInvited、isInvitationAccepted）は非推奨。`invitationStatus`を使用。

---

### SharedGroupRole 🔢

**ファイル**: `lib/models/shared_group.dart`
**HiveType**: typeId: 0

**目的**: グループ内のメンバー役割を定義。

**値**:

- `owner`: オーナー（最高権限）
- `manager`: マネージャー
- `member`: 一般メンバー
- `partner`: パートナー（全グループへの管理者権限）

**権限階層**: owner > manager > member, partner

**制約**: 新規グループ作成時は作成者がowner。コピー時は既存ownerを自動的にmanagerに降格。

---

### SharedItem 📦🗃️

**ファイル**: `lib/models/shared_list.dart`
**HiveType**: typeId: 3

**目的**: 買い物リストまたはTODOタスクの個別アイテム。

**主要フィールド**:

- アイテムID（UUID v4）
- メンバーID（登録者）
- 名前、数量
- 登録日、購入日
- 購入済みフラグ
- 繰り返し購入間隔（日数、0=非繰り返し）
- 購入期限（deadline）
- 論理削除フラグ、削除日時

**ファクトリーメソッド**:

- `SharedItem.createNow()`: 現在日時で登録、itemId自動生成

**特徴**: Map<String, SharedItem>形式での管理により差分同期を実現（90%データ転送削減）。

---

### SharedList 📦🗃️☁️

**ファイル**: `lib/models/shared_list.dart`
**HiveType**: typeId: 4

**目的**: 買い物リストまたはTODOタスクリストの管理。

**主要フィールド**:

- リストID（UUID v4）
- オーナーUID、グループID・名前
- アイテムMap（Map<String, SharedItem>）
- リスト名、説明文
- 作成・更新日時
- リストタイプ

**ゲッターメソッド**:

- `activeItems`: 削除されていないアイテムのみ（isDeleted=false）
- `deletedItemCount`: 削除済みアイテム数
- `activeItemCount`: アクティブアイテム数
- `needsCleanup`: クリーンアップ必要判定（削除済み10個以上）

**ファクトリーメソッド**:

- `SharedList.create()`: listId自動生成、日時自動設定

**特徴**: Map形式により単一アイテムのFirestore差分同期が可能。論理削除により履歴保持。

---

### SyncStatus 🔢

**ファイル**: `lib/models/shared_group.dart`
**HiveType**: typeId: 10

**目的**: グループのFirestore同期状態を定義。

**値**:

- `synced`: Firestoreと同期済み
- `pending`: 招待受諾中（プレースホルダー）
- `local`: ローカルのみ（Firestoreに未送信）

**使用シーン**: デフォルトグループは`local`、共有グループは`synced`。

---

## U

### UserSettings 📦🗃️

**ファイル**: `lib/models/user_settings.dart`
**HiveType**: typeId: 6

**目的**: ユーザー個別の設定データ。

**主要フィールド**:

- ユーザー名、ユーザーID、メールアドレス
- 最後に使用したグループID・リストID
- アプリモード（0=買い物、1=TODO）
- リスト通知ON/OFF
- ホワイトボード色設定（色5、色6）

**特徴**: SharedPreferencesではなくHiveで管理。ユーザーUID別に分離可能。

---

## W

### Whiteboard 📦🗃️☁️

**ファイル**: `lib/models/whiteboard.dart`
**HiveType**: typeId: 17

**目的**: グループ共有または個人用のホワイトボード。

**主要フィールド**:

- ホワイトボードID
- グループID、オーナーID（null=グループ共通）
- ストロークリスト（DrawingStroke配列）
- プライベートフラグ（自分以外編集不可）
- 作成・更新日時
- キャンバスサイズ

**特徴**:

- リアルタイム共同編集対応
- ストローク単位の差分同期
- グループ共有と個人用の両対応

---

## 注意事項

### HiveType ID一覧

使用中のtypeId：

- 0: SharedGroupRole
- 1: SharedGroupMember
- 2: SharedGroup
- 3: SharedItem
- 4: SharedList
- 6: UserSettings
- 7: AcceptedInvitation
- 8: InvitationStatus
- 9: InvitationType
- 10: SyncStatus
- 11: GroupType
- 12: ListType
- 15: DrawingStroke
- 16: DrawingPoint
- 17: Whiteboard

### Freezed生成ファイル

Freezedクラスは以下のファイルを自動生成:

- `*.freezed.dart`: Freezedコード生成
- `*.g.dart`: Hiveアダプター + JSON変換

生成コマンド:

```bash
dart run build_runner build --delete-conflicting-outputs
```

### 命名規則の重要性

- SharedGroupMemberの`memberId`フィールドは`memberID`ではない（注意）
- SharedItem/SharedList内のIDも統一して`itemId`, `listId`

### Firestore連携パターン

1. **Freezed + fromFirestore()**: Invitation, AcceptedInvitation
2. **専用クラス**: FirestoreSharedList, FirestoreAcceptedInvitation
3. **シンプル変換**: AppNews（fromMap）

### 差分同期の重要性

SharedListは`Map<String, SharedItem>`形式を採用:

- 従来: リスト全体送信（10アイテム = ~5KB）
- 現在: 単一アイテム送信（1アイテム = ~500B）
- **結果: 90%データ転送削減達成**

使用メソッド: `addSingleItem()`, `updateSingleItem()`, `removeSingleItem()`

---

**最終更新**: 2026-02-18
