// lib/services/user_initialization_service.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/purchase_group.dart';
import '../providers/purchase_group_provider.dart';
import '../flavors.dart';
import 'ad_service.dart';

final userInitializationServiceProvider = Provider<UserInitializationService>((ref) {
  return UserInitializationService(ref);
});

class UserInitializationService {
  final Ref _ref;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  UserInitializationService(this._ref);

  /// Firebase Auth状態変化を監視してユーザー初期化を実行
  void startAuthStateListener() {
    _auth.authStateChanges().listen((User? user) {
      if (user != null) {
        // ユーザーがログインした時の初期化処理
        _initializeUserDefaults(user);
      }
    });
  }

  /// ユーザーのデフォルトデータを初期化
  Future<void> _initializeUserDefaults(User user) async {
    try {
      // 広告サービスの初期化
      final adService = _ref.read(adServiceProvider);
      await adService.initialize();
      
      // サインイン広告の表示
      await adService.showSignInAd();
      
      // Prod環境でのみFirebase連携の初期化を実行
      if (F.appFlavor == Flavor.prod) {
        await _createDefaultGroupIfNeeded(user);
      }
    } catch (e) {
      print('⚠️ ユーザー初期化エラー: $e');
    }
  }

  /// デフォルトグループが存在しない場合に作成
  Future<void> _createDefaultGroupIfNeeded(User user) async {
    try {
      final repository = _ref.read(purchaseGroupRepositoryProvider);
      final defaultGroupId = 'default_${user.uid}';
      
      // 既存のデフォルトグループをチェック
      try {
        final existingGroup = await repository.getGroupById(defaultGroupId);
        print('✅ デフォルトグループは既に存在します: ${existingGroup.groupName}');
        return;
      } catch (e) {
        // グループが存在しない場合は作成を続行
        print('💡 デフォルトグループが存在しないため、新規作成します');
      }

      // デフォルトグループのオーナーメンバーを作成
      final ownerMember = PurchaseGroupMember.create(
        name: user.displayName ?? user.email ?? 'ユーザー',
        contact: user.email ?? '',
        role: PurchaseGroupRole.owner,
        isSignedIn: true,
        isInvited: false,
        isInvitationAccepted: false,
      );

      // デフォルトグループを作成
      final defaultGroupName = '${user.displayName ?? 'マイ'}グループ';
      await repository.createGroup(
        defaultGroupId,
        defaultGroupName,
        ownerMember,
      );

      print('✅ デフォルトグループを作成しました: $defaultGroupName (ID: $defaultGroupId)');
      
    } catch (e) {
      print('❌ デフォルトグループ作成エラー: $e');
    }
  }

  /// 手動でデフォルトグループを作成（テスト用）
  Future<void> createDefaultGroupManually() async {
    final user = _auth.currentUser;
    if (user != null) {
      await _createDefaultGroupIfNeeded(user);
    } else {
      print('⚠️ ユーザーがログインしていません');
    }
  }
}