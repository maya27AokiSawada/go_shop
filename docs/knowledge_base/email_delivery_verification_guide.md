# 📧 Firebase Extensions Trigger Email 送信確認方法

## 🔍 メール送信状況の確認手順

### 1. **Firebase Console での確認**

#### 📊 Functions ログ確認
1. **Firebase Console** → **Functions** → **ログ**
2. 時間順にログを確認し、以下のメッセージを探す：

**成功時のログ:**
```
✅ Message sent successfully: <messageId>
✅ Email sent to: fatima.sumomo@gmail.com
✅ SMTP connection established
```

**エラー時のログ:**
```
❌ SMTP Authentication failed
❌ Connection timeout to mail.sakura.ne.jp
❌ Invalid recipient address
```

#### 📈 Extensions 実行状況
1. **Firebase Console** → **Extensions** → **Trigger Email**
2. **実行状況** タブで送信履歴を確認
3. **設定** で SMTP設定が正しいか確認

### 2. **Firestore での確認**

#### 📄 mail コレクションのドキュメント状態

Firebase Console → Firestore Database → `mail` コレクション

**処理前（送信待ち）:**
```javascript
{
  to: "fatima.sumomo@gmail.com",
  message: {
    subject: "Go Shop テスト",
    text: "テスト内容"
  }
  // delivery フィールドなし = 未処理
}
```

**処理後（送信完了）:**
```javascript
{
  to: "fatima.sumomo@gmail.com",
  message: { ... },
  delivery: {
    state: "SUCCESS",
    attempts: 1,
    endTime: "2025-10-10T10:00:00.000Z",
    info: {
      messageId: "abc123...",
      response: "250 OK"
    }
  }
}
```

**送信失敗時:**
```javascript
{
  delivery: {
    state: "ERROR",
    attempts: 3,
    error: {
      message: "SMTP Authentication failed"
    }
  }
}
```

### 3. **Go Shop アプリでの確認機能**

#### 🧪 診断機能の拡張

現在の `EmailTestService` に送信確認機能を追加：

```dart
// lib/services/email_test_service.dart に追加
Future<EmailDeliveryStatus> checkEmailDeliveryStatus(String docId) async {
  try {
    final doc = await FirebaseFirestore.instance
        .collection('mail')
        .doc(docId)
        .get();
    
    if (!doc.exists) {
      return EmailDeliveryStatus.notFound;
    }
    
    final data = doc.data()!;
    final delivery = data['delivery'] as Map<String, dynamic>?;
    
    if (delivery == null) {
      return EmailDeliveryStatus.pending;
    }
    
    switch (delivery['state']) {
      case 'SUCCESS':
        return EmailDeliveryStatus.success;
      case 'ERROR':
        return EmailDeliveryStatus.error;
      default:
        return EmailDeliveryStatus.processing;
    }
  } catch (e) {
    print('送信状況確認エラー: $e');
    return EmailDeliveryStatus.error;
  }
}

enum EmailDeliveryStatus {
  pending,    // 送信待ち
  processing, // 処理中
  success,    // 送信成功
  error,      // 送信エラー
  notFound    // ドキュメント未発見
}
```

#### 📱 UI での送信確認表示

```dart
// lib/widgets/email_test_button.dart に追加
class EmailDeliveryStatusWidget extends StatefulWidget {
  final String documentId;
  
  const EmailDeliveryStatusWidget({
    Key? key,
    required this.documentId,
  }) : super(key: key);
  
  @override
  _EmailDeliveryStatusWidgetState createState() => _EmailDeliveryStatusWidgetState();
}

class _EmailDeliveryStatusWidgetState extends State<EmailDeliveryStatusWidget> {
  EmailDeliveryStatus? _status;
  Timer? _timer;
  
  @override
  void initState() {
    super.initState();
    _checkStatus();
    // 5秒毎に状況確認
    _timer = Timer.periodic(Duration(seconds: 5), (timer) {
      _checkStatus();
    });
  }
  
  Future<void> _checkStatus() async {
    final service = ref.read(emailTestServiceProvider);
    final status = await service.checkEmailDeliveryStatus(widget.documentId);
    setState(() {
      _status = status;
    });
    
    // 成功またはエラーで自動停止
    if (status == EmailDeliveryStatus.success || 
        status == EmailDeliveryStatus.error) {
      _timer?.cancel();
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: _getStatusIcon(),
        title: Text('送信状況: ${_getStatusText()}'),
        subtitle: _getStatusDescription(),
      ),
    );
  }
  
  Icon _getStatusIcon() {
    switch (_status) {
      case EmailDeliveryStatus.success:
        return Icon(Icons.check_circle, color: Colors.green);
      case EmailDeliveryStatus.error:
        return Icon(Icons.error, color: Colors.red);
      case EmailDeliveryStatus.processing:
        return Icon(Icons.hourglass_empty, color: Colors.orange);
      default:
        return Icon(Icons.schedule, color: Colors.grey);
    }
  }
  
  String _getStatusText() {
    switch (_status) {
      case EmailDeliveryStatus.success:
        return '送信成功 ✅';
      case EmailDeliveryStatus.error:
        return '送信失敗 ❌';
      case EmailDeliveryStatus.processing:
        return '送信中 ⏳';
      case EmailDeliveryStatus.pending:
        return '送信待ち 📤';
      default:
        return '確認中 🔍';
    }
  }
}
```

### 4. **実際の受信確認**

#### 📬 fatima.sumomo@gmail.com での確認

1. **Gmail で受信確認**
   - 受信トレイ
   - 迷惑メールフォルダ
   - すべてのメールフォルダ

2. **受信メール詳細確認**
   ```
   送信者: sumomo-planning@sakura.ne.jp
   件名: Go Shop - テスト送信
   内容: テスト送信メッセージ
   ```

3. **配信遅延の可能性**
   - さくらインターネット → Gmail: 通常数秒〜数分
   - 初回送信時は遅延する場合あり

### 5. **デバッグ用コマンド確認**

#### 🛠️ Firebase CLI での確認

```bash
# Functions ログをリアルタイム表示
firebase functions:log --project gotoshop-572b7

# 特定期間のログ確認
firebase functions:log --project gotoshop-572b7 --since 1h

# Firestore データ確認
firebase firestore:export --project gotoshop-572b7
```

### 6. **トラブルシューティング チェックリスト**

#### ✅ 確認項目

1. **Firestore `mail` コレクション**
   - ドキュメントが作成されているか
   - `delivery` フィールドが追加されているか

2. **Firebase Functions ログ**
   - エラーメッセージの有無
   - SMTP接続ログの確認

3. **Extensions 設定**
   - SMTP Connection URI が正しいか
   - さくらインターネット認証情報が正しいか

4. **受信側確認**
   - Gmail の迷惑メールフィルター
   - ドメイン認証設定

### 🚀 実装手順

1. **現在のテスト実行** → Firebase Console ログ確認
2. **送信確認機能をアプリに追加** → リアルタイム状況表示
3. **受信確認** → fatima.sumomo@gmail.com チェック

どの確認方法から始めますか？まずはFirebase Console のログ確認がおすすめです！