import 'dart:convert';

// Logger instance

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../utils/app_logger.dart';
import 'invitation_security_service.dart';
import 'user_preferences_service.dart';
import 'notification_service.dart';
import '../providers/user_settings_provider.dart';
import 'error_log_service.dart';

// QRコード招待サービスプロバイダー
final qrInvitationServiceProvider = Provider<QRInvitationService>((ref) {
  return QRInvitationService(ref);
});

class QRInvitationService {
  final Ref _ref;
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  // 🔥 依存性注入対応: テスト時はmockを注入、本番時はデフォルト値を使用
  QRInvitationService(
    this._ref, {
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  InvitationSecurityService get _securityService =>
      _ref.read(invitationSecurityServiceProvider);

  /// セキュアなQRコード用の招待データを作成
  Future<Map<String, dynamic>> createQRInvitationData({
    required String sharedGroupId,
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

    // Firestoreプロファイルから表示名を取得（最優先）
    String? firestoreName;
    try {
      final userDoc =
          await _firestore.collection('users').doc(currentUser.uid).get();

      if (userDoc.exists) {
        firestoreName = userDoc.data()?['displayName'] as String?;
      }
    } catch (e) {
      Log.error('📤 [INVITER] Firestoreプロファイル取得エラー: $e');
    }

    // SharedPreferencesから表示名を取得
    final prefsName = await UserPreferencesService.getUserName();

    // UserSettingsから表示名を取得（Hive）
    final userSettings = await _ref.read(userSettingsProvider.future);
    final settingsName = userSettings.userName;

    // 名前の優先順位: Firestore → SharedPreferences → UserSettings → Auth.displayName → email → UID
    final inviterName = (firestoreName?.isNotEmpty == true)
        ? firestoreName!
        : (prefsName?.isNotEmpty == true)
            ? prefsName!
            : (settingsName.isNotEmpty
                ? settingsName
                : (currentUser.displayName?.isNotEmpty == true
                    ? currentUser.displayName!
                    : (currentUser.email?.isNotEmpty == true
                        ? currentUser.email!
                        : currentUser.uid)));

    Log.info(
        '📤 [INVITER] Firestore.displayName: ${AppLogger.maskName(firestoreName)}');
    Log.info(
        '📤 [INVITER] SharedPreferences.userName: ${AppLogger.maskName(prefsName)}');
    Log.info(
        '📤 [INVITER] UserSettings.userName: ${AppLogger.maskName(settingsName)}');
    Log.info(
        '📤 [INVITER] Auth.displayName: ${AppLogger.maskName(currentUser.displayName)}');
    Log.info(
        '📤 [INVITER] Auth.email: ${AppLogger.maskName(currentUser.email)}');
    Log.info('📤 [INVITER] 最終決定した名前: ${AppLogger.maskName(inviterName)}');

    // セキュリティキーを生成
    final securityKey = _securityService.generateSecurityKey();
    final invitationId = _securityService.generateInvitationId(sharedGroupId);

    // セキュアな招待トークンを生成
    final invitationToken = _securityService.generateInvitationToken(
      groupId: sharedGroupId,
      invitationType: invitationType,
      securityKey: securityKey,
      inviterUid: currentUser.uid,
    );

    // 招待データを作成
    final invitationData = {
      'invitationId': invitationId,
      'inviterUid': currentUser.uid,
      'inviterEmail': currentUser.email ?? '',
      'inviterDisplayName': inviterName,
      'sharedGroupId': sharedGroupId,
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

    // 🔥 FIX: Firestoreのサブコレクションに保存（permission-denied対策のリトライあり）
    // SharedGroups/{groupId}/invitations/{invitationId}
    final invitationDocData = {
      ...invitationData,
      'token': invitationId, // Invitationモデルのtokenフィールド用
      'groupId': sharedGroupId, // Invitationモデル用 (sharedGroupIdのエイリアス)
      'invitedBy': currentUser.uid, // Invitationモデル用
      'inviterName': inviterName, // Invitationモデル用（Firestoreプロファイルから取得した名前）
      'groupMemberUids':
          {groupOwnerUid, ...groupAllowedUids}.toList(), // 重複除去してグループメンバー全員のUID
      'createdAt': FieldValue.serverTimestamp(),
      'expiresAt': DateTime.now().add(const Duration(hours: 24)),
      'status': 'pending', // pending, accepted, expired
      'maxUses': 5, // 最大5人まで使用可能
      'currentUses': 0, // 初期値は0
      'usedBy': [], // 使用済みユーザーのUIDリスト
    };

    try {
      await _firestore
          .collection('SharedGroups')
          .doc(sharedGroupId)
          .collection('invitations')
          .doc(invitationId)
          .set(invitationDocData);
      Log.info('🔐 招待データをFirestoreに保存: $invitationId');
    } catch (e) {
      if (e.toString().contains('permission-denied')) {
        Log.warning('⚠️ [INVITATION] 招待作成でpermission-denied、リトライします: $e');
        // グループ作成直後の伝播遅延の可能性があるため、100ms待機してリトライ
        await Future.delayed(const Duration(milliseconds: 100));
        await _firestore
            .collection('SharedGroups')
            .doc(sharedGroupId)
            .collection('invitations')
            .doc(invitationId)
            .set(invitationDocData);
        Log.info('✅ [INVITATION] リトライ成功: $invitationId');
      } else {
        Log.error('❌ [INVITATION] 招待データ保存エラー: $e');
        await ErrorLogService.logOperationError('QR招待作成', '$e');
        rethrow;
      }
    }

    return invitationData;
  }

  /// QRコードデータをJSONエンコード（軽量版: 必須データのみ）
  String encodeQRData(Map<String, dynamic> invitationData) {
    // QRコードには最小限のデータのみ含める（スキャン精度向上のため）
    final minimalData = {
      'invitationId': invitationData['invitationId'],
      'sharedGroupId': invitationData['sharedGroupId'],
      'securityKey': invitationData['securityKey'],
      'type': 'secure_qr_invitation',
      'version': '3.1', // 軽量版
    };
    final encodedData = jsonEncode(minimalData);
    Log.info('📲 [QR_ENCODE] QRコード生成: データ長=${encodedData.length}文字');
    Log.info('📲 [QR_ENCODE] データ内容: $encodedData');
    return encodedData;
  }

  /// QRコードデータをJSONデコード（セキュリティ検証付き）
  Future<Map<String, dynamic>?> decodeQRData(String qrData) async {
    Log.info('📲 [QR_DECODE] QRコードデコード開始: データ長=${qrData.length}文字');
    Log.info(
        '📲 [QR_DECODE] 受信データ: ${qrData.substring(0, qrData.length > 200 ? 200 : qrData.length)}');
    try {
      final decoded = jsonDecode(qrData) as Map<String, dynamic>;
      Log.info('📲 [QR_DECODE] JSONデコード成功');
      Log.info('📲 [QR_DECODE] version: ${decoded['version']}');
      Log.info('📲 [QR_DECODE] type: ${decoded['type']}');

      // バージョンチェック
      final version = decoded['version'] as String?;
      if (version == '3.0' || version == '3.1') {
        final validated = _validateSecureInvitation(decoded);
        if (validated == null) return null;

        // v3.1（軽量版）の場合はFirestoreから詳細を取得
        if (version == '3.1') {
          return await _fetchInvitationDetails(validated);
        }

        return validated;
      } else {
        Log.warning('📲 [QR_DECODE] 未対応のバージョン: $version');
        return _validateLegacyInvitation(decoded);
      }
    } catch (e, stackTrace) {
      Log.error('❌ [QR_DECODE] QRコードデコードエラー: $e');
      Log.error('❌ [QR_DECODE] スタックトレース: $stackTrace');
      Log.error(
          '❌ [QR_DECODE] 問題のあるデータ: ${qrData.substring(0, qrData.length > 100 ? 100 : qrData.length)}');
      await ErrorLogService.logOperationError('QRコードデコード', '$e', stackTrace);
      return null;
    }
  }

  /// Firestoreから招待詳細を取得（v3.1軽量版用）
  Future<Map<String, dynamic>?> _fetchInvitationDetails(
      Map<String, dynamic> minimalData) async {
    try {
      final invitationId = minimalData['invitationId'] as String;
      final sharedGroupId = minimalData['sharedGroupId'] as String;
      final securityKey = minimalData['securityKey'] as String;

      Log.info('📥 Firestoreから招待詳細を取得: $invitationId');

      // Firestoreから招待詳細を取得
      final invitationDoc = await _firestore
          .collection('SharedGroups')
          .doc(sharedGroupId)
          .collection('invitations')
          .doc(invitationId)
          .get();

      if (!invitationDoc.exists) {
        Log.error('❌ 招待が見つかりません: $invitationId');
        return null;
      }

      final invitationData = invitationDoc.data()!;

      // セキュリティキー検証
      if (invitationData['securityKey'] != securityKey) {
        Log.error('❌ セキュリティキーが一致しません');
        return null;
      }

      // 有効期限チェック
      final expiresAt = (invitationData['expiresAt'] as Timestamp).toDate();
      if (DateTime.now().isAfter(expiresAt)) {
        Log.error('❌ 招待の有効期限切れ');
        return null;
      }

      // 使用回数チェック（maxUsesベース）
      final status = invitationData['status'] as String?;
      final currentUses = invitationData['currentUses'] as int? ?? 0;
      final maxUses = invitationData['maxUses'] as int? ?? 5;

      if (currentUses >= maxUses) {
        Log.error('❌ 招待の使用回数上限に達しています: $currentUses/$maxUses');
        return null;
      }

      // 有効なステータスかチェック（pending または使用枠が残っている accepted）
      if (status != 'pending' && status != 'accepted') {
        Log.error('❌ 招待のステータスが無効: $status');
        return null;
      }

      Log.info('✅ 招待詳細取得成功');
      // 🔥 FIX: QRコードのバージョン"3.1"を保持（Firestoreの"3.0"で上書きしない）
      invitationData['version'] = '3.1';
      return invitationData;
    } catch (e) {
      Log.error('❌ 招待詳細取得エラー: $e');
      await ErrorLogService.logOperationError('QR招待詳細取得', '$e');
      return null;
    }
  }

  /// セキュア招待（v3.0/v3.1）の検証
  Map<String, dynamic>? _validateSecureInvitation(
      Map<String, dynamic> decoded) {
    final version = decoded['version'] as String?;

    // v3.1（軽量版）: 最小限のフィールドのみチェック
    if (version == '3.1') {
      if (decoded['type'] != 'secure_qr_invitation' ||
          decoded['invitationId'] == null ||
          decoded['sharedGroupId'] == null ||
          decoded['securityKey'] == null) {
        Log.info('セキュア招待データ（軽量版）の必須フィールドが不足');
        return null;
      }
      // 軽量版: Firestoreから詳細取得するためここではバリデーションのみ
      return decoded;
    }

    // v3.0（フル版）: 全フィールドチェック（後方互換性）
    if (decoded['type'] != 'secure_qr_invitation' ||
        decoded['invitationId'] == null ||
        decoded['inviterUid'] == null ||
        decoded['sharedGroupId'] == null ||
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
    if (tokenData.groupId != decoded['sharedGroupId'] ||
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
        decoded['sharedListId'] != null &&
        decoded['sharedGroupId'] != null &&
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

  /// QRコードウィジェットを生成（デフォルトサイズ250でスキャン精度向上）
  Widget generateQRWidget(String qrData, {double size = 250.0}) {
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
          return const Center(
            child: Text('QRコードの生成に失敗しました'),
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
      Log.info('📤 [ACCEPTOR] 招待元UID: ${AppLogger.maskUserId(inviterUid)}');
      Log.info('📤 [ACCEPTOR] 受諾者UID: ${AppLogger.maskUserId(acceptorUid)}');

      // 招待元のオーナーに通知を送信
      final notificationService = _ref.read(notificationServiceProvider);
      final acceptorUser = _auth.currentUser;

      // Firestoreプロファイルから表示名を取得
      String? firestoreName;
      try {
        final userDoc =
            await _firestore.collection('users').doc(acceptorUid).get();

        if (userDoc.exists) {
          firestoreName = userDoc.data()?['displayName'] as String?;
        }
      } catch (e) {
        Log.error('📤 [ACCEPTOR] Firestoreプロファイル取得エラー: $e');
      }

      // SharedPreferencesから表示名を取得（ホーム画面で保存した名前）
      final prefsName = await UserPreferencesService.getUserName();

      // UserSettingsから表示名を取得（Hive）
      final userSettings = await _ref.read(userSettingsProvider.future);
      final settingsName = userSettings.userName;

      // 名前の優先順位: Firestore → SharedPreferences → UserSettings.userName → Auth.displayName → email → UID
      final userName = (firestoreName?.isNotEmpty == true)
          ? firestoreName!
          : (prefsName?.isNotEmpty == true)
              ? prefsName!
              : (settingsName.isNotEmpty
                  ? settingsName
                  : (acceptorUser?.displayName?.isNotEmpty == true
                      ? acceptorUser!.displayName!
                      : (acceptorUser?.email?.isNotEmpty == true
                          ? acceptorUser!.email!
                          : acceptorUid)));

      Log.info(
          '📤 [ACCEPTOR] Firestore.displayName: ${AppLogger.maskName(firestoreName)}');
      Log.info(
          '📤 [ACCEPTOR] SharedPreferences.userName: ${AppLogger.maskName(prefsName)}');
      Log.info(
          '📤 [ACCEPTOR] UserSettings.userName: ${AppLogger.maskName(settingsName)}');
      Log.info(
          '📤 [ACCEPTOR] Auth.displayName: ${AppLogger.maskName(acceptorUser?.displayName)}');
      Log.info(
          '📤 [ACCEPTOR] Auth.email: ${AppLogger.maskName(acceptorUser?.email)}');
      Log.info('📤 [ACCEPTOR] 最終決定した名前: ${AppLogger.maskName(userName)}');

      final groupId = invitationData['sharedGroupId'] as String;
      final groupName = invitationData['groupName'] as String? ?? 'グループ';

      Log.info(
          '📤 [ACCEPTOR] 通知データ: groupId=$groupId, groupName=$groupName, userName=$userName');
      Log.info(
          '📤 [ACCEPTOR] 通知送信開始 - targetUserId: ${AppLogger.maskUserId(inviterUid)}');

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

      // 🔥 FIX: 通知が実際にFirestoreに書き込まれたか検証（100ms待機後に確認）
      await Future.delayed(const Duration(milliseconds: 100));

      try {
        final recentNotifications = await _firestore
            .collection('notifications')
            .where('userId', isEqualTo: inviterUid)
            .where('metadata.acceptorUid', isEqualTo: acceptorUid)
            .orderBy('timestamp', descending: true)
            .limit(1)
            .get();

        if (recentNotifications.docs.isNotEmpty) {
          Log.info(
              '✅ [ACCEPTOR] 通知Firestore書き込み確認済み - docId: ${recentNotifications.docs.first.id}');
        } else {
          Log.warning('⚠️ [ACCEPTOR] 通知Firestore書き込み未確認 - リトライが必要かもしれません');
        }
      } catch (verifyError) {
        Log.warning('⚠️ [ACCEPTOR] 通知検証エラー（書き込みは成功した可能性あり）: $verifyError');
      }

      Log.info('✅ 招待受諾処理完了 - 招待元がメンバー追加を実施します');

      return true;
    } catch (e) {
      Log.error('QR招待受諾エラー: $e');
      await ErrorLogService.logOperationError('QR招待受諾', '$e');
      return false;
    }
  }

  /// 招待のセキュリティを検証（Firestoreから取得）
  Future<bool> _validateInvitationSecurity(
      Map<String, dynamic> invitationData, String? providedKey) async {
    final version = invitationData['version'] as String?;
    Log.info('🔍 [SECURITY] バージョン: $version');

    // v3.0（セキュア版）の場合
    if (version == '3.0') {
      final invitationId = invitationData['invitationId'] as String?;
      if (invitationId == null) {
        Log.info('❌ 招待IDが不足');
        return false;
      }
      Log.info('🔍 [SECURITY] invitationId: $invitationId');

      // QRデータ内のセキュリティキーを取得（providedKeyがnullの場合）
      final securityKeyToValidate =
          providedKey ?? invitationData['securityKey'] as String?;
      Log.info(
          '🔍 [SECURITY] セキュリティキー: ${securityKeyToValidate?.substring(0, 10)}...');

      // Firestoreから実際の招待データを取得
      final sharedGroupId = invitationData['sharedGroupId'] as String?;
      if (sharedGroupId == null) {
        Log.info('❌ sharedGroupIdが見つかりません');
        return false;
      }
      Log.info('🔍 [SECURITY] sharedGroupId: $sharedGroupId');

      final invitationPath =
          'SharedGroups/$sharedGroupId/invitations/$invitationId';
      Log.info('🔍 [SECURITY] Firestoreパス: $invitationPath');

      final invitationDoc = await _firestore
          .collection('SharedGroups')
          .doc(sharedGroupId)
          .collection('invitations')
          .doc(invitationId)
          .get();

      if (!invitationDoc.exists) {
        Log.info('❌ 招待が見つかりません: $invitationId (パス: $invitationPath)');
        return false;
      }
      Log.info('✅ [SECURITY] Firestoreドキュメント取得成功');

      final storedData = invitationDoc.data()!;
      final storedSecurityKey = storedData['securityKey'] as String?;
      final status = storedData['status'] as String?;
      final expiresAt = storedData['expiresAt'] as Timestamp?;
      final currentUses = storedData['currentUses'] as int? ?? 0;
      final maxUses = storedData['maxUses'] as int? ?? 5;

      Log.info('🔍 [SECURITY] status: $status');
      Log.info('🔍 [SECURITY] currentUses: $currentUses / maxUses: $maxUses');
      Log.info('🔍 [SECURITY] expiresAt: $expiresAt');

      // ステータスチェック（maxUsesベース）
      if (currentUses >= maxUses) {
        Log.info('❌ 招待の使用回数上限に達しています: $currentUses/$maxUses');
        return false;
      }

      // 有効なステータスかチェック（pending または使用枠が残っている accepted）
      if (status != 'pending' && status != 'accepted') {
        Log.info('❌ 招待は無効です: $status');
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
}
