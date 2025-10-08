// lib/services/invitation_service.dart
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class InvitationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// 招待コードを生成
  String generateInviteCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return List.generate(8, (index) => chars[random.nextInt(chars.length)]).join();
  }

  /// 招待を作成してFirestoreに保存し、メール送信
  Future<String> inviteUserToGroup({
    required String groupId,
    required String groupName,
    required String inviteeEmail,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) throw Exception('ユーザーが認証されていません');

    final inviteCode = generateInviteCode();
    final now = DateTime.now();
    
    // Firestoreに招待情報を保存
    final invitationData = {
      'groupId': groupId,
      'inviteCode': inviteCode,
      'inviterUid': currentUser.uid,
      'inviterEmail': currentUser.email,
      'inviteeEmail': inviteeEmail,
      'groupName': groupName,
      'createdAt': now.toIso8601String(),
      'expiresAt': now.add(const Duration(hours: 24)).toIso8601String(), // 24時間有効
      'isAccepted': false,
      'acceptedByUid': null,
      'acceptedAt': null,
    };

    await _firestore.collection('invitations').add(invitationData);


    // 許可されたメールアドレスのみ送信
    const allowedEmails = [
      'pisce.plum@gmai.com',
      'fatima.sumomo@gmail.com',
      'Fatima.yatomi@outlook.com',
      'fatima.sumomo@outlook.com',
    ];
    final normalized = inviteeEmail.trim().toLowerCase();
    final allowed = allowedEmails.map((e) => e.trim().toLowerCase()).toList();
    if (allowed.contains(normalized)) {
      await sendInvitationEmail(
        groupName: groupName,
        inviteeEmail: inviteeEmail,
        inviteCode: inviteCode,
      );
    } else {
      print('⛔️ 招待メール送信スキップ: $inviteeEmail');
    }

    return inviteCode;
  }

  /// 招待メールを送信
  Future<void> sendInvitationEmail({
    required String groupName,
    required String inviteeEmail,
    required String inviteCode,
  }) async {
    final inviteLink = 'go-shop://invite?code=$inviteCode';
    
    final emailSubject = 'Go Shop: 「$groupName」グループへの招待';
    final emailBody = '''
こんにちは！

Go Shop の買い物リストグループ「$groupName」に招待されました。

下記のリンクをタップしてグループに参加してください：
$inviteLink

Go Shopアプリをお持ちでない場合は、まずアプリをダウンロードしてから上記リンクをタップしてください。

有効期限：24時間

よろしくお願いします！
''';

    // テスト用：招待情報をFirestoreに保存してログ出力
    // SMTP設定完了後、実際のメール送信に切り替え可能
    try {
      // テスト用：招待メールデータをログ用コレクションに保存
      await _firestore.collection('invitation_emails_log').add({
        'to': inviteeEmail,
        'subject': emailSubject,
        'body': emailBody,
        'inviteCode': inviteCode,
        'groupName': groupName,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'test_mode',
      });
      
      print('🧪 テストモード：招待メール情報を保存しました');
      print('📧 宛先: $inviteeEmail');
      print('🔑 招待コード: $inviteCode');
      print('🔗 招待リンク: $inviteLink');
      
      // SMTP設定が完了している場合のみ実際のメール送信を試行
      final isSmtpConfigured = await _checkSmtpConfiguration();
      if (isSmtpConfigured) {
        await _firestore.collection('emails').add({
          'to': [inviteeEmail],
          'message': {
            'subject': emailSubject,
            'text': emailBody,
          },
        });
        print('✅ Firebase経由でメール送信リクエストを送信しました');
      } else {
        print('⚠️ SMTP未設定のため、テストモードで実行中');
        print('💡 実際のメール送信には Firebase Console で SMTP設定が必要です');
      }
    } catch (e) {
      print('❌ メール送信エラー: $e');
      // フォールバック：外部メールクライアントを起動
      final uri = Uri(
        scheme: 'mailto',
        path: inviteeEmail,
        queryParameters: {
          'subject': emailSubject,
          'body': emailBody,
        },
      );
      await _openEmailClient(uri);
    }
  }

  /// SMTP設定の確認（簡易版）
  Future<bool> _checkSmtpConfiguration() async {
    // 実際の実装では Firebase Functions を使用してSMTP設定を確認
    // テスト用として常にfalseを返す（SMTP未設定想定）
    return false;
  }

  /// プラットフォーム固有のメール送信
  Future<void> _openEmailClient(Uri uri) async {
    // Windowsの場合、Process.runでシステムコマンド使用
    try {
      // 仮実装：デバッグ出力
      print('メール送信: ${uri.toString()}');
      // 実際の実装では、下記のような処理になります：
      // if (Platform.isWindows) {
      //   await Process.run('start', [uri.toString()], runInShell: true);
      // }
    } catch (e) {
      throw Exception('メール送信に失敗しました: $e');
    }
  }

  /// 招待を検証して受諾処理
  Future<Map<String, dynamic>> acceptInvitation({
    required String inviteCode,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) throw Exception('ユーザーが認証されていません');

    // 招待コードでFirestoreから検索
    final querySnapshot = await _firestore
        .collection('invitations')
        .where('inviteCode', isEqualTo: inviteCode)
        .where('isAccepted', isEqualTo: false)
        .limit(1)
        .get();

    if (querySnapshot.docs.isEmpty) {
      throw Exception('無効または期限切れの招待コードです');
    }

    final doc = querySnapshot.docs.first;
    final data = doc.data();
    
    // 期限チェック
    final expiresAt = DateTime.parse(data['expiresAt']);
    if (DateTime.now().isAfter(expiresAt)) {
      throw Exception('招待の有効期限が切れています');
    }

    // 招待を受諾済みに更新
    await doc.reference.update({
      'isAccepted': true,
      'acceptedByUid': currentUser.uid,
      'acceptedAt': DateTime.now().toIso8601String(),
    });

    // グループにメンバーを追加
    await _addMemberToGroup(data['groupId'], currentUser);

    return {
      'groupId': data['groupId'],
      'groupName': data['groupName'],
      'success': true,
    };
  }

  /// グループにメンバーを追加
  Future<void> _addMemberToGroup(String groupId, User user) async {
    final groupRef = _firestore.collection('purchase_groups').doc(groupId);
    
    // 新しいメンバー情報
    final newMember = {
      'memberId': user.uid,
      'name': user.displayName ?? user.email?.split('@')[0] ?? 'New Member',
      'contact': user.email ?? '',
      'role': 'member', // デフォルトはメンバー
      'isSignedIn': true,
      'joinedAt': DateTime.now().toIso8601String(),
    };

    await groupRef.update({
      'members': FieldValue.arrayUnion([newMember])
    });
  }

  /// 招待コードから招待情報を取得（プレビュー用）
  Future<Map<String, dynamic>?> getInvitationByCode(String inviteCode) async {
    final querySnapshot = await _firestore
        .collection('invitations')
        .where('inviteCode', isEqualTo: inviteCode)
        .where('isAccepted', isEqualTo: false)
        .limit(1)
        .get();

    if (querySnapshot.docs.isEmpty) {
      return null;
    }

    final data = querySnapshot.docs.first.data();
    
    // 期限チェック
    final expiresAt = DateTime.parse(data['expiresAt']);
    if (DateTime.now().isAfter(expiresAt)) {
      return null;
    }

    return {
      'groupId': data['groupId'],
      'groupName': data['groupName'],
      'inviterEmail': data['inviterEmail'],
      'expiresAt': expiresAt,
    };
  }
}

// Provider
final invitationServiceProvider = Provider<InvitationService>((ref) {
  return InvitationService();
});
