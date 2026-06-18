# 📧 Firebase Extensions Trigger Email 設定ガイド

## 🎯 概要

任意のテスト用メールアドレスへのメール送信テスト機能を実装するための Firebase Extensions Trigger Email の詳細設定手順です。

## 🔧 Firebase Console での設定手順

### 1. Firebase Extensions のインストール

1. **Firebase Console** にアクセス
   - https://console.firebase.google.com/
   - 自分の Firebase プロジェクトを選択

2. **Extensions** セクションを開く
   - 左サイドバーから「Extensions」をクリック
   - 「Browse Hub」をクリック

3. **Trigger Email** を検索・インストール
   - 検索バーで "Trigger Email" を検索
   - 「Trigger Email」拡張機能を選択
   - 「Install in Firebase project」をクリック

### 2. アクセス権限とロール設定

#### 🔐 必要な IAM ロール

**プロジェクト所有者またはエディターとして以下の権限を確認：**

```bash
# Firebase CLI でログイン状態確認
firebase login

# プロジェクト設定確認
firebase projects:list
firebase use <your-firebase-project-id>
```

#### 📝 Cloud Firestore セキュリティルール

現在のルール（開発環境）:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // 認証済みユーザーに全アクセス許可（開発環境）
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

**メール送信用コレクションの追加ルール:**

```javascript
// メール送信コレクション用ルール
match /mail/{mailId} {
  allow create: if request.auth != null;
  allow read: if request.auth != null &&
              resource.data.uid == request.auth.uid;
}
```

### 3. Extensions 設定パラメータ

#### 🌟 基本設定

| パラメータ               | 値          | 説明                                       |
| ------------------------ | ----------- | ------------------------------------------ |
| **Cloud Firestore path** | `mail`      | メール送信リクエストを保存するコレクション |
| **Email documents TTL**  | `86400`     | メールドキュメントの生存時間（24時間）     |
| **Users collection**     | `users`     | ユーザー情報コレクション                   |
| **Templates collection** | `templates` | メールテンプレートコレクション             |

#### 📮 SMTP 設定（重要）

**さくらインターネット SMTP設定:**

```
SMTP Connection URI: smtps://sumomo-planning%40sakura.ne.jp:YOUR_PASSWORD@mail.sakura.ne.jp:465
Default FROM address: sumomo-planning@sakura.ne.jp
Default REPLY-TO address: sumomo-planning@sakura.ne.jp
```

**さくらインターネット代替設定（ポート587使用）:**

```
SMTP Connection URI: smtp://sumomo-planning%40sakura.ne.jp:YOUR_PASSWORD@mail.sakura.ne.jp:587
Default FROM address: sumomo-planning@sakura.ne.jp
Default REPLY-TO address: sumomo-planning@sakura.ne.jp
```

**Gmail SMTP設定例（参考）:**

```
SMTP Connection URI: smtps://YOUR_EMAIL%40gmail.com:YOUR_APP_PASSWORD@smtp.gmail.com:465
Default FROM address: YOUR_EMAIL@gmail.com
Default REPLY-TO address: YOUR_EMAIL@gmail.com
```

#### 🔑 さくらインターネット メール設定手順

1. **さくらインターネット コントロールパネル**
   - さくらのレンタルサーバ コントロールパネルにログイン
   - 「メール設定」→「メールアドレス設定」

2. **SMTP認証設定確認**
   - メールアドレス: `sumomo-planning@sakura.ne.jp`
   - SMTPサーバー: `mail.sakura.ne.jp`
   - ポート: 465（SMTPS） または 587（SMTP over TLS）
   - 認証: 必要（メールアドレスとパスワード）

3. **セキュリティ設定**
   - SMTP認証が有効になっていることを確認
   - 必要に応じて外部送信許可を設定

#### 🔑 Gmail App Password の作成手順（参考）

1. **Googleアカウント設定**
   - https://myaccount.google.com/security
   - 「2段階認証プロセス」を有効化

2. **アプリパスワード生成**
   - 「2段階認証プロセス」→「アプリパスワード」
   - 「アプリを選択」→「その他（カスタム名）」
   - 「Go Shop App」と入力
   - 生成された16桁のパスワードを使用

### 4. Firestore コレクション構造

#### 📄 メール送信ドキュメント構造

```javascript
// /mail/{docId} コレクション
{
   to: "tester@example.com",
  message: {
    subject: "Go Shop - テスト送信",
    text: "これは Go Shop アプリからのテスト送信です。",
    html: "<h1>Go Shop テスト</h1><p>メール送信テスト成功！</p>"
  },
  template: {
    name: "welcome", // オプション
    data: {
      userName: "テストユーザー",
      appName: "Go Shop"
    }
  }
}
```

### 5. セキュリティ設定

#### 🛡️ Firebase Authentication 設定

```dart
// Flutter アプリでの認証チェック
User? user = FirebaseAuth.instance.currentUser;
if (user == null) {
  throw Exception('ユーザーが認証されていません');
}
```

#### 🔒 環境変数設定

**Firebase Functions の環境変数:**

```bash
firebase functions:config:set gmail.email="your.email@gmail.com"
firebase functions:config:set gmail.password="your-app-password"
```

### 6. テスト実行手順

#### 🧪 基本テスト

1. **Flutter アプリからのテスト**

```dart
await EmailTestService.sendTestEmail('tester@example.com');
```

2. **Firebase Console での確認**
   - Firestore → `mail` コレクション
   - Extensions → Trigger Email → Logs

3. **ログ確認**
   - Firebase Console → Functions → Logs
   - エラーメッセージと送信状況を確認

#### 🔍 トラブルシューティング

**よくある問題:**

1. **SMTP認証エラー**

   ```
   解決策: Gmail App Passwordの再生成
   ```

2. **権限エラー**

   ```
   解決策: IAM ロール「Firebase Admin」を付与
   ```

3. **Firestore ルールエラー**
   ```
   解決策: mail コレクションの書き込み権限確認
   ```

### 7. 実装コード例

#### 📱 Flutter側実装

```dart
// lib/services/email_test_service.dart で既に実装済み
Future<void> sendTestEmail(String email) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) throw Exception('認証が必要です');

  await FirebaseFirestore.instance.collection('mail').add({
    'to': email,
    'message': {
      'subject': 'Go Shop - テスト送信',
      'text': 'Go Shop アプリからのテスト送信です。',
      'html': '<h1>Go Shop</h1><p>メール送信テスト成功！</p>',
    },
  });
}
```

## 🚀 次のステップ

1. ✅ Firebase Extensions Trigger Email インストール
2. ✅ SMTP設定（Gmail App Password）
3. ✅ Firestore セキュリティルール更新
4. ✅ テスト送信実行
5. ✅ 任意の受信テスト用メールアドレスでの受信確認

**完了後、Go Shop アプリの「🧪 メール送信テスト」機能が完全に動作します！**
