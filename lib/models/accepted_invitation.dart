// lib/models/accepted_invitation.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive/hive.dart';

part 'accepted_invitation.freezed.dart';
part 'accepted_invitation.g.dart';

/// 招待受諾データモデル
/// Firestoreパス: /users/{inviterUid}/acceptedInvitations/{acceptorUid}
@HiveType(typeId: 7)
@freezed
class AcceptedInvitation with _$AcceptedInvitation {
  const factory AcceptedInvitation({
    @HiveField(0) required String acceptorUid,        // 受諾者のUID
    @HiveField(1) required String acceptorEmail,      // 受諾者のメール
    @HiveField(2) required String acceptorName,       // 受諾者の表示名
    @HiveField(3) required String SharedGroupId,    // 対象SharedGroupのID
    @HiveField(4) required String shoppingListId,     // 対象ShoppingListのID
    @HiveField(5) required String inviteRole,         // 招待時のロール（member/manager）
    @HiveField(6) required DateTime acceptedAt,       // 受諾日時
    @HiveField(7) @Default(false) bool isProcessed,   // 招待元が処理済みかフラグ
    @HiveField(8) DateTime? processedAt,              // 処理済み日時
    @HiveField(9) String? notes,                      // 追加メモ
  }) = _AcceptedInvitation;

  factory AcceptedInvitation.fromJson(Map<String, dynamic> json) =>
      _$AcceptedInvitationFromJson(json);
}

/// Firestore用のAcceptedInvitationクラス
class FirestoreAcceptedInvitation {
  final String id;                    // ドキュメントID (acceptorUid)
  final String acceptorUid;
  final String acceptorEmail;
  final String acceptorName;
  final String SharedGroupId;
  final String shoppingListId;
  final String inviteRole;
  final DateTime acceptedAt;
  final bool isProcessed;
  final DateTime? processedAt;
  final String? notes;

  const FirestoreAcceptedInvitation({
    required this.id,
    required this.acceptorUid,
    required this.acceptorEmail,
    required this.acceptorName,
    required this.SharedGroupId,
    required this.shoppingListId,
    required this.inviteRole,
    required this.acceptedAt,
    this.isProcessed = false,
    this.processedAt,
    this.notes,
  });

  /// Firestoreドキュメントから生成
  factory FirestoreAcceptedInvitation.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data()!;
    return FirestoreAcceptedInvitation(
      id: snapshot.id,
      acceptorUid: data['acceptorUid'] as String,
      acceptorEmail: data['acceptorEmail'] as String,
      acceptorName: data['acceptorName'] as String,
      SharedGroupId: data['SharedGroupId'] as String,
      shoppingListId: data['shoppingListId'] as String,
      inviteRole: data['inviteRole'] as String,
      acceptedAt: (data['acceptedAt'] as Timestamp).toDate(),
      isProcessed: data['isProcessed'] as bool? ?? false,
      processedAt: data['processedAt'] != null 
          ? (data['processedAt'] as Timestamp).toDate() 
          : null,
      notes: data['notes'] as String?,
    );
  }

  /// Firestoreドキュメントに変換
  Map<String, dynamic> toFirestore() {
    return {
      'acceptorUid': acceptorUid,
      'acceptorEmail': acceptorEmail,
      'acceptorName': acceptorName,
      'SharedGroupId': SharedGroupId,
      'shoppingListId': shoppingListId,
      'inviteRole': inviteRole,
      'acceptedAt': Timestamp.fromDate(acceptedAt),
      'isProcessed': isProcessed,
      'processedAt': processedAt != null ? Timestamp.fromDate(processedAt!) : null,
      'notes': notes,
    };
  }

  /// 処理済みに更新
  FirestoreAcceptedInvitation markAsProcessed({String? notes}) {
    return FirestoreAcceptedInvitation(
      id: id,
      acceptorUid: acceptorUid,
      acceptorEmail: acceptorEmail,
      acceptorName: acceptorName,
      SharedGroupId: SharedGroupId,
      shoppingListId: shoppingListId,
      inviteRole: inviteRole,
      acceptedAt: acceptedAt,
      isProcessed: true,
      processedAt: DateTime.now(),
      notes: notes ?? this.notes,
    );
  }
}