// lib/providers/user_name_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'dart:html' as html;

// ユーザー名を管理するプロバイダー
class UserNameNotifier extends StateNotifier<String?> {
  UserNameNotifier() : super(null) {
    _loadUserName();
  }

  // Hiveからユーザー名を読み込み（LocalStorageもフォールバック）
  Future<void> _loadUserName() async {
    try {
      print('📥 UserNameNotifier: Hiveからユーザー名を読み込み中...');
      final box = Hive.box('userSettings');
      final savedName = box.get('user_name', defaultValue: null);
      print('📥 UserNameNotifier: Hive読み込み結果: $savedName');
      
      if (savedName != null && savedName.isNotEmpty) {
        state = savedName;
        print('✅ UserNameNotifier: Hiveからユーザー名を復元: $savedName');
        return;
      }
      
      // Hiveに無い場合、LocalStorageからも確認
      print('🔄 UserNameNotifier: LocalStorageからも確認中...');
      final localStorageName = html.window.localStorage['user_name'];
      print('📥 UserNameNotifier: LocalStorage読み込み結果: $localStorageName');
      
      if (localStorageName != null && localStorageName.isNotEmpty) {
        state = localStorageName;
        print('✅ UserNameNotifier: LocalStorageからユーザー名を復元: $localStorageName');
        // Hiveにもバックアップとして保存
        await _saveToHive(localStorageName);
      } else {
        print('⚠️ UserNameNotifier: どちらにも保存されたユーザー名がありません');
      }
    } catch (e) {
      // エラーの場合は何もしない
      print('❌ UserNameNotifier: 読み込みエラー: $e');
    }
  }

  // ユーザー名を設定し、HiveとLocalStorageの両方に保存
  Future<void> setUserName(String userName) async {
    print('📤 UserNameNotifier: ユーザー名を設定: $userName');
    state = userName;
    
    // Hiveに保存
    await _saveToHive(userName);
    
    // LocalStorageにも保存（フォールバック）
    try {
      html.window.localStorage['user_name'] = userName;
      print('✅ UserNameNotifier: LocalStorageに保存完了: $userName');
    } catch (e) {
      print('⚠️ UserNameNotifier: LocalStorage保存エラー: $e');
    }
  }

  // Hiveに保存するプライベートメソッド
  Future<void> _saveToHive(String userName) async {
    try {
      final box = Hive.box('userSettings');
      await box.put('user_name', userName);
      print('✅ UserNameNotifier: Hiveに保存完了: $userName');
    } catch (e) {
      print('❌ UserNameNotifier: Hive保存エラー: $e');
    }
  }

  // ユーザー名をクリアし、HiveとLocalStorageの両方から削除
  Future<void> clearUserName() async {
    print('🗑️ UserNameNotifier: ユーザー名をクリア');
    state = null;
    
    // Hiveから削除
    try {
      final box = Hive.box('userSettings');
      await box.delete('user_name');
      print('✅ UserNameNotifier: Hiveから削除完了');
    } catch (e) {
      print('❌ UserNameNotifier: Hive削除エラー: $e');
    }
    
    // LocalStorageからも削除
    try {
      html.window.localStorage.remove('user_name');
      print('✅ UserNameNotifier: LocalStorageから削除完了');
    } catch (e) {
      print('⚠️ UserNameNotifier: LocalStorage削除エラー: $e');
    }
  }

  // ユーザー名を取得
  String? getUserName() {
    print('📖 UserNameNotifier: 現在のユーザー名: $state');
    return state;
  }

  // 強制的にHiveから再読み込み
  Future<void> reloadFromHive() async {
    print('🔄 UserNameNotifier: Hiveからの強制再読み込み');
    await _loadUserName();
  }
}

// ユーザー名プロバイダー
final userNameProvider = StateNotifierProvider<UserNameNotifier, String?>((ref) {
  return UserNameNotifier();
});