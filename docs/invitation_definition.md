# 招待機能仕様 (期限付きセキュリティキー方式)

## 基本仕様
- グループごとの招待
- 招待時のロールは一般ユーザー(member)
- オーナーと管理者がロールを昇格可能
- **期限付き招待トークン (24時間有効)**
- **1トークンで最大5人まで招待可能**

---

## データ構造

### 1. Firestore: `/invitations/{invitationToken}`
招待トークン情報を一時保存 (期限切れ後は自動削除可能)

```json
{
  "token": "INV_abc123xyz789",
  "groupId": "1762322612481",
  "groupName": "家族グループ",
  "invitedBy": "ownerUid",
  "inviterName": "Maya",
  "createdAt": "2025-11-07T10:00:00Z",
  "expiresAt": "2025-11-08T10:00:00Z",
  "maxUses": 5,
  "currentUses": 0,
  "usedBy": []
}
```

### 2. Firestore: `/users/{ownerUid}/groups/{groupId}`
既存のグループドキュメント (members配列に追加)

```json
{
  "groupId": "1762322612481",
  "groupName": "家族グループ",
  "ownerUid": "ownerUid123",
  "members": [
    {
      "memberId": "ownerUid123",
      "name": "Maya",
      "role": "owner",
      "invitationStatus": "self"
    },
    {
      "memberId": "invitedUid456",
      "name": "招待ユーザー",
      "role": "member",
      "invitationStatus": "accepted"
    }
  ]
}
```

---

## 招待処理フロー

### **Phase 1: 招待QRコード生成 (招待元)**

1. **UI操作**:
   - グループメンバー管理画面 → 「メンバー招待」ボタン

2. **トークン生成**:
   ```dart
   final token = 'INV_${Uuid().v4()}';
   final expiresAt = DateTime.now().add(Duration(hours: 24));
   ```

3. **Firestoreに保存**:
   ```dart
   await FirebaseFirestore.instance
     .collection('invitations')
     .doc(token)
     .set({
       'token': token,
       'groupId': currentGroup.groupId,
       'groupName': currentGroup.groupName,
       'invitedBy': currentUser.uid,
       'inviterName': currentUser.displayName,
       'createdAt': FieldValue.serverTimestamp(),
       'expiresAt': Timestamp.fromDate(expiresAt),
       'maxUses': 5,
       'currentUses': 0,
       'usedBy': [],
     });
   ```

4. **QRコード表示**:
   ```json
   QRコードに含むデータ:
   {
     "type": "go_shop_invitation",
     "version": "1.0",
     "token": "INV_abc123xyz789"
   }
   ```

5. **共有オプション**:
   - QRコード画像として保存
   - リンクとして共有: `goshop://invite?token=INV_abc123xyz789`

---

### **Phase 2: 招待受諾 (招待される側)**

1. **QRコードスキャン**:
   - アプリ内のQRスキャナーで読み取り

2. **トークン検証**:
   ```dart
   final invitationDoc = await FirebaseFirestore.instance
     .collection('invitations')
     .doc(token)
     .get();

   // 検証項目:
   if (!invitationDoc.exists) throw '招待が見つかりません';
   if (invitationDoc['expiresAt'].toDate().isBefore(DateTime.now())) {
     throw '招待の有効期限が切れています';
   }
   if (invitationDoc['currentUses'] >= invitationDoc['maxUses']) {
     throw '招待の使用回数上限に達しています';
   }
   if (invitationDoc['usedBy'].contains(currentUser.uid)) {
     throw 'すでにこの招待を使用しています';
   }
   ```

3. **グループ情報取得**:
   ```dart
   final groupRef = FirebaseFirestore.instance
     .collection('users')
     .doc(invitationDoc['invitedBy'])
     .collection('groups')
     .doc(invitationDoc['groupId']);
   ```

4. **メンバーとして追加**:
   ```dart
   final newMember = {
     'memberId': currentUser.uid,
     'name': currentUser.displayName ?? 'ユーザー',
     'contact': currentUser.email ?? '',
     'role': 'member',
     'invitationStatus': 'accepted',
     'isSignedIn': true,
   };

   await groupRef.update({
     'members': FieldValue.arrayUnion([newMember]),
     'updatedAt': FieldValue.serverTimestamp(),
   });
   ```

5. **招待トークン更新**:
   ```dart
   await FirebaseFirestore.instance
     .collection('invitations')
     .doc(token)
     .update({
       'currentUses': FieldValue.increment(1),
       'usedBy': FieldValue.arrayUnion([currentUser.uid]),
     });
   ```

6. **自分のFirestoreにもコピー** (ハイブリッド同期):
   ```dart
   // 自分のFirestoreパスにもグループ情報を保存
   await FirebaseFirestore.instance
     .collection('users')
     .doc(currentUser.uid)
     .collection('groups')
     .doc(invitationDoc['groupId'])
     .set(groupData);
   ```

7. **ローカルHiveに同期**:
   ```dart
   await hiveRepository.saveGroup(group);
   ```

---

## セキュリティ対策

### 1. **トークンの安全性**
- UUID v4形式 (128bit) = 2^128通り (推測不可能)
- プレフィックス `INV_` で識別

### 2. **Firestore Security Rules**
```javascript
match /invitations/{token} {
  // 誰でも読み取り可能 (QRスキャン時)
  allow read: if request.auth != null;

  // グループオーナーのみ作成可能
  allow create: if request.auth != null
    && request.resource.data.invitedBy == request.auth.uid;

  // 招待使用時のみ更新可能 (currentUses, usedBy)
  allow update: if request.auth != null
    && request.auth.uid not in resource.data.usedBy
    && request.resource.data.currentUses <= request.resource.data.maxUses;
}
```

### 3. **期限切れトークンの削除**
- Cloud Functionsで定期実行 (推奨):
  ```javascript
  // 24時間ごとに期限切れトークンを削除
  exports.cleanupExpiredInvitations = functions.pubsub
    .schedule('every 24 hours')
    .onRun(async (context) => {
      const expired = await db.collection('invitations')
        .where('expiresAt', '<', admin.firestore.Timestamp.now())
        .get();

      expired.forEach(doc => doc.ref.delete());
    });
  ```

- または、アプリ側で期限切れチェック時に削除

---

## ロール管理

### メンバーロール昇格 (オーナー/管理者のみ)
```dart
await groupRef.update({
  'members': updatedMembersArray,
  'updatedAt': FieldValue.serverTimestamp(),
});
```

### グループ退出/削除
- **オーナー**: グループ全体を削除 (`isDeleted: true`)
- **他メンバー**: 自分の`memberId`を`members`から削除

---

## UI/UX

### 招待元画面
1. 「メンバー招待」ボタン
2. QRコード表示
3. **「招待コードを表示」ボタン** (タップでトークン文字列表示)
4. 「リンクをコピー」ボタン
5. 有効期限表示: 「あと23時間58分」
6. 使用状況: 「0/5人が参加」

**表示イメージ**:
```
┌─────────────────────────┐
│   メンバー招待          │
├─────────────────────────┤
│                         │
│   [QRコード画像]        │
│                         │
├─────────────────────────┤
│ 📋 招待コードを表示     │  ← タップで文字列表示
├─────────────────────────┤
│ 🔗 リンクをコピー       │
├─────────────────────────┤
│ ⏰ あと23時間58分       │
│ 👥 0/5人が参加         │
└─────────────────────────┘
```

### 招待される側画面

#### **パターンA: QRスキャン**
1. 「QRコードで参加」ボタン
2. カメラ起動 → QRスキャン
3. グループ情報プレビュー表示
4. 「参加する」ボタン
5. 参加完了通知

#### **パターンB: 招待コード手動入力** (NEW!)
1. **「招待コードで参加」ボタン**
2. **招待コード入力フィールド**:
   ```
   ┌─────────────────────────────┐
   │ 招待コードを入力            │
   ├─────────────────────────────┤
   │ INV_abc123-def456-ghi789... │ ← テキスト入力
   ├─────────────────────────────┤
   │      [参加する]             │
   └─────────────────────────────┘
   ```
3. 入力検証:
   - プレフィックス `INV_` チェック
   - 文字列フォーマット検証
   - リアルタイム入力補助 (ハイフン自動挿入など)
4. グループ情報プレビュー表示
5. 「参加する」ボタン
6. 参加完了通知

**UI配置例**:
```
┌────────────────────────────┐
│   グループに参加           │
├────────────────────────────┤
│                            │
│  📷 QRコードで参加         │  ← タップでスキャナー起動
│                            │
├────────────────────────────┤
│                            │
│  🔢 招待コードで参加       │  ← タップで入力画面表示
│                            │
└────────────────────────────┘
```

### 招待コード表示画面 (招待元)
```
┌─────────────────────────────┐
│   招待コード                │
├─────────────────────────────┤
│                             │
│  INV_a1b2c3d4-e5f6-g7h8... │  ← 選択可能なテキスト
│                             │
├─────────────────────────────┤
│     [コピー]                │  ← ワンタップでコピー
├─────────────────────────────┤
│ ℹ️ このコードを共有して      │
│    グループに招待できます    │
│                             │
│ ⚠️ 有効期限: 24時間         │
└─────────────────────────────┘
```

### 招待コード入力画面 (招待される側)
```
┌─────────────────────────────┐
│   招待コードを入力          │
├─────────────────────────────┤
│                             │
│  [___________________]      │  ← テキスト入力フィールド
│   INV_...を入力             │  ← プレースホルダー
│                             │
├─────────────────────────────┤
│  📋 クリップボードから       │  ← 自動検出&貼り付け
│     貼り付け                │
├─────────────────────────────┤
│     [次へ]                  │  ← 検証後に有効化
├─────────────────────────────┤
│ ℹ️ 招待コードは「INV_」で    │
│    始まる文字列です         │
└─────────────────────────────┘
```

---

## エラーハンドリング

| エラー種別 | エラー内容 | メッセージ | 対応方法 |
|-----------|-----------|-----------|---------|
| **入力エラー** | 空白入力 | 招待コードを入力してください | - |
| | フォーマット不正 | 招待コードの形式が正しくありません | 「INV_」で始まる形式を確認 |
| | プレフィックス不正 | 招待コードは「INV_」で始まる必要があります | コピー&ペースト推奨 |
| **検証エラー** | トークン不正 | 招待コードが無効です | 招待元に再発行を依頼 |
| | 期限切れ | 招待の有効期限が切れています (24時間以内に再発行してください) | 新しい招待コードを取得 |
| | 使用回数超過 | この招待は使用できません (新しい招待を発行してもらってください) | 新しい招待コードを取得 |
| | 重複参加 | すでにこのグループに参加しています | グループ一覧を確認 |
| **ネットワークエラー** | 接続失敗 | 接続を確認してください | Wi-Fi/モバイルデータ確認 |
| | タイムアウト | 通信がタイムアウトしました。再試行してください | リトライボタン表示 |
| **QRエラー** | スキャン失敗 | QRコードを読み取れませんでした | 手動入力に切り替え案内 |
| | カメラ権限なし | カメラへのアクセスが許可されていません | 設定画面へ誘導 |

### 入力検証ロジック
```dart
String? validateInvitationCode(String input) {
  // 空白チェック
  if (input.trim().isEmpty) {
    return '招待コードを入力してください';
  }

  // プレフィックスチェック
  if (!input.startsWith('INV_')) {
    return '招待コードは「INV_」で始まる必要があります';
  }

  // 最小長チェック (INV_ + UUID = 最低40文字程度)
  if (input.length < 40) {
    return '招待コードの形式が正しくありません';
  }

  // 許可文字チェック (英数字、ハイフン、アンダースコアのみ)
  final validPattern = RegExp(r'^INV_[a-zA-Z0-9\-_]+$');
  if (!validPattern.hasMatch(input)) {
    return '招待コードに使用できない文字が含まれています';
  }

  return null; // 検証OK
}
```

---

## 実装優先度

### Phase 1: 基本機能 (MVP)
- [x] 招待トークン生成・保存 (Firestore)
- [x] QRコード生成・表示
- [x] **招待コード文字列表示** (NEW!)
- [x] QRスキャン機能
- [x] **招待コード手動入力** (NEW!)
- [x] トークン検証
- [x] メンバー追加処理
- [x] 基本的なエラーハンドリング

### Phase 2: UX改善
- [ ] **クリップボード自動検出** (NEW!)
  - アプリ起動時にクリップボードをチェック
  - `INV_` プレフィックスを検出したら自動提案
- [ ] リアルタイム入力補助
  - ハイフン自動挿入
  - 大文字小文字自動変換
- [ ] 有効期限カウントダウン表示
- [ ] 参加人数リアルタイム更新
- [ ] 招待リンク共有 (Share API)

### Phase 3: 拡張機能
- [ ] 招待履歴の表示
- [ ] 招待の取り消し機能
- [ ] カスタム有効期限 (1時間/24時間/1週間)
- [ ] カスタム使用回数制限
- [ ] 招待専用ロール設定
- [ ] プッシュ通知 (メンバー参加時)

---

## 今後の拡張性

### セキュリティ強化
- [ ] 二要素認証的な承認フロー (招待元が手動承認)
- [ ] IP制限・地域制限
- [ ] 招待元による参加メンバーの事前承認

### 利便性向上
- [ ] ディープリンク対応 (`goshop://invite?token=...`)
- [ ] SMS/メール共有
- [ ] 招待URLの短縮化
- [ ] オフライン招待 (ローカル一時保存)

### 業務アプリ版対応 (Future)
- [ ] **設定ファイルによる自動データ作成**
  - YAML/JSON形式のグループ定義
  - 初期メンバー・ロール一括設定
  - テンプレート機能
- [ ] 組織階層対応
  - 部署・チーム単位のグループ管理
  - 権限継承・委譲
- [ ] 監査ログ
  - 招待・参加履歴の記録
  - アクセスログ
- [ ] 一括招待機能
  - CSVインポート
  - メールアドレスリストから一括招待

---

## 業務アプリ版: 設定ファイル仕様 (案)

### YAML形式の設定例

```yaml
# organization_config.yaml
organization:
  name: "株式会社サンプル"
  admin_email: "admin@example.com"

groups:
  - id: "sales_team"
    name: "営業部"
    description: "営業チームの買い物リスト"
    auto_create: true
    members:
      - email: "tanaka@example.com"
        name: "田中太郎"
        role: "admin"
      - email: "suzuki@example.com"
        name: "鈴木花子"
        role: "member"
    default_lists:
      - name: "定期購入品"
        items:
          - name: "コピー用紙"
            quantity: 10
            unit: "箱"
          - name: "ボールペン"
            quantity: 50
            unit: "本"

  - id: "dev_team"
    name: "開発部"
    description: "開発チームの備品リスト"
    auto_create: true
    members:
      - email: "yamada@example.com"
        name: "山田一郎"
        role: "owner"
      - email: "sato@example.com"
        name: "佐藤二郎"
        role: "admin"
    default_lists:
      - name: "開発環境機材"
        items:
          - name: "USBメモリ"
            quantity: 5
            unit: "個"

settings:
  invitation:
    default_expiry_hours: 168  # 1週間
    max_uses: 50
    require_approval: false
  security:
    allowed_domains:
      - "example.com"
      - "sample.co.jp"
    ip_whitelist:
      - "192.168.1.0/24"
```

### JSON形式の設定例

```json
{
  "organization": {
    "name": "株式会社サンプル",
    "admin_email": "admin@example.com"
  },
  "groups": [
    {
      "id": "sales_team",
      "name": "営業部",
      "auto_create": true,
      "members": [
        {
          "email": "tanaka@example.com",
          "name": "田中太郎",
          "role": "admin"
        }
      ],
      "default_lists": [
        {
          "name": "定期購入品",
          "items": [
            {
              "name": "コピー用紙",
              "quantity": 10,
              "unit": "箱"
            }
          ]
        }
      ]
    }
  ],
  "settings": {
    "invitation": {
      "default_expiry_hours": 168,
      "max_uses": 50,
      "require_approval": false
    }
  }
}
```

### 自動データ作成フロー

```dart
// 1. 設定ファイル読み込み
Future<void> initializeFromConfig(String configPath) async {
  final config = await loadYamlConfig(configPath);

  // 2. 組織情報設定
  await setupOrganization(config['organization']);

  // 3. グループ一括作成
  for (final groupConfig in config['groups']) {
    if (groupConfig['auto_create'] == true) {
      final group = await createGroupFromConfig(groupConfig);

      // 4. メンバー招待
      for (final memberConfig in groupConfig['members']) {
        await inviteMemberFromConfig(group, memberConfig);
      }

      // 5. デフォルトリスト作成
      for (final listConfig in groupConfig['default_lists']) {
        await createListFromConfig(group, listConfig);
      }
    }
  }

  // 6. 設定適用
  await applySettings(config['settings']);
}

// メンバー招待処理
Future<void> inviteMemberFromConfig(
  PurchaseGroup group,
  Map<String, dynamic> memberConfig
) async {
  // メールアドレスベースの招待
  final email = memberConfig['email'];
  final role = memberConfig['role'];

  // 招待トークン生成
  final token = await generateInvitationToken(
    groupId: group.groupId,
    email: email,
    role: role,
    expiryHours: settings.invitation.default_expiry_hours,
  );

  // メール送信
  await sendInvitationEmail(
    to: email,
    token: token,
    groupName: group.groupName,
  );
}
```

### 管理者用UI (Future)

```
┌────────────────────────────────┐
│   組織設定                     │
├────────────────────────────────┤
│                                │
│  📁 設定ファイルをインポート   │  ← YAML/JSON選択
│                                │
├────────────────────────────────┤
│  現在の組織: 株式会社サンプル   │
│  グループ数: 5                 │
│  総メンバー数: 23              │
├────────────────────────────────┤
│                                │
│  [プレビュー]  [実行]          │
│                                │
└────────────────────────────────┘
```

### セキュリティ考慮事項

1. **ドメイン制限**:
   - 許可ドメインからのメールアドレスのみ招待可能

2. **IP制限**:
   - 社内ネットワークからのみ設定インポート可能

3. **承認フロー**:
   - 管理者承認必須オプション

4. **監査ログ**:
   - 設定変更・一括作成の記録
   - 誰が・いつ・何を変更したか

### ユースケース例

#### ケース1: 新規部署立ち上げ
1. 管理者がYAMLファイル作成
2. 部署名・メンバーリストを定義
3. アプリでインポート実行
4. 自動でグループ作成 + メンバー招待メール送信
5. メンバーがリンクから参加

#### ケース2: 定期購入品リストの標準化
1. 全営業所共通の購入品リストをYAMLで定義
2. 各営業所グループに一括適用
3. 各営業所が個別にカスタマイズ可能

#### ケース3: 組織変更対応
1. 異動・配置転換をYAMLで記述
2. インポートで自動反映
3. 旧グループからの削除 + 新グループへの追加
