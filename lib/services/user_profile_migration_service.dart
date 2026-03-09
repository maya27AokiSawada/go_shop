import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/app_logger.dart';

/// ユーザープロファイルの移行サービス
/// 旧構造: /users/{uid}/profile/profile or /users/{uid}/profile/userName
/// 新構造: /users/{uid} (displayName, email, createdAt, updatedAt)
class UserProfileMigrationService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  UserProfileMigrationService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  /// 現在のユーザーのプロファイルを移行
  Future<bool> migrateCurrentUserProfile() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        AppLogger.warning('⚠️ [MIGRATION] ユーザーが未ログイン - 移行スキップ');
        return false;
      }

      return await migrateUserProfile(user.uid);
    } catch (e) {
      AppLogger.error('❌ [MIGRATION] 現在のユーザープロファイル移行エラー: $e');
      return false;
    }
  }

  /// 指定されたUIDのユーザープロファイルを移行
  Future<bool> migrateUserProfile(String uid) async {
    try {
      AppLogger.info(
          '🔄 [MIGRATION] プロファイル移行開始: UID=${AppLogger.maskUserId(uid)}');

      final userDocRef = _firestore.collection('users').doc(uid);
      final userDoc = await userDocRef.get();

      // 既に新構造になっている場合はスキップ
      if (userDoc.exists) {
        final data = userDoc.data();
        if (data != null &&
            data.containsKey('displayName') &&
            data.containsKey('email')) {
          AppLogger.info('✅ [MIGRATION] 既に移行済み - スキップ');
          return true;
        }
      }

      // 旧構造からデータを取得
      String? displayName;
      String? email;
      DateTime? createdAt;

      // パターン1: /users/{uid}/profile/profile (displayName使用)
      final profileDoc =
          await userDocRef.collection('profile').doc('profile').get();

      if (profileDoc.exists) {
        final profileData = profileDoc.data();
        displayName = profileData?['displayName'] as String?;
        email = profileData?['email'] as String?;
        createdAt = (profileData?['createdAt'] as Timestamp?)?.toDate();
        AppLogger.info(
            '📦 [MIGRATION] profile/profile から取得: displayName=${AppLogger.maskName(displayName)}');
      }

      // パターン2: /users/{uid}/profile/userName (userName使用)
      if (displayName == null || displayName.isEmpty) {
        final userNameDoc =
            await userDocRef.collection('profile').doc('userName').get();

        if (userNameDoc.exists) {
          final userNameData = userNameDoc.data();
          displayName = userNameData?['userName'] as String?;
          email ??= userNameData?['userEmail'] as String?;
          createdAt ??= (userNameData?['createdAt'] as Timestamp?)?.toDate();
          AppLogger.info(
              '📦 [MIGRATION] profile/userName から取得: userName=${AppLogger.maskName(displayName)}');
        }
      }

      // Firebase Authから補完
      final user = await _getUser(uid);
      email ??= user?.email;
      displayName ??= user?.displayName;

      if (displayName == null || displayName.isEmpty) {
        AppLogger.warning('⚠️ [MIGRATION] displayName取得失敗 - 移行スキップ');
        return false;
      }

      // 新構造で保存
      final newData = <String, dynamic>{
        'displayName': displayName,
        'email': email ?? '',
        'createdAt': createdAt ?? FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await userDocRef.set(newData, SetOptions(merge: true));
      AppLogger.info(
          '✅ [MIGRATION] プロファイル移行完了: ${AppLogger.maskName(displayName)}');

      return true;
    } catch (e) {
      AppLogger.error('❌ [MIGRATION] プロファイル移行エラー (UID=$uid): $e');
      return false;
    }
  }

  /// 全ユーザーのプロファイルを移行（管理者用）
  /// 注意: Firebase Functionsで実行することを推奨
  Future<Map<String, int>> migrateAllUserProfiles() async {
    int successCount = 0;
    int skipCount = 0;
    int failCount = 0;

    try {
      AppLogger.info('🔄 [MIGRATION] 全ユーザープロファイル移行開始');

      // 全ユーザードキュメントを取得
      final usersSnapshot = await _firestore.collection('users').get();

      for (final doc in usersSnapshot.docs) {
        final uid = doc.id;
        final result = await migrateUserProfile(uid);

        if (result) {
          successCount++;
        } else {
          failCount++;
        }

        // レート制限対策（500ms待機）
        await Future.delayed(const Duration(milliseconds: 500));
      }

      AppLogger.info(
          '✅ [MIGRATION] 全ユーザープロファイル移行完了: 成功=$successCount, スキップ=$skipCount, 失敗=$failCount');

      return {
        'success': successCount,
        'skip': skipCount,
        'fail': failCount,
      };
    } catch (e) {
      AppLogger.error('❌ [MIGRATION] 全ユーザープロファイル移行エラー: $e');
      return {
        'success': successCount,
        'skip': skipCount,
        'fail': failCount,
      };
    }
  }

  /// 移行状況をチェック
  Future<Map<String, dynamic>> checkMigrationStatus(String uid) async {
    try {
      final userDocRef = _firestore.collection('users').doc(uid);
      final userDoc = await userDocRef.get();

      final hasNewStructure =
          userDoc.exists && userDoc.data()?.containsKey('displayName') == true;

      final profileDoc =
          await userDocRef.collection('profile').doc('profile').get();
      final userNameDoc =
          await userDocRef.collection('profile').doc('userName').get();

      final hasOldStructure = profileDoc.exists || userNameDoc.exists;

      return {
        'migrated': hasNewStructure,
        'needsMigration': hasOldStructure && !hasNewStructure,
        'hasOldData': hasOldStructure,
        'hasNewData': hasNewStructure,
      };
    } catch (e) {
      AppLogger.error('❌ [MIGRATION] 移行状況チェックエラー: $e');
      return {
        'migrated': false,
        'needsMigration': false,
        'hasOldData': false,
        'hasNewData': false,
        'error': e.toString(),
      };
    }
  }

  /// Firebase AuthからUserオブジェクトを取得（内部用）
  Future<User?> _getUser(String uid) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser?.uid == uid) {
        return currentUser;
      }
      // 他のユーザーのデータは取得不可
      return null;
    } catch (e) {
      return null;
    }
  }
}
