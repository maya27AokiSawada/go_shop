import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/app_logger.dart';

/// ユーザー名をFirestoreで管理するサービス
///
/// コレクション構造:
/// users/{uid}/profile/userName -> { userName: string, userEmail: string, createdAt: timestamp, updatedAt: timestamp }
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

      Log.info('🔍 Firestoreからユーザー名取得開始: UID=${user.uid}');

      final docRef = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('profile')
          .doc('userName');
      final docSnapshot = await docRef.get();

      if (docSnapshot.exists) {
        final data = docSnapshot.data() as Map<String, dynamic>;
        final userName = data['userName'] as String?;

        Log.info('✅ Firestoreからユーザー名取得成功: $userName');
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
  static Future<bool> saveUserName(String userName) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        Log.warning('❌ 認証されていないユーザー - ユーザー名保存不可');
        return false;
      }

      Log.info('💾 Firestoreにユーザー名保存開始: UID=${user.uid}, 名前=$userName');

      final docRef = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('profile')
          .doc('userName');

      await docRef.set({
        'userName': userName,
        'userEmail': user.email ?? '',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      Log.info('✅ Firestoreにユーザー名保存完了: $userName');
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

      final docRef = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('profile')
          .doc('userName');
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
        .collection('profile')
        .doc('userName')
        .snapshots()
        .map((snapshot) {
      if (snapshot.exists) {
        final data = snapshot.data() as Map<String, dynamic>;
        final userName = data['userName'] as String?;
        Log.info('🔄 Firestoreユーザー名リアルタイム更新: $userName');
        return userName;
      } else {
        return null;
      }
    });
  }

  /// ユーザープロファイルを作成または更新（サインイン時に呼び出す）
  /// Firestoreにユーザードキュメントが存在しない場合に自動作成
  static Future<void> ensureUserProfileExists({String? userName}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        Log.warning('❌ 認証されていないユーザー - プロファイル作成不可');
        return;
      }

      Log.info('🔍 [PROFILE] ユーザープロファイル確認開始: UID=${user.uid}');

      final docRef = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('profile')
          .doc('userName');

      Log.info('📍 [PROFILE] ドキュメントパス: users/${user.uid}/profile/userName');

      final docSnapshot = await docRef.get();
      Log.info('🔍 [PROFILE] ドキュメント存在チェック: exists=${docSnapshot.exists}');

      if (!docSnapshot.exists) {
        // プロファイルが存在しない場合は作成
        final defaultUserName = userName ??
            user.displayName ??
            user.email?.split('@').first ??
            'ユーザー';

        Log.info('📝 [PROFILE] ドキュメント作成開始: $defaultUserName');

        await docRef.set({
          'userName': defaultUserName,
          'userEmail': user.email ?? '',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        Log.info(
            '✅ [PROFILE] Firestoreにユーザードキュメント作成完了: $defaultUserName (UID: ${user.uid})');
      } else {
        final existingData = docSnapshot.data();
        Log.info(
            '💡 [PROFILE] ユーザードキュメントは既に存在します (UID: ${user.uid}), データ: $existingData');
      }
    } catch (e) {
      Log.error('❌ [PROFILE] ユーザープロファイル作成エラー: $e');
    }
  }
}
