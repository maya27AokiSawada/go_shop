// lib/services/user_initialization_service.dart
import 'package:flutter/widgets.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/app_logger.dart';
import '../models/purchase_group.dart';
import '../providers/purchase_group_provider.dart';

import '../datastore/hive_purchase_group_repository.dart' as hive_repo;

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
      // STEP1: AllGroupsProviderでグループ一覧を取得
      Log.info('🔄 [INIT] グループ一覧を初期化中...');
      final groups = await _ref.read(allGroupsProvider.future);

      // STEP2: デフォルトグループが存在しない場合は作成（シンプル版）
      final defaultGroup =
          groups.where((g) => g.groupId == 'default_group').firstOrNull;
      if (defaultGroup == null) {
        Log.info('🔄 [INIT] デフォルトグループが見つかりません。ローカルで作成します...');
        final currentUser = _auth.currentUser;
        if (currentUser != null) {
          await _createDefaultGroupLocally(currentUser);
        } else {
          Log.warning('⚠️ [INIT] ユーザーがログインしていません - デフォルトグループ作成をスキップ');
        }
      }

      // STEP3: Firestore同期を一時的に無効化（デバッグ用）
      Log.info('🔧 [INIT] Firestore同期は一時的に無効化されています（デバッグ用）');
      // final currentUser = _auth.currentUser;
      // if (currentUser != null && _isFirebaseUserId(currentUser.uid)) {
      //   Log.info('🔄 [INIT] Firebase認証済みユーザー検出 - Firestoreとの同期を開始');
      //   await _syncWithFirestore(currentUser);
      // } else {
      //   Log.info('💡 [INIT] 未サインインまたはローカルユーザー - ローカルデータで動作');
      // }

      // STEP4: プロバイダーを更新（userNameProviderはホーム画面表示時まで遅延）
      _ref.invalidate(allGroupsProvider);
      Log.info('✅ [INIT] ユーザー状態初期化完了');
    } catch (e) {
      Log.error('❌ [INIT] ユーザー状態初期化エラー: $e');
      // エラーが発生した場合はAllGroupsProviderに委ねる（自動でデフォルトグループが作成される）
    }
  }

  /// ユーザーのデフォルトデータを初期化
  Future<void> _initializeUserDefaults(User user) async {
    try {
      // 広告サービス無効化（AdMob未設定のため）
      Log.info('💡 広告サービスは無効化されています');

      // デフォルトグループをローカル（Hive）のみで作成
      await _createDefaultGroupLocally(user);

      Log.info('✅ ユーザーデフォルト初期化完了');
    } catch (e) {
      Log.warning('⚠️ ユーザー初期化エラー: $e');
    }
  }

  /// デフォルトグループをローカル（Hive）のみで作成
  Future<void> _createDefaultGroupLocally(User user) async {
    try {
      // Hiveリポジトリを直接使用（Firestoreにはアクセスしない）
      final hiveRepository =
          _ref.read(hive_repo.hivePurchaseGroupRepositoryProvider);
      final defaultGroupId = 'default_group'; // シンプルなID

      // 既存のデフォルトグループをチェック（ローカルのみ）
      try {
        final existingGroup = await hiveRepository.getGroupById(defaultGroupId);
        Log.info('✅ ローカルデフォルトグループは既に存在します: ${existingGroup.groupName}');
        return;
      } catch (e) {
        // グループが存在しない場合は作成を続行
        Log.info('💡 ローカルデフォルトグループが存在しないため、新規作成します');
      }

      // プリファレンスからユーザー名を取得（シンプル）
      final prefsName = await UserPreferencesService.getUserName();
      final displayName = prefsName ?? 'maya';
      Log.info('📝 [DEFAULT GROUP] プリファレンス優先: $displayName');

      // メールアドレスをSharedPreferencesに保存
      if (user.email != null && user.email!.isNotEmpty) {
        await UserPreferencesService.saveUserEmail(user.email!);
        Log.info('� SharedPreferences saveUserEmail: ${user.email} - 成功: true');
      }

      // デフォルトグループのオーナーメンバーを作成（UIDを後で更新可能）
      final ownerMember = PurchaseGroupMember.create(
        name: displayName,
        contact: user.email ?? '',
        role: PurchaseGroupRole.owner,
        isSignedIn: true,
        isInvited: false,
        isInvitationAccepted: false,
      );

      // デフォルトグループをローカルで作成
      final defaultGroupName = '${displayName}グループ';
      await hiveRepository.createGroup(
        defaultGroupId,
        defaultGroupName,
        ownerMember,
      );

      Log.info('✅ デフォルトグループを作成しました: $defaultGroupName (ID: $defaultGroupId)');
    } catch (e) {
      Log.error('❌ ローカルデフォルトグループ作成エラー: $e');
    }
  }

  /// 手動でデフォルトグループを作成（テスト用）
  Future<void> createDefaultGroupManually() async {
    final user = _auth.currentUser;
    if (user != null) {
      await _createDefaultGroupLocally(user);
    } else {
      Log.warning('⚠️ ユーザーがログインしていません');
    }
  }
}
