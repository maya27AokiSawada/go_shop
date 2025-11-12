// lib/services/access_control_service.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_logger.dart';
import '../flavors.dart';
import '../providers/purchase_group_provider.dart';

/// ユーザーのアクセス権限を管理するサービス
class AccessControlService {
  final Ref _ref;
  static const String _secretModeKey = 'secret_mode';

  // DEV環境ではnull
  FirebaseAuth? get _auth =>
      F.appFlavor == Flavor.prod ? FirebaseAuth.instance : null;

  AccessControlService(this._ref);

  /// 現在のユーザーがグループ作成可能かチェック
  bool canCreateGroup() {
    Log.info('🔄 [ACCESS_CONTROL_SERVICE] canCreateGroup() 開始');

    if (F.appFlavor == Flavor.dev) {
      return true; // 開発環境では制限なし
    }

    final user = _auth?.currentUser;
    if (user != null) {
      Log.info('🔒 グループ作成許可: 認証済みユーザー ${user.email}');
      return true;
    } else {
      Log.info('🔒 グループ作成拒否: 未認証ユーザー');
      return false;
    }
  }

  /// 現在のユーザーがグループ編集可能かチェック
  bool canEditGroup(String groupId) {
    Log.info('🔄 [ACCESS_CONTROL_SERVICE] canEditGroup($groupId) 開始');

    if (F.appFlavor == Flavor.dev) {
      return true; // 開発環境では制限なし
    }

    // デフォルトグループは常に編集可能（ローカルのみ）
    if (groupId == 'default_group') {
      return true;
    }

    final user = _auth?.currentUser;
    if (user != null) {
      Log.info('🔒 グループ編集許可: 認証済みユーザー ${user.email}');
      return true;
    } else {
      Log.info('🔒 グループ編集拒否: 未認証ユーザー（グループ: $groupId）');
      return false;
    }
  }

  /// 現在のユーザーがメンバー招待可能かチェック
  bool canInviteMembers(String groupId) {
    if (F.appFlavor == Flavor.dev) {
      return true; // 開発環境では制限なし
    }

    // デフォルトグループは招待不可（個人用）
    if (groupId == 'default_group') {
      Log.info('🔒 メンバー招待拒否: デフォルトグループは個人用');
      return false;
    }

    final user = _auth?.currentUser;
    if (user != null) {
      Log.info('🔒 メンバー招待許可: 認証済みユーザー ${user.email}');
      return true;
    } else {
      Log.info('🔒 メンバー招待拒否: 未認証ユーザー');
      return false;
    }
  }

  /// グループ表示モード（シークレットモード対応）
  Future<GroupVisibilityMode> getGroupVisibilityMode() async {
    Log.info('🔄 [ACCESS_CONTROL_SERVICE] getGroupVisibilityMode() 開始');

    final user = _auth?.currentUser;
    final isSecretMode = await _isSecretModeEnabled();

    Log.info('🔒 [VISIBILITY] シークレットモード状態: $isSecretMode');
    Log.info(
        '🔒 [VISIBILITY] ユーザーサインイン状態: ${user != null} (${user?.email ?? "未サインイン"})');

    if (isSecretMode) {
      // シークレットモードON: サインイン必須
      if (user != null) {
        Log.info('🔒 [VISIBILITY] 結果: 全グループ表示（シークレットON + サインイン済み）');
        return GroupVisibilityMode.all; // サインイン済み：全グループ表示
      } else {
        Log.info('🔒 [VISIBILITY] 結果: MyListsのみ表示（シークレットON + 未サインイン）');
        return GroupVisibilityMode.defaultOnly; // 未サインイン：隠す（MyListsのみ）
      }
    } else {
      // シークレットモードOFF: サインインなしでも表示
      Log.info('🔒 [VISIBILITY] 結果: 全グループ表示（シークレットOFF）');
      return GroupVisibilityMode.all; // 常に全グループ表示
    }
  }

  /// シークレットモードが有効かチェック
  Future<bool> _isSecretModeEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_secretModeKey) ?? false;
  }

  /// シークレットモードの状態を公開用メソッドで取得
  Future<bool> isSecretModeEnabled() async {
    return await _isSecretModeEnabled();
  }

  /// シークレットモードの現在の状態を同期的に返すプロバイダー用
  Stream<bool> watchSecretMode() async* {
    yield await _isSecretModeEnabled();
    // Note: SharedPreferencesには変更監視機能がないため、
    // 実際の変更は toggleSecretMode() でプロバイダー無効化により伝達される
  }

  /// シークレットモードの切り替え（認証済みユーザーまたは開発環境）
  Future<bool> toggleSecretMode() async {
    final user = _auth?.currentUser;
    Log.info('🔒 [TOGGLE] 現在のユーザー: ${user?.email ?? "未サインイン"}');
    Log.info('🔒 [TOGGLE] 環境: ${F.appFlavor}');

    if (user == null && F.appFlavor != Flavor.dev) {
      Log.warning('🔒 シークレットモード切り替え拒否: 未認証ユーザー');
      return false;
    }

    final prefs = await SharedPreferences.getInstance();
    final currentMode = await _isSecretModeEnabled();
    final newMode = !currentMode;

    Log.info('🔒 [TOGGLE] SharedPreferencesに保存中: $currentMode → $newMode');
    final saveSuccess = await prefs.setBool(_secretModeKey, newMode);
    Log.info('🔒 [TOGGLE] SharedPreferences保存結果: $saveSuccess');

    // 保存後の状態確認
    final verifiedMode = await _isSecretModeEnabled();
    Log.info('🔒 [TOGGLE] 保存後の確認値: $verifiedMode');

    Log.info(
        '🔒 シークレットモード切り替え: $currentMode → $newMode (開発環境=${F.appFlavor == Flavor.dev})');

    // 🔄 AllGroupsProviderを無効化して再フィルタリングを強制
    _ref.invalidate(allGroupsProvider);
    Log.info('🔒 [TOGGLE] allGroupsProviderを無効化して再読み込み強制');

    return newMode;
  }

  /// エラーメッセージを取得
  String getAccessDeniedMessage(AccessType type) {
    switch (type) {
      case AccessType.createGroup:
        return 'グループを作成するにはサインインが必要です';
      case AccessType.editGroup:
        return 'グループを編集するにはサインインが必要です';
      case AccessType.inviteMembers:
        return 'メンバーを招待するにはサインインが必要です';
    }
  }
}

enum GroupVisibilityMode {
  all, // 全グループ表示
  defaultOnly, // デフォルトグループのみ
  readOnly, // 読み取り専用モード
}

enum AccessType {
  createGroup,
  editGroup,
  inviteMembers,
}

// プロバイダー
final accessControlServiceProvider = Provider<AccessControlService>((ref) {
  return AccessControlService(ref);
});

// グループ表示モードをリアクティブに監視するプロバイダー
final groupVisibilityModeProvider =
    FutureProvider<GroupVisibilityMode>((ref) async {
  // allGroupsProviderの変更を監視（シークレットモード切り替え時にinvalidateされる）
  ref.watch(allGroupsProvider);

  // selectedGroupIdProviderの変更も監視（グループ変更時に再評価）
  ref.watch(selectedGroupIdProvider);

  final accessControl = ref.read(accessControlServiceProvider);
  return await accessControl.getGroupVisibilityMode();
});

// Note: secretModeStateProviderは循環依存を避けるため削除
