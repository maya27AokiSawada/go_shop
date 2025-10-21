// lib/services/user_initialization_service.dart
import 'package:flutter/widgets.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/app_logger.dart';
import '../models/purchase_group.dart';
import '../providers/purchase_group_provider.dart';
import '../providers/user_specific_hive_provider.dart';
import '../datastore/hybrid_purchase_group_repository.dart';
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
    // アプリ起動時にユーザー状態に応じた初期化を実行
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeBasedOnUserState();
    });
    
    _auth.authStateChanges().listen((User? user) {
      if (user != null) {
        // ユーザーがログインした時の初期化処理
        _initializeUserDefaults(user);
      }
    });
  }
  
  /// ユーザー状態に応じた初期化処理
  /// Firebase認証状態とmemberIDの形式に基づいて適切なデータソースを選択
  Future<void> _initializeBasedOnUserState() async {
    try {
      final currentUser = _auth.currentUser;
      final currentUserId = _ref.read(currentUserIdProvider);
      
      // Firebase認証済みかつFirebase形式のmemberIDの場合
      if (currentUser != null && _isFirebaseUserId(currentUser.uid)) {
        Log.info('🔄 [INIT] Firebase認証済みユーザー検出 - Firestoreとの同期を開始');
        await _syncWithFirestore(currentUser);
      } else {
        Log.info('🔄 [INIT] ローカルユーザー検出 - ローカルデータで初期化');
        await _ensureDefaultGroupExists();
      }
    } catch (e) {
      Log.error('❌ [INIT] ユーザー状態初期化エラー: $e');
      // エラーが発生した場合はフォールバック
      await _ensureDefaultGroupExists();
    }
  }
  
  /// Firebase形式のユーザーIDかどうかを判定
  bool _isFirebaseUserId(String userId) {
    // Firebase UIDの特徴: 28文字の英数字
    return RegExp(r'^[a-zA-Z0-9]{20,}$').hasMatch(userId) && userId.length >= 20;
  }
  
  /// Firestoreとの同期処理
  Future<void> _syncWithFirestore(User user) async {
    try {
      Log.info('🔄 [FIRESTORE_SYNC] Firestoreからデータを取得中...');
      
      final repository = _ref.read(purchaseGroupRepositoryProvider);
      
      // HybridRepositoryの場合、Firestoreを優先した同期を実行
      if (repository is HybridPurchaseGroupRepository) {
        // Firestoreからすべてのグループを取得してHiveに同期
        await repository.syncFromFirestore();
        Log.info('✅ [FIRESTORE_SYNC] Firestoreとの同期完了');
      } else {
        // Hybrid以外の場合は通常の初期化
        Log.info('💡 [FIRESTORE_SYNC] Non-Hybridリポジトリ - 通常初期化');
        await _ensureDefaultGroupExists();
      }
      
      // プロバイダーを更新して画面に反映
      _ref.invalidate(allGroupsProvider);
      
    } catch (e) {
      Log.error('❌ [FIRESTORE_SYNC] Firestore同期エラー: $e');
      // Firestore同期に失敗した場合はローカル初期化
      await _ensureDefaultGroupExists();
    }
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
      const defaultGroupId = 'default_group';  // ユーザー配下の固定ID
      
      // 既存のデフォルトグループがあれば削除（データ不整合対応）
      try {
        await repository.deleteGroup(defaultGroupId);
        Log.info('🗑️ [DEFAULT GROUP] 既存のデフォルトグループを削除しました');
      } catch (e) {
        Log.info('💡 [DEFAULT GROUP] 既存のデフォルトグループなし（新規作成）');
      }
      
      // Firebase認証済みユーザーの情報を取得
      final currentUser = FirebaseAuth.instance.currentUser;
      final currentUserId = currentUser?.uid ?? _ref.read(currentUserIdProvider) ?? 'user_$timestamp';
      final userEmail = currentUser?.email ?? 'guest@local.app';
      final displayName = currentUser?.displayName ?? 'あなた';
      
      Log.info('🔄 [DEFAULT GROUP] Firebase User: uid=$currentUserId, email=$userEmail, name=$displayName');
      
      // デフォルトグループのオーナーメンバーを作成
      final ownerMember = PurchaseGroupMember.create(
        memberId: currentUserId,
        name: displayName,
        contact: userEmail,
        role: PurchaseGroupRole.owner,
        invitationStatus: InvitationStatus.self,
      );

      // プライベート専用のデフォルトグループを作成
      const defaultGroupName = 'マイリスト';
      await repository.createGroup(
        defaultGroupId,
        defaultGroupName,
        ownerMember,
      );

      Log.info('✅ プライベート専用デフォルトグループを作成しました: $defaultGroupName (ID: $defaultGroupId)');
      
      // メンバープールも初期化
      try {
        await repository.getOrCreateMemberPool();
        Log.info('✅ メンバープールを初期化しました');
      } catch (e) {
        Log.warning('⚠️ メンバープール初期化エラー: $e');
      }
      
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