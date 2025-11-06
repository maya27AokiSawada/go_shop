// lb/services/user_initialization_service.darti
import 'package:flutter/widgets.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/app_logger.dart';
import '../models/purchase_group.dart';
import '../providers/purchase_group_provider.dart';
import '../providers/user_specific_hive_provider.dart';
import '../flavors.dart';

import '../datastore/hive_purchase_group_repository.dart' as hive_repo;

import 'user_preferences_service.dart';

final userInitializationServiceProvider = Provider<UserInitializationService>((
  ref,
) {
  return UserInitializationService(ref);
});

/// 初期化完了状態を監視するStateProvider
final userInitializationStatusProvider = StateProvider<bool>((ref) => false);

/// Firestore同期状態を監視するStateProvider
final firestoreSyncStatusProvider = StateProvider<String>(
    (ref) => 'idle'); // 'idle', 'syncing', 'completed', 'error'

class UserInitializationService {
  final Ref _ref;
  FirebaseAuth? _auth;

  UserInitializationService(this._ref) {
    // 本番環境のみFirebase Authを初期化
    if (F.appFlavor == Flavor.prod) {
      _auth = FirebaseAuth.instance;
    }
  }

  /// Firebase Auth状態変化を監視してユーザー初期化を実行
  void startAuthStateListener() {
    // アプリ起動時にユーザー状態に応じた初期化を実行
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeBasedOnUserState();
    });

    // 本番環境のみFirebase Auth監視
    if (_auth != null) {
      _auth!.authStateChanges().listen((User? user) {
        if (user != null) {
          // ユーザーがログインした時の初期化処理
          _initializeUserDefaults(user);
        }
      });
    }
  }

  /// ユーザー状態に応じた初期化処理
  /// 1. AllGroupsProviderに委ねる（デフォルトグループ作成は自動化）
  /// 2. Firebase認証済みの場合はFirestoreと同期
  Future<void> _initializeBasedOnUserState() async {
    try {
      // STEP1: AllGroupsProviderでグループ一覧を取得
      Log.info('🔄 [INIT] グループ一覧を初期化中...');
      final groups = await _ref.read(allGroupsProvider.future);

      // STEP2: デフォルトグループが存在しない場合は作成（Hive初期化完了を待つ）
      final defaultGroup =
          groups.where((g) => g.groupId == 'default_group').firstOrNull;
      if (defaultGroup == null) {
        Log.info('🔄 [INIT] デフォルトグループが見つかりません。ローカルで作成します...');

        // Hive初期化完了まで待機
        await _ref.read(hiveUserInitializationProvider.future);
        Log.info('🔄 [INIT] Hive初期化完了、デフォルトグループ作成を続行...');

        // 追加の安全性のため、少し待機してからBox状態を確認
        await Future.delayed(const Duration(milliseconds: 100));

        // hiveInitializationStatusProviderの状態を再確認
        final hiveReady = _ref.read(hiveInitializationStatusProvider);
        Log.info('🔄 [INIT] HiveBox状態確認: $hiveReady');

        if (!hiveReady) {
          Log.info('⚠️ [INIT] Hive初期化プロバイダーが完了したがBoxが準備できていません。追加待機...');
          // 最大3秒まで待機
          for (int i = 0; i < 30; i++) {
            await Future.delayed(const Duration(milliseconds: 100));
            final ready = _ref.read(hiveInitializationStatusProvider);
            if (ready) {
              Log.info('✅ [INIT] Hive Box準備完了 (${i * 100}ms後)');
              break;
            }
          }
        }

        // Dev環境ではFirebase Userが存在しないため、nullを許容
        await _createDefaultGroupLocally(_auth?.currentUser);
      }

      // STEP3: Firestore同期を実行（サインイン状態の場合）
      final currentUser = _auth?.currentUser;
      if (currentUser != null && _isFirebaseUserId(currentUser.uid)) {
        Log.info('🔄 [INIT] Firebase認証済みユーザー検出 - Firestoreとの同期を開始');
        await _syncWithFirestore(currentUser);
      } else {
        Log.info('💡 [INIT] 未サインインまたはローカルユーザー - ローカルデータで動作');
      }

      // STEP4: プロバイダーを更新（userNameProviderはホーム画面表示時まで遅延）
      _ref.invalidate(allGroupsProvider);
      Log.info('✅ [INIT] ユーザー状態初期化完了');
    } catch (e) {
      Log.error('❌ [INIT] ユーザー状態初期化エラー: $e');
      // エラーが発生した場合はAllGroupsProviderに委ねる（自動でデフォルトグループが作成される）
    }
  }

  /// FirebaseユーザーIDかどうかを判定
  bool _isFirebaseUserId(String uid) {
    // Firebase AuthのUIDは通常28文字の英数字
    return uid.length >= 20 && RegExp(r'^[a-zA-Z0-9]+$').hasMatch(uid);
  }

  /// Firestoreとの同期を実行
  Future<void> _syncWithFirestore(User user) async {
    try {
      // 同期状態を開始
      _ref.read(firestoreSyncStatusProvider.notifier).state = 'syncing';
      Log.info('🔄 [SYNC] Firestore同期を開始');

      // 【重要】Firestore→Hive同期を先に実行して、Firestoreの状態を優先
      // これによりFirestoreで削除されたグループがHiveからも削除される
      await syncFromFirestoreToHive(user);

      // Hive→Firestore同期は実行しない（起動時はFirestoreが真実の情報源）
      // グループ作成・更新時のみ個別に同期する
      Log.info('💡 [SYNC] 起動時はFirestore→Hive同期のみ実行（Hive→Firestoreはスキップ）');

      // 同期状態を完了に設定
      _ref.read(firestoreSyncStatusProvider.notifier).state = 'completed';
      Log.info('✅ [SYNC] Firestore同期完了');
    } catch (e) {
      // 同期状態をエラーに設定
      _ref.read(firestoreSyncStatusProvider.notifier).state = 'error';
      Log.error('❌ [SYNC] Firestore同期エラー: $e');
      rethrow;
    }
  }

  /// ユーザーのデフォルトデータを初期化
  Future<void> _initializeUserDefaults(User user) async {
    try {
      // 広告サービス無効化（AdMob未設定のため）
      Log.info('💡 広告サービスは無効化されています');

      // デフォルトグループをローカル（Hive）のみで作成
      await _createDefaultGroupLocally(user);

      // サインイン時もFirestore同期を実行
      if (_isFirebaseUserId(user.uid)) {
        Log.info('🔄 [INIT] サインイン検出 - Firestoreとの同期を開始');
        await _syncWithFirestore(user);
      }

      Log.info('✅ ユーザーデフォルト初期化完了');
    } catch (e) {
      Log.warning('⚠️ ユーザー初期化エラー: $e');
    }
  }

  /// デフォルトグループをローカル（Hive）のみで作成
  /// Dev環境ではuserがnullの可能性がある
  Future<void> _createDefaultGroupLocally(User? user) async {
    try {
      // Hiveリポジトリを直接使用（Firestoreにはアクセスしない）
      final hiveRepository =
          _ref.read(hive_repo.hivePurchaseGroupRepositoryProvider);
      const defaultGroupId = 'default_group'; // シンプルなID

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

      // メールアドレスをSharedPreferencesに保存（ユーザーが存在する場合のみ）
      if (user?.email != null && user!.email!.isNotEmpty) {
        await UserPreferencesService.saveUserEmail(user.email!);
        Log.info(
            '📧 SharedPreferences saveUserEmail: ${user.email} - 成功: true');
      }

      // デフォルトグループのオーナーメンバーを作成
      final ownerMember = PurchaseGroupMember.create(
        name: displayName,
        contact: user?.email ?? '',
        role: PurchaseGroupRole.owner,
        isSignedIn: user != null,
        isInvited: false,
        isInvitationAccepted: false,
      );

      // デフォルトグループをローカルで作成
      final defaultGroupName = '$displayNameグループ';
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
    final user = _auth?.currentUser;
    if (user != null) {
      await _createDefaultGroupLocally(user);
    } else {
      Log.warning('⚠️ ユーザーがログインしていません');
    }
  }

  /// Firestoreでグループを削除済みとしてマーク（物理削除せずフラグを立てる）
  Future<void> markGroupAsDeletedInFirestore(User user, String groupId) async {
    if (F.appFlavor != Flavor.prod) {
      Log.info('💡 [FIRESTORE] Dev環境のため、Firestore削除フラグはスキップ');
      return;
    }

    try {
      final firestore = FirebaseFirestore.instance;
      final docRef = firestore
          .collection('users')
          .doc(user.uid)
          .collection('groups')
          .doc(groupId);

      await docRef.update({
        'isDeleted': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      Log.info('✅ [FIRESTORE] グループに削除フラグを設定: $groupId');
    } catch (e) {
      Log.error('❌ [FIRESTORE] 削除フラグ設定エラー: $e');
      rethrow;
    }
  }

  /// Hive→Firestoreへの同期（グループ作成時などに呼び出す）
  Future<void> syncHiveToFirestore(User user) async {
    if (F.appFlavor != Flavor.prod) {
      Log.info('💡 [FIRESTORE] Dev環境のため、Hive→Firestore同期はスキップ');
      return;
    }

    try {
      Log.info('⬆️ [SYNC] Hive→Firestore同期開始');
      final firestore = FirebaseFirestore.instance;
      final userGroupsRef =
          firestore.collection('users').doc(user.uid).collection('groups');
      final hiveRepository =
          _ref.read(hive_repo.hivePurchaseGroupRepositoryProvider);

      final allHiveGroups = await hiveRepository.getAllGroups();
      final batch = firestore.batch();
      int syncedCount = 0;

      for (final group in allHiveGroups) {
        // 削除済みグループはFirestoreに同期しない
        if (group.isDeleted) {
          Log.info('🗑️ [SYNC] 削除済みグループはスキップ: ${group.groupId}');
          continue;
        }

        final docRef = userGroupsRef.doc(group.groupId);
        batch.set(
            docRef,
            {
              'groupId': group.groupId,
              'groupName': group.groupName,
              'ownerUid': group.ownerUid,
              'ownerName': group.ownerName,
              'ownerEmail': group.ownerEmail,
              'members': group.members
                      ?.map((m) => {
                            'memberId': m.memberId,
                            'name': m.name,
                            'contact': m.contact,
                            'role': m.role.name,
                            'isSignedIn': m.isSignedIn,
                            'invitationStatus': m.invitationStatus.name,
                          })
                      .toList() ??
                  [],
              'isDeleted': group.isDeleted,
              'lastAccessedAt': group.lastAccessedAt?.toIso8601String(),
              'createdAt': group.createdAt?.toIso8601String(),
              'updatedAt': FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true));
        syncedCount++;
      }

      if (syncedCount > 0) {
        await batch.commit();
        Log.info('✅ [SYNC] Hive→Firestore同期完了: $syncedCount グループ');
      } else {
        Log.info('💡 [SYNC] 同期対象グループなし');
      }
    } catch (e) {
      Log.error('❌ [SYNC] Hive→Firestore同期エラー: $e');
    }
  }

  /// Firestore→Hive同期（アプリ起動時などに呼び出す）
  Future<void> syncFromFirestoreToHive(User user) async {
    if (F.appFlavor != Flavor.prod) {
      Log.info('💡 [FIRESTORE] Dev環境のため、Firestore→Hive同期はスキップ');
      return;
    }

    try {
      Log.info('⬇️ [SYNC] Firestore→Hive同期開始');
      final firestore = FirebaseFirestore.instance;
      final userGroupsRef =
          firestore.collection('users').doc(user.uid).collection('groups');

      // 削除済みでないグループのみ取得
      final snapshot =
          await userGroupsRef.where('isDeleted', isEqualTo: false).get();

      final hiveRepository =
          _ref.read(hive_repo.hivePurchaseGroupRepositoryProvider);

      int syncedCount = 0;
      int skippedCount = 0;

      // Firestoreにないグループ(削除済み)をHiveから削除
      final firestoreGroupIds = snapshot.docs.map((doc) => doc.id).toSet();
      Log.info('📊 [SYNC] Firestoreから取得したグループ: ${firestoreGroupIds.length}個');
      for (final groupId in firestoreGroupIds) {
        Log.info('  - $groupId');
      }

      final hiveGroups = await hiveRepository.getAllGroups();
      Log.info('📊 [SYNC] Hiveに存在するグループ: ${hiveGroups.length}個');
      for (final hiveGroup in hiveGroups) {
        Log.info('  - ${hiveGroup.groupName} (${hiveGroup.groupId})');
      }

      for (final hiveGroup in hiveGroups) {
        if (!firestoreGroupIds.contains(hiveGroup.groupId) &&
            hiveGroup.groupId != 'default_group' &&
            hiveGroup.groupId != 'defaultGroup' &&
            hiveGroup.groupId != 'current_list') {
          try {
            await hiveRepository.deleteGroup(hiveGroup.groupId);
            Log.info(
                '🗑️ [SYNC] Firestoreにないグループを削除: ${hiveGroup.groupName} (${hiveGroup.groupId})');
            skippedCount++;
          } catch (e) {
            Log.warning('⚠️ [SYNC] グループ削除失敗: ${hiveGroup.groupId}');
          }
        }
      }

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final isDeleted = data['isDeleted'] as bool? ?? false;

        // 削除済みグループはスキップ（Hiveにあれば削除）
        if (isDeleted) {
          try {
            await hiveRepository.deleteGroup(doc.id);
            Log.info('🗑️ [SYNC] 削除済みグループをHiveから削除: ${doc.id}');
          } catch (e) {
            // グループが存在しない場合はスキップ
          }
          skippedCount++;
          continue;
        }

        // グループをHiveに保存/更新
        try {
          final members = (data['members'] as List?)
                  ?.map((m) => PurchaseGroupMember(
                        memberId: m['memberId'] ?? '',
                        name: m['name'] ?? '',
                        contact: m['contact'] ?? '',
                        role: PurchaseGroupRole.values.firstWhere(
                          (r) => r.name == (m['role'] ?? ''),
                          orElse: () => PurchaseGroupRole.member,
                        ),
                        isSignedIn: m['isSignedIn'] ?? false,
                        invitationStatus: InvitationStatus.values.firstWhere(
                          (s) => s.name == (m['invitationStatus'] ?? ''),
                          orElse: () => InvitationStatus.self,
                        ),
                      ))
                  .toList() ??
              [];

          final group = PurchaseGroup(
            groupId: doc.id,
            groupName: data['groupName'] ?? '',
            ownerUid: data['ownerUid'],
            ownerName: data['ownerName'],
            ownerEmail: data['ownerEmail'],
            members: members,
            isDeleted: data['isDeleted'] as bool? ?? false, // Firestoreの値を使用
            lastAccessedAt: data['lastAccessedAt'] != null
                ? DateTime.parse(data['lastAccessedAt'])
                : null,
            createdAt: data['createdAt'] != null
                ? DateTime.parse(data['createdAt'])
                : null,
            updatedAt: DateTime.now(),
          );

          await hiveRepository.saveGroup(group);
          syncedCount++;
        } catch (e) {
          Log.warning('⚠️ [SYNC] グループ同期エラー（${doc.id}）: $e');
        }
      }

      Log.info(
          '✅ [SYNC] Firestore→Hive同期完了: $syncedCount 同期, $skippedCount スキップ');
    } catch (e) {
      Log.error('❌ [SYNC] Firestore→Hive同期エラー: $e');
    }
  }
}
