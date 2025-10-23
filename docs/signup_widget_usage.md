# サインアップ処理ウィジェット使用方法

## 概要

サインアップ時のデータ移行処理を包括的に行うウィジェットとサービスクラスを作成しました。

## 主要コンポーネント

### 1. SignupProcessingWidget
- UIを持つサインアップ処理ウィジェット
- アニメーション付きのプログレス表示
- ステップバイステップの処理状況表示

### 2. SignupDialog
- ダイアログ形式でのサインアップ処理表示
- モーダル表示で処理完了まで待機

### 3. SignupService
- UIレスのサインアップ処理サービス
- バックグラウンド処理やテスト用途に適用

## サインアップ処理内容

### STEP1: ユーザープロフィール設定
- Firebase UIDと紐づけ
- ユーザー名の優先順位決定（プリファレンス vs Firebase）
- メールアドレスのローカル保存

### STEP2: ローカルデータ検出
- 既存の`default_group`を検出
- メンバー情報とShoppingListの確認

### STEP3: Firebase形式デフォルトグループ作成
- `default_{firebase_uid}`形式のグループID
- 統一された"My Lists"グループ名
- オーナーロール設定

### STEP4: データ移行
- オーナーのmemberIdをFirebase UIDに変更
- ローカルグループの適切な削除
- ShoppingListの移行（今後実装）

### STEP5: 状態更新
- 全てのプロバイダーのリフレッシュ
- UIへの反映

## 使用方法

### 1. ダイアログ表示
```dart
import 'package:go_shop/widgets/signup_dialog.dart';

// サインアップ成功後に表示
final result = await showSignupDialog(
  context: context,
  user: firebaseUser,
  displayName: '太郎',
  onCompleted: () {
    // 処理完了後のコールバック
    Navigator.pushReplacementNamed(context, '/home');
  },
);
```

### 2. ウィジェット直接使用
```dart
import 'package:go_shop/widgets/signup_processing_widget.dart';

SignupProcessingWidget(
  user: firebaseUser,
  displayName: '太郎',
  onCompleted: () {
    // 完了処理
  },
  onError: (error) {
    // エラー処理
  },
)
```

### 3. サービスクラス使用
```dart
import 'package:go_shop/services/signup_service.dart';

final signupService = ref.read(signupServiceProvider);
final success = await signupService.processSignup(
  user: firebaseUser,
  displayName: '太郎',
);

if (success) {
  // 成功処理
} else {
  // エラー処理
}
```

## 統合例（認証画面）

```dart
class AuthScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Column(
        children: [
          ElevatedButton(
            onPressed: () async {
              try {
                // Firebase Authでサインアップ
                final credential = await FirebaseAuth.instance
                    .createUserWithEmailAndPassword(
                  email: emailController.text,
                  password: passwordController.text,
                );

                if (credential.user != null && context.mounted) {
                  // サインアップ処理ダイアログを表示
                  final result = await showSignupDialog(
                    context: context,
                    user: credential.user!,
                    displayName: nameController.text,
                    onCompleted: () {
                      // ホーム画面に遷移
                      Navigator.pushReplacementNamed(context, '/home');
                    },
                  );

                  if (result != true) {
                    // 処理に失敗した場合の対処
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('アカウント設定に失敗しました')),
                    );
                  }
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('サインアップエラー: $e')),
                );
              }
            },
            child: const Text('サインアップ'),
          ),
        ],
      ),
    );
  }
}
```

## 利点

1. **包括的な処理**: サインアップ時の全ての必要な処理を一箇所で実行
2. **ユーザーフレンドリー**: 処理状況の可視化とアニメーション
3. **エラーハンドリング**: 各ステップでの適切なエラー処理
4. **再利用性**: ダイアログ、ウィジェット、サービスの3つの形式で提供
5. **テスタビリティ**: UIレスのサービスクラスでテストが容易

## 今後の拡張予定

- ShoppingListの完全移行実装
- より詳細なエラーメッセージ
- 処理のキャンセル機能
- オフライン対応