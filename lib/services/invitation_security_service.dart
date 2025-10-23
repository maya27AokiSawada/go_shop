import 'dart:convert';
import 'dart:math';

// Logger instance

import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/app_logger.dart';
import '../models/purchase_group.dart';

// プロバイダー
final invitationSecurityServiceProvider = Provider<InvitationSecurityService>(
  (ref) => InvitationSecurityService(),
);

/// 招待のセキュリティ管理を行うサービス
class InvitationSecurityService {
  static const int _keyLength = 32; // セキュリティキーの長さ
  static const String _charset =
      'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';

  final Random _random = Random.secure();

  /// セキュリティキーを生成
  String generateSecurityKey() {
    final buffer = StringBuffer();
    for (int i = 0; i < _keyLength; i++) {
      buffer.write(_charset[_random.nextInt(_charset.length)]);
    }
    return buffer.toString();
  }

  /// ユニークな招待IDを生成（グループID + タイムスタンプ + ランダム）
  String generateInvitationId(String groupId) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final randomSuffix = _random.nextInt(999999).toString().padLeft(6, '0');
    return '$groupId-$timestamp-$randomSuffix';
  }

  /// セキュアな招待URL用のトークンを生成
  String generateInvitationToken({
    required String groupId,
    required String invitationType, // 'individual' or 'friend'
    required String securityKey,
    String? inviterUid,
  }) {
    final payload = {
      'groupId': groupId,
      'type': invitationType,
      'key': securityKey,
      'inviter': inviterUid,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };

    final jsonString = jsonEncode(payload);
    final bytes = utf8.encode(jsonString);
    final base64Token = base64.encode(bytes);

    return base64Token;
  }

  /// 招待トークンを解析・検証
  InvitationTokenData? parseInvitationToken(String token) {
    try {
      final bytes = base64.decode(token);
      final jsonString = utf8.decode(bytes);
      final payload = jsonDecode(jsonString) as Map<String, dynamic>;

      // 必須フィールドのチェック
      if (!payload.containsKey('groupId') ||
          !payload.containsKey('type') ||
          !payload.containsKey('key') ||
          !payload.containsKey('timestamp')) {
        return null;
      }

      return InvitationTokenData(
        groupId: payload['groupId'] as String,
        invitationType: payload['type'] as String,
        securityKey: payload['key'] as String,
        inviterUid: payload['inviter'] as String?,
        timestamp: payload['timestamp'] as int,
      );
    } catch (e) {
      Log.error('招待トークン解析エラー: $e');
      return null;
    }
  }

  /// セキュリティキーの検証
  bool validateSecurityKey(String providedKey, String expectedKey) {
    if (providedKey.isEmpty || expectedKey.isEmpty) {
      return false;
    }

    // タイミング攻撃を防ぐための定数時間比較
    return _constantTimeEquals(providedKey, expectedKey);
  }

  /// 招待の有効期限チェック（デフォルト7日間）
  bool isInvitationExpired(DateTime invitedAt, {int validDays = 7}) {
    final expiryDate = invitedAt.add(Duration(days: validDays));
    return DateTime.now().isAfter(expiryDate);
  }

  /// 招待トークンの有効期限チェック（デフォルト24時間）
  bool isTokenExpired(int timestamp, {int validHours = 24}) {
    final tokenDate = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final expiryDate = tokenDate.add(Duration(hours: validHours));
    return DateTime.now().isAfter(expiryDate);
  }

  /// PurchaseGroupMemberの招待状態を更新
  PurchaseGroupMember updateInvitationStatus(
    PurchaseGroupMember member,
    InvitationStatus newStatus, {
    String? securityKey,
    DateTime? statusChangeTime,
  }) {
    final now = statusChangeTime ?? DateTime.now();

    return member.copyWith(
      invitationStatus: newStatus,
      securityKey: securityKey ?? member.securityKey,
      invitedAt: newStatus == InvitationStatus.pending
          ? (member.invitedAt ?? now)
          : member.invitedAt,
      acceptedAt:
          newStatus == InvitationStatus.accepted ? now : member.acceptedAt,
    );
  }

  /// 招待レスポンス用のデータを作成
  InvitationResponse createInvitationResponse({
    required String groupId,
    required String memberId,
    required String memberName,
    required String securityKey,
    required bool accepted,
  }) {
    return InvitationResponse(
      groupId: groupId,
      memberId: memberId,
      memberName: memberName,
      securityKey: securityKey,
      accepted: accepted,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );
  }

  /// 定数時間でのString比較（タイミング攻撃対策）
  bool _constantTimeEquals(String a, String b) {
    if (a.length != b.length) return false;

    int result = 0;
    for (int i = 0; i < a.length; i++) {
      result |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return result == 0;
  }

  /// セキュリティキーのハッシュ化（保存用）
  String hashSecurityKey(String key) {
    final bytes = utf8.encode(key);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// ハッシュ化されたキーとの比較
  bool validateHashedKey(String providedKey, String hashedKey) {
    final providedHash = hashSecurityKey(providedKey);
    return _constantTimeEquals(providedHash, hashedKey);
  }
}

/// 招待トークンのデータクラス
class InvitationTokenData {
  final String groupId;
  final String invitationType;
  final String securityKey;
  final String? inviterUid;
  final int timestamp;

  InvitationTokenData({
    required this.groupId,
    required this.invitationType,
    required this.securityKey,
    this.inviterUid,
    required this.timestamp,
  });

  bool get isIndividualInvitation => invitationType == 'individual';
  bool get isFriendInvitation => invitationType == 'friend';

  DateTime get createdAt => DateTime.fromMillisecondsSinceEpoch(timestamp);
}

/// 招待レスポンスのデータクラス
class InvitationResponse {
  final String groupId;
  final String memberId;
  final String memberName;
  final String securityKey;
  final bool accepted;
  final int timestamp;

  InvitationResponse({
    required this.groupId,
    required this.memberId,
    required this.memberName,
    required this.securityKey,
    required this.accepted,
    required this.timestamp,
  });

  DateTime get respondedAt => DateTime.fromMillisecondsSinceEpoch(timestamp);

  Map<String, dynamic> toJson() => {
        'groupId': groupId,
        'memberId': memberId,
        'memberName': memberName,
        'securityKey': securityKey,
        'accepted': accepted,
        'timestamp': timestamp,
      };

  factory InvitationResponse.fromJson(Map<String, dynamic> json) {
    return InvitationResponse(
      groupId: json['groupId'],
      memberId: json['memberId'],
      memberName: json['memberName'],
      securityKey: json['securityKey'],
      accepted: json['accepted'],
      timestamp: json['timestamp'],
    );
  }
}
