import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/app_logger.dart';

/// ユーザー名をFirestoreで管理するサービス
///
/// コレクション構造:
/// users/{uid} -> { displayName: string, email: string, createdAt: timestamp, updatedAt: timestamp }
class FirestoreUserNameService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// 現在のユーザーのユーザー名を取得
  static Future<String?> getUserName() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        Log.warning('❌ 認証されていないユーザー - ユーザー名取得不可');
        return null;
      }

      Log.info(
          '🔍 Firestoreからユーザー名取得開始: UID=${AppLogger.maskUserId(user.uid)}');

      final docRef = _firestore.collection('users').doc(user.uid);
      final docSnapshot = await docRef.get();

      if (docSnapshot.exists) {
        final data = docSnapshot.data() as Map<String, dynamic>;
        final userName = data['displayName'] as String?;

        Log.info('✅ Firestoreからユーザー名取得成功: ${AppLogger.maskName(userName)}');
        return userName;
      } else {
        Log.info('📭 Firestoreにユーザードキュメントなし');
        return null;
      }
    } catch (e) {
      Log.error('❌ Firestoreユーザー名取得エラー: $e');
      return null;
    }
  }

  /// 現在のユーザーのユーザー名を保存
  /// - ドキュメントが存在しない場合は自動作成（SetOptions(merge: true)使用）
  /// - emailはFirebase Authの値と比較して更新
  static Future<bool> saveUserName(String userName) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        Log.warning('❌ 認証されていないユーザー - ユーザー名保存不可');
        return false;
      }

      Log.info(
          '💾 Firestoreにユーザー名保存開始: UID=${AppLogger.maskUserId(user.uid)}, 名前=${AppLogger.maskName(userName)}');

      final docRef = _firestore.collection('users').doc(user.uid);

      // 既存のドキュメントを取得してemailを確認
      final docSnapshot = await docRef.get();
      final currentEmail = user.email ?? '';

      final Map<String, dynamic> dataToSave = {
        'displayName': userName,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (docSnapshot.exists) {
        // ドキュメントが存在する場合、emailが異なるなら更新
        final existingData = docSnapshot.data() as Map<String, dynamic>;
        final storedEmail = existingData['email'] as String? ?? '';

        if (storedEmail != currentEmail) {
          Log.info(
              '📧 [PROFILE] emailが異なります: 保存済み=$storedEmail, Auth=$currentEmail');
          dataToSave['email'] = currentEmail;
          Log.info('✅ [PROFILE] emailを更新: $currentEmail');
        } else {
          Log.info('✅ [PROFILE] emailは既に同期済み');
        }
      } else {
        // ドキュメントが存在しない場合は新規作成（createdAtも追加）
        Log.info('🆕 [PROFILE] 新規ドキュメント作成: ${AppLogger.maskName(userName)}');
        dataToSave['email'] = currentEmail;
        dataToSave['createdAt'] = FieldValue.serverTimestamp();
      }

      // SetOptions(merge: true)でドキュメントを作成または更新
      Log.info('📝 [FIRESTORE WRITE] set()実行前 - データ: $dataToSave');
      Log.info(
          '📝 [FIRESTORE WRITE] パス: users/${AppLogger.maskUserId(user.uid)}');

      // Windows版Firestoreのスレッド問題を回避するため、メインスレッドで実行
      await Future.microtask(() async {
        await docRef.set(dataToSave, SetOptions(merge: true));
      });

      Log.info('✅ [FIRESTORE WRITE] set()実行完了');
      Log.info('✅ Firestoreにユーザー名保存完了: ${AppLogger.maskName(userName)}');
      return true;
    } catch (e) {
      Log.error('❌ Firestoreユーザー名保存エラー: $e');
      return false;
    }
  }

  /// ユーザー名を削除（ユーザードキュメント全体を削除）
  static Future<bool> deleteUserName() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        Log.warning('❌ 認証されていないユーザー - ユーザー名削除不可');
        return false;
      }

      Log.info('🗑️ Firestoreからユーザー名削除開始: UID=${user.uid}');

      final docRef = _firestore.collection('users').doc(user.uid);
      await docRef.delete();

      Log.info('✅ Firestoreからユーザードキュメント削除完了');
      return true;
    } catch (e) {
      Log.error('❌ Firestoreユーザー名削除エラー: $e');
      return false;
    }
  }

  /// ユーザー名のリアルタイム監視
  static Stream<String?> watchUserName() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value(null);
    }

    return _firestore
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .map((snapshot) {
      if (snapshot.exists) {
        final data = snapshot.data() as Map<String, dynamic>;
        final userName = data['displayName'] as String?;
        Log.info('🔄 Firestoreユーザー名リアルタイム更新: $userName');
        return userName;
      } else {
        return null;
      }
    });
  }

  /// ユーザープロファイルを作成または更新（サインイン時に呼び出す）
  /// Firestoreにユーザードキュメントが存在しない場合に自動作成
  /// - emailはFirebase Authの値と比較して更新
  static Future<void> ensureUserProfileExists({String? userName}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        Log.warning('❌ 認証されていないユーザー - プロファイル作成不可');
        return;
      }

      Log.info(
          '🔍 [PROFILE] ユーザープロファイル確認開始: UID=${AppLogger.maskUserId(user.uid)}');

      final docRef = _firestore.collection('users').doc(user.uid);

      Log.info(
          '📍 [PROFILE] ドキュメントパス: users/${AppLogger.maskUserId(user.uid)}');

      final docSnapshot = await docRef.get();
      Log.info('🔍 [PROFILE] ドキュメント存在チェック: exists=${docSnapshot.exists}');

      final currentEmail = user.email ?? '';

      // 🔍 デバッグ: パラメータ確認
      Log.info(
          '🔍 [PROFILE DEBUG] userNameパラメータ: ${userName != null ? AppLogger.maskName(userName) : "null"} (isEmpty: ${userName?.isEmpty})');

      // userNameパラメータが指定されている場合は、必ず使用する（新規作成時も既存更新時も）
      if (userName != null && userName.trim().isNotEmpty) {
        Log.info(
            '📝 [PROFILE] 指定されたユーザー名で作成/更新: ${AppLogger.maskName(userName)}');

        final dataToSave = {
          'displayName': userName.trim(), // ✅ trim()を追加
          'email': currentEmail,
          'updatedAt': FieldValue.serverTimestamp(),
        };

        if (!docSnapshot.exists) {
          // 新規作成時はcreatedAtも追加
          dataToSave['createdAt'] = FieldValue.serverTimestamp();
          Log.info('📝 [FIRESTORE WRITE] set()実行前（新規作成） - データ: $dataToSave');
        } else {
          Log.info('📝 [FIRESTORE WRITE] set()実行前（既存更新） - データ: $dataToSave');
        }

        // Windows版Firestoreのスレッド問題を回避するため、メインスレッドで実行
        await Future.microtask(() async {
          await docRef.set(dataToSave, SetOptions(merge: true));
        });

        Log.info('✅ [FIRESTORE WRITE] set()実行完了');
        Log.info(
            '✅ [PROFILE] ユーザー名を作成/更新: ${AppLogger.maskName(userName)} (UID: ${AppLogger.maskUserId(user.uid)})');
        return;
      }

      // ⚠️ userNameパラメータがnullまたは空の場合のみ、既存データまたはデフォルト値を使用
      Log.warning('⚠️ [PROFILE] userNameパラメータが無効です。デフォルト値を使用します。');

      if (!docSnapshot.exists) {
        // プロファイルが存在しない場合は作成
        final defaultUserName =
            user.displayName ?? user.email?.split('@').first ?? 'ユーザー';

        Log.warning(
            '⚠️ [PROFILE] デフォルト値でドキュメント作成: ${AppLogger.maskName(defaultUserName)} (理由: userNameパラメータが空)');
        Log.info(
            '📝 [PROFILE] ドキュメント作成開始（デフォルト値使用）: ${AppLogger.maskName(defaultUserName)}');

        final createData = {
          'displayName': defaultUserName,
          'email': currentEmail,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        };
        Log.info('📝 [FIRESTORE WRITE] set()実行前 - データ: $createData');

        // Windows版Firestoreのスレッド問題を回避するため、メインスレッドで実行
        await Future.microtask(() async {
          await docRef.set(createData);
        });

        Log.info('✅ [FIRESTORE WRITE] set()実行完了');
        Log.info(
            '✅ [PROFILE] Firestoreにユーザードキュメント作成完了: ${AppLogger.maskName(defaultUserName)} (UID: ${AppLogger.maskUserId(user.uid)})');
      } else {
        // プロファイルが存在する場合、emailが異なるなら更新
        final existingData = docSnapshot.data() as Map<String, dynamic>;
        final storedEmail = existingData['email'] as String? ?? '';

        if (storedEmail != currentEmail) {
          Log.info(
              '📧 [PROFILE] emailが異なります: 保存済み=$storedEmail, Auth=$currentEmail');

          final updateData = {
            'email': currentEmail,
            'updatedAt': FieldValue.serverTimestamp(),
          };
          Log.info('📝 [FIRESTORE WRITE] update()実行前 - データ: $updateData');

          // Windows版Firestoreのスレッド問題を回避するため、メインスレッドで実行
          await Future.microtask(() async {
            await docRef.update(updateData);
          });

          Log.info('✅ [FIRESTORE WRITE] update()実行完了');
          Log.info('✅ [PROFILE] emailを更新: $currentEmail');
        } else {
          final existingUserName = existingData['displayName'] as String? ?? '';
          Log.info(
              '💡 [PROFILE] ユーザードキュメントは既に存在します (UID: ${AppLogger.maskUserId(user.uid)}), ユーザー名: ${AppLogger.maskName(existingUserName)}, email: $storedEmail');
        }
      }
    } catch (e) {
      Log.error('❌ [PROFILE] ユーザープロファイル作成エラー: $e');
    }
  }
}
