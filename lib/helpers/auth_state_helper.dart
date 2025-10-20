import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthStateHelper {
  

  /// 認証状態に基づいてUI機能を制限する
  static bool canUseAdvancedFeatures(User? user) {
    return user != null && !_isTemporaryUser(user);
  }

  /// QRコード機能が利用可能かチェック
  static bool canUseQrCodeFeatures(User? user) {
    return canUseAdvancedFeatures(user);
  }

  /// グループ招待機能が利用可能かチェック
  static bool canInviteMembers(User? user) {
    return canUseAdvancedFeatures(user);
  }

  /// 一時ユーザー（サインアップ前）かどうかを判定
  static bool _isTemporaryUser(User user) {
    return user.isAnonymous || user.uid.startsWith('temp_') || user.uid.startsWith('mock_');
  }

  /// サインアップ前の制限付きUIを構築
  static Widget buildRestrictedFeatureMessage({
    required String featureName,
    VoidCallback? onSignUpTap,
  }) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Icon(
              Icons.lock_outline,
              size: 48,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              '$featureNameを利用するには',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'サインアップが必要です',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            if (onSignUpTap != null)
              ElevatedButton(
                onPressed: onSignUpTap,
                child: const Text('サインアップ'),
              ),
          ],
        ),
      ),
    );
  }

  /// QRコードスキャンボタンを認証状態に応じて構築
  static Widget buildQrScanButton({
    required User? user,
    required VoidCallback onScan,
    VoidCallback? onSignUpPrompt,
  }) {
    if (canUseQrCodeFeatures(user)) {
      return ElevatedButton.icon(
        onPressed: onScan,
        icon: const Icon(Icons.qr_code_scanner),
        label: const Text('QRコードスキャン'),
      );
    }
    
    return ElevatedButton.icon(
      onPressed: onSignUpPrompt,
      icon: const Icon(Icons.lock),
      label: const Text('QRコード（要サインアップ）'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.grey,
        foregroundColor: Colors.white,
      ),
    );
  }

  /// グループ招待ボタンを認証状態に応じて構築
  static Widget buildInviteButton({
    required User? user,
    required VoidCallback onInvite,
    VoidCallback? onSignUpPrompt,
  }) {
    if (canInviteMembers(user)) {
      return ElevatedButton.icon(
        onPressed: onInvite,
        icon: const Icon(Icons.person_add),
        label: const Text('メンバー招待'),
      );
    }
    
    return ElevatedButton.icon(
      onPressed: onSignUpPrompt,
      icon: const Icon(Icons.lock),
      label: const Text('招待（要サインアップ）'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.grey,
        foregroundColor: Colors.white,
      ),
    );
  }

  /// サインアップ前の簡素化されたホーム画面コンテンツ
  static Widget buildPreSignUpContent({
    required BuildContext context,
    required VoidCallback onShowSignUp,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.shopping_bag_outlined,
          size: 80,
          color: Colors.grey,
        ),
        const SizedBox(height: 24),
        const Text(
          'Go Shopへようこそ！',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            '家族やグループで買い物リストを共有して、\nより便利にお買い物を楽しみましょう',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ),
        const SizedBox(height: 32),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const Text(
                  '✨ 利用可能な機能',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                const Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 20),
                    SizedBox(width: 8),
                    Text('個人用買い物リスト作成'),
                  ],
                ),
                const SizedBox(height: 8),
                const Row(
                  children: [
                    Icon(Icons.cancel, color: Colors.grey, size: 20),
                    SizedBox(width: 8),
                    Text('グループでのリスト共有', style: TextStyle(color: Colors.grey)),
                  ],
                ),
                const SizedBox(height: 8),
                const Row(
                  children: [
                    Icon(Icons.cancel, color: Colors.grey, size: 20),
                    SizedBox(width: 8),
                    Text('QRコード招待機能', style: TextStyle(color: Colors.grey)),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onShowSignUp,
                    child: const Text('サインアップして全機能を利用'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// サインアップ促進メッセージ表示
  static void showSignUpPrompt(BuildContext context, VoidCallback onSignUp) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('サインアップが必要です'),
        content: const Text(
          'この機能を利用するには、アカウント作成が必要です。\n'
          'サインアップすると以下の機能が利用できます：\n\n'
          '• グループでの買い物リスト共有\n'
          '• QRコードでの簡単招待\n'
          '• メンバー管理機能\n'
          '• バックアップとデータ同期',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('後で'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onSignUp();
            },
            child: const Text('サインアップ'),
          ),
        ],
      ),
    );
  }
}