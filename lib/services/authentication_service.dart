// lib/services/authentication_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/app_logger.dart';
import 'user_preferences_service.dart';
import 'firestore_group_sync_service.dart';
import 'firestore_user_name_service.dart';
import 'firestore_migration_service.dart';
import 'data_version_service.dart';
import '../flavors.dart';

/// 認証関連の処理を統合管理するサービス
class AuthenticationService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// メールアドレスとパスワードでサインイン
  static Future<UserCredential?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      Log.info('🔐 サインイン開始: $email');

      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      Log.info('✅ サインイン成功: ${userCredential.user?.uid}');

      // サインイン後の処理
      await _postSignInProcessing(userCredential.user);

      return userCredential;
    } on FirebaseAuthException catch (e) {
      Log.error('❌ サインインエラー: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      Log.error('❌ サインイン予期しないエラー: $e');
      rethrow;
    }
  }

  /// メールアドレスとパスワードでサインアップ
  static Future<UserCredential?> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String userName,
  }) async {
    try {
      Log.info('📝 サインアップ開始: $email');

      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      Log.info('✅ サインアップ成功: ${userCredential.user?.uid}');

      // ユーザー名をSharedPreferencesに保存
      await UserPreferencesService.saveUserName(userName);

      // Firestoreにユーザー名を保存（本番環境のみ）
      if (userCredential.user != null) {
        await FirestoreUserNameService.saveUserName(userName);
      }

      // サインアップ後の処理
      await _postSignInProcessing(userCredential.user);

      return userCredential;
    } on FirebaseAuthException catch (e) {
      Log.error('❌ サインアップエラー: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      Log.error('❌ サインアップ予期しないエラー: $e');
      rethrow;
    }
  }

  /// サインアウト
  static Future<void> signOut() async {
    try {
      Log.info('🚪 サインアウト開始');

      // Firestoreの同期データをクリア
      await FirestoreGroupSyncService.clearSyncDataOnSignOut();

      // Firebaseからサインアウト
      await _auth.signOut();

      Log.info('✅ サインアウト完了');
    } catch (e) {
      Log.error('❌ サインアウトエラー: $e');
      rethrow;
    }
  }

  /// サインイン・サインアップ後の共通処理
  static Future<void> _postSignInProcessing(User? user) async {
    if (user == null) return;

    try {
      Log.info('🔄 サインイン後処理開始: UID=${user.uid}');

      // 注: UIDの保存はAuth listenerでUID変更チェック後に行う
      // ここでは保存しない（タイミング問題を回避）

      // 1. メールアドレスをSharedPreferencesに保存
      if (user.email != null) {
        await UserPreferencesService.saveUserEmail(user.email!);
      }

      // 2. Firestoreデータマイグレーション実行（本番環境のみ）
      // データバージョンをチェックしてマイグレーションが必要か確認
      final dataVersionService = DataVersionService();
      final savedVersion = await dataVersionService.getSavedDataVersion();
      final currentVersion = DataVersionService.currentDataVersion;

      if (savedVersion < currentVersion) {
        Log.info(
            '🔄 [サインイン時] Firestoreマイグレーション実行: v$savedVersion → v$currentVersion');
        try {
          final migrationService = FirestoreDataMigrationService();
          await migrationService.migrateToVersion3();

          // マイグレーション成功後にバージョンを更新
          await dataVersionService.saveDataVersion(currentVersion);
          Log.info('✅ [サインイン時] Firestoreマイグレーション完了');
        } catch (e) {
          Log.error('❌ [サインイン時] Firestoreマイグレーションエラー: $e');
          // マイグレーションエラーでもサインインは継続
        }
      }

      // 3. Firestoreからグループデータを同期（本番環境のみ）
      final groups = await FirestoreGroupSyncService.syncGroupsOnSignIn();
      Log.info('📦 Firestoreから${groups.length}件のグループを同期');

      // 4. Firestoreからユーザー名を復帰（本番環境のみ）
      final firestoreName = await FirestoreUserNameService.getUserName();
      if (firestoreName != null && firestoreName.isNotEmpty) {
        await UserPreferencesService.saveUserName(firestoreName);
        Log.info('👤 Firestoreからユーザー名を復帰: $firestoreName');
      }

      Log.info('✅ サインイン後処理完了');
    } catch (e) {
      Log.error('❌ サインイン後処理エラー: $e');
      // エラーが発生しても認証自体は成功しているので、例外を再スローしない
    }
  }

  /// 現在のユーザーを取得
  static User? get currentUser => _auth.currentUser;

  /// 認証状態のストリーム
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Firebase Auth エラーメッセージを日本語化
  static String getErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'このメールアドレスは登録されていません';
      case 'wrong-password':
        return 'パスワードが正しくありません';
      case 'email-already-in-use':
        return 'このメールアドレスは既に使用されています';
      case 'invalid-email':
        return 'メールアドレスの形式が正しくありません';
      case 'weak-password':
        return 'パスワードは6文字以上で設定してください';
      case 'network-request-failed':
        return 'ネットワークエラーが発生しました';
      case 'too-many-requests':
        return 'リクエストが多すぎます。しばらく待ってから再試行してください';
      default:
        return 'エラーが発生しました: ${e.message}';
    }
  }
}
