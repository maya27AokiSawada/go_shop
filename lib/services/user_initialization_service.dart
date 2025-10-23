// lib/services/user_initialization_service.dart
import 'package:flutter/widgets.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/app_logger.dart';
import '../models/purchase_group.dart';
import '../providers/purchase_group_provider.dart';
import '../providers/user_name_provider.dart';
import '../datastore/hybrid_purchase_group_repository.dart';
import '../flavors.dart';
import 'ad_service.dart';

import 'user_preferences_service.dart';

final userInitializationServiceProvider = Provider<UserInitializationService>((
  ref,
) {
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
  /// 1. AllGroupsProviderに委ねる（デフォルトグループ作成は自動化）
  /// 2. Firebase認証済みの場合はFirestoreと同期
  Future<void> _initializeBasedOnUserState() async {
    try {
      // STEP1: AllGroupsProviderでグループ一覧を取得（デフォルトグループも自動作成される）
      Log.info('🔄 [INIT] グループ一覧を初期化中...');
      await _ref.read(allGroupsProvider.future);

      // STEP2: Firebase認証済みの場合はFirestoreと同期
      final currentUser = _auth.currentUser;
      if (currentUser != null && _isFirebaseUserId(currentUser.uid)) {
        Log.info('🔄 [INIT] Firebase認証済みユーザー検出 - Firestoreとの同期を開始');
        await _syncWithFirestore(currentUser);
      } else {
        Log.info('� [INIT] 未サインインまたはローカルユーザー - ローカルデータで動作');
      }

      // STEP3: プロバイダーを更新
      _ref.invalidate(userNameProvider);
      _ref.invalidate(allGroupsProvider);
      Log.info('✅ [INIT] ユーザー状態初期化完了');
    } catch (e) {
      Log.error('❌ [INIT] ユーザー状態初期化エラー: $e');
      // エラーが発生した場合はAllGroupsProviderに委ねる（自動でデフォルトグループが作成される）
    }
  }

  /// Firebase形式のユーザーIDかどうかを判定
  bool _isFirebaseUserId(String userId) {
    // Firebase UIDの特徴: 28文字の英数字
    return RegExp(r'^[a-zA-Z0-9]{20,}$').hasMatch(userId) &&
        userId.length >= 20;
  }

  /// Firestoreとの同期処理
  /// ローカルデフォルトグループとFirestoreデータをマージ
  Future<void> _syncWithFirestore(User user) async {
    try {
      Log.info('🔄 [FIRESTORE_SYNC] Firestoreからデータを取得中...');

      final repository = _ref.read(purchaseGroupRepositoryProvider);

      // HybridRepositoryの場合、Firestoreとローカルデータをマージ
      if (repository is HybridPurchaseGroupRepository) {
        // STEP1: Firestoreからデータを取得
        await repository.syncFromFirestore();
        Log.info('✅ [FIRESTORE_SYNC] Firestoreデータ取得完了');

        // STEP2: ローカルのデフォルトグループとマージが必要かチェック
        await _mergeLocalDefaultWithFirestore(user, repository);
      } else {
        // Hybrid以外の場合は何もしない（AllGroupsProviderが自動でデフォルトグループを作成する）
        Log.info('💡 [FIRESTORE_SYNC] Non-Hybridリポジトリ - AllGroupsProviderに委ねる');
      }

      // プロバイダーを更新して画面に反映
      _ref.invalidate(allGroupsProvider);
      Log.info('✅ [FIRESTORE_SYNC] 同期とマージ完了');
    } catch (e) {
      Log.error('❌ [FIRESTORE_SYNC] Firestore同期エラー: $e');
      // Firestore同期に失敗してもローカルデータは保持
      Log.info('💡 [FIRESTORE_SYNC] Firestore同期失敗 - ローカルデータで継続');
    }
  }

  /// ローカルデフォルトグループとFirestoreデータをマージ
  Future<void> _mergeLocalDefaultWithFirestore(
    User user,
    HybridPurchaseGroupRepository repository,
  ) async {
    try {
      Log.info('🔄 [MERGE] ローカルとFirestoreデータのマージ開始');

      // 現在の全グループを取得
      final allGroups = await repository.getAllGroups();
      final localDefaultGroup =
          allGroups.where((g) => g.groupId == 'default_group').firstOrNull;

      if (localDefaultGroup == null) {
        Log.info('💡 [MERGE] ローカルデフォルトグループなし - Firestoreデータのみ使用');
        return;
      }

      // Firestoreにユーザーのグループがない場合、ローカルデフォルトをアップロード
      final firestoreGroups =
          allGroups.where((g) => g.groupId != 'default_group').toList();

      if (firestoreGroups.isEmpty) {
        Log.info('🔄 [MERGE] Firestoreにデータなし - ローカルデフォルトを移行開始');
        await _migrateLocalDefaultToFirestore(
            user, localDefaultGroup, repository);
      } else {
        Log.info(
          '💡 [MERGE] Firestoreにデータあり(${firestoreGroups.length}グループ) - 両方を保持',
        );
        // Firestoreデータとローカルデフォルトグループを共存
        // 特に処理は不要（HybridRepositoryが管理）
      }
    } catch (e) {
      Log.warning('⚠️ [MERGE] マージ処理エラー: $e');
    }
  }

  /// サインアップ時: ローカルデフォルトグループをFirestoreに移行
  Future<void> _migrateLocalDefaultToFirestore(
    User user,
    PurchaseGroup localDefaultGroup,
    HybridPurchaseGroupRepository repository,
  ) async {
    try {
      Log.info('🔄 [MIGRATE] ローカルデフォルトグループのFirestore移行開始');

      // STEP1: 新しいFirebase形式のgroupIdを生成
      final newGroupId = 'default_${user.uid}';
      // final timestamp = DateTime.now().millisecondsSinceEpoch;

      // STEP2: オーナーメンバーをFirebase UIDで更新
      final migratedMembers = <PurchaseGroupMember>[];
      for (final member in localDefaultGroup.members ?? []) {
        if (member.role == PurchaseGroupRole.owner) {
          // オーナーのmemberIdをFirebase UIDに変更
          final updatedOwner = member.copyWith(
            memberId: user.uid,
            name: user.displayName ?? member.name,
            contact: user.email ?? member.contact,
            isSignedIn: true,
          );
          migratedMembers.add(updatedOwner);
          Log.info('🔄 [MIGRATE] オーナー更新: ${updatedOwner.name} (${user.uid})');
        } else {
          migratedMembers.add(member);
        }
      }

      // STEP3: 移行後のグループを作成
      final migratedGroup = localDefaultGroup.copyWith(
        groupId: newGroupId,
        groupName: 'My Lists', // 統一した名前
        members: migratedMembers,
        ownerUid: user.uid,
      );

      // STEP4: FirestoreにアップロードしてHiveを更新
      await repository.updateGroup(newGroupId, migratedGroup);
      Log.info('✅ [MIGRATE] グループFirestore移行完了: $newGroupId');

      // STEP5: 関連するShoppingListも移行
      await _migrateShoppingListsToFirebase(
        'default_group', // 古いgroupId
        newGroupId, // 新しいgroupId
        user.uid,
      );

      // STEP6: 古いローカルグループを削除
      try {
        await repository.deleteGroup('default_group');
        Log.info('✅ [MIGRATE] 古いローカルグループ削除完了');
      } catch (e) {
        Log.warning('⚠️ [MIGRATE] 古いグループ削除エラー: $e');
      }

      Log.info('✅ [MIGRATE] ローカルデフォルトグループの完全移行完了');
    } catch (e) {
      Log.error('❌ [MIGRATE] グループ移行エラー: $e');
      rethrow;
    }
  }

  /// ShoppingListをFirebase形式のIDに移行
  Future<void> _migrateShoppingListsToFirebase(
    String oldGroupId,
    String newGroupId,
    String firebaseUid,
  ) async {
    try {
      Log.info(
          '🔄 [MIGRATE_LISTS] ShoppingList移行開始: $oldGroupId → $newGroupId');
      // TODO: 実際のShoppingList移行ロジックを実装
      // 現在は基本的なログ記録のみ
      Log.info('💡 [MIGRATE_LISTS] ShoppingList移行をスキップ（今後実装予定）');
    } catch (e) {
      Log.error('❌ [MIGRATE_LISTS] ShoppingList移行エラー: $e');
      // ShoppingList移行エラーでもグループ移行は続行
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

      // ユーザー名の優先順位に従って決定（Firebase形式のデフォルトグループ用）
      String displayName = user.displayName ?? 'ユーザー';
      try {
        final prefsName = await _ref
            .read(userNameNotifierProvider.notifier)
            .restoreUserNameFromPreferences();
        Log.info(
          '📝 [DEFAULT GROUP] Firebase形式 - プリファレンス名: $prefsName, Firebase名: ${user.displayName}',
        );

        if (prefsName == null || prefsName.isEmpty || prefsName == 'あなた') {
          // Firebase優先
          if (user.displayName != null && user.displayName!.isNotEmpty) {
            displayName = user.displayName!;
            await _ref
                .read(userNameNotifierProvider.notifier)
                .setUserName(displayName);
            Log.info('📝 [DEFAULT GROUP] Firebase優先: $displayName');
          }
        } else {
          // プリファレンス優先
          displayName = prefsName;
          await user.updateDisplayName(displayName);
          await user.reload();
          Log.info('📝 [DEFAULT GROUP] プリファレンス優先: $displayName');
        }

        // UIの更新のためプロバイダーを無効化
        _ref.invalidate(userNameProvider);
      } catch (e) {
        Log.warning('⚠️ [DEFAULT GROUP] Firebase形式ユーザー名決定エラー: ${e.toString()}');
      }

      // メールアドレスをSharedPreferencesに保存
      if (user.email != null && user.email!.isNotEmpty) {
        try {
          await UserPreferencesService.saveUserEmail(user.email!);
          Log.info(
            '📧 [DEFAULT GROUP] Firebase形式 - メールアドレスをSharedPreferencesに保存: ${user.email}',
          );
        } catch (e) {
          Log.warning('⚠️ [DEFAULT GROUP] Firebase形式 - メールアドレス保存エラー: $e');
        }
      }

      // デフォルトグループのオーナーメンバーを作成
      final ownerMember = PurchaseGroupMember.create(
        name: displayName,
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
