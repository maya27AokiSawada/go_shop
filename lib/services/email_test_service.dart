// lib/services/email_test_service.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/app_logger.dart';

final emailTestServiceProvider = Provider<EmailTestService>((ref) {
  return EmailTestService();
});

class EmailTestService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// テスト用メール送信
  Future<bool> sendTestEmail({
    required String testEmail,
    String? customSubject,
    String? customBody,
  }) async {
    final subject =
        customSubject ?? 'Go Shop テストメール - ${DateTime.now().toString()}';
    final body = customBody ??
        '''
こんにちは！

これはGo Shopアプリからのテストメールです。

送信日時: ${DateTime.now().toString()}
送信先: $testEmail
システム: Firebase Extensions Trigger Email

メール送信機能が正常に動作しています。

Go Shop開発チーム
      ''';

    try {
      Log.info('📧 テストメール送信開始');
      Log.info('   宛先: ${Log.maskEmail(testEmail)}');
      Log.info('   件名: $subject');

      // Firebase Extensions Trigger Emailを使用してメール送信
      await _sendEmailViaFirebaseExtensions(
        to: testEmail,
        subject: subject,
        body: body,
      );

      Log.info('✅ Firebase Extensions経由でテストメール送信成功');
      return true;
    } catch (emailError) {
      Log.warning('⚠️ Firebase Extensions テストメール送信エラー: $emailError');

      // エラータイプに応じた詳細ログ
      if (emailError.toString().contains('missing credentials') ||
          emailError.toString().contains('UNAUTHENTICATED')) {
        Log.error('🔑 Firebase Extensions認証エラー: SMTP設定を確認してください');
        Log.info('📋 対処方法:');
        Log.info('   1. Firebaseコンソール → Extensions → Trigger Email');
        Log.info('   2. SMTP_CONNECTION_URI の設定確認');
        Log.info('   3. DEFAULT_FROM の設定確認');
      } else if (emailError.toString().contains('permission')) {
        Log.error('🚫 権限エラー: Firestore権限を確認してください');
      }

      Log.info('📱 フォールバック: システムメールクライアントを起動します');

      // フォールバック：システムメールクライアント起動
      try {
        await _openSystemEmailClient(testEmail, subject, body);
        return true;
      } catch (e) {
        Log.error('❌ システムメールクライアント起動も失敗: $e');
        return false;
      }
    }
  }

  /// Firebase Extensions Trigger Email経由でメール送信
  Future<void> _sendEmailViaFirebaseExtensions({
    required String to,
    required String subject,
    required String body,
  }) async {
    // Firebase Extensions Trigger Emailのコレクションにドキュメントを追加
    await _firestore.collection('mail').add({
      'to': to,
      'message': {
        'subject': subject,
        'text': body,
        'html': body.replaceAll('\n', '<br>'), // HTMLバージョンも提供
      },
      'template': {
        'name': 'test_email',
        'data': {
          'timestamp': DateTime.now().toIso8601String(),
          'recipient': to,
        },
      },
    });
  }

  /// システムメールクライアントでmailto URLを開く
  Future<void> _openSystemEmailClient(
      String email, String subject, String body) async {
    final uri = Uri(
      scheme: 'mailto',
      path: email,
      queryParameters: {
        'subject': subject,
        'body': body,
      },
    );

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
      Log.info('✅ システムメールクライアント起動成功');
    } else {
      Log.error('❌ メールクライアントを起動できませんでした');
      throw Exception('メールクライアントを起動できませんでした');
    }
  }

  /// 複数の宛先にテストメールを送信
  Future<List<bool>> sendBulkTestEmails(List<String> emails) async {
    final results = <bool>[];

    for (int i = 0; i < emails.length; i++) {
      try {
        Log.info(
            '📧 ${i + 1}/${emails.length}: ${Log.maskEmail(emails[i])} にテストメール送信中...');

        final result = await sendTestEmail(
          testEmail: emails[i],
          customSubject: 'Go Shop 一括テストメール ${i + 1}/${emails.length}',
          customBody: '''
Go Shop 一括テストメール

送信番号: ${i + 1}/${emails.length}
宛先: ${emails[i]}
送信日時: ${DateTime.now().toString()}

このメールは Firebase Extensions Trigger Email の動作確認のために送信されています。

Go Shop開発チーム
          ''',
        );

        results.add(result);

        // レート制限を避けるため少し待機
        if (i < emails.length - 1) {
          await Future.delayed(const Duration(milliseconds: 1000));
        }
      } catch (e) {
        Log.error('❌ ${emails[i]} への送信に失敗: $e');
        results.add(false);
      }
    }

    return results;
  }

  /// メール送信設定の診断
  Future<Map<String, dynamic>> diagnoseEmailSettings() async {
    final diagnosis = <String, dynamic>{};

    try {
      // Firestoreへの接続テスト
      await _firestore.collection('test_connection').add({
        'timestamp': FieldValue.serverTimestamp(),
        'test': 'connection_check',
      });
      diagnosis['firestore_connection'] = true;
    } catch (e) {
      diagnosis['firestore_connection'] = false;
      diagnosis['firestore_error'] = e.toString();
    }

    try {
      // mail コレクションへの書き込みテスト
      await _firestore.collection('mail').add({
        'to': 'test@example.com',
        'message': {
          'subject': 'Connection Test',
          'text': 'This is a connection test',
        },
        'test': true,
      });
      diagnosis['mail_collection_write'] = true;
    } catch (e) {
      diagnosis['mail_collection_write'] = false;
      diagnosis['mail_collection_error'] = e.toString();
    }

    diagnosis['timestamp'] = DateTime.now().toIso8601String();
    return diagnosis;
  }
}
