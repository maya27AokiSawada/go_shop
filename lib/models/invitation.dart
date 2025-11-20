// lib/models/invitation.dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

part 'invitation.freezed.dart';
part 'invitation.g.dart';

/// 招待トークン情報
/// Firestoreの /invitations/{token} に保存
@freezed
class Invitation with _$Invitation {
  const Invitation._();

  const factory Invitation({
    /// 招待トークン (UUID v4形式: "INV_abc123-def456-...")
    required String token,

    /// 招待先グループID
    required String groupId,

    /// 招待先グループ名
    required String groupName,

    /// 招待元ユーザーUID
    required String invitedBy,

    /// 招待元ユーザー名
    required String inviterName,

    /// 作成日時
    required DateTime createdAt,

    /// 有効期限
    required DateTime expiresAt,

    /// 最大使用回数
    @Default(5) int maxUses,

    /// 現在の使用回数
    @Default(0) int currentUses,

    /// 使用済みユーザーUIDリスト
    @Default([]) List<String> usedBy,

    /// セキュリティキー (QR検証用)
    String? securityKey,
  }) = _Invitation;

  /// Firestoreから取得
  factory Invitation.fromJson(Map<String, dynamic> json) =>
      _$InvitationFromJson(json);

  /// FirestoreのTimestamp対応版
  factory Invitation.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data();
    if (data == null) {
      throw Exception('Invitation data is null');
    }

    // createdAt/expiresAtのnullセーフ処理
    final createdAtData = data['createdAt'];
    final expiresAtData = data['expiresAt'];

    final createdAt = createdAtData is Timestamp
        ? createdAtData.toDate()
        : (createdAtData is String
            ? DateTime.parse(createdAtData)
            : DateTime.now());

    final expiresAt = expiresAtData is Timestamp
        ? expiresAtData.toDate()
        : (expiresAtData is String
            ? DateTime.parse(expiresAtData)
            : DateTime.now().add(const Duration(hours: 24)));

    return Invitation(
      token: data['token'] as String,
      groupId: data['groupId'] as String,
      groupName: data['groupName'] as String,
      invitedBy: data['invitedBy'] as String,
      inviterName: data['inviterName'] as String? ?? '',
      createdAt: createdAt,
      expiresAt: expiresAt,
      maxUses: data['maxUses'] as int? ?? 5,
      currentUses: data['currentUses'] as int? ?? 0,
      usedBy: (data['usedBy'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      securityKey: data['securityKey'] as String?,
    );
  }

  /// Firestoreへ保存用
  Map<String, dynamic> toFirestore() {
    return {
      'token': token,
      'groupId': groupId,
      'groupName': groupName,
      'invitedBy': invitedBy,
      'inviterName': inviterName,
      'createdAt': Timestamp.fromDate(createdAt),
      'expiresAt': Timestamp.fromDate(expiresAt),
      'maxUses': maxUses,
      'currentUses': currentUses,
      'usedBy': usedBy,
      'securityKey': securityKey,
    };
  }

  /// 有効期限切れチェック
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  /// 使用回数上限チェック
  bool get isMaxUsesReached => currentUses >= maxUses;

  /// 使用可能かチェック
  bool get isValid => !isExpired && !isMaxUsesReached;

  /// 特定ユーザーが使用済みかチェック
  bool isUsedBy(String uid) => usedBy.contains(uid);

  /// 残り有効時間
  Duration get remainingTime {
    if (isExpired) return Duration.zero;
    return expiresAt.difference(DateTime.now());
  }

  /// 残り使用可能回数
  int get remainingUses => maxUses - currentUses;
}

/// QRコード用の招待データ
@freezed
class InvitationQRData with _$InvitationQRData {
  const factory InvitationQRData({
    /// データタイプ識別子
    @Default('go_shop_invitation') String type,

    /// バージョン
    @Default('1.0') String version,

    /// 招待トークン
    required String token,
  }) = _InvitationQRData;

  factory InvitationQRData.fromJson(Map<String, dynamic> json) =>
      _$InvitationQRDataFromJson(json);
}
