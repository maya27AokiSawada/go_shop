import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_logger.dart';

// Logger instance

/// 未サインイン時の招待情報を一時保存するサービス
///
/// ユーザーが未サインインの状態でQRコード招待を受け取った場合、
/// 招待情報をSharedPreferencesに保存し、サインイン後に自動処理する
class PendingInvitationService {
  static const String _pendingInvitationKey = 'pending_invitation';

  /// 招待情報を保存
  ///
  /// [invitationData] QRコードから読み取った招待情報
  /// Returns: 保存成功の場合true
  static Future<bool> savePendingInvitation(
    Map<String, dynamic> invitationData,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(invitationData);

      final success = await prefs.setString(_pendingInvitationKey, jsonString);

      if (success) {
        Log.info('📥 招待情報を一時保存しました: ${invitationData['groupName']}');
        Log.info('   招待者: ${invitationData['inviterEmail']}');
      }

      return success;
    } catch (e) {
      Log.error('❌ 招待情報の保存に失敗: $e');
      return false;
    }
  }

  /// 保存された招待情報を取得
  ///
  /// Returns: 保存された招待情報。存在しない場合はnull
  static Future<Map<String, dynamic>?> getPendingInvitation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_pendingInvitationKey);

      if (jsonString == null) {
        return null;
      }

      final invitationData = jsonDecode(jsonString) as Map<String, dynamic>;
      Log.info('📤 保存された招待情報を取得: ${invitationData['groupName']}');

      return invitationData;
    } catch (e) {
      Log.error('❌ 招待情報の取得に失敗: $e');
      return null;
    }
  }

  /// 招待情報が保存されているかチェック
  ///
  /// Returns: 招待情報が存在する場合true
  static Future<bool> hasPendingInvitation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.containsKey(_pendingInvitationKey);
    } catch (e) {
      Log.error('❌ 招待情報のチェックに失敗: $e');
      return false;
    }
  }

  /// 招待情報を削除
  ///
  /// 招待処理完了後、またはキャンセル時に呼び出す
  /// Returns: 削除成功の場合true
  static Future<bool> clearPendingInvitation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final success = await prefs.remove(_pendingInvitationKey);

      if (success) {
        Log.info('🗑️ 招待情報を削除しました');
      }

      return success;
    } catch (e) {
      Log.error('❌ 招待情報の削除に失敗: $e');
      return false;
    }
  }

  /// 招待情報のサマリーを取得（ログ・UI表示用）
  ///
  /// Returns: 招待情報の概要文字列。存在しない場合はnull
  static Future<String?> getPendingInvitationSummary() async {
    final invitation = await getPendingInvitation();

    if (invitation == null) {
      return null;
    }

    final groupName = invitation['groupName'] ?? '不明なグループ';
    final inviterEmail = invitation['inviterEmail'] ?? '不明な招待者';
    final message = invitation['message'] ?? '';

    return '$inviterEmailさんから「$groupName」への招待${message.isNotEmpty ? '\nメッセージ: $message' : ''}';
  }
}

/// 招待処理の結果
class InvitationProcessResult {
  final bool success;
  final String message;
  final String? error;

  InvitationProcessResult({
    required this.success,
    required this.message,
    this.error,
  });

  factory InvitationProcessResult.success(String message) {
    return InvitationProcessResult(
      success: true,
      message: message,
    );
  }

  factory InvitationProcessResult.failure(String message, {String? error}) {
    return InvitationProcessResult(
      success: false,
      message: message,
      error: error,
    );
  }
}
