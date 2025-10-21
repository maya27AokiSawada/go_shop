// lib/services/user_info_service.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import '../utils/app_logger.dart';
import '../models/purchase_group.dart';
import '../models/shopping_list.dart';
import '../providers/auth_provider.dart';
import '../providers/purchase_group_provider.dart';
import '../providers/shopping_list_provider.dart';
import '../providers/user_name_provider.dart';
import '../providers/user_settings_provider.dart';
import '../datastore/user_settings_repository.dart';
import 'user_preferences_service.dart';
import 'group_management_service.dart';

final userInfoServiceProvider = Provider<UserInfoService>((ref) {
  return UserInfoService(ref);
});

/// ユーザー情報の保存・管理を統合するサービス
class UserInfoService {
  final Ref _ref;
  final Logger _logger = Logger();

  UserInfoService(this._ref);

  /// ユーザー情報を保存（デフォルトグループ、ShoppingList、UserSettings）
  /// 
  /// 優先順位でユーザー名を取得:
  /// 1. フォーム入力
  /// 2. SharedPreferences
  /// 3. 認証状態のdisplayName
  Future<UserInfoSaveResult> saveUserInfo({
    String? userNameFromForm,
    String? emailFromForm,
  }) async {
    Log.info('🚀 saveUserInfo() 開始');
    
    // ユーザー名を複数の方法で取得（優先順位付き）
    String userName = '';
    
    // 1. まずフォームから取得
    if (userNameFromForm != null && userNameFromForm.trim().isNotEmpty) {
      userName = userNameFromForm.trim();
      Log.info('🚀 フォームからユーザー名取得: "$userName"');
    }
    
    // 2. フォームが空の場合、SharedPreferencesから取得
    if (userName.isEmpty) {
      final settingsUserName = await UserPreferencesService.getUserName();
      if (settingsUserName != null && settingsUserName.isNotEmpty) {
        userName = settingsUserName;
        Log.info('🚀 SharedPreferencesからユーザー名取得: "$userName"');
      }
    }
    
    // 3. それでも空の場合、認証状態から取得
    if (userName.isEmpty) {
      final authState = _ref.read(authStateProvider);
      await authState.when(
        data: (user) async {
          if (user != null && user.displayName != null && user.displayName!.isNotEmpty) {
            userName = user.displayName!;
            Log.info('🚀 認証状態からユーザー名取得: "$userName"');
          }
        },
        loading: () async {},
        error: (error, stack) async {},
      );
    }
    
    if (userName.isEmpty) {
      Log.warning('⚠️ ユーザー名が取得できませんでした');
      return UserInfoSaveResult(
        success: false,
        message: 'ユーザー名を入力してください',
      );
    }
    
    Log.info('🚀 使用するユーザー名: "$userName"');
    
    try {
      // メールアドレスを取得
      final userEmail = await _getUserEmail(emailFromForm);
      Log.info('🚀 使用するメールアドレス: $userEmail');
      
      // デフォルトグループを更新
      await _updateDefaultGroup(userName, userEmail);
      
      // デフォルトShoppingListを作成（存在しない場合のみ）
      await _ensureDefaultShoppingList();
      
      // 全グループで同じUID/メールアドレスのメンバー名を更新
      final groupService = _ref.read(groupManagementServiceProvider);
      await groupService.updateUserNameInAllGroups(userName, userEmail);
      
      // ユーザー名プロバイダーにも保存
      await _ref.read(userNameNotifierProvider.notifier).setUserName(userName);
      Log.info('✅ ユーザー名プロバイダー保存完了');
      
      // UserSettingsにもユーザー情報を保存
      await _updateUserSettings(userName, userEmail);
      
      Log.info('✅ ユーザー情報保存完了: $userName ($userEmail)');
      
      return UserInfoSaveResult(
        success: true,
        message: 'ユーザー情報を保存しました',
        userName: userName,
        userEmail: userEmail,
      );
      
    } catch (e, stackTrace) {
      Log.error('❌ ユーザー情報保存エラー: $e\n$stackTrace');
      return UserInfoSaveResult(
        success: false,
        message: '保存に失敗しました: $e',
      );
    }
  }

  /// メールアドレスを取得
  Future<String> _getUserEmail(String? emailFromForm) async {
    String userEmail = 'default@example.com'; // デフォルト値
    
    try {
      // 1. 認証状態から確認
      final authState = _ref.read(authStateProvider);
      final currentUser = await authState.when(
        data: (user) async => user,
        loading: () async => null,
        error: (err, stack) async => null,
      );
      
      // 2. 直接authProviderから確認
      final authService = _ref.read(authProvider);
      final directUser = authService.currentUser;
      
      // メールアドレスの取得
      String? actualEmail;
      
      if (currentUser != null && currentUser.email != null) {
        actualEmail = currentUser.email;
        Log.info('🔍 認証ユーザーのメールアドレス: $actualEmail');
      } else if (directUser != null && directUser.email != null) {
        actualEmail = directUser.email;
        Log.info('🔍 直接認証サービスのメールアドレス: $actualEmail');
      }
      
      // メールアドレスの設定
      if (actualEmail != null && actualEmail.isNotEmpty) {
        userEmail = actualEmail;
      } else if (emailFromForm != null && emailFromForm.isNotEmpty) {
        userEmail = emailFromForm;
        Log.info('🔍 フォーム入力のメールアドレスを使用: $userEmail');
      } else {
        Log.info('🔍 メールアドレスが取得できないため、デフォルトを使用: $userEmail');
      }
    } catch (e) {
      Log.warning('⚠️ 認証状態取得エラー、デフォルトメールアドレスを使用: $e');
    }
    
    return userEmail;
  }

  /// デフォルトグループを更新
  Future<void> _updateDefaultGroup(String userName, String userEmail) async {
    const groupId = 'default_group';
    
    // 既存のデフォルトグループを取得
    PurchaseGroup? existingGroup;
    try {
      existingGroup = await _ref.read(selectedGroupProvider).value;
    } catch (e) {
      existingGroup = null;
    }
    
    PurchaseGroup defaultGroup;
    
    if (existingGroup != null) {
      Log.info('📋 既存グループを更新: $userName');
      
      // 新しいサインインユーザーを必ずオーナーにする
      final updatedMembers = <PurchaseGroupMember>[];
      
      // 既存のメンバーから非オーナーのみを保持
      for (var member in (existingGroup.members ?? [])) {
        if (member.role != PurchaseGroupRole.owner) {
          updatedMembers.add(member);
          Log.info('  - 非オーナーメンバーを保持: ${member.name} (${member.role})');
        }
      }
      
      // 新しいオーナーを追加
      updatedMembers.add(PurchaseGroupMember(
        memberId: 'defaultUser',
        name: userName,
        contact: userEmail,
        role: PurchaseGroupRole.owner,
        invitationStatus: InvitationStatus.self,
        isSignedIn: true,
      ));
      Log.info('  - 新しいオーナーを追加: $userName ($userEmail)');
      
      defaultGroup = existingGroup.copyWith(
        members: updatedMembers,
        ownerName: userName,
        ownerEmail: userEmail,
        ownerUid: 'defaultUser',
      );
    } else {
      Log.info('📋 新しいデフォルトグループを作成');
      
      // 新しいデフォルトグループを作成
      defaultGroup = PurchaseGroup(
        groupId: groupId,
        groupName: 'あなたのグループ',
        members: [
          PurchaseGroupMember(
            memberId: 'defaultUser',
            name: userName,
            contact: userEmail,
            role: PurchaseGroupRole.owner,
            invitationStatus: InvitationStatus.self,
            isSignedIn: true,
          )
        ],
      );
    }
    
    // 購入グループを保存
    await _ref.read(selectedGroupNotifierProvider.notifier).updateGroup(defaultGroup);
    Log.info('✅ デフォルトグループ保存完了');
  }

  /// デフォルトShoppingListを確保（存在しない場合のみ作成）
  Future<void> _ensureDefaultShoppingList() async {
    const groupId = 'default_group';
    
    try {
      final existingShoppingList = await _ref.read(shoppingListProvider.future);
      Log.info('📝 既存のShoppingListを発見: ${existingShoppingList.items.length}個のアイテム');
      // 既に存在する場合は何もしない
    } catch (e) {
      Log.info('📝 ShoppingListが存在しないため新規作成');
      
      // 存在しない場合のみ作成
      final defaultShoppingList = ShoppingList.create(
        ownerUid: 'defaultUser',
        groupId: groupId,
        groupName: 'あなたのグループ',
        listName: 'メインリスト',
        items: [
          ShoppingItem.createNow(
            memberId: 'defaultUser',
            name: 'サンプル商品',
            quantity: 1,
          ),
        ],
      );
      
      await _ref.read(shoppingListProvider.notifier).updateShoppingList(defaultShoppingList);
      Log.info('✅ デフォルトShoppingListを作成しました（サンプル商品含む）');
    }
  }

  /// UserSettingsにユーザー情報を保存
  Future<void> _updateUserSettings(String userName, String userEmail) async {
    Log.info('💾 UserSettingsにユーザー情報を保存開始');
    
    try {
      final userSettingsRepository = _ref.read(userSettingsRepositoryProvider);
      await userSettingsRepository.updateUserName(userName);
      await userSettingsRepository.updateUserEmail(userEmail);
      Log.info('✅ UserSettings保存完了: $userName, $userEmail');
    } catch (e) {
      Log.warning('⚠️ UserSettings保存エラー: $e');
    }
  }
}

/// ユーザー情報保存結果
class UserInfoSaveResult {
  final bool success;
  final String message;
  final String? userName;
  final String? userEmail;

  UserInfoSaveResult({
    required this.success,
    required this.message,
    this.userName,
    this.userEmail,
  });
}
