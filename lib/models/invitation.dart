import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive/hive.dart';

part 'invitation.freezed.dart';
part 'invitation.g.dart';

@HiveType(typeId: 5)
@freezed
class Invitation with _$Invitation {
  const factory Invitation({
    @HiveField(0) required String id,
    @HiveField(1) required String groupId,
    @HiveField(2) required String inviteCode,
    @HiveField(3) required String inviterUid,
    @HiveField(4) required String inviteeEmail,
    @HiveField(5) required DateTime createdAt,
    @HiveField(6) required DateTime expiresAt,
    @HiveField(7) @Default(false) bool isAccepted,
    @HiveField(8) String? acceptedByUid,
    @HiveField(9) DateTime? acceptedAt,
  }) = _Invitation;

  factory Invitation.fromJson(Map<String, dynamic> json) => _$InvitationFromJson(json);
}

/// 招待作成用のデータクラス
@freezed
class CreateInvitationRequest with _$CreateInvitationRequest {
  const factory CreateInvitationRequest({
    required String groupId,
    required String inviteeEmail,
    required String inviterUid,
  }) = _CreateInvitationRequest;
}

/// 招待受諾用のデータクラス
@freezed
class AcceptInvitationRequest with _$AcceptInvitationRequest {
  const factory AcceptInvitationRequest({
    required String inviteCode,
    required String accepterUid,
  }) = _AcceptInvitationRequest;
}