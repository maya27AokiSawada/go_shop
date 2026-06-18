# 🌸 さくらインターネット SMTP設定 専用ガイド

## 📧 sumomo-planning@sakura.ne.jp でのメール送信設定

### 🔧 Firebase Extensions Trigger Email 設定

#### 📮 さくらインターネット SMTP 推奨設定

**プライマリ設定（SMTPS ポート465）:**

```
SMTP Connection URI: smtps://sumomo-planning%40sakura.ne.jp:YOUR_PASSWORD@mail.sakura.ne.jp:465
Default FROM address: sumomo-planning@sakura.ne.jp
Default REPLY-TO address: sumomo-planning@sakura.ne.jp
```

**セカンダリ設定（SMTP+TLS ポート587）:**

```
SMTP Connection URI: smtp://sumomo-planning%40sakura.ne.jp:YOUR_PASSWORD@mail.sakura.ne.jp:587
Default FROM address: sumomo-planning@sakura.ne.jp
Default REPLY-TO address: sumomo-planning@sakura.ne.jp
```

### 🔑 さくらインターネット 事前設定確認

#### 1. **メールアドレス設定確認**

- さくらのレンタルサーバ コントロールパネルにログイン
- 「メール設定」→「メールアドレス設定」
- `sumomo-planning@sakura.ne.jp` が作成済みか確認

#### 2. **SMTP認証設定**

- 「メール設定」→「送信制限設定」
- SMTP認証が「有効」になっていることを確認
- 外部送信許可が必要な場合は設定

#### 3. **パスワード確認**

- メールアドレスのパスワードを確認
- Firebase Extensions設定で使用するパスワードを準備

### 🎯 Firebase Console での設定手順

#### Extensions インストール後の設定

1. **Firebase Console** → **Extensions** → **Trigger Email**
2. **Configure** をクリック

#### 重要パラメータ設定

| パラメータ                   | 設定値                                                                    |
| ---------------------------- | ------------------------------------------------------------------------- |
| **SMTP Connection URI**      | `smtps://sumomo-planning%40sakura.ne.jp:パスワード@mail.sakura.ne.jp:465` |
| **Default FROM address**     | `sumomo-planning@sakura.ne.jp`                                            |
| **Default REPLY-TO address** | `sumomo-planning@sakura.ne.jp`                                            |
| **Cloud Firestore path**     | `mail`                                                                    |
| **Email documents TTL**      | `86400`                                                                   |

### 📝 Firestore セキュリティルール

現在のルールで対応済み（認証済みユーザーに書き込み許可）:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

### 🧪 テスト用メール送信コード

既存の `EmailTestService` を使用してテスト:

```dart
// 任意のテスト用メールアドレスにテスト送信
await FirebaseFirestore.instance.collection('mail').add({
  'to': 'tester@example.com',
  'message': {
    'subject': 'Go Shop - さくらインターネット SMTP テスト',
    'text': 'さくらインターネット (sumomo-planning@sakura.ne.jp) からのテスト送信です。',
    'html': '''
      <h1>🌸 Go Shop メールテスト</h1>
      <p>送信者: sumomo-planning@sakura.ne.jp</p>
      <p>SMTPサーバー: mail.sakura.ne.jp</p>
      <p>テスト送信成功！</p>
    ''',
  },
});
```

### 🔍 トラブルシューティング

#### よくある問題と解決策

**1. 認証エラー**

```
エラー: SMTP Authentication failed
解決策: さくらコントロールパネルでSMTP認証が有効か確認
```

**2. 接続タイムアウト**

```
エラー: Connection timeout
解決策: ポート587を試す（465がブロックされている場合）
```

**3. 送信制限エラー**

```
エラー: Mail sending restricted
解決策: さくらコントロールパネルで外部送信許可を設定
```

#### デバッグ用ログ確認

Firebase Console → Functions → Logs で以下を確認:

- SMTP接続ログ
- 認証成功/失敗ログ
- メール送信結果

### 🚀 実行手順

1. **さくらコントロールパネル設定確認** ✅
2. **Firebase Extensions Trigger Email インストール** ✅
3. **SMTP設定入力** (sumomo-planning@sakura.ne.jp)
4. **Go Shop アプリでテスト実行** ✅
5. **任意のテスト用メールアドレスで受信確認** 📧

### 📱 Go Shop アプリでのテスト

アプリ起動後:

1. ログイン
2. ホーム画面スクロール
3. 「🧪 メール送信テスト」セクション
4. 「メール送信テスト」ボタンクリック
5. さくらインターネットSMTPで任意のテスト受信先に送信

**設定完了後、設定した送信元から任意の受信テスト先へのメール送信が可能になります。**
