// lib/services/user_initialization_service.dart
import 'package:flutter/widgets.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/app_logger.dart';
import '../models/purchase_group.dart';
import '../providers/purchase_group_provider.dart';
import '../flavors.dart';
import 'ad_service.dart';
import 'data_version_service.dart';

final userInitializationServiceProvider = Provider<UserInitializationService>((ref) {
  return UserInitializationService(ref);
});

class UserInitializationService {
  final Ref _ref;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  UserInitializationService(this._ref);

  /// Firebase Auth状態変化を監視してユーザー初期化を実行
  void startAuthStateListener() {
    // アプリ起動時にデフォルトグループをチェック/作成
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ensureDefaultGroupExists();
    });
    
    _auth.authStateChanges().listen((User? user) {
      if (user != null) {
        // ユーザーがログインした時の初期化処理
        _initializeUserDefaults(user);
      }
    });
  }
  
  /// デフォルトグループの存在を確認し、なければ作成
  /// 
  /// データバージョン管理との連携:
  /// - データクリア後は新規デフォルトグループを自動作成
  /// - Playストア公開時: マイグレーション後の整合性チェック機能追加予定
  Future<void> _ensureDefaultGroupExists() async {
    try {
      // データバージョンチェック（念のため再確認）
      final dataVersionService = DataVersionService();
      final dataCleared = await dataVersionService.checkAndMigrateData();
      
      final allGroupsAsync = _ref.read(allGroupsProvider);
      
      await allGroupsAsync.when(
        data: (allGroups) async {
          if (allGroups.isEmpty || dataCleared) {
            if (dataCleared) {
              Log.info('🔄 データバージョン更新により新規デフォルトグループを作成します');
              Log.info('💡 Playストア公開時: マイグレーション後の整合性チェック機能追加予定');
            } else {
              Log.info('💡 グループが存在しないため、デフォルトグループを作成します');
            }
            await _createGuestDefaultGroup();
          } else {
            Log.info('✅ 既存のグループが見つかりました (${allGroups.length}個)');
          }
        },
        loading: () async {
          Log.info('🔄 グループデータ読み込み中...');
          // ローディング中は何もしない
        },
        error: (error, stack) async {
          Log.warning('⚠️ グループデータ読み込みエラー: $error');
          // エラーが発生した場合もデフォルトグループを作成
          await _createGuestDefaultGroup();
        },
      );
    } catch (e) {
      Log.warning('⚠️ デフォルトグループチェック中にエラー: $e');
      // エラーが発生した場合もデフォルトグループを作成
      await _createGuestDefaultGroup();
    }
  }
  
  /// ゲスト用のデフォルトグループを作成
  Future<void> _createGuestDefaultGroup() async {
    try {
      final repository = _ref.read(purchaseGroupRepositoryProvider);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final defaultGroupId = 'default_guest_$timestamp';
      
      // デフォルトグループのオーナーメンバーを作成
      final ownerMember = PurchaseGroupMember.create(
        memberId: 'user_$timestamp',
        name: 'あなた',
        contact: 'guest@local.app',
        role: PurchaseGroupRole.owner,
        invitationStatus: InvitationStatus.self,
      );

      // デフォルトグループを作成
      const defaultGroupName = 'あなたのグループ';
      await repository.createGroup(
        defaultGroupId,
        defaultGroupName,
        ownerMember,
      );

      Log.info('✅ ゲスト用デフォルトグループを作成しました: $defaultGroupName (ID: $defaultGroupId)');
      
      // プロバイダーを更新
      final allGroupsNotifier = _ref.read(allGroupsProvider.notifier);
      await allGroupsNotifier.refresh();
      
    } catch (e) {
      Log.error('❌ ゲスト用デフォルトグループ作成エラー: $e');
    }
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
      Log.warning('⚠️ ユーザー初期化エラー: $e');
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
        Log.info('✅ デフォルトグループは既に存在します: ${existingGroup.groupName}');
        return;
      } catch (e) {
        // グループが存在しない場合は作成を続行
        Log.info('💡 デフォルトグループが存在しないため、新規作成します');
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

      Log.info('✅ デフォルトグループを作成しました: $defaultGroupName (ID: $defaultGroupId)');
      
    } catch (e) {
      Log.error('❌ デフォルトグループ作成エラー: $e');
    }
  }

  /// 手動でデフォルトグループを作成（テスト用）
  Future<void> createDefaultGroupManually() async {
    final user = _auth.currentUser;
    if (user != null) {
      await _createDefaultGroupIfNeeded(user);
    } else {
      Log.warning('⚠️ ユーザーがログインしていません');
    }
  }
}