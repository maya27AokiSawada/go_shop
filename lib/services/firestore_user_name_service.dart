import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logger/logger.dart';
import '../utils/app_logger.dart';

/// ユーザー名をFirestoreで管理するサービス
/// 
/// コレクション構造:
/// users/{uid}/profile -> { userName: string, updatedAt: timestamp }
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
      
      final docRef = _firestore.collection('users').doc(user.uid).collection('profile').doc('userName');
      final docSnapshot = await docRef.get();
      
      if (docSnapshot.exists) {
        final data = docSnapshot.data() as Map<String, dynamic>;
        final userName = data['userName'] as String?;
        
        Log.info('✅ Firestoreからユーザー名取得成功: $userName');
        return userName;
      } else {
        Log.info('📭 Firestoreにユーザー名データなし');
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
      
      final docRef = _firestore.collection('users').doc(user.uid).collection('profile').doc('userName');
      
      await docRef.set({
        'userName': userName,
        'updatedAt': FieldValue.serverTimestamp(),
        'userEmail': user.email ?? '',
      }, SetOptions(merge: true));
      
      Log.info('✅ Firestoreにユーザー名保存完了: $userName');
      return true;
    } catch (e) {
      Log.error('❌ Firestoreユーザー名保存エラー: $e');
      return false;
    }
  }

  /// ユーザー名を削除
  static Future<bool> deleteUserName() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        Log.warning('❌ 認証されていないユーザー - ユーザー名削除不可');
        return false;
      }

      Log.info('🗑️ Firestoreからユーザー名削除開始: UID=${user.uid}');
      
      final docRef = _firestore.collection('users').doc(user.uid).collection('profile').doc('userName');
      await docRef.delete();
      
      Log.info('✅ Firestoreからユーザー名削除完了');
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
}