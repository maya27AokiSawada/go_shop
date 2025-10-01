// lib/helper/firebase_diagnostics.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logger/logger.dart';

class FirebaseDiagnostics {
  static final logger = Logger();
  
  /// Firebase接続の包括的な診断テスト
  static Future<Map<String, dynamic>> runDiagnostics() async {
    final results = <String, dynamic>{};
    
    try {
      // 1. Firebase Auth状態確認
      final user = FirebaseAuth.instance.currentUser;
      results['auth_status'] = user != null;
      results['user_email'] = user?.email ?? 'No user';
      results['user_uid'] = user?.uid ?? 'No UID';
      
      logger.i('🔐 Auth Status: ${results['auth_status']}');
      logger.i('👤 User: ${results['user_email']}');
      
      // 2. Firestore基本接続テスト
      final startTime = DateTime.now();
      
      try {
        // 簡単な読み取りテスト
        final testRef = FirebaseFirestore.instance.collection('_test');
        await testRef.limit(1).get().timeout(Duration(seconds: 5));
        
        final endTime = DateTime.now();
        final latency = endTime.difference(startTime).inMilliseconds;
        
        results['firestore_connection'] = true;
        results['firestore_latency_ms'] = latency;
        logger.i('✅ Firestore接続成功 (${latency}ms)');
        
      } catch (e) {
        results['firestore_connection'] = false;
        results['firestore_error'] = e.toString();
        logger.e('❌ Firestore接続失敗: $e');
      }
      
      // 3. 書き込みテスト（認証済みユーザーのみ）
      if (user != null) {
        try {
          final testDoc = FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('_diagnostics')
              .doc('test');
              
          await testDoc.set({
            'timestamp': FieldValue.serverTimestamp(),
            'test_data': 'Firebase diagnostics test',
          }).timeout(Duration(seconds: 5));
          
          results['firestore_write'] = true;
          logger.i('✅ Firestore書き込み成功');
          
          // テストデータを削除
          await testDoc.delete();
          
        } catch (e) {
          results['firestore_write'] = false;
          results['firestore_write_error'] = e.toString();
          logger.e('❌ Firestore書き込み失敗: $e');
        }
      }
      
      // 4. ネットワーク状態確認
      results['timestamp'] = DateTime.now().toIso8601String();
      
    } catch (e) {
      results['general_error'] = e.toString();
      logger.e('❌ 診断テスト中にエラー: $e');
    }
    
    return results;
  }
  
  /// Firebase接続問題の解決策を提案
  static List<String> getSolutions(Map<String, dynamic> diagnostics) {
    final solutions = <String>[];
    
    if (diagnostics['auth_status'] != true) {
      solutions.add('❌ Firebase認証が必要です');
    }
    
    if (diagnostics['firestore_connection'] != true) {
      solutions.add('❌ Firestore接続失敗 - ネットワークまたは設定を確認');
      solutions.add('🔧 Firebase Console > Firestore > データベース作成');
      solutions.add('🔧 セキュリティルールの確認');
    }
    
    if (diagnostics['firestore_write'] != true && diagnostics['auth_status'] == true) {
      solutions.add('❌ Firestore書き込み権限なし');
      solutions.add('🔧 Firebase Console > Firestore > ルール設定');
      solutions.add('🔧 認証ユーザーのアクセス許可');
    }
    
    final latency = diagnostics['firestore_latency_ms'] as int?;
    if (latency != null && latency > 3000) {
      solutions.add('⚠️ Firestore接続が遅い (${latency}ms)');
      solutions.add('🔧 ネットワーク環境の確認');
    }
    
    if (solutions.isEmpty) {
      solutions.add('✅ Firebase接続は正常です');
    }
    
    return solutions;
  }
}