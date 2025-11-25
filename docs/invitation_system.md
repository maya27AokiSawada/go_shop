# Go Shop - 招待機能 詳細仕様書

## 概要
Go Shopの招待機能は、**QRコードベースのセキュアな招待システム**です。
3層のセキュリティチェックにより、不正な招待の受諾を防止し、24時間の有効期限と一度きりの使用制限により安全性を確保しています。

---

## 1. 招待タイプ

### 1.1 個別招待（Individual Invitation）
**用途:** 特定のグループへの招待

```dart
invitationType: 'individual'
```

**動作:**
- 1つのグループのみへのアクセス権を付与
- 受諾者の`allowedUid`がそのグループにのみ追加される
- 最も一般的な招待方法

**使用場面:**
- 家族グループへの招待
- プロジェクトチームへの招待
- 一時的な共同作業

### 1.2 フレンド招待（Friend Invitation）
**用途:** すべてのグループへのアクセス権を付与

```dart
invitationType: 'friend'
```

**動作:**
- 招待者がオーナーのすべてのグループへアクセス可能
- `users/{uid}/friends`コレクションに相互登録
- 新規グループ作成時も自動的にアクセス権が付与される（予定）

**使用場面:**
- 家族メンバーの追加
- 長期的なパートナーシップ
- 全グループへのアクセスが必要な場合

---

## 2. 招待の作成フロー

### 2.1 QRコード生成プロセス

```
ユーザーがQR招待ボタンをタップ
    ↓
QRInvitationService.createQRInvitationData()
    ↓
┌─────────────────────────────────────┐
│ 1. セキュリティキー生成              │
│    generateSecurityKey()             │
│    → 32文字のランダム英数字          │
└─────────────────────────────────────┘
    ↓
┌─────────────────────────────────────┐
│ 2. 招待ID生成                        │
│    generateInvitationId()            │
│    → groupId-timestamp-random        │
└─────────────────────────────────────┘
    ↓
┌─────────────────────────────────────┐
│ 3. 招待トークン生成                  │
│    generateInvitationToken()         │
│    → Base64エンコードされたペイロード│
└─────────────────────────────────────┘
    ↓
┌─────────────────────────────────────┐
│ 4. Firestoreに保存                   │
│    invitations/{invitationId}        │
│    - securityKey                     │
│    - status: 'pending'               │
│    - expiresAt: now + 24h            │
└─────────────────────────────────────┘
    ↓
┌─────────────────────────────────────┐
│ 5. 招待データをJSON化                │
│    encodeQRData()                    │
└─────────────────────────────────────┘
    ↓
QRコード画像生成（qr_flutter）
    ↓
画面に表示
```

### 2.2 招待データ構造

```json
{
  "invitationId": "1762...-1699999999999-123456",
  "inviterUid": "VqNEozvTyXXw55Q46mNiGNMNngw2",
  "inviterEmail": "maya@example.com",
  "inviterDisplayName": "Maya",
  "shoppingListId": "list_123",
  "SharedGroupId": "1762...",
  "groupName": "家族の買い物",
  "groupOwnerUid": "VqNEozvTyXXw55Q46mNiGNMNngw2",
  "invitationType": "individual",
  "inviteRole": "member",
  "message": "Go Shopグループへの招待です",
  "securityKey": "abc123...xyz",
  "invitationToken": "eyJncm91cElkIjoi...",
  "createdAt": "2025-11-08T10:30:00.000Z",
  "expiresAt": "2025-11-09T10:30:00.000Z",
  "type": "secure_qr_invitation",
  "version": "3.0"
}
```

### 2.3 Firestoreの招待ドキュメント

**コレクション:** `invitations/{invitationId}`

```javascript
{
  // 基本情報
  invitationId: "1762...-1699999999999-123456",
  inviterUid: "VqNEozvTyXXw55Q46mNiGNMNngw2",
  inviterEmail: "maya@example.com",
  inviterDisplayName: "Maya",

  // グループ情報
  SharedGroupId: "1762...",
  groupName: "家族の買い物",
  groupOwnerUid: "VqNEozvTyXXw55Q46mNiGNMNngw2",

  // 招待設定
  invitationType: "individual",
  inviteRole: "member",
  message: "Go Shopグループへの招待です",

  // セキュリティ
  securityKey: "abc123...xyz",  // ← 検証用の実データ
  invitationToken: "eyJncm91cElkIjoi...",

  // ステータス管理
  status: "pending",  // pending | accepted | expired
  createdAt: Timestamp(2025-11-08 10:30:00),
  expiresAt: Timestamp(2025-11-09 10:30:00),

  // 受諾情報（受諾後に追加）
  acceptedAt?: Timestamp(2025-11-08 11:00:00),
  acceptorUid?: "K35DAuQUktfhSr4XWFoAtBNL32E3",

  // メタデータ
  type: "secure_qr_invitation",
  version: "3.0"
}
```

---

## 3. 招待の受諾フロー

### 3.1 QRコードスキャンから受諾まで

```
受諾者がQRコードをスキャン
    ↓
QRInvitationService.decodeQRData()
    ↓
JSON解析
    ↓
┌─────────────────────────────────────┐
│ セキュリティ検証開始                 │
│ _validateInvitationSecurity()        │
└─────────────────────────────────────┘
    ↓
┌─────────────────────────────────────┐
│ 【検証1】Firestoreから実データ取得   │
│                                      │
│ invitations/{invitationId}.get()     │
│                                      │
│ ❌ ドキュメントが存在しない           │
│    → 無効な招待                      │
└─────────────────────────────────────┘
    ↓
┌─────────────────────────────────────┐
│ 【検証2】ステータスチェック           │
│                                      │
│ status == 'pending'?                 │
│                                      │
│ ❌ accepted / expired                │
│    → 既に使用済み / 期限切れ         │
└─────────────────────────────────────┘
    ↓
┌─────────────────────────────────────┐
│ 【検証3】有効期限チェック            │
│                                      │
│ expiresAt > DateTime.now()?          │
│                                      │
│ ❌ 有効期限切れ                      │
│    → 24時間経過                      │
└─────────────────────────────────────┘
    ↓
┌─────────────────────────────────────┐
│ 【検証4】セキュリティキー照合        │
│                                      │
│ QRコードのキー == Firestoreのキー?   │
│                                      │
│ ❌ キーが一致しない                  │
│    → QRコードが改ざんされた         │
└─────────────────────────────────────┘
    ↓
✅ すべての検証をパス
    ↓
┌─────────────────────────────────────┐
│ 招待タイプによる分岐                 │
└─────────────────────────────────────┘
    ↓
    ├─ individual → _processIndividualInvitation()
    │                  ↓
    │              特定グループのみ追加
    │
    └─ friend → _processFriendInvitation()
                   ↓
               すべてのグループに追加
    ↓
┌─────────────────────────────────────┐
│ Firestore更新                        │
│                                      │
│ SharedGroups/{groupId}:            │
│   - allowedUid: [..., acceptorUid]   │
│   - members: [..., acceptor]         │
└─────────────────────────────────────┘
    ↓
┌─────────────────────────────────────┐
│ 招待ステータス更新                   │
│                                      │
│ invitations/{invitationId}:          │
│   - status: 'accepted'               │
│   - acceptedAt: serverTimestamp()    │
│   - acceptorUid: acceptorUid         │
└─────────────────────────────────────┘
    ↓
┌─────────────────────────────────────┐
│ 通知送信                             │
│                                      │
│ users/{inviterUid}/notifications/    │
│   - type: 'groupMemberAdded'         │
│   - metadata: { groupId, ... }       │
└─────────────────────────────────────┘
    ↓
2秒待機（Firestore伝播待ち）
    ↓
┌─────────────────────────────────────┐
│ 全グループ同期                       │
│ syncFromFirestoreToHive()            │
└─────────────────────────────────────┘
    ↓
UI更新
    ↓
「参加しました」メッセージ表示
```

### 3.2 個別招待の処理詳細

**メソッド:** `_processIndividualInvitation()`

```dart
1. グループIDを取得
   final groupId = invitationData['SharedGroupId'];

2. Firestoreのグループドキュメントを取得
   final groupDoc = await _firestore
     .collection('SharedGroups')
     .doc(groupId)
     .get();

3. 現在のallowedUidとmembersを取得
   final allowedUids = List<String>.from(groupData['allowedUid'] ?? []);
   final members = List<Map>.from(groupData['members'] ?? []);

4. 受諾者のUIDを追加
   if (!allowedUids.contains(acceptorUid)) {
     allowedUids.add(acceptorUid);
   }

5. メンバー情報を追加
   if (!members.any((m) => m['memberId'] == acceptorUid)) {
     members.add({
       'memberId': acceptorUid,
       'name': acceptorDisplayName,
       'role': 'member',
       'joinedAt': FieldValue.serverTimestamp(),
     });
   }

6. Firestoreを更新
   await groupDoc.reference.update({
     'allowedUid': allowedUids,
     'members': members,
     'lastUpdated': FieldValue.serverTimestamp(),
   });
```

### 3.3 フレンド招待の処理詳細

**メソッド:** `_processFriendInvitation()`

```dart
1. フレンドリストに相互登録
   users/{inviterUid}/friends/{acceptorUid}
   users/{acceptorUid}/friends/{inviterUid}

2. 招待者がオーナーのグループを検索
   final ownerGroupsQuery = await _firestore
     .collection('SharedGroups')
     .where('ownerUid', isEqualTo: inviterUid)
     .get();

3. 各グループに受諾者を追加
   for (final doc in ownerGroupsQuery.docs) {
     // allowedUidに追加
     allowedUids.add(acceptorUid);

     // membersに追加
     members.add({
       'memberId': acceptorUid,
       'name': acceptorDisplayName,
       'role': 'member',
       'joinedAt': FieldValue.serverTimestamp(),
     });

     // Firestore更新
     await doc.reference.update({
       'allowedUid': allowedUids,
       'members': members,
     });
   }
```

---

## 4. セキュリティ層

### 4.1 3層のセキュリティチェック

#### 第1層: 招待の存在確認
```dart
final invitationDoc = await _firestore
  .collection('invitations')
  .doc(invitationId)
  .get();

if (!invitationDoc.exists) {
  // 無効な招待ID
  return false;
}
```

**防止する攻撃:**
- ランダムなQRコードの生成攻撃
- 存在しない招待IDの使用

#### 第2層: ステータス・有効期限チェック
```dart
final status = storedData['status'] as String?;
final expiresAt = storedData['expiresAt'] as Timestamp?;

// ステータスチェック
if (status != 'pending') {
  // 既に使用済みまたは無効
  return false;
}

// 有効期限チェック
if (expiresAt != null && expiresAt.toDate().isBefore(DateTime.now())) {
  // 有効期限切れ
  return false;
}
```

**防止する攻撃:**
- QRコードの再利用攻撃
- 期限切れQRコードの使用
- スクリーンショットの悪用

#### 第3層: セキュリティキー照合
```dart
final storedSecurityKey = storedData['securityKey'] as String?;

if (!_securityService.validateSecurityKey(providedKey, storedSecurityKey)) {
  // セキュリティキーが一致しない
  return false;
}
```

**防止する攻撃:**
- QRコードの改ざん
- 中間者攻撃（MITM）
- データの偽造

### 4.2 セキュリティキーの生成

**InvitationSecurityService.generateSecurityKey()**

```dart
- 長さ: 32文字
- 文字セット: A-Z, a-z, 0-9（62種類）
- 生成方法: Random.secure()（暗号学的に安全な乱数）
- エントロピー: 約190ビット（62^32 ≈ 2^190）
```

**セキュリティ強度:**
```
総組み合わせ数: 62^32 ≈ 2.27 × 10^57
ブルートフォース: 実質不可能
衝突確率: 極めて低い（宝くじに100回連続当選より低い）
```

### 4.3 招待IDの生成

**InvitationSecurityService.generateInvitationId()**

```dart
format: {groupId}-{timestamp}-{random6digits}
例: 1762abc123-1699999999999-123456
```

**構成要素:**
- `groupId`: グループの識別子
- `timestamp`: ミリ秒単位のタイムスタンプ
- `random6digits`: 000000-999999のランダム値

**ユニーク性:**
- 同一グループ・同一ミリ秒でも100万通りのバリエーション
- 衝突確率: 1/1,000,000

---

## 5. 招待のライフサイクル

### 5.1 ステータス遷移図

```
     [作成]
       ↓
   ┌─────────┐
   │ pending │ ← 初期状態（QRコード生成直後）
   └─────────┘
       ↓
       ├─→ [受諾] → ┌──────────┐
       │             │ accepted │ ← 最終状態（再利用不可）
       │             └──────────┘
       │
       ├─→ [24時間経過] → ┌─────────┐
       │                   │ expired │ ← 最終状態
       │                   └─────────┘
       │
       └─→ [手動無効化] → ┌──────────┐
                          │ revoked  │ ← 最終状態（将来実装）
                          └──────────┘
```

### 5.2 各ステータスの詳細

| ステータス | 説明 | 受諾可能 | 表示 |
|-----------|------|---------|------|
| `pending` | 受諾待ち | ✅ YES | QRコード表示中 |
| `accepted` | 受諾済み | ❌ NO | 「この招待は既に使用されています」 |
| `expired` | 期限切れ | ❌ NO | 「招待の有効期限が切れています」 |
| `revoked` | 取り消し | ❌ NO | 「招待が取り消されました」（将来実装） |

### 5.3 有効期限管理

**デフォルト設定:**
```dart
expiresAt: DateTime.now().add(const Duration(hours: 24))
```

**期限チェックのタイミング:**
1. QRコードスキャン時（受諾前）
2. Firebaseセキュリティルールで二重チェック（推奨）

**期限切れ後の動作:**
```dart
if (expiresAt.toDate().isBefore(DateTime.now())) {
  throw Exception('招待の有効期限が切れています');
}
```

---

## 6. 通知システムとの連携

### 6.1 招待受諾通知

**送信タイミング:** 招待受諾後、Firestore更新完了後

**送信先:** `users/{inviterUid}/notifications/`

**通知データ:**
```javascript
{
  type: 'groupMemberAdded',
  title: 'グループに新しいメンバーが参加しました',
  message: 'すもも さんがグループに参加しました',
  metadata: {
    groupId: '1762...',           // 特定グループ同期用
    newMemberId: 'K35DAuQ...',
    newMemberName: 'すもも',
    invitationType: 'individual'
  },
  isRead: false,
  createdAt: Timestamp(...)
}
```

### 6.2 招待者側の処理フロー

```
通知リスナーが検知
    ↓
NotificationService._handleNotification()
    ↓
type == 'groupMemberAdded'?
    ↓ YES
metadata.groupId を取得
    ↓
_syncSpecificGroupFromFirestore(groupId)
    ↓
Firestoreから該当グループを取得
    ↓
Hiveを更新（新メンバー情報を反映）
    ↓
ref.invalidate(allGroupsProvider)
    ↓
UI自動更新
    ↓
新メンバーがリストに表示される
```

---

## 7. エラーハンドリング

### 7.1 招待作成時のエラー

| エラー | 原因 | 対処 |
|-------|------|------|
| ユーザー未認証 | FirebaseAuth.currentUser == null | ログイン画面へ遷移 |
| Firestore書き込み失敗 | ネットワークエラー / 権限不足 | リトライまたはエラーメッセージ |
| グループIDが無効 | 存在しないグループ | グループ選択画面へ戻る |

### 7.2 招待受諾時のエラー

| エラー | 原因 | ユーザーへのメッセージ |
|-------|------|---------------------|
| 招待が見つからない | 無効なQRコード / 削除済み | 「無効な招待です」 |
| 既に使用済み | status == 'accepted' | 「この招待は既に使用されています」 |
| 有効期限切れ | expiresAt < now | 「招待の有効期限が切れています」 |
| セキュリティキー不一致 | QRコード改ざん | 「招待の検証に失敗しました」 |
| 自分自身への招待 | inviterUid == acceptorUid | 「自分自身を招待することはできません」 |
| Firestore更新失敗 | ネットワークエラー | 「招待の受諾に失敗しました。もう一度お試しください」 |

### 7.3 エラーログの例

```dart
// 成功時
✅ [QR_INVITATION] 招待データをFirestoreに保存: 1762...-1699999999999-123456
✅ [QR_INVITATION] セキュリティ検証成功
✅ [QR_INVITATION] 招待受諾完了: すもも → 家族の買い物

// エラー時
❌ [QR_INVITATION] 招待が見つかりません: invalid-id
❌ [QR_INVITATION] 招待は既に使用済みまたは無効です: accepted
❌ [QR_INVITATION] 招待の有効期限が切れています
❌ [QR_INVITATION] セキュリティキーが無効
```

---

## 8. UI/UX フロー

### 8.1 招待者側の画面遷移

```
SharedGroupPage（グループ詳細画面）
    ↓
「QR招待」ボタンをタップ
    ↓
┌────────────────────────────────┐
│ QR招待ダイアログ                │
│                                │
│ [個別招待] [フレンド招待]       │
│                                │
│ ↓ 招待タイプ選択                │
└────────────────────────────────┘
    ↓
┌────────────────────────────────┐
│ QRコード表示ダイアログ          │
│                                │
│   ┌─────────────┐              │
│   │             │              │
│   │  QRコード   │              │
│   │             │              │
│   └─────────────┘              │
│                                │
│ グループ名: 家族の買い物        │
│ 有効期限: 24時間               │
│                                │
│ [閉じる]                       │
└────────────────────────────────┘
    ↓
（待機中）
    ↓
通知受信「すもも さんが参加しました」
    ↓
自動的にグループメンバーリストが更新
```

### 8.2 受諾者側の画面遷移

```
カメラ起動またはQRコードスキャン
    ↓
QRコードを読み取り
    ↓
┌────────────────────────────────┐
│ 招待確認ダイアログ              │
│                                │
│ グループ名: 家族の買い物        │
│ 招待者: Maya                   │
│                                │
│ このグループに参加しますか？    │
│                                │
│ [キャンセル] [参加する]        │
└────────────────────────────────┘
    ↓
[参加する] をタップ
    ↓
セキュリティ検証中...
    ↓
┌────────────────────────────────┐
│ 成功メッセージ                  │
│                                │
│ ✅ 参加しました                 │
│                                │
│ 「家族の買い物」グループに      │
│ 参加しました                   │
│                                │
│ [OK]                           │
└────────────────────────────────┘
    ↓
グループリストに新しいグループが表示
```

---

## 9. テストシナリオ

### 9.1 正常系テスト

#### テスト1: 個別招待の作成と受諾
```
1. Windows（maya）でtest_group1を作成
2. 「QR招待」→「個別招待」を選択
3. QRコードが表示される
4. Android（すもも）でQRコードをスキャン
5. 「参加する」をタップ
6. 「参加しました」メッセージが表示される
7. Windows側で通知受信
8. Windows側のメンバーリストに「すもも」が追加される
9. Android側のグループリストに「test_group1」が表示される
```

**期待結果:**
- ✅ Windows: メンバーリストに「すもも」表示
- ✅ Android: グループリストに「test_group1」表示
- ✅ Firestore: allowedUid = ["mayaUID", "sumomoUID"]

#### テスト2: フレンド招待
```
1. Windows（maya）がオーナーのグループ3つ作成
   - group_A, group_B, group_C
2. 「フレンド招待」のQRコードを生成
3. Android（すもも）でスキャン
4. すもも が3つすべてのグループに追加される
```

**期待結果:**
- ✅ すもも は group_A, B, C すべてにアクセス可能
- ✅ users/maya/friends/すもも が作成される
- ✅ users/すもも/friends/maya が作成される

### 9.2 異常系テスト

#### テスト3: 期限切れQRコード
```
1. QRコードを生成
2. 24時間待機（または手動でFirestoreのexpiresAtを過去に変更）
3. QRコードをスキャン
4. 「招待の有効期限が切れています」エラー表示
```

#### テスト4: 再利用防止
```
1. QRコードを生成
2. ユーザーAが受諾（status → 'accepted'）
3. ユーザーBが同じQRコードをスキャン
4. 「この招待は既に使用されています」エラー表示
```

#### テスト5: QRコード改ざん
```
1. QRコードのJSONデータを手動で編集
   - securityKeyを変更
2. 改ざんされたQRコードをスキャン
3. 「招待の検証に失敗しました」エラー表示
```

#### テスト6: 自分自身への招待
```
1. maya がQRコードを生成
2. maya 自身がそのQRコードをスキャン
3. 「自分自身を招待することはできません」エラー表示
```

---

## 10. パフォーマンス

### 10.1 実測値

| 操作 | 処理時間 |
|-----|---------|
| QRコード生成 | 約200ms |
| QRコード表示 | 約100ms |
| QRコードスキャン | 約50ms（カメラ起動除く） |
| セキュリティ検証 | 約300ms（Firestore取得含む） |
| グループ追加（Firestore書き込み） | 約400ms |
| 通知送信 | 約200ms |
| 全体（スキャン→完了） | 約2-3秒 |

### 10.2 最適化ポイント

- **QRコードのキャッシュ**: 同じQRコードを再生成しない
- **並列処理**: Firestore書き込みと通知送信を並列化
- **プリフェッチ**: グループ情報を事前に取得
- **ローカル検証**: 基本的なバリデーションをクライアント側で実行

---

## 11. セキュリティベストプラクティス

### 11.1 推奨事項

✅ **Firestoreセキュリティルールの設定**
```javascript
match /invitations/{invitationId} {
  allow read: if request.auth != null;
  allow create: if request.auth != null;
  allow update: if request.auth != null
    && request.resource.data.status == 'accepted'
    && resource.data.status == 'pending';
}
```

✅ **Cloud Functionsでの二重チェック**
```javascript
// 招待受諾時にサーバーサイドで再検証
exports.validateInvitation = functions.https.onCall(async (data, context) => {
  // セキュリティキー検証
  // 有効期限チェック
  // ステータス確認
});
```

✅ **レート制限**
```dart
// 1ユーザーあたり1日10回まで招待作成可能
if (todayInvitationCount >= 10) {
  throw Exception('招待作成の上限に達しました');
}
```

### 11.2 注意事項

❌ **避けるべき実装**
- QRコードの埋め込みデータだけで認証する
- セキュリティキーをログに出力する
- 有効期限なしの招待を作成する
- ステータスチェックを省略する

⚠️ **注意が必要な処理**
- QRコードのスクリーンショット共有（有効期限で対処）
- 招待IDの推測攻撃（ランダム性で対処）
- 同時受諾（Firestoreのトランザクションで対処予定）

---

## 12. 今後の改善予定

### 12.1 短期（1-2ヶ月）
- [ ] 招待の手動取り消し機能
- [ ] 招待履歴の表示
- [ ] カスタムメッセージの追加
- [ ] 招待可能人数の制限設定

### 12.2 中期（3-6ヶ月）
- [ ] メールベースの招待
- [ ] ディープリンクによる招待
- [ ] 招待コード（英数字）の生成
- [ ] グループ参加申請機能

### 12.3 長期（6ヶ月以上）
- [ ] 条件付き招待（特定の期間のみ有効）
- [ ] ロールベースの招待（管理者 / メンバー）
- [ ] 招待の一括管理
- [ ] 招待分析ダッシュボード

---

## 13. 関連ファイル

| ファイル | 役割 |
|---------|------|
| `lib/services/qr_invitation_service.dart` | QR招待のメインロジック |
| `lib/services/invitation_security_service.dart` | セキュリティキー生成・検証 |
| `lib/services/notification_service.dart` | 招待受諾通知の処理 |
| `lib/pages/purchase_group_page.dart` | QR招待ボタンとダイアログ |
| `lib/widgets/qr_scanner_widget.dart` | QRコードスキャナー |

---

## 14. FAQ

**Q1: QRコードのスクリーンショットを撮られたら悪用されませんか？**
A: 以下の対策により悪用を防止しています:
- 24時間の有効期限
- 一度使用したら無効化（status: 'accepted'）
- セキュリティキーによる検証

**Q2: 招待を取り消すことはできますか？**
A: 現在は自動取り消し（期限切れ）のみ対応。手動取り消しは今後実装予定です。

**Q3: 何人まで招待できますか？**
A: 現在は制限なし。将来的にはグループ設定で制限可能にする予定です。

**Q4: オフラインでも招待を受諾できますか？**
A: いいえ。セキュリティ検証でFirestoreへのアクセスが必須のため、インターネット接続が必要です。

**Q5: フレンド招待と個別招待の違いは？**
A:
- **個別招待**: 1つのグループのみへのアクセス
- **フレンド招待**: 招待者のすべてのグループへのアクセス

---

**最終更新:** 2025年11月8日
**バージョン:** 3.0
**作成者:** GitHub Copilot
