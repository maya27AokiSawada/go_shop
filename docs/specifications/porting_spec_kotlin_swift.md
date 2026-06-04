# GoShopping アプリ 移植仕様説明書
## Kotlin (Android) / Swift (iOS) 向け

**対象ブランチ**: `oneness`
**バージョン**: 1.1.0 (Build 16)
**作成日**: 2026-06-04

---

## 目次

1. [アプリ概要](#1-アプリ概要)
2. [アーキテクチャ設計](#2-アーキテクチャ設計)
3. [画面設計](#3-画面設計)
4. [Firebase Authentication](#4-firebase-authentication)
5. [Firestoreデータモデル](#5-firestoreデータモデル)
6. [Repositoryパターン](#6-repositoryパターン)
7. [リアルタイム同期設計](#7-リアルタイム同期設計)
8. [QR招待フロー](#8-qr招待フロー)
9. [ホワイトボード機能](#9-ホワイトボード機能)
10. [通知設計](#10-通知設計)
11. [セキュリティルール](#11-セキュリティルール)
12. [移植時の注意事項](#12-移植時の注意事項)

---

## 1. アプリ概要

GoShoppingは**グループ共有型の買い物リスト管理アプリ**です。
家族・パートナー間でリアルタイムに買い物リストを共有し、ホワイトボード機能でメモも共有できます。

### 主な機能

| 機能 | 概要 |
|------|------|
| グループ管理 | 複数メンバーで買い物グループを共有 |
| 共有リスト | グループ内で複数の買い物リスト管理 |
| アイテム管理 | リスト内のアイテムをリアルタイム同期 |
| ホワイトボード | グループ共有 + 個人の手書きメモ |
| QR招待 | QRコードでグループへ招待 |
| 通知 | リスト操作・招待受諾の通知 |

### Firebase プロジェクト

| 環境 | Project ID | 用途 |
|------|------------|------|
| Production | `go-shopping-61515` | リリース版 |
| Development | `gotoshop-572b7` | 開発・テスト |

---

## 2. アーキテクチャ設計

### レイヤー構成

```
UI Layer          → 画面・ウィジェット (Pages / Screens)
State Layer       → 状態管理 (ViewModel / StateFlow 相当)
Repository Layer  → データアクセス抽象化 (Interface + 実装)
DataSource Layer  → Firestore / ローカルDB
```

### データ戦略

- **Firestore ファースト**: Firestoreが唯一の真実 (Source of Truth)
- **ローカルキャッシュ**: 読み込み高速化のみに使用（Hive → Kotlin: Room / Swift: Core Data or SwiftData）
- **Hybrid戦略**: Firestore失敗時もローカルに書き込みを続行する

```kotlin
// Kotlin 実装例
suspend fun createGroup(groupId: String, groupName: String, member: SharedGroupMember) {
    try {
        firestoreRepo.createGroup(groupId, groupName, member)
    } catch (e: Exception) {
        // Firestore失敗でもローカルは続行
    }
    localRepo.createGroup(groupId, groupName, member)
}
```

```swift
// Swift 実装例
func createGroup(groupId: String, groupName: String, member: SharedGroupMember) async {
    do {
        try await firestoreRepo.createGroup(groupId: groupId, groupName: groupName, member: member)
    } catch {
        // Firestore失敗でもローカルは続行
    }
    await localRepo.createGroup(groupId: groupId, groupName: groupName, member: member)
}
```

---

## 3. 画面設計

### 3-1. 画面一覧

```
アプリ起動
    ↓
[HomeScreen] サインイン / サインアップ
    ↓ (認証成功)
[MainScreen] BottomNavigationBar 3タブ
    ├── Tab1: [SharedListPage]   買い物リスト
    ├── Tab2: [SharedGroupPage]  グループ管理
    └── Tab3: [SettingsPage]     設定
```

### 3-2. HomeScreen（サインイン / サインアップ）

**パス**: `lib/pages/home_page.dart`

#### 状態

| 変数 | 型 | 説明 |
|------|----|------|
| `isSignUpMode` | Bool | true=アカウント作成 / false=サインイン |
| `isPasswordVisible` | Bool | パスワード表示切替 |
| `isLoading` | Bool | 認証処理中フラグ |
| `rememberEmail` | Bool | メールアドレス保存チェック |
| `showEmailSignIn` | Bool | メール入力フォーム表示切替 |

#### UI要素

- ユーザー名入力フィールド（サインアップ時のみ表示）
- メールアドレス入力フィールド
- パスワード入力フィールド（表示/非表示トグル付き）
- サインアップ / サインインボタン
- メールアドレス保存チェックボックス
- ニュース・広告パネル（下部）

#### バリデーション

- ユーザー名: 空文字禁止（サインアップ時）
- メールアドレス: 形式チェック
- パスワード: 最低文字数チェック

---

### 3-3. SharedListPage（買い物リスト画面）

**パス**: `lib/pages/shared_list_page.dart`

#### 状態

| 変数 | 型 | 説明 |
|------|----|------|
| `selectedGroupId` | String? | 現在選択中グループID |
| `currentList` | SharedList? | 現在選択中リスト |

#### UI要素

1. **グループ選択ドロップダウン** (SingleモードではHidden)
2. **リスト選択タブ / ドロップダウン**
3. **アイテム一覧** (ListView)
   - 各アイテム行: チェックボックス + アイテム名 + 数量 + 期限
   - 購入済みアイテムは取り消し線 or グレーアウト
4. **FAB**: アイテム追加
5. **アイテム編集モーダル**: 名前・数量・繰り返し間隔・期限

#### データフロー

```
Firestore (watchSharedList Stream)
    → SharedListRepository.watchSharedList()
    → StateFlow<SharedList?>
    → UI表示 (activeItemsのみ: isDeleted=false)
```

> ⚠️ `items` Mapの全件を表示しないこと。**必ず `activeItems` (isDeleted=false)** のみ表示する。

---

### 3-4. SharedGroupPage（グループ管理画面）

**パス**: `lib/pages/shared_group_page.dart`

#### UI要素

1. **グループ一覧** (GroupListWidget)
   - グループカード: グループ名 + メンバー数 + タイプアイコン
   - 長押し: 削除 / 離脱メニュー
2. **FAB**: QRスキャン / 新規グループ作成
   - シングルモード + グループ1件以上: FAB無効化

#### 権限制御

- 削除ボタン: オーナー(`ownerUid == currentUid`)のみ表示
- 離脱ボタン: メンバーのみ（オーナーは離脱不可）

---

### 3-5. SettingsPage（設定画面）

**パス**: `lib/pages/settings_page.dart`

#### セクション構成

| セクション | 内容 |
|-----------|------|
| AuthStatusPanel | 認証状態・ユーザー名表示 |
| FirestoreSyncStatusPanel | 同期状態インジケーター |
| AppUIModeSwicher | SingleUI / MultiUI 切替 |
| AppModeSwitcher | Shopping / ToDo モード切替 |
| LanguageSettings | 言語設定 |
| WhiteboardSettings | ホワイトボードカラー設定 |
| FeedbackSection | フィードバック送信 |
| AccountDeletion | アカウント削除 |

---

### 3-6. WhiteboardEditorPage（ホワイトボード）

**パス**: `lib/pages/whiteboard_editor_page.dart`

#### 固定キャンバスサイズ

- Width: 1280px
- Height: 720px (16:9)

#### UI要素

1. **描画キャンバス** (2レイヤー構成)
   - 背景レイヤー: 保存済みストロークを CustomPaint で描画
   - 前景レイヤー: 現在描画中のストローク
2. **ツールバー**: 色選択 / 太さ選択 / Undo / Redo / 保存
3. **スクロール**: 横・縦スクロール対応
4. **ズーム**: ピンチイン/アウト対応

---

### 3-7. QrScanScreen（QRスキャン）

**パス**: `lib/screens/qr_scan_screen.dart`

#### UI要素

1. **カメラプレビュー** (full screen)
2. **スキャン枠オーバーレイ**
3. **処理中インジケーター**
4. **手動入力ボタン** (AppBar右上) → ダイアログ表示

---

## 4. Firebase Authentication

### 4-1. 認証方式

**メールアドレス + パスワード**認証のみ。

### 4-2. サインアップフロー

```
① ローカルキャッシュを全クリア（Firebase Auth登録より先に実行）
② FirebaseAuth.createUserWithEmailAndPassword()
③ UserPreferencesService.saveUserName()（SharedPreferences）
④ user.updateDisplayName(userName)
⑤ Firestore /users/{uid} にユーザー情報を保存
⑥ 全Providerを invalidate → Firestore→ローカル同期
```

**Firestoreユーザードキュメント構造**:

```json
// /users/{uid}
{
  "displayName": "ユーザー名",
  "email": "user@example.com",
  "createdAt": Timestamp,
  "updatedAt": Timestamp
}
```

### 4-3. サインインフロー

```
① FirebaseAuth.signInWithEmailAndPassword()
② Firestoreからユーザー名取得 → SharedPreferences保存
③ ローカルDB同期（Firestore→ローカル）
④ 全グループProvider を invalidate して再読み込み
```

### 4-4. サインアウトフロー

```
① ローカルキャッシュ（SharedPreferences + ローカルDB）を全クリア
② 各Providerを invalidate
③ FirebaseAuth.signOut()  ← 必ず最後
```

> ⚠️ サインアウト順序は厳守。Auth を先に signOut すると Firestore ルールのアクセス拒否が起きる。

### 4-5. 認証状態の監視

```kotlin
// Kotlin
FirebaseAuth.getInstance().addAuthStateListener { auth ->
    val user = auth.currentUser
    if (user != null) {
        // 認証済み → メイン画面へ
    } else {
        // 未認証 → ホーム（サインイン）画面へ
    }
}
```

```swift
// Swift
Auth.auth().addStateDidChangeListener { auth, user in
    if let user = user {
        // 認証済み → メイン画面へ
    } else {
        // 未認証 → ホーム（サインイン）画面へ
    }
}
```

### 4-6. エラーコード対応表

| FirebaseAuthException code | 表示メッセージ |
|---------------------------|--------------|
| `email-already-in-use` | このメールアドレスは既に使用されています |
| `invalid-email` | メールアドレスの形式が正しくありません |
| `weak-password` | パスワードは6文字以上にしてください |
| `user-not-found` | アカウントが見つかりません |
| `wrong-password` | パスワードが間違っています |
| `too-many-requests` | 試行回数が上限に達しました。しばらく待ってから再試行してください |
| `network-request-failed` | ネットワークエラーが発生しました |

---

## 5. Firestoreデータモデル

### 5-1. コレクション構成（ルート）

```
Firestore
├── users/{uid}                        ← ユーザープロファイル
│   └── acceptedInvitations/{uid}      ← 受諾済み招待
├── SharedGroups/{groupId}             ← 共有グループ
│   ├── sharedLists/{listId}           ← 買い物リスト
│   ├── whiteboards/{whiteboardId}     ← ホワイトボード
│   │   └── strokes/{strokeId}         ← 手書きストローク
│   └── invitations/{invitationId}    ← グループ招待
├── notifications/{notificationId}    ← 通知
└── invitation_logs/{logId}           ← 招待ログ（変更不可）
```

### 5-2. SharedGroup ドキュメント

**パス**: `/SharedGroups/{groupId}`

```json
{
  "groupId": "a3f8c9d2_1707835200000",
  "groupName": "家族の買い物",
  "ownerUid": "firebase_user_uid",
  "allowedUid": ["uid1", "uid2", "uid3"],
  "members": [
    {
      "memberId": "uuid-v4",
      "name": "田中太郎",
      "contact": "taro@example.com",
      "role": "owner",          // owner / member / manager / partner
      "isSignedIn": true,
      "invitationStatus": "self",  // self / pending / accepted / deleted
      "securityKey": null,
      "invitedAt": null,
      "acceptedAt": null
    }
  ],
  "groupType": "shopping",      // shopping / todo
  "syncStatus": "synced",       // synced / pending / local
  "createdAt": Timestamp,
  "updatedAt": Timestamp
}
```

**重要**:
- `allowedUid` に自分のUIDが含まれているグループのみ取得可能（Firestoreクエリ条件）
- `ownerUid` は必ず `allowedUid` にも含まれる
- グループID形式: `{DeviceIdPrefix}_{timestamp}` (例: `a3f8c9d2_1707835200000`)

### 5-3. SharedList ドキュメント

**パス**: `/SharedGroups/{groupId}/sharedLists/{listId}`

```json
{
  "listId": "a3f8c9d2_f3e1a7b4",
  "listName": "週末の買い物",
  "ownerUid": "firebase_user_uid",
  "groupId": "a3f8c9d2_1707835200000",
  "groupName": "家族の買い物",
  "description": "",
  "listType": "shopping",   // shopping / todo
  "items": {
    "item_uuid_1": {
      "itemId": "item_uuid_1",
      "name": "牛乳",
      "quantity": 2,
      "registeredDate": Timestamp,
      "purchaseDate": null,
      "isPurchased": false,
      "isDeleted": false,
      "deletedAt": null,
      "shoppingInterval": 7,
      "deadline": null,
      "memberId": "member_uuid"
    }
  },
  "createdAt": Timestamp,
  "updatedAt": Timestamp
}
```

**重要**:
- `items` は `Map<String, SharedItem>` 形式（**配列ではない**）
- キーは `itemId`
- アイテム追加・更新は `items.{itemId}` フィールド単位で差分更新（全件置換禁止）
- **UI表示は `isDeleted=false` のアイテムのみ** 表示すること
- リストID形式: `{DeviceIdPrefix}_{uuid8}` (例: `a3f8c9d2_f3e1a7b4`)

#### アイテム差分更新（必須）

```kotlin
// Kotlin: アイテム追加
firestore.collection("SharedGroups").document(groupId)
    .collection("sharedLists").document(listId)
    .update(mapOf(
        "items.${item.itemId}" to item.toMap(),
        "updatedAt" to FieldValue.serverTimestamp()
    ))
```

```swift
// Swift: アイテム追加
firestore.collection("SharedGroups").document(groupId)
    .collection("sharedLists").document(listId)
    .updateData([
        "items.\(item.itemId)": item.toDictionary(),
        "updatedAt": FieldValue.serverTimestamp()
    ])
```

### 5-4. SharedItem フィールド定義

| フィールド | 型 | 説明 |
|-----------|------|------|
| `itemId` | String | UUID v4（自動生成） |
| `name` | String | 商品名 |
| `quantity` | Int | 数量（デフォルト: 1） |
| `registeredDate` | Timestamp | 登録日時 |
| `purchaseDate` | Timestamp? | 購入日時（null=未購入） |
| `isPurchased` | Bool | 購入済みフラグ |
| `isDeleted` | Bool | 論理削除フラグ（**UI非表示**） |
| `deletedAt` | Timestamp? | 削除日時 |
| `shoppingInterval` | Int | 繰り返し間隔(日数)。0=繰り返しなし |
| `deadline` | Timestamp? | 購入期限 |
| `memberId` | String | 登録者のメンバーID |

### 5-5. Whiteboard ドキュメント

**パス**: `/SharedGroups/{groupId}/whiteboards/{whiteboardId}`

```json
{
  "whiteboardId": "uuid-v4",
  "groupId": "a3f8c9d2_1707835200000",
  "ownerId": null,        // null=グループ共有、uid=個人用
  "isPrivate": false,     // false=グループ共有、true=個人用
  "createdAt": Timestamp,
  "updatedAt": Timestamp
}
```

#### DrawingStroke サブコレクション

**パス**: `/SharedGroups/{groupId}/whiteboards/{whiteboardId}/strokes/{strokeId}`

```json
{
  "strokeId": "uuid-v4",
  "points": [
    { "x": 123.5, "y": 456.7 },
    { "x": 124.0, "y": 457.2 }
  ],
  "colorValue": -16777216,   // Color ARGB int値（例: -16777216 = 黒）
  "strokeWidth": 4.0,
  "createdAt": Timestamp,
  "authorId": "firebase_user_uid",
  "authorName": "田中太郎"
}
```

### 5-6. Invitation ドキュメント（QR招待）

**パス**: `/SharedGroups/{groupId}/invitations/{token}`

```json
{
  "token": "INV_abc123-def456-...",
  "groupId": "a3f8c9d2_1707835200000",
  "groupName": "家族の買い物",
  "invitedBy": "firebase_user_uid",
  "inviterName": "田中太郎",
  "createdAt": Timestamp,
  "expiresAt": Timestamp,
  "maxUses": 5,
  "currentUses": 1,
  "usedBy": ["uid1"],
  "securityKey": "optional_security_key"
}
```

### 5-7. Notification ドキュメント

**パス**: `/notifications/{notificationId}`

```json
{
  "userId": "宛先ユーザーUID",
  "type": "listCreated",       // listCreated / listDeleted / memberJoined / groupDeleted 等
  "groupId": "グループID",
  "listId": "リストID（省略可）",
  "message": "通知メッセージ",
  "isRead": false,
  "createdAt": Timestamp
}
```

### 5-8. User ドキュメント

**パス**: `/users/{uid}`

```json
{
  "displayName": "田中太郎",
  "email": "taro@example.com",
  "createdAt": Timestamp,
  "updatedAt": Timestamp
}
```

---

## 6. Repositoryパターン

### 6-1. インターフェース設計

#### SharedGroupRepository

```kotlin
// Kotlin Interface
interface SharedGroupRepository {
    suspend fun createGroup(groupId: String, groupName: String, member: SharedGroupMember): SharedGroup
    suspend fun getAllGroups(): List<SharedGroup>
    suspend fun getGroupById(groupId: String): SharedGroup
    suspend fun updateGroup(groupId: String, group: SharedGroup): SharedGroup
    suspend fun deleteGroup(groupId: String): SharedGroup
    suspend fun addMember(groupId: String, member: SharedGroupMember): SharedGroup
    suspend fun removeMember(groupId: String, member: SharedGroupMember): SharedGroup
}
```

```swift
// Swift Protocol
protocol SharedGroupRepository {
    func createGroup(groupId: String, groupName: String, member: SharedGroupMember) async throws -> SharedGroup
    func getAllGroups() async throws -> [SharedGroup]
    func getGroupById(groupId: String) async throws -> SharedGroup
    func updateGroup(groupId: String, group: SharedGroup) async throws -> SharedGroup
    func deleteGroup(groupId: String) async throws -> SharedGroup
    func addMember(groupId: String, member: SharedGroupMember) async throws -> SharedGroup
    func removeMember(groupId: String, member: SharedGroupMember) async throws -> SharedGroup
}
```

#### SharedListRepository

```kotlin
// Kotlin Interface
interface SharedListRepository {
    suspend fun createSharedList(ownerUid: String, groupId: String, listName: String, description: String?, customListId: String?): SharedList
    suspend fun getSharedListById(listId: String): SharedList?
    suspend fun getSharedListsByGroup(groupId: String): List<SharedList>
    suspend fun updateSharedList(list: SharedList)
    suspend fun deleteSharedList(groupId: String, listId: String)
    // 差分更新（必須）
    suspend fun addSingleItem(listId: String, item: SharedItem)
    suspend fun updateSingleItem(listId: String, item: SharedItem)
    suspend fun removeSingleItem(listId: String, itemId: String)  // 論理削除
    // リアルタイム監視
    fun watchSharedList(groupId: String, listId: String): Flow<SharedList?>
}
```

### 6-2. Hybrid実装パターン

```kotlin
// Kotlin: HybridSharedGroupRepository
class HybridSharedGroupRepository(
    private val firestoreRepo: FirestoreSharedGroupRepository,
    private val localRepo: LocalSharedGroupRepository
) : SharedGroupRepository {

    override suspend fun createGroup(
        groupId: String, groupName: String, member: SharedGroupMember
    ): SharedGroup {
        val newGroup: SharedGroup
        try {
            newGroup = firestoreRepo.createGroup(groupId, groupName, member)
        } catch (e: Exception) {
            // Firestore失敗でもローカルを更新
        }
        return localRepo.createGroup(groupId, groupName, member)
    }

    override suspend fun getAllGroups(): List<SharedGroup> {
        return try {
            val groups = firestoreRepo.getAllGroups()
            localRepo.saveGroups(groups)  // キャッシュ更新
            groups
        } catch (e: Exception) {
            localRepo.getAllGroups()  // フォールバック
        }
    }
}
```

### 6-3. ID生成ルール

```kotlin
// Kotlin: ID生成
object DeviceIdService {
    // グループID: DevicePrefix_timestamp
    fun generateGroupId(devicePrefix: String): String {
        return "${devicePrefix}_${System.currentTimeMillis()}"
    }

    // リストID: DevicePrefix_uuid8
    fun generateListId(devicePrefix: String): String {
        val uuid8 = UUID.randomUUID().toString().replace("-", "").substring(0, 8)
        return "${devicePrefix}_${uuid8}"
    }
}
```

> ⚠️ タイムスタンプのみのID（`timestamp.toString()`）は衝突リスクがあるため**禁止**

---

## 7. リアルタイム同期設計

### 7-1. SharedList のリアルタイム監視

Firestoreのリアルタイムリスナーで `sharedLists/{listId}` を監視する。

```kotlin
// Kotlin: Flow で監視
fun watchSharedList(groupId: String, listId: String): Flow<SharedList?> = callbackFlow {
    val docRef = firestore
        .collection("SharedGroups").document(groupId)
        .collection("sharedLists").document(listId)

    val listener = docRef.addSnapshotListener { snapshot, error ->
        if (error != null) { close(error); return@addSnapshotListener }
        val list = snapshot?.toObject(SharedList::class.java)
        trySend(list)
    }

    awaitClose { listener.remove() }
}
```

```swift
// Swift: AsyncStream で監視
func watchSharedList(groupId: String, listId: String) -> AsyncStream<SharedList?> {
    AsyncStream { continuation in
        let docRef = firestore
            .collection("SharedGroups").document(groupId)
            .collection("sharedLists").document(listId)

        let listener = docRef.addSnapshotListener { snapshot, error in
            guard error == nil else { continuation.finish(); return }
            let list = try? snapshot?.data(as: SharedList.self)
            continuation.yield(list)
        }

        continuation.onTermination = { _ in listener.remove() }
    }
}
```

### 7-2. ホワイトボードストロークの監視

ストロークはサブコレクションを監視。`hasPendingWrites` フィルターは**使用禁止**。

```kotlin
// Kotlin: ストローク監視
fun watchStrokes(groupId: String, whiteboardId: String): Flow<List<DrawingStroke>> = callbackFlow {
    val colRef = firestore
        .collection("SharedGroups").document(groupId)
        .collection("whiteboards").document(whiteboardId)
        .collection("strokes")
    // orderBy は使用しない（インデックス不要、クライアントソートで代替）
    val listener = colRef.addSnapshotListener { snapshot, error ->
        if (error != null) { close(error); return@addSnapshotListener }
        val strokes = snapshot?.documents
            ?.mapNotNull { it.toObject(DrawingStroke::class.java) }
            ?.sortedBy { it.createdAt }  // クライアントソート
            ?: emptyList()
        trySend(strokes)
    }
    awaitClose { listener.remove() }
}
```

---

## 8. QR招待フロー

### 8-1. 招待作成（ホスト側）

```
① UUID v4 でトークン生成 ("INV_" + uuid)
② /SharedGroups/{groupId}/invitations/{token} に保存
   - expiresAt = createdAt + 24時間
   - maxUses = 5
③ QRコード生成（内容: token文字列）
④ QRコード表示
```

### 8-2. 招待受諾（ゲスト側）

```
① カメラでQRコードスキャン or 手動入力
② token で /SharedGroups/{*/invitations/{token} を検索
③ 招待バリデーション:
   - expiresAt > 現在時刻
   - currentUses < maxUses
   - usedBy に自分のUIDが含まれないこと
   - 既にグループメンバーでないこと
④ バリデーション通過後:
   - invitations/{token}.currentUses をインクリメント
   - invitations/{token}.usedBy に自分のUIDを追加
   - SharedGroups/{groupId}.allowedUid に自分のUIDを追加
   - SharedGroups/{groupId}.members に自分の情報を追加
   - /users/{ownerUid}/acceptedInvitations/{myUid} に受諾記録
⑤ グループ一覧を再読み込み
```

### 8-3. QRコード内容フォーマット

```
INV_xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
```
（プレフィックス `INV_` + UUID v4）

---

## 9. ホワイトボード機能

### 9-1. ストロークの保存（差分保存）

ペンを離したタイミングで**未保存ストロークのみ**をFirestoreに保存する。

```kotlin
// Kotlin: ストローク差分保存
class WhiteboardViewModel {
    private val unsavedStrokeIds = mutableSetOf<String>()

    // ペンアップ時に呼ぶ
    fun onStrokeComplete(stroke: DrawingStroke) {
        unsavedStrokeIds.add(stroke.strokeId)
    }

    // 保存ボタン or 自動保存
    fun saveStrokes() {
        val newStrokes = workingStrokes.filter { unsavedStrokeIds.contains(it.strokeId) }
        if (newStrokes.isEmpty()) return

        // fire-and-forget（awaitしない）
        viewModelScope.launch {
            try {
                repository.addStrokesToSubcollection(
                    groupId = groupId,
                    whiteboardId = whiteboardId,
                    newStrokes = newStrokes
                )
                newStrokes.forEach { unsavedStrokeIds.remove(it.strokeId) }
            } catch (e: Exception) {
                // エラー通知のみ（UIブロックしない）
            }
        }
    }
}
```

### 9-2. ストロークのバッチ書き込み

```kotlin
// Kotlin: Firestoreバッチ書き込み
suspend fun addStrokesToSubcollection(
    groupId: String,
    whiteboardId: String,
    newStrokes: List<DrawingStroke>
) {
    val batch = firestore.batch()
    val strokesCol = firestore.collection("SharedGroups").document(groupId)
        .collection("whiteboards").document(whiteboardId)
        .collection("strokes")

    newStrokes.forEach { stroke ->
        val docRef = strokesCol.document(stroke.strokeId)
        batch.set(docRef, stroke.toMap())
    }

    // 親ドキュメントのupdatedAtも更新
    batch.update(
        firestore.collection("SharedGroups").document(groupId)
            .collection("whiteboards").document(whiteboardId),
        mapOf("updatedAt" to FieldValue.serverTimestamp())
    )

    batch.commit().await()
}
```

### 9-3. グループ共有 vs 個人用

- `ownerId == null` かつ `isPrivate == false` → **グループ共有**ホワイトボード（全メンバー閲覧・編集可）
- `ownerId == currentUid` かつ `isPrivate == true` → **個人用**ホワイトボード（本人のみ）

---

## 10. 通知設計

### 10-1. 通知タイプ

| type | トリガー |
|------|---------|
| `listCreated` | リスト作成時 |
| `listDeleted` | リスト削除時 |
| `listRenamed` | リスト名変更時 |
| `memberJoined` | メンバー参加時 |
| `memberLeft` | メンバー離脱時 |
| `groupDeleted` | グループ削除時 |

### 10-2. 通知の送受信

**送信**: Firestoreの `/notifications/{notificationId}` にドキュメントを書き込む
**受信**: 自分の `userId` 宛の通知を定期ポーリング or リアルタイムリスナーで取得

```kotlin
// Kotlin: 自分宛通知の監視
fun watchNotifications(userId: String): Flow<List<Notification>> = callbackFlow {
    val listener = firestore.collection("notifications")
        .whereEqualTo("userId", userId)
        .whereEqualTo("isRead", false)
        .addSnapshotListener { snapshot, error ->
            val notifications = snapshot?.toObjects(Notification::class.java) ?: emptyList()
            trySend(notifications)
        }
    awaitClose { listener.remove() }
}
```

---

## 11. セキュリティルール

### 11-1. アクセス制御の基本方針

| コレクション | 読み取り | 書き込み |
|-------------|---------|---------|
| `/users/{uid}` | 本人のみ | 本人のみ |
| `/SharedGroups/{groupId}` | `allowedUid` に含まれるユーザー | メンバー |
| `/SharedGroups/{groupId}/sharedLists/*` | グループメンバー | グループメンバー |
| `/SharedGroups/{groupId}/whiteboards/*` | グループメンバー | グループメンバー |
| `/SharedGroups/{groupId}/invitations/*` | 認証済みユーザー全員 | グループメンバーのみ作成 |
| `/notifications/{id}` | 宛先ユーザーのみ | 認証済みユーザー |
| `/firestoreNews/*` | 全員（未認証含む） | 管理者のみ |

### 11-2. SharedGroupへのアクセス判定

```javascript
// Firestoreルール（参考）
function isGroupMember() {
    return request.auth != null && (
        resource.data.ownerUid == request.auth.uid ||
        request.auth.uid in resource.data.allowedUid
    );
}
```

クライアント側でも同様のチェックを実装すること:
```kotlin
// Kotlin
fun canAccessGroup(group: SharedGroup, currentUid: String): Boolean {
    return group.ownerUid == currentUid || group.allowedUid.contains(currentUid)
}
```

---

## 12. 移植時の注意事項

### 12-1. アイテムの差分更新（CRITICAL）

**全件置換は絶対禁止**。アイテムの追加・更新・削除は必ず`items.{itemId}`フィールドの差分更新で行う。

```kotlin
// ❌ 禁止
firestore.document(listPath).set(mapOf("items" to allItems))

// ✅ 正しい
firestore.document(listPath).update(mapOf(
    "items.${itemId}" to itemData,
    "updatedAt" to FieldValue.serverTimestamp()
))
```

### 12-2. アイテムの論理削除

- アイテム削除は `isDeleted = true` にする（物理削除は定期クリーンアップのみ）
- UI表示は必ず `isDeleted == false` のアイテムのみ

### 12-3. オフライン対応

- Firestoreオフライン永続化を有効にする
- `runTransaction()` はサーバー接続必須 → オフライン時にハングするため避ける
- 代わりに `.set()` / `.update()` を使う（ローカルキャッシュに即座にキューイングされる）

```kotlin
// Kotlin: オフライン永続化の有効化
FirebaseFirestore.getInstance().apply {
    firestoreSettings = firestoreSettings {
        isPersistenceEnabled = true
    }
}
```

### 12-4. DropdownButton / Spinner の重複ID禁止

- グループ一覧をドロップダウンに表示する場合、`groupId` で重複除去してから表示する

### 12-5. グループクエリ方法

```kotlin
// Kotlin: 自分が所属するグループのみ取得
firestore.collection("SharedGroups")
    .whereArrayContains("allowedUid", currentUid)
    .get()
```

### 12-6. ホワイトボードの `orderBy` 禁止

- ストロークのクエリに `.orderBy("createdAt")` を使用しない（インデックス未作成時にエラー）
- クライアント側でソートする

### 12-7. ストローク保存の fire-and-forget

- ストロークの保存は `await` しない（UIをブロックしない）
- Firestoreのオフライン永続化によりローカルへの書き込みは即時完了する

### 12-8. サインアウト順序

```
ローカルキャッシュクリア → Provider invalidate → Firebase signOut（最後）
```

この順序を必ず守ること。逆にするとFirestoreアクセス時に権限エラーが発生する。

### 12-9. グループ離脱時のローカルクリーンアップ

メンバー離脱時は以下をローカルからも即座に削除する：
1. 該当グループのSharedGroupデータ
2. 該当グループのすべてのSharedListデータ
3. グループ一覧を再読み込み（UIを即座に反映）

ネットワーク切断や他オーナーのオフライン状態に関わらず、**ローカルから即座に削除**してUIを更新すること。

---

## Appendix: データモデル型定義（Kotlin）

```kotlin
// SharedGroup
data class SharedGroup(
    val groupId: String,
    val groupName: String,
    val ownerUid: String,
    val allowedUid: List<String>,
    val members: List<SharedGroupMember>,
    val groupType: GroupType,
    val syncStatus: SyncStatus,
    val createdAt: Date,
    val updatedAt: Date?
)

enum class GroupType { SHOPPING, TODO }
enum class SyncStatus { SYNCED, PENDING, LOCAL }
enum class SharedGroupRole { OWNER, MEMBER, MANAGER, PARTNER }
enum class InvitationStatus { SELF, PENDING, ACCEPTED, DELETED }

data class SharedGroupMember(
    val memberId: String,
    val name: String,
    val contact: String,
    val role: SharedGroupRole,
    val isSignedIn: Boolean,
    val invitationStatus: InvitationStatus,
    val securityKey: String?,
    val invitedAt: Date?,
    val acceptedAt: Date?
)

// SharedList
data class SharedList(
    val listId: String,
    val listName: String,
    val ownerUid: String,
    val groupId: String,
    val groupName: String,
    val description: String,
    val listType: ListType,
    val items: Map<String, SharedItem>,
    val createdAt: Date,
    val updatedAt: Date?
) {
    val activeItems: List<SharedItem>
        get() = items.values.filter { !it.isDeleted }.sortedBy { it.registeredDate }
}

enum class ListType { SHOPPING, TODO }

data class SharedItem(
    val itemId: String,
    val name: String,
    val quantity: Int,
    val memberId: String,
    val registeredDate: Date,
    val purchaseDate: Date?,
    val isPurchased: Boolean,
    val isDeleted: Boolean,
    val deletedAt: Date?,
    val shoppingInterval: Int,
    val deadline: Date?
)

// Whiteboard
data class Whiteboard(
    val whiteboardId: String,
    val groupId: String,
    val ownerId: String?,
    val isPrivate: Boolean,
    val createdAt: Date,
    val updatedAt: Date?
)

data class DrawingStroke(
    val strokeId: String,
    val points: List<DrawingPoint>,
    val colorValue: Int,
    val strokeWidth: Float,
    val createdAt: Date,
    val authorId: String,
    val authorName: String
)

data class DrawingPoint(val x: Float, val y: Float)
```

---

## Appendix: データモデル型定義（Swift）

```swift
// SharedGroup
struct SharedGroup: Codable {
    let groupId: String
    let groupName: String
    let ownerUid: String
    let allowedUid: [String]
    let members: [SharedGroupMember]
    let groupType: GroupType
    let syncStatus: SyncStatus
    let createdAt: Date
    let updatedAt: Date?
}

enum GroupType: String, Codable { case shopping, todo }
enum SyncStatus: String, Codable { case synced, pending, local }
enum SharedGroupRole: String, Codable { case owner, member, manager, partner }
enum InvitationStatus: String, Codable { case `self`, pending, accepted, deleted }

struct SharedGroupMember: Codable {
    let memberId: String
    let name: String
    let contact: String
    let role: SharedGroupRole
    let isSignedIn: Bool
    let invitationStatus: InvitationStatus
    let securityKey: String?
    let invitedAt: Date?
    let acceptedAt: Date?
}

// SharedList
struct SharedList: Codable {
    let listId: String
    let listName: String
    let ownerUid: String
    let groupId: String
    let groupName: String
    let description: String
    let listType: ListType
    let items: [String: SharedItem]
    let createdAt: Date
    let updatedAt: Date?

    var activeItems: [SharedItem] {
        items.values.filter { !$0.isDeleted }.sorted { $0.registeredDate < $1.registeredDate }
    }
}

enum ListType: String, Codable { case shopping, todo }

struct SharedItem: Codable {
    let itemId: String
    let name: String
    let quantity: Int
    let memberId: String
    let registeredDate: Date
    let purchaseDate: Date?
    let isPurchased: Bool
    let isDeleted: Bool
    let deletedAt: Date?
    let shoppingInterval: Int
    let deadline: Date?
}

// Whiteboard
struct Whiteboard: Codable {
    let whiteboardId: String
    let groupId: String
    let ownerId: String?
    let isPrivate: Bool
    let createdAt: Date
    let updatedAt: Date?
}

struct DrawingStroke: Codable {
    let strokeId: String
    let points: [DrawingPoint]
    let colorValue: Int
    let strokeWidth: Double
    let createdAt: Date
    let authorId: String
    let authorName: String
}

struct DrawingPoint: Codable {
    let x: Double
    let y: Double
}
```
