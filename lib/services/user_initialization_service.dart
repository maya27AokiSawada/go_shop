// lib/services/user_initialization_service.dart
import 'package:flutter/widgets.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/app_logger.dart';
import '../models/purchase_group.dart';
import '../providers/purchase_group_provider.dart';
import '../providers/user_specific_hive_provider.dart';
import '../providers/user_name_provider.dart';
import '../datastore/hybrid_purchase_group_repository.dart';
import '../flavors.dart';
import 'ad_service.dart';
import 'data_version_service.dart';
import 'user_preferences_service.dart';

final userInitializationServiceProvider =
    Provider<UserInitializationService>((ref) {
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
  /// 1. 常にローカルデフォルトグループを確保
  /// 2. Firebase認証済みの場合はFirestoreと同期
  Future<void> _initializeBasedOnUserState() async {
    try {
      // STEP1: まずローカルデフォルトグループを確保（未サインインでも必要）
      Log.info('🔄 [INIT] ローカルデフォルトグループを確保中...');
      await _ensureLocalDefaultGroupExists();

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
      // エラーが発生した場合も最低限のデフォルトグループは確保
      try {
        await _ensureLocalDefaultGroupExists();
      } catch (fallbackError) {
        Log.error('❌ [INIT] フォールバック処理もエラー: $fallbackError');
      }
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
        // Hybrid以外の場合は通常の初期化
        Log.info('💡 [FIRESTORE_SYNC] Non-Hybridリポジトリ - デフォルトグループのみ確保');
        await _ensureDefaultGroupExists();
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
      User user, HybridPurchaseGroupRepository repository) async {
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
        Log.info('🔄 [MERGE] Firestoreにデータなし - ローカルデフォルトをアップロード');
        // TODO: 必要に応じてローカルデフォルトをFirestoreにアップロード
        // 現在はローカルデータをそのまま保持
      } else {
        Log.info(
            '💡 [MERGE] Firestoreにデータあり(${firestoreGroups.length}グループ) - 両方を保持');
        // Firestoreデータとローカルデフォルトグループを共存
        // 特に処理は不要（HybridRepositoryが管理）
      }
    } catch (e) {
      Log.warning('⚠️ [MERGE] マージ処理エラー: $e');
    }
  }

  /// ローカルデフォルトグループの存在を確保（常時実行）
  /// 未サインインでも、初回起動でも必ず仮のデフォルトグループを作成
  Future<void> _ensureLocalDefaultGroupExists() async {
    try {
      Log.info('🔄 [LOCAL_DEFAULT] ローカルデフォルトグループ確認開始');
      final repository = _ref.read(purchaseGroupRepositoryProvider);

      // Hiveから直接グループを取得（Firestoreは見ない）
      List<PurchaseGroup> localGroups = [];
      try {
        if (repository is HybridPurchaseGroupRepository) {
          // Hiveのみからグループを取得
          localGroups = await repository.getLocalGroups();
        } else {
          localGroups = await repository.getAllGroups();
        }
      } catch (e) {
        Log.warning('⚠️ [LOCAL_DEFAULT] ローカルグループ取得エラー: $e');
        localGroups = []; // 空リストで続行
      }

      Log.info('💡 [LOCAL_DEFAULT] 現在のローカルグループ数: ${localGroups.length}');

      // ローカルにデフォルトグループがない場合は作成
      final hasDefaultGroup =
          localGroups.any((g) => g.groupId == 'default_group');

      if (!hasDefaultGroup) {
        Log.info('🔄 [LOCAL_DEFAULT] デフォルトグループが存在しないため作成します');
        await _createLocalDefaultGroup();
      } else {
        Log.info('✅ [LOCAL_DEFAULT] デフォルトグループは既に存在します');
      }
    } catch (e) {
      Log.error('❌ [LOCAL_DEFAULT] ローカルデフォルトグループ確認エラー: $e');
      // エラーでも作成を試行
      try {
        await _createLocalDefaultGroup();
      } catch (createError) {
        Log.error('❌ [LOCAL_DEFAULT] デフォルトグループ作成もエラー: $createError');
      }
    }
  }

  /// 従来のデフォルトグループ確認メソッド（既存コード互換用）
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

  /// ローカル専用のデフォルトグループを作成（未サインイン対応）
  Future<void> _createLocalDefaultGroup() async {
    try {
      final repository = _ref.read(purchaseGroupRepositoryProvider);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      const defaultGroupId = 'default_group';

      Log.info('🔄 [LOCAL_DEFAULT] ローカルデフォルトグループを作成開始');

      // 現在のユーザー情報を取得（サインイン済みでも未サインインでも対応）
      final currentUser = FirebaseAuth.instance.currentUser;
      final currentUserId = currentUser?.uid ?? 'local_user_$timestamp';
      final userEmail = currentUser?.email ?? 'guest@local.app';

      // ユーザー名の決定
      String displayName = 'あなた';
      if (currentUser != null) {
        // サインイン済みの場合はFirebase情報を優先
        displayName = currentUser.displayName ??
            currentUser.email?.split('@')[0] ??
            'あなた';
      } else {
        // 未サインインの場合はプリファレンスから取得を試行
        try {
          final prefsName = await UserPreferencesService.getUserName();
          if (prefsName != null && prefsName.isNotEmpty && prefsName != 'あなた') {
            displayName = prefsName;
          }
        } catch (e) {
          Log.info('💡 [LOCAL_DEFAULT] プリファレンス名取得失敗、デフォルト名使用');
        }
      }

      Log.info(
          '🔄 [LOCAL_DEFAULT] ユーザー情報: uid=$currentUserId, name=$displayName');

      // デフォルトグループのオーナーメンバーを作成
      final ownerMember = PurchaseGroupMember.create(
        memberId: currentUserId,
        name: displayName,
        contact: userEmail,
        role: PurchaseGroupRole.owner,
        invitationStatus: InvitationStatus.self,
      );

      // プライベート専用のデフォルトグループを作成
      // 自分のみがメンバーの個人用リスト集
      const defaultGroupName = 'My Lists';
      await repository.createGroup(
        defaultGroupId,
        defaultGroupName,
        ownerMember,
      );

      Log.info(
          '✅ [LOCAL_DEFAULT] プライベート専用デフォルトグループ作成完了: $defaultGroupName (メンバー: ${ownerMember.name}のみ)');

      // プロバイダーを確実に更新
      _ref.invalidate(allGroupsProvider);
    } catch (e) {
      Log.error('❌ [LOCAL_DEFAULT] ローカルデフォルトグループ作成エラー: $e');
      rethrow;
    }
  }

  /// ゲスト用のデフォルトグループを作成（従来メソッド）
  Future<void> _createGuestDefaultGroup() async {
    try {
      final repository = _ref.read(purchaseGroupRepositoryProvider);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      const defaultGroupId = 'default_group'; // ユーザー配下の固定ID

      // 既存のデフォルトグループがあれば削除（データ不整合対応）
      try {
        await repository.deleteGroup(defaultGroupId);
        Log.info('🗑️ [DEFAULT GROUP] 既存のデフォルトグループを削除しました');
      } catch (e) {
        Log.info('💡 [DEFAULT GROUP] 既存のデフォルトグループなし（新規作成）');
      }

      // Firebase認証済みユーザーの情報を取得
      final currentUser = FirebaseAuth.instance.currentUser;
      final currentUserId = currentUser?.uid ??
          _ref.read(currentUserIdProvider) ??
          'user_$timestamp';
      final userEmail = currentUser?.email ?? 'guest@local.app';

      // ユーザー名の優先順位に従って決定
      String displayName = 'あなた';
      if (currentUser != null) {
        try {
          // プリファレンスからユーザー名を取得
          final prefsName = await _ref
              .read(userNameNotifierProvider.notifier)
              .restoreUserNameFromPreferences();
          Log.info(
              '📝 [DEFAULT GROUP] プリファレンス名: $prefsName, Firebase名: ${currentUser.displayName}');

          // プリファレンスが「あなた」または空の場合はFirebase優先
          if (prefsName == null || prefsName.isEmpty || prefsName == 'あなた') {
            if (currentUser.displayName != null &&
                currentUser.displayName!.isNotEmpty) {
              displayName = currentUser.displayName!;
              // プリファレンスにも保存
              await _ref
                  .read(userNameNotifierProvider.notifier)
                  .setUserName(displayName);
              Log.info('📝 [DEFAULT GROUP] Firebase優先で設定: $displayName');
            }
          } else {
            // プリファレンス優先、Firebaseに反映
            displayName = prefsName;
            await currentUser.updateDisplayName(displayName);
            await currentUser.reload();
            Log.info('📝 [DEFAULT GROUP] プリファレンス優先で設定: $displayName');
          }

          // UIの更新のためプロバイダーを無効化
          _ref.invalidate(userNameProvider);
        } catch (e) {
          Log.warning('⚠️ [DEFAULT GROUP] ユーザー名決定エラー、フォールバック: ${e.toString()}');
          displayName = currentUser.displayName ?? 'あなた';
        }
      }

      Log.info(
          '🔄 [DEFAULT GROUP] Firebase User: uid=$currentUserId, email=$userEmail, name=$displayName');

      // メールアドレスをSharedPreferencesに保存
      if (userEmail != 'guest@local.app' && userEmail.isNotEmpty) {
        try {
          await UserPreferencesService.saveUserEmail(userEmail);
          Log.info(
              '📧 [DEFAULT GROUP] メールアドレスをSharedPreferencesに保存: $userEmail');
        } catch (e) {
          Log.warning('⚠️ [DEFAULT GROUP] メールアドレス保存エラー: $e');
        }
      }

      // デフォルトグループのオーナーメンバーを作成
      final ownerMember = PurchaseGroupMember.create(
        memberId: currentUserId,
        name: displayName,
        contact: userEmail,
        role: PurchaseGroupRole.owner,
        invitationStatus: InvitationStatus.self,
      );

      // プライベート専用のデフォルトグループを作成（自分のみがメンバー）
      const defaultGroupName = 'My Lists';
      await repository.createGroup(
        defaultGroupId,
        defaultGroupName,
        ownerMember,
      );

      Log.info(
          '✅ プライベート専用デフォルトグループを作成しました: $defaultGroupName (ID: $defaultGroupId, メンバー: ${ownerMember.name}のみ)');

      // メンバープールも初期化
      try {
        await repository.getOrCreateMemberPool();
        Log.info('✅ メンバープールを初期化しました');
      } catch (e) {
        Log.warning('⚠️ メンバープール初期化エラー: $e');
      }

      // プロバイダーを確実に更新
      _ref.invalidate(allGroupsProvider);
      final allGroupsNotifier = _ref.read(allGroupsProvider.notifier);
      await allGroupsNotifier.refresh();

      // 少し待ってから再度確認（UI更新のため）
      await Future.delayed(const Duration(milliseconds: 200));
      final updatedGroups = await _ref.read(allGroupsProvider.future);
      Log.info('✅ [DEFAULT GROUP] プロバイダー更新完了: ${updatedGroups.length}グループ');
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

      // ユーザー名の優先順位に従って決定（Firebase形式のデフォルトグループ用）
      String displayName = user.displayName ?? 'ユーザー';
      try {
        final prefsName = await _ref
            .read(userNameNotifierProvider.notifier)
            .restoreUserNameFromPreferences();
        Log.info(
            '📝 [DEFAULT GROUP] Firebase形式 - プリファレンス名: $prefsName, Firebase名: ${user.displayName}');

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
              '📧 [DEFAULT GROUP] Firebase形式 - メールアドレスをSharedPreferencesに保存: ${user.email}');
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
