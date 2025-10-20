import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/app_logger.dart';
import '../providers/user_name_provider.dart';
import '../services/user_info_service.dart';
import '../services/user_preferences_service.dart';
import '../helpers/ui_helper.dart';

/// ユーザー名管理の統合サービス
class UserNameManager {
  final WidgetRef ref;
  
  UserNameManager(this.ref);
  
  /// ユーザー名優先順位に従って表示名を決定
  /// 1. 未サインイン + プリファレンス空 → 「あなた」
  /// 2. サインイン + UID同じ → プリファレンス優先、Firebaseに反映  
  /// 3. サインイン + 「あなた」表記 → Firebase優先
  /// 4. UID違い → データ引継ぎ確認
  Future<String> getDisplayName() async {
    final user = FirebaseAuth.instance.currentUser;
    final prefsName = await UserPreferencesService.getUserName();
    
    // 未サインイン状態
    if (user == null) {
      if (prefsName == null || prefsName.isEmpty) {
        Log.info('📝 未サインイン + プリファレンス空 → あなた表記');
        return 'あなた';
      }
      Log.info('📝 未サインイン + プリファレンス有 → $prefsName');
      return prefsName;
    }
    
    // サインイン状態
    Log.info('📝 サインイン中: UID=${user.uid}, Firebase名=${user.displayName}, プリファレンス=$prefsName');
    
    // UIDが同じかチェック（実装は後で）
    final storedUid = await _getStoredUid();
    if (storedUid == user.uid) {
      // UID同じ：プリファレンス優先、Firebaseに反映
      if (prefsName != null && prefsName.isNotEmpty && prefsName != 'あなた') {
        Log.info('📝 UID同じ + プリファレンス有効 → プリファレンス優先: $prefsName');
        await _syncToFirebase(prefsName);
        return prefsName;
      }
    }
    
    // 「あなた」表記の場合はFirebase優先
    if (prefsName == null || prefsName.isEmpty || prefsName == 'あなた') {
      final firebaseName = user.displayName;
      if (firebaseName != null && firebaseName.isNotEmpty) {
        Log.info('📝 あなた表記 → Firebase優先: $firebaseName');
        await ref.read(userNameNotifierProvider.notifier).setUserName(firebaseName);
        return firebaseName;
      }
    }
    
    // UID違いの場合：データ引継ぎ確認（後で実装）
    if (storedUid != null && storedUid != user.uid) {
      Log.info('📝 UID違い → データ引継ぎ確認が必要');
      // TODO: データ引継ぎダイアログ
    }
    
    // デフォルト
    return prefsName ?? 'あなた';
  }
  
  /// ユーザー名保存（プリファレンス + Firebase同期）
  Future<void> saveUserName(BuildContext context, String userName) async {
    if (userName.isEmpty) {
      UiHelper.showWarningMessage(context, 'ユーザー名を入力してください');
      return;
    }

    try {
      Log.info('💾 ユーザー名保存開始: $userName');
      
      // 1. SharedPreferences + Firestoreに保存
      await ref.read(userNameNotifierProvider.notifier).setUserName(userName);
      Log.info('✅ プリファレンス保存完了');
      
      // 2. Firebaseにも反映
      await _syncToFirebase(userName);
      
      // 3. デフォルトグループの情報も更新
      await _updateDefaultGroup(userName);
      
      UiHelper.showSuccessMessage(context, 'ユーザー名「$userName」を保存しました');
    } catch (e) {
      Log.error('❌ ユーザー名保存エラー: $e');
      UiHelper.showErrorMessage(context, 'ユーザー名の保存に失敗しました: $e');
    }
  }
  
  /// Firebase UserProfileに名前を同期
  Future<void> _syncToFirebase(String userName) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await user.updateDisplayName(userName);
        await user.reload();
        Log.info('✅ Firebase displayName更新完了: $userName');
      } catch (e) {
        Log.error('❌ Firebase displayName更新失敗: $e');
      }
    }
  }
  
  /// デフォルトグループ情報更新
  Future<void> _updateDefaultGroup(String userName) async {
    try {
      final userInfoService = ref.read(userInfoServiceProvider);
      await userInfoService.saveUserInfo(
        userNameFromForm: userName,
        emailFromForm: '',
      );
      Log.info('✅ デフォルトグループ更新完了');
    } catch (e) {
      Log.error('❌ デフォルトグループ更新エラー: $e');
    }
  }
  
  /// 保存されたUIDを取得（実装は後で）
  Future<String?> _getStoredUid() async {
    // TODO: SharedPreferencesからUIDを取得
    return null;
  }
}

/// ユーザー名管理プロバイダー（Familyを使用してWidgetRefを受け取る）
final userNameManagerProvider = Provider.family<UserNameManager, WidgetRef>((ref, widgetRef) {
  return UserNameManager(widgetRef);
});