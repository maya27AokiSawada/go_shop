import 'dart:convert';

// Logger instance

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../utils/app_logger.dart';
import '../utils/firestore_helper.dart'; // Firestore操作ヘルパー
import 'invitation_security_service.dart';
import 'user_initialization_service.dart';
import 'user_preferences_service.dart';
import 'notification_service.dart';
import '../providers/purchase_group_provider.dart';
import '../providers/user_settings_provider.dart';
import '../models/shared_group.dart' as models;
import '../datastore/hive_purchase_group_repository.dart'
    show hiveSharedGroupRepositoryProvider;

// QRコード招待サービスプロバイダー
final qrInvitationServiceProvider = Provider<QRInvitationService>((ref) {
  return QRInvitationService(ref);
});

class QRInvitationService {
  final Ref _ref;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  QRInvitationService(this._ref);

  InvitationSecurityService get _securityService =>
      _ref.read(invitationSecurityServiceProvider);

  /// セキュアなQRコード用の招待データを作成
  Future<Map<String, dynamic>> createQRInvitationData({
    required String shoppingListId,
    required String SharedGroupId,
    required String groupName,
    required String groupOwnerUid,
    required List<String> groupAllowedUids, // グループメンバーのUIDリスト
    required String invitationType, // 'individual' または 'partner'
    String? customMessage,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('ユーザーが認証されていません');
    }

    // セキュリティキーを生成
    final securityKey = _securityService.generateSecurityKey();
    final invitationId = _securityService.generateInvitationId(SharedGroupId);

    // セキュアな招待トークンを生成
    final invitationToken = _securityService.generateInvitationToken(
      groupId: SharedGroupId,
      invitationType: invitationType,
      securityKey: securityKey,
      inviterUid: currentUser.uid,
    );

    // 招待データを作成
    final invitationData = {
      'invitationId': invitationId,
      'inviterUid': currentUser.uid,
      'inviterEmail': currentUser.email ?? '',
      'inviterDisplayName':
          currentUser.displayName ?? currentUser.email ?? 'ユーザー',
      'shoppingListId': shoppingListId,
      'SharedGroupId': SharedGroupId,
      'groupName': groupName,
      'groupOwnerUid': groupOwnerUid,
      'invitationType': invitationType,
      'inviteRole': 'member',
      'message': customMessage ?? 'Go Shopグループへの招待です',
      'securityKey': securityKey,
      'invitationToken': invitationToken,
      'createdAt': DateTime.now().toIso8601String(),
      'expiresAt':
          DateTime.now().add(const Duration(hours: 24)).toIso8601String(),
      'type': 'secure_qr_invitation',
      'version': '3.0', // セキュリティ強化版
    };

    // Firestoreのサブコレクションに保存: SharedGroups/{groupId}/invitations/{invitationId}
    await _firestore
        .collection('SharedGroups')
        .doc(SharedGroupId)
        .collection('invitations')
        .doc(invitationId)
        .set({
      ...invitationData,
      'token': invitationId, // Invitationモデルのtokenフィールド用
      'groupId': SharedGroupId, // Invitationモデル用 (SharedGroupIdのエイリアス)
      'invitedBy': currentUser.uid, // Invitationモデル用
      'inviterName': currentUser.displayName ??
          currentUser.email ??
          'ユーザー', // Invitationモデル用
      'groupMemberUids':
          {groupOwnerUid, ...groupAllowedUids}.toList(), // 重複除去してグループメンバー全員のUID
      'createdAt': FieldValue.serverTimestamp(),
      'expiresAt': DateTime.now().add(const Duration(hours: 24)),
      'status': 'pending', // pending, accepted, expired
      'maxUses': 5, // 最大5人まで使用可能
      'currentUses': 0, // 初期値は0
      'usedBy': [], // 使用済みユーザーのUIDリスト
    });

    Log.info('🔐 招待データをFirestoreに保存: $invitationId');

    return invitationData;
  }

  /// QRコードデータをJSONエンコード
  String encodeQRData(Map<String, dynamic> invitationData) {
    return jsonEncode(invitationData);
  }

  /// QRコードデータをJSONデコード（セキュリティ検証付き）
  Map<String, dynamic>? decodeQRData(String qrData) {
    try {
      final decoded = jsonDecode(qrData) as Map<String, dynamic>;

      // バージョンチェック
      final version = decoded['version'] as String?;
      if (version == '3.0') {
        return _validateSecureInvitation(decoded);
      } else {
        return _validateLegacyInvitation(decoded);
      }
    } catch (e) {
      Log.error('QRコードデコードエラー: $e');
      return null;
    }
  }

  /// セキュア招待（v3.0）の検証
  Map<String, dynamic>? _validateSecureInvitation(
      Map<String, dynamic> decoded) {
    // 必須フィールドのチェック
    if (decoded['type'] != 'secure_qr_invitation' ||
        decoded['invitationId'] == null ||
        decoded['inviterUid'] == null ||
        decoded['SharedGroupId'] == null ||
        decoded['securityKey'] == null ||
        decoded['invitationToken'] == null ||
        decoded['expiresAt'] == null) {
      Log.info('セキュア招待データの必須フィールドが不足');
      return null;
    }

    // 有効期限チェック
    final expiresAt = DateTime.parse(decoded['expiresAt']);
    if (DateTime.now().isAfter(expiresAt)) {
      Log.info('招待コードが期限切れです');
      return null;
    }

    // 招待トークンの検証
    final token = decoded['invitationToken'] as String;
    final tokenData = _securityService.parseInvitationToken(token);
    if (tokenData == null) {
      Log.info('無効な招待トークン');
      return null;
    }

    // トークンの整合性チェック
    if (tokenData.groupId != decoded['SharedGroupId'] ||
        tokenData.securityKey != decoded['securityKey'] ||
        _securityService.isTokenExpired(tokenData.timestamp)) {
      Log.info('招待トークンの整合性チェック失敗');
      return null;
    }

    return decoded;
  }

  /// レガシー招待（v2.0以前）の検証
  Map<String, dynamic>? _validateLegacyInvitation(
      Map<String, dynamic> decoded) {
    if (decoded['type'] == 'qr_invitation' &&
        decoded['inviterUid'] != null &&
        decoded['inviterDisplayName'] != null &&
        decoded['shoppingListId'] != null &&
        decoded['SharedGroupId'] != null &&
        decoded['groupName'] != null &&
        decoded['groupOwnerUid'] != null &&
        decoded['inviteRole'] != null) {
      final role = decoded['inviteRole'] as String;
      if (role != 'member' && role != 'manager') {
        Log.warning('警告: 予期しない招待ロール: $role, memberとして扱います');
        decoded['inviteRole'] = 'member';
      }
      return decoded;
    }
    return null;
  }

  /// QRコードウィジェットを生成
  Widget generateQRWidget(String qrData, {double size = 200.0}) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.3),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: QrImageView(
        data: qrData,
        version: QrVersions.auto,
        size: size,
        backgroundColor: Colors.white,
        dataModuleStyle: const QrDataModuleStyle(
          dataModuleShape: QrDataModuleShape.square,
          color: Colors.black,
        ),
        eyeStyle: const QrEyeStyle(
          eyeShape: QrEyeShape.square,
          color: Colors.black,
        ),
        embeddedImage: null,
        embeddedImageStyle: null,
        errorStateBuilder: (cxt, err) {
          return Container(
            child: const Center(
              child: Text('QRコードの生成に失敗しました'),
            ),
          );
        },
      ),
    );
  }

  /// 招待を受諾する処理（セキュリティ検証付き）
  Future<bool> acceptQRInvitation({
    required Map<String, dynamic> invitationData,
    required String acceptorUid,
    required WidgetRef ref,
    String? providedSecurityKey, // セキュリティキー（必要な場合）
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null || currentUser.uid != acceptorUid) {
        throw Exception('ユーザー認証が無効です');
      }

      // セキュリティ検証
      if (!await _validateInvitationSecurity(
          invitationData, providedSecurityKey)) {
        throw Exception('招待のセキュリティ検証に失敗しました');
      }

      final inviterUid = invitationData['inviterUid'] as String;

      // 自分自身への招待を防ぐ
      if (inviterUid == acceptorUid) {
        throw Exception('自分自身を招待することはできません');
      }

      // 招待タイプを取得
      final invitationType =
          invitationData['invitationType'] as String? ?? 'individual';

      Log.info('💡 セキュア招待受諾: タイプ=$invitationType');

      // ⚠️ 受諾者の処理: 通知送信のみ（Hive/Firestore更新は招待元が実施）
      Log.info('📤 [ACCEPTOR] 招待元への通知を送信（すべての更新は招待元が実施）');
      Log.info('📤 [ACCEPTOR] 招待元UID: $inviterUid');
      Log.info('📤 [ACCEPTOR] 受諾者UID: $acceptorUid');

      // 招待元のオーナーに通知を送信
      final notificationService = _ref.read(notificationServiceProvider);
      final acceptorUser = _auth.currentUser;

      // SharedPreferencesから表示名を取得（ホーム画面で保存した名前）
      final prefsName = await UserPreferencesService.getUserName();

      // UserSettingsから表示名を取得（Hive）
      final userSettings = await _ref.read(userSettingsProvider.future);
      final settingsName = userSettings.userName;

      // 名前の優先順位: SharedPreferences → UserSettings.userName → Auth.displayName → email → UID
      final userName = (prefsName?.isNotEmpty == true)
          ? prefsName!
          : (settingsName.isNotEmpty
              ? settingsName
              : (acceptorUser?.displayName?.isNotEmpty == true
                  ? acceptorUser!.displayName!
                  : (acceptorUser?.email?.isNotEmpty == true
                      ? acceptorUser!.email!
                      : acceptorUid)));

      Log.info('📤 [ACCEPTOR] SharedPreferences.userName: $prefsName');
      Log.info('📤 [ACCEPTOR] UserSettings.userName: $settingsName');
      Log.info('📤 [ACCEPTOR] Auth.displayName: ${acceptorUser?.displayName}');
      Log.info('📤 [ACCEPTOR] Auth.email: ${acceptorUser?.email}');
      Log.info('📤 [ACCEPTOR] 最終決定した名前: $userName');

      final groupId = invitationData['SharedGroupId'] as String;
      final groupName = invitationData['groupName'] as String? ?? 'グループ';

      Log.info(
          '📤 [ACCEPTOR] 通知データ: groupId=$groupId, groupName=$groupName, userName=$userName');

      await notificationService.sendNotification(
        targetUserId: inviterUid,
        groupId: groupId,
        type: NotificationType.groupMemberAdded,
        message: '$userName さんが「$groupName」への参加を希望しています',
        metadata: {
          'groupName': groupName,
          'acceptorUid': acceptorUid,
          'acceptorName': userName,
          'invitationId': invitationData['invitationId'],
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      Log.info('✅ [ACCEPTOR] 通知送信完了 - 招待元の確認待ち');

      Log.info('✅ 招待受諾処理完了 - バックグラウンド同期開始');

      return true;
    } catch (e) {
      Log.error('QR招待受諾エラー: $e');
      return false;
    }
  }

  /// 確認通知を待機してFirestore→Hive同期（バックグラウンド）
  Future<void> _waitForConfirmationAndSync({
    required String groupId,
    required User currentUser,
  }) async {
    try {
      Log.info('⏳ [BACKGROUND] 確認通知待機開始...');

      final notificationService = _ref.read(notificationServiceProvider);

      // 最大10秒待機（短縮）
      final confirmed = await notificationService.waitForSyncConfirmation(
        groupId: groupId,
        timeout: const Duration(seconds: 10),
      );

      if (!confirmed) {
        Log.warning('⚠️ [BACKGROUND] 確認通知タイムアウト - Firestore反映待機後同期');
        // Firestore書き込み反映とクエリキャッシュ更新を待つ
        await Future.delayed(const Duration(seconds: 5));
      } else {
        Log.info('✅ [BACKGROUND] 確認通知受信 - 即座に同期');
      }

      // Firestore→Hive同期を実行
      Log.info('🔄 [BACKGROUND] Firestore→Hive同期開始');
      final userInitService = _ref.read(userInitializationServiceProvider);
      await userInitService.syncFromFirestoreToHive(currentUser);

      // AllGroupsProviderを再読み込み
      _ref.invalidate(allGroupsProvider);

      // SelectedGroupProviderも再読み込み（現在選択中のグループがある場合）
      try {
        _ref.invalidate(selectedGroupProvider);
        Log.info('✅ [BACKGROUND] selectedGroupProviderも無効化');
      } catch (e) {
        Log.info('ℹ️ [BACKGROUND] selectedGroupProvider無効化スキップ: $e');
      }

      Log.info('✅ [BACKGROUND] バックグラウンド同期完了');
    } catch (e) {
      Log.error('❌ [BACKGROUND] バックグラウンド同期エラー: $e');
    }
  }

  /// Hiveにプレースホルダーグループを作成
  Future<void> _createPlaceholderGroup({
    required String groupId,
    required String groupName,
    required String inviterUid,
    required String acceptorUid,
  }) async {
    try {
      Log.info('🔧 [PLACEHOLDER] プレースホルダーグループ作成開始');

      // リポジトリ取得
      final repository = _ref.read(SharedGroupRepositoryProvider);

      // 既に存在する場合はスキップ
      try {
        final existingGroup = await repository.getGroupById(groupId);
        Log.info(
            'ℹ️ [PLACEHOLDER] グループは既に存在: $groupId, ${existingGroup.groupName}');
        return;
      } catch (e) {
        // グループが存在しない場合は続行
        Log.info('📝 [PLACEHOLDER] グループが存在しないため作成します: $groupId');
      }

      // プレースホルダーグループ作成
      final placeholderGroup = models.SharedGroup(
        groupId: groupId,
        groupName: groupName,
        ownerUid: inviterUid,
        ownerName: '招待元ユーザー', // 仮データ
        ownerEmail: '',
        allowedUid: [inviterUid, acceptorUid], // 両方のUIDを設定
        members: [
          models.SharedGroupMember(
            memberId: inviterUid,
            name: '招待元ユーザー',
            contact: '',
            role: models.SharedGroupRole.owner,
            isSignedIn: true,
            invitationStatus: models.InvitationStatus.self,
          ),
          models.SharedGroupMember(
            memberId: acceptorUid,
            name: '招待されたユーザー',
            contact: '',
            role: models.SharedGroupRole.member,
            isSignedIn: true,
            invitationStatus: models.InvitationStatus.pending,
          ),
        ],
        syncStatus: models.SyncStatus.pending, // pending状態に設定
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Hiveに保存
      await repository.updateGroup(groupId, placeholderGroup);
      Log.info('✅ [PLACEHOLDER] プレースホルダーグループ保存完了: $groupId');

      // UI更新
      _ref.invalidate(allGroupsProvider);
      Log.info('✅ [PLACEHOLDER] UI更新完了');
    } catch (e) {
      Log.error('❌ [PLACEHOLDER] プレースホルダーグループ作成エラー: $e');
      rethrow;
    }
  }

  /// 招待のセキュリティを検証（Firestoreから取得）
  Future<bool> _validateInvitationSecurity(
      Map<String, dynamic> invitationData, String? providedKey) async {
    final version = invitationData['version'] as String?;

    // v3.0（セキュア版）の場合
    if (version == '3.0') {
      final invitationId = invitationData['invitationId'] as String?;
      if (invitationId == null) {
        Log.info('❌ 招待IDが不足');
        return false;
      }

      // QRデータ内のセキュリティキーを取得（providedKeyがnullの場合）
      final securityKeyToValidate =
          providedKey ?? invitationData['securityKey'] as String?;

      // Firestoreから実際の招待データを取得
      final SharedGroupId = invitationData['SharedGroupId'] as String?;
      if (SharedGroupId == null) {
        Log.info('❌ SharedGroupIdが見つかりません');
        return false;
      }
      final invitationDoc = await _firestore
          .collection('SharedGroups')
          .doc(SharedGroupId)
          .collection('invitations')
          .doc(invitationId)
          .get();

      if (!invitationDoc.exists) {
        Log.info('❌ 招待が見つかりません: $invitationId');
        return false;
      }

      final storedData = invitationDoc.data()!;
      final storedSecurityKey = storedData['securityKey'] as String?;
      final status = storedData['status'] as String?;
      final expiresAt = storedData['expiresAt'] as Timestamp?;

      // ステータスチェック
      if (status != 'pending') {
        Log.info('❌ 招待は既に使用済みまたは無効です: $status');
        return false;
      }

      // 有効期限チェック
      if (expiresAt != null && expiresAt.toDate().isBefore(DateTime.now())) {
        Log.info('❌ 招待の有効期限が切れています');
        return false;
      }

      // セキュリティキー検証
      if (storedSecurityKey == null || securityKeyToValidate == null) {
        Log.info('❌ セキュリティキーが不足');
        return false;
      }

      if (!_securityService.validateSecurityKey(
          securityKeyToValidate, storedSecurityKey)) {
        Log.info('❌ セキュリティキーが無効');
        return false;
      }

      Log.info('✅ セキュリティ検証成功');
    }

    return true;
  }

  /// 招待受諾を記録
  Future<void> _recordInvitationAcceptance(
      Map<String, dynamic> invitationData, String acceptorUid) async {
    final invitationId = invitationData['invitationId'] as String?;
    if (invitationId != null) {
      await _firestore.collection('invitation_logs').doc(invitationId).set({
        'invitationId': invitationId,
        'acceptorUid': acceptorUid,
        'acceptedAt': FieldValue.serverTimestamp(),
        'groupId': invitationData['SharedGroupId'],
        'invitationType': invitationData['invitationType'],
      });
    }
  }

  /// パートナー招待を処理 - 招待者の全グループへのアクセスを許可
  Future<void> _processPartnerInvitation(
      String inviterUid, String acceptorUid) async {
    try {
      Log.info('🤝 パートナー招待を処理中...');

      // パートナーリストに追加
      await _firestore
          .collection('users')
          .doc(inviterUid)
          .collection('partners')
          .doc(acceptorUid)
          .set({
        'uid': acceptorUid,
        'addedAt': FieldValue.serverTimestamp(),
        'addedBy': 'invitation',
      });

      await _firestore
          .collection('users')
          .doc(acceptorUid)
          .collection('partners')
          .doc(inviterUid)
          .set({
        'uid': inviterUid,
        'addedAt': FieldValue.serverTimestamp(),
        'addedBy': 'invitation_acceptance',
      });

      // 招待者がオーナーのグループを取得
      final ownerGroupsQuery = await _firestore
          .collection('SharedGroups')
          .where('ownerUid', isEqualTo: inviterUid)
          .get();

      // 各グループにパートナーとして追加
      for (final doc in ownerGroupsQuery.docs) {
        final groupData = doc.data();

        // ユーザー情報を取得（優先順位: SharedPreferences > Firestore profile > Firebase Auth）
        final acceptorUser = _auth.currentUser;
        String userName = '';

        // 1. SharedPreferencesから取得を試みる
        try {
          final prefs = await UserPreferencesService.getUserName();
          if (prefs != null && prefs.isNotEmpty) {
            userName = prefs;
            Log.info('✅ [PARTNER] SharedPreferencesからユーザー名取得: "$userName"');
          }
        } catch (e) {
          Log.warning('⚠️ [PARTNER] SharedPreferences取得エラー: $e');
        }

        // 2. Firestore /users/{uid}/profile/userName から取得を試みる
        if (userName.isEmpty) {
          try {
            final profileDoc = await _firestore
                .collection('users')
                .doc(acceptorUid)
                .collection('profile')
                .doc('userName')
                .get();

            if (profileDoc.exists) {
              final profileData = profileDoc.data();
              userName = profileData?['userName'] ?? '';
              if (userName.isNotEmpty) {
                Log.info('✅ [PARTNER] Firestore profileからユーザー名取得: "$userName"');
              }
            }
          } catch (e) {
            Log.error('⚠️ [PARTNER] Firestore profile取得エラー: $e');
          }
        }

        // 3. Firebase Auth displayNameから取得を試みる
        if (userName.isEmpty) {
          userName = acceptorUser?.displayName ?? '';
          if (userName.isNotEmpty) {
            Log.info('✅ [PARTNER] Firebase Auth displayNameから取得: "$userName"');
          }
        }

        // 4. 最終フォールバック
        if (userName.isEmpty) {
          final userEmail = acceptorUser?.email ?? '';
          userName = userEmail.isNotEmpty
              ? userEmail.split('@').first
              : 'Unknown User';
          Log.warning('⚠️ [PARTNER] すべての取得失敗 - フォールバック: "$userName"');
        }

        // 新しいメンバー情報
        final newMember = {
          'memberId': acceptorUid,
          'name': userName,
          'role': 'partner', // パートナーロール
          'joinedAt': FieldValue.serverTimestamp(),
        };

        // Firestoreを更新（FieldValue.arrayUnionでマージ）
        await doc.reference.update({
          'allowedUid': FieldValue.arrayUnion([acceptorUid]), // 🔥 マージ処理
          'members': FieldValue.arrayUnion([newMember]), // 🔥 マージ処理
          'updatedAt': FieldValue.serverTimestamp(),
        });

        Log.info('✅ パートナーとして ${doc.id} グループに追加: $acceptorUid');

        // グループの全メンバーに通知を送信（参加者本人は除く）
        final notificationService = _ref.read(notificationServiceProvider);

        await notificationService.sendNotificationToGroup(
          groupId: doc.id,
          type: NotificationType.groupMemberAdded,
          message: '$userName さんがパートナーとして参加しました',
          excludeUserIds: [acceptorUid], // 参加者本人には送らない
          metadata: {
            'groupId': doc.id,
            'newMemberId': acceptorUid,
            'newMemberName': userName,
            'acceptorUid': acceptorUid, // 確認通知送信先
            'invitationType': 'partner',
          },
        );
      }

      Log.info('✅ パートナー招待処理完了');
    } catch (e) {
      Log.error('❌ フレンド招待処理エラー: $e');
      rethrow;
    }
  }

  /// 個別招待を処理 - 特定のグループのみ
  Future<void> _processIndividualInvitation(
      Map<String, dynamic> invitationData, String acceptorUid) async {
    try {
      Log.info('👤 個別招待を処理中...');

      final groupId = invitationData['SharedGroupId'] as String;
      final groupName = invitationData['groupName'] as String;

      Log.info('🔍 [QR_INVITATION] グループID: $groupId');
      Log.info('🔍 [QR_INVITATION] グループ名: $groupName');

      // ⚠️ 重要: FirestoreとHiveの両方からallowedUidを取得してマージ
      final repository = _ref.read(SharedGroupRepositoryProvider);

      // 1. Firestoreから最新データを取得（招待元のallowedUidを保持するため）
      models.SharedGroup? firestoreGroup;
      List<String> firestoreAllowedUid = [];
      List<models.SharedGroupMember> firestoreMembers = [];

      // 🔥 共通ユーティリティでFirestoreから取得
      firestoreGroup = await FirestoreHelper.fetchGroup(groupId);
      if (firestoreGroup != null) {
        firestoreAllowedUid = List<String>.from(firestoreGroup.allowedUid);
        firestoreMembers =
            List<models.SharedGroupMember>.from(firestoreGroup.members ?? []);
        Log.info(
            '✅ [QR_INVITATION] Firestoreから取得: ${firestoreGroup.groupName}');
        Log.info(
            '🔍 [QR_INVITATION] Firestore allowedUid: $firestoreAllowedUid');
      } else {
        Log.info('⚠️ [QR_INVITATION] Firestoreにグループなし');
      }

      // 2. Hiveからプレースホルダーを取得
      List<String> hiveAllowedUid = [];
      List<models.SharedGroupMember> hiveMembers = [];
      models.SharedGroup? hiveGroup;

      try {
        hiveGroup = await repository.getGroupById(groupId);
        hiveAllowedUid = List<String>.from(hiveGroup.allowedUid);
        hiveMembers =
            List<models.SharedGroupMember>.from(hiveGroup.members ?? []);
        Log.info('✅ [QR_INVITATION] Hiveから取得: ${hiveGroup.groupName}');
        Log.info('🔍 [QR_INVITATION] Hive allowedUid: $hiveAllowedUid');
      } catch (e) {
        Log.error('⚠️ [QR_INVITATION] Hive取得エラー: $e');
      }

      // 3. allowedUidをマージ（重複を除去）
      final mergedAllowedUid = <String>{
        ...firestoreAllowedUid,
        ...hiveAllowedUid,
      }.toList();
      Log.info('🔀 [QR_INVITATION] マージ後 allowedUid: $mergedAllowedUid');

      // 4. ベースとなるグループを決定（Firestoreを優先、なければHive）
      final baseGroup = firestoreGroup ?? hiveGroup;
      if (baseGroup == null) {
        throw Exception('グループが見つかりません: $groupId');
      }

      Log.info('🔍 [QR_INVITATION] ベースグループ: ${baseGroup.groupName}');

      // allowedUidを準備（マージ済みリストのコピー + acceptorUid追加）
      final allowedUid = List<String>.from(mergedAllowedUid);
      final members = List<models.SharedGroupMember>.from(
        firestoreMembers.isNotEmpty ? firestoreMembers : hiveMembers,
      );

      // allowedUidに追加（重複チェック）
      if (!allowedUid.contains(acceptorUid)) {
        allowedUid.add(acceptorUid);
        Log.info('✅ [QR_INVITATION] acceptorUidを追加: $acceptorUid');
      } else {
        Log.info('💡 [QR_INVITATION] acceptorUidは既に存在: $acceptorUid');
      }

      Log.info('🔍 [QR_INVITATION] 最終 allowedUid: $allowedUid');

      // membersリストにも追加
      final memberExists = members.any((m) => m.memberId == acceptorUid);
      if (!memberExists) {
        // ユーザー情報を取得（優先順位: SharedPreferences > Firestore profile > Firebase Auth > メールアドレス）
        final acceptorUser = _auth.currentUser;
        String userName = '';
        String userEmail = acceptorUser?.email ?? '';

        Log.info('🔍 [QR_INVITATION] ユーザー名取得開始');

        // 1. SharedPreferencesから取得を試みる
        try {
          final prefs = await UserPreferencesService.getUserName();
          if (prefs != null && prefs.isNotEmpty) {
            userName = prefs;
            Log.info(
                '✅ [QR_INVITATION] SharedPreferencesからユーザー名取得: "$userName"');
          }
        } catch (e) {
          Log.warning('⚠️ [QR_INVITATION] SharedPreferences取得エラー: $e');
        }

        // 2. Firestore /users/{uid}/profile/userName から取得を試みる
        if (userName.isEmpty) {
          Log.info(
              '⚠️ [QR_INVITATION] SharedPreferences空 - Firestore profileから取得試行');
          try {
            final profileDoc = await _firestore
                .collection('users')
                .doc(acceptorUid)
                .collection('profile')
                .doc('userName')
                .get();

            Log.info(
                '🔍 [QR_INVITATION] Firestore profileドキュメント存在: ${profileDoc.exists}');
            if (profileDoc.exists) {
              final profileData = profileDoc.data();
              userName = profileData?['userName'] ?? '';
              Log.info(
                  '✅ [QR_INVITATION] Firestore profileからユーザー名取得: "$userName"');
            }
          } catch (e) {
            Log.error('⚠️ [QR_INVITATION] Firestore profile取得エラー: $e');
          }
        }

        // 3. Firebase Auth displayNameから取得を試みる
        if (userName.isEmpty) {
          userName = acceptorUser?.displayName ?? '';
          if (userName.isNotEmpty) {
            Log.info(
                '✅ [QR_INVITATION] Firebase Auth displayNameから取得: "$userName"');
          }
        }

        // 4. 最終フォールバック: メールアドレスのローカル部分
        if (userName.isEmpty) {
          Log.warning('⚠️ [QR_INVITATION] すべての取得失敗 - メールから生成');
          userName = userEmail.isNotEmpty ? userEmail.split('@').first : 'ユーザー';
        }

        Log.info('✅ [QR_INVITATION] 最終ユーザー名: "$userName"');

        // 新しいメンバーを追加
        final newMember = models.SharedGroupMember(
          memberId: acceptorUid,
          name: userName,
          contact: userEmail,
          role: models.SharedGroupRole.member, // デフォルトは一般メンバー
          isSignedIn: true,
          invitationStatus: models.InvitationStatus.accepted,
          acceptedAt: DateTime.now(),
        );
        members.add(newMember);
        Log.info('✅ membersリストに追加: $userName ($acceptorUid)');
      }

      // グループを更新（リポジトリ経由）
      final updatedGroup = baseGroup.copyWith(
        allowedUid: allowedUid,
        members: members,
        syncStatus: models.SyncStatus.pending, // ⚠️ 招待元の更新待ち状態に設定
        updatedAt: DateTime.now(),
      );

      Log.info('🔍 [QR_INVITATION] 更新前 - allowedUid: ${baseGroup.allowedUid}');
      Log.info(
          '🔍 [QR_INVITATION] 更新後 - allowedUid: ${updatedGroup.allowedUid}');
      Log.info('🔍 [QR_INVITATION] メンバー数: ${updatedGroup.members?.length}');
      Log.info(
          '🔍 [QR_INVITATION] syncStatus: ${updatedGroup.syncStatus} (pending=招待元が更新するまで削除保護)');

      // ⚠️ CRITICAL: Hive専用リポジトリを使用（Firestore更新を回避）
      // HybridRepositoryを使うとFirestoreにも書き込もうとしてPermission-Deniedになる
      final hiveRepository = _ref.read(hiveSharedGroupRepositoryProvider);
      await hiveRepository.saveGroup(updatedGroup);
      Log.info('✅ Hiveのみにグループ更新完了（受諾者ローカル、Firestoreは招待元が更新）');

      // Firestoreへの直接更新は行わない（招待元が通知を受け取って更新する）
      Log.info('📤 [NOTIFICATION] 招待元への通知準備');

      // グループの全メンバーに通知を送信（参加者本人は除く）
      final notificationService = _ref.read(notificationServiceProvider);
      final acceptorUser = _auth.currentUser;
      final userName =
          acceptorUser?.displayName ?? acceptorUser?.email ?? 'ユーザー';

      await notificationService.sendNotificationToGroup(
        groupId: groupId,
        type: NotificationType.groupMemberAdded,
        message: '$userName さんがグループに参加しました',
        excludeUserIds: [acceptorUid], // 参加者本人には送らない
        metadata: {
          'groupId': groupId, // 招待元がこのグループを再同期するため
          'newMemberId': acceptorUid,
          'newMemberName': userName,
          'acceptorUid': acceptorUid,
        },
      );

      Log.info('✅ 個別招待処理完了 + 通知送信完了（招待元が更新を実行）');
    } catch (e) {
      Log.error('❌ 個別招待処理エラー: $e');
      rethrow;
    }
  }

  /// 招待トークンの使用回数を更新
  // ⚠️ [DELETED] _updateInvitationUsage()
  // PlanBでは招待元のStreamBuilderが招待ドキュメントを監視・更新するため、
  // 受諾者側でFirestore更新は不要（Permission-Denied回避）
}
