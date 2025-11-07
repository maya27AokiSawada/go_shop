// lib/datastore/invitation_repository.dart
import '../models/invitation.dart';

/// 招待機能のリポジトリインターフェース
abstract class InvitationRepository {
  /// 招待を作成
  ///
  /// [groupId] 招待先グループID
  /// [groupName] 招待先グループ名
  /// [invitedBy] 招待元ユーザーUID
  /// [inviterName] 招待元ユーザー名
  /// [expiry] 有効期限 (デフォルト: 24時間)
  /// [maxUses] 最大使用回数 (デフォルト: 5人)
  ///
  /// Returns: 作成された招待情報
  Future<Invitation> inviteOthers({
    required String groupId,
    required String groupName,
    required String invitedBy,
    required String inviterName,
    Duration expiry = const Duration(hours: 24),
    int maxUses = 5,
  });

  /// 招待を使用してグループに参加
  ///
  /// [token] 招待トークン
  /// [userId] 参加ユーザーUID
  /// [userName] 参加ユーザー名
  /// [userEmail] 参加ユーザーメールアドレス
  ///
  /// Throws:
  /// - [Exception] トークンが無効、期限切れ、使用回数超過、重複参加の場合
  Future<void> allowAcceptUsers({
    required String token,
    required String userId,
    required String userName,
    required String userEmail,
  });

  /// 期限切れ招待を削除
  ///
  /// 現在時刻より前のexpiresAtを持つ招待を全て削除
  Future<void> cleanUpExpiredInvitation();

  /// トークンで招待情報を取得
  ///
  /// [token] 招待トークン
  ///
  /// Returns: 招待情報、存在しない場合はnull
  Future<Invitation?> getInvitationByToken(String token);

  /// グループの招待一覧を取得
  ///
  /// [groupId] グループID
  ///
  /// Returns: 招待情報のリスト (有効期限内のみ)
  Future<List<Invitation>> getInvitationsByGroup(String groupId);

  /// 招待を取り消し
  ///
  /// [token] 招待トークン
  Future<void> cancelInvitation(String token);
}
