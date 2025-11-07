// lib/providers/invitation_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../datastore/firestore_invitation_repository.dart';
import '../datastore/invitation_repository.dart';
import '../flavors.dart';
import '../models/invitation.dart';
import '../utils/app_logger.dart';

/// InvitationRepositoryのProvider
///
/// Flavorに応じて実装を切り替え
/// - prod/dev: FirestoreInvitationRepository
final invitationRepositoryProvider = Provider<InvitationRepository>((ref) {
  if (F.appFlavor == Flavor.prod || F.appFlavor == Flavor.dev) {
    return FirestoreInvitationRepository();
  } else {
    throw UnimplementedError(
        'InvitationRepository is not implemented for ${F.appFlavor}');
  }
});

/// 招待管理用のStateNotifier
///
/// グループの有効な招待一覧を管理
class InvitationNotifier extends StateNotifier<AsyncValue<List<Invitation>>> {
  final InvitationRepository _repository;
  final String _groupId;

  InvitationNotifier(this._repository, this._groupId)
      : super(const AsyncValue.loading()) {
    _loadInvitations();
  }

  /// 招待一覧を読み込み
  Future<void> _loadInvitations() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final invitations = await _repository.getInvitationsByGroup(_groupId);
      Log.info('📋 [INVITATION] 招待一覧取得: $_groupId (${invitations.length}件)');
      return invitations;
    });
  }

  /// 新しい招待を作成
  Future<Invitation?> createInvitation({
    required String groupName,
    required String invitedBy,
    required String inviterName,
    Duration expiry = const Duration(hours: 24),
    int maxUses = 5,
  }) async {
    try {
      final invitation = await _repository.inviteOthers(
        groupId: _groupId,
        groupName: groupName,
        invitedBy: invitedBy,
        inviterName: inviterName,
        expiry: expiry,
        maxUses: maxUses,
      );

      // 一覧を再読み込み
      await _loadInvitations();

      Log.info('✅ [INVITATION] 招待作成成功: ${invitation.token}');
      return invitation;
    } catch (e) {
      Log.error('❌ [INVITATION] 招待作成エラー: $e');
      return null;
    }
  }

  /// 招待を取り消し
  Future<bool> cancelInvitation(String token) async {
    try {
      await _repository.cancelInvitation(token);

      // 一覧を再読み込み
      await _loadInvitations();

      Log.info('🗑️ [INVITATION] 招待取り消し成功: $token');
      return true;
    } catch (e) {
      Log.error('❌ [INVITATION] 招待取り消しエラー: $e');
      return false;
    }
  }

  /// 期限切れ招待をクリーンアップ
  Future<void> cleanupExpired() async {
    try {
      await _repository.cleanUpExpiredInvitation();

      // 一覧を再読み込み
      await _loadInvitations();

      Log.info('🗑️ [INVITATION] 期限切れクリーンアップ完了');
    } catch (e) {
      Log.error('❌ [INVITATION] クリーンアップエラー: $e');
    }
  }

  /// 招待一覧を手動で再読み込み
  Future<void> refresh() async {
    await _loadInvitations();
  }
}

/// グループごとの招待一覧Provider
///
/// 引数: groupId
final invitationListProvider = StateNotifierProvider.family<InvitationNotifier,
    AsyncValue<List<Invitation>>, String>((ref, groupId) {
  final repository = ref.watch(invitationRepositoryProvider);
  return InvitationNotifier(repository, groupId);
});

/// 招待サービス用Provider
///
/// 招待の受諾処理などのビジネスロジック
class InvitationService {
  final InvitationRepository _repository;

  InvitationService(this._repository);

  /// 招待を検証して取得
  Future<Invitation?> validateAndGetInvitation(String token) async {
    try {
      final invitation = await _repository.getInvitationByToken(token);

      if (invitation == null) {
        Log.warning('⚠️ [INVITATION] 招待が見つかりません: $token');
        return null;
      }

      if (invitation.isExpired) {
        Log.warning('⚠️ [INVITATION] 招待の有効期限切れ: $token');
        return null;
      }

      if (invitation.isMaxUsesReached) {
        Log.warning('⚠️ [INVITATION] 招待の使用回数上限: $token');
        return null;
      }

      return invitation;
    } catch (e) {
      Log.error('❌ [INVITATION] 招待検証エラー: $e');
      return null;
    }
  }

  /// 招待を受諾してグループに参加
  Future<bool> acceptInvitation({
    required String token,
    required String userId,
    required String userName,
    required String userEmail,
  }) async {
    try {
      // 事前検証
      final invitation = await validateAndGetInvitation(token);
      if (invitation == null) {
        return false;
      }

      // すでに使用済みかチェック
      if (invitation.isUsedBy(userId)) {
        Log.warning('⚠️ [INVITATION] すでに使用済み: $token by $userId');
        return false;
      }

      // 受諾処理
      await _repository.allowAcceptUsers(
        token: token,
        userId: userId,
        userName: userName,
        userEmail: userEmail,
      );

      Log.info('✅ [INVITATION] 招待受諾成功: $userName → ${invitation.groupName}');
      return true;
    } catch (e) {
      Log.error('❌ [INVITATION] 招待受諾エラー: $e');
      return false;
    }
  }

  /// トークンから招待情報を取得（検証なし）
  Future<Invitation?> getInvitationByToken(String token) async {
    return await _repository.getInvitationByToken(token);
  }
}

/// InvitationServiceのProvider
final invitationServiceProvider = Provider<InvitationService>((ref) {
  final repository = ref.watch(invitationRepositoryProvider);
  return InvitationService(repository);
});
