// lib/services/user_initialization_service.dart
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/app_logger.dart';
import '../utils/firestore_converter.dart'; // Firestore変換ユーティリティ
import '../models/purchase_group.dart' as models;
import '../providers/purchase_group_provider.dart';
import '../providers/hive_provider.dart'; // Hive Box プロバイダー
import '../datastore/hive_purchase_group_repository.dart'
    show hivePurchaseGroupRepositoryProvider;
import '../datastore/firestore_purchase_group_repository.dart'; // Repository型チェック用
import '../flavors.dart';
import 'notification_service.dart';
import 'sync_service.dart';
import 'user_preferences_service.dart';
import '../utils/error_handler.dart';
import '../helpers/user_id_change_helper.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // アプリ起動時にもプロフィール同期を実行
      if (_auth != null && _auth!.currentUser != null) {
        await _syncUserProfile(_auth!.currentUser!);
      }

      _initializeBasedOnUserState();

      // 🔧 FIX: 既にログイン済みの場合も通知リスナーを起動
      if (_auth != null && _auth!.currentUser != null) {
        final notificationService = _ref.read(notificationServiceProvider);
        notificationService.startListening();
        Log.info('🔔 [INIT] アプリ起動時 - 既存ユーザーで通知リスナー起動');
      }
    });

    // 本番環境のみFirebase Auth監視
    if (_auth != null) {
      _auth!.authStateChanges().listen((User? user) async {
        if (user != null) {
          // ユーザープロフィールをFirestoreと同期
          await _syncUserProfile(user);

          // ユーザーがログインした時の初期化処理
          _initializeUserDefaults(user);

          // 通知リスナーを起動
          final notificationService = _ref.read(notificationServiceProvider);
          notificationService.startListening();
          Log.info('🔔 [INIT] 認証状態変更 - 通知リスナー起動');
        } else {
          // ログアウト時は通知リスナーを停止
          final notificationService = _ref.read(notificationServiceProvider);
          notificationService.stopListening();
          Log.info('🔕 [INIT] ログアウト - 通知リスナー停止');
        }
      });
    }
  }

  /// ユーザー状態に応じた初期化処理
  /// 1. AllGroupsProviderに委ねる（デフォルトグループ作成は自動化）
  /// 2. Firebase認証済みの場合はFirestoreと同期
  Future<void> _initializeBasedOnUserState() async {
    try {
      // STEP1: AllGroupsProviderでグループ一覧を取得（内部でHive初期化を待機する）
      Log.info('🔄 [INIT] グループ一覧を初期化中...');
      await _ref.read(allGroupsProvider.future);

      // STEP2: デフォルトグループ（groupId = user.uid）の確認・復活・作成
      final user = _auth?.currentUser;
      final expectedDefaultGroupId = user?.uid ?? 'local_default';
      Log.info('🔍 [INIT] デフォルトグループID確認: $expectedDefaultGroupId');

      final hiveRepository = _ref.read(hivePurchaseGroupRepositoryProvider);

      // STEP2-0: レガシー'default_group'をuidに移行
      if (user != null && expectedDefaultGroupId != 'local_default') {
        try {
          final legacyGroup =
              await hiveRepository.getGroupById('default_group');
          Log.info('🔄 [INIT] レガシーdefault_groupを検出: ${legacyGroup.groupName}');

          // UIDグループが既に存在するかチェック
          bool uidGroupExists = false;
          try {
            await hiveRepository.getGroupById(expectedDefaultGroupId);
            uidGroupExists = true;
          } catch (_) {
            // UID グループは存在しない
          }

          if (!uidGroupExists) {
            // レガシーグループをuidに移行
            final migratedGroup = legacyGroup.copyWith(
              groupId: expectedDefaultGroupId,
              syncStatus: models.SyncStatus.local,
              updatedAt: DateTime.now(),
            );
            await hiveRepository.saveGroup(migratedGroup);
            Log.info('✅ [INIT] default_group → $expectedDefaultGroupId に移行完了');
          } else {
            Log.info('💡 [INIT] UIDグループが既に存在。レガシーグループは削除のみ実行');
          }

          // ⚠️ レガシーグループを必ず削除（移行の有無に関わらず）
          try {
            await hiveRepository.deleteGroup('default_group');
            Log.info('🗑️ [INIT] レガシーdefault_groupを削除');

            // AllGroupsProviderを更新して削除を反映
            _ref.invalidate(allGroupsProvider);
            Log.info('🔄 [INIT] AllGroupsProviderを更新（レガシーグループ削除反映）');
          } catch (e) {
            Log.warning('⚠️ [INIT] レガシーdefault_group削除エラー: $e');
          }
        } catch (e) {
          // レガシーグループが存在しない場合は何もしない
          Log.info('💡 [INIT] レガシーdefault_groupは存在しません');
        }
      }

      // STEP2-1: isDeleted=trueの削除済みデフォルトグループを確認・復活
      try {
        final deletedDefaultGroup =
            await hiveRepository.getGroupById(expectedDefaultGroupId);
        await hiveRepository.getGroupById(expectedDefaultGroupId);

        if (deletedDefaultGroup.isDeleted) {
          Log.warning(
              '⚠️ [INIT] 削除済みデフォルトグループを検出。復活させます: ${deletedDefaultGroup.groupName}');
          final revivedGroup = deletedDefaultGroup.copyWith(
            isDeleted: false,
            syncStatus: models.SyncStatus.local,
            updatedAt: DateTime.now(),
          );
          await hiveRepository.saveGroup(revivedGroup);
          Log.info('✅ [INIT] デフォルトグループを復活: ${revivedGroup.groupName}');

          // プロバイダーを更新して復活を反映
          _ref.invalidate(allGroupsProvider);
        } else {
          Log.info('✅ [INIT] デフォルトグループは既に存在: ${deletedDefaultGroup.groupName}');

          // STEP2-1.5: デフォルトグループ名とオーナー情報を現在のユーザー情報に更新
          final prefsName = await UserPreferencesService.getUserName();
          final expectedGroupName = prefsName?.isNotEmpty == true
              ? '$prefsName'
              : (user?.displayName?.isNotEmpty == true
                  ? user!.displayName!
                  : (user?.email?.split('@').first ?? 'ユーザー'));
          final expectedDefaultGroupName = '$expectedGroupNameグループ';

          // オーナーメンバー情報の更新が必要かチェック
          final ownerMember = deletedDefaultGroup.members?.firstWhere(
            (m) => m.role == models.PurchaseGroupRole.owner,
            orElse: () => models.PurchaseGroupMember(
              memberId: user?.uid ?? '',
              name: '',
              contact: '',
              role: models.PurchaseGroupRole.owner,
            ),
          );

          final needsGroupNameUpdate =
              deletedDefaultGroup.groupName != expectedDefaultGroupName;
          final needsOwnerNameUpdate = ownerMember?.name != expectedGroupName;
          final needsOwnerContactUpdate =
              ownerMember?.contact != (user?.email ?? '');

          if (needsGroupNameUpdate ||
              needsOwnerNameUpdate ||
              needsOwnerContactUpdate) {
            Log.info(
                '🔄 [INIT] デフォルトグループ情報を更新: グループ名=${deletedDefaultGroup.groupName} → $expectedDefaultGroupName, オーナー名=${ownerMember?.name} → $expectedGroupName');

            // 更新されたメンバーリストを作成
            final updatedMembers = deletedDefaultGroup.members?.map((m) {
              if (m.role == models.PurchaseGroupRole.owner) {
                return m.copyWith(
                  name: expectedGroupName,
                  contact: user?.email ?? m.contact,
                  memberId: user?.uid ?? m.memberId,
                );
              }
              return m;
            }).toList();

            final updatedGroup = deletedDefaultGroup.copyWith(
              groupName: expectedDefaultGroupName,
              ownerName: expectedGroupName,
              members: updatedMembers,
              updatedAt: DateTime.now(),
            );
            await hiveRepository.saveGroup(updatedGroup);
            Log.info('✅ [INIT] デフォルトグループ情報更新完了（グループ名+オーナー情報）');

            // プロバイダーを更新して名前変更を反映
            _ref.invalidate(allGroupsProvider);
          }
        }
      } catch (e) {
        // グループが存在しない場合は新規作成
        Log.info(
            '🆕 [INIT] デフォルトグループ($expectedDefaultGroupId)が見つかりません。AllGroupsNotifierで作成します...');

        // AllGroupsNotifier経由でデフォルトグループを作成（安全）
        final groupNotifier = _ref.read(allGroupsProvider.notifier);
        await groupNotifier.createDefaultGroup(user);

        Log.info('✅ [INIT] デフォルトグループ作成完了');
      }

      // STEP3: Firestore同期（ローカル専用グループは保護される）
      // ⚠️ 注意: syncFromFirestoreToHiveでsyncStatus=localのグループは削除されない
      final currentUser = _auth?.currentUser;
      if (currentUser != null && _isFirebaseUserId(currentUser.uid)) {
        Log.info('🔄 [INIT] Firebase認証済みユーザー検出 - Firestoreとの同期を開始');
        Log.info('💡 [INIT] デフォルトグループ(syncStatus=local)は同期処理で保護されます');
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

  /// Firestoreのユーザープロフィールとローカルのプリファレンスを同期
  Future<void> _syncUserProfile(User user) async {
    try {
      Log.info('🔄 [PROFILE SYNC] ユーザープロフィール同期開始: UID=${user.uid}');

      final firestore = FirebaseFirestore.instance;
      final profileDoc = firestore
          .collection('users')
          .doc(user.uid)
          .collection('profile')
          .doc('userName');

      // Firestoreからプロフィールを取得
      final profileSnapshot = await profileDoc.get();
      final firestoreData = profileSnapshot.exists
          ? profileSnapshot.data() as Map<String, dynamic>
          : null;

      // SharedPreferencesから現在のデータを取得
      final localUserName = await UserPreferencesService.getUserName();
      final localUserEmail = await UserPreferencesService.getUserEmail();
      final localUserId = await UserPreferencesService.getUserId();

      // Firebase Authのメールアドレスを取得
      final authEmail = user.email;

      Log.info(
          '📊 [PROFILE SYNC] Firestore: ${firestoreData != null ? firestoreData['userName'] : 'なし'}');
      Log.info('📊 [PROFILE SYNC] Local: $localUserName');

      // 同期の優先順位: Firestore > Local
      String? finalUserName;
      String finalUserEmail = authEmail ?? localUserEmail ?? '';
      String finalUserId = user.uid;

      if (firestoreData != null && firestoreData['userName'] != null) {
        // Firestoreにデータがある場合
        finalUserName = firestoreData['userName'] as String;

        // ローカルと異なる場合は更新
        if (finalUserName != localUserName) {
          Log.info('📥 [PROFILE SYNC] Firestoreからローカルに同期: $finalUserName');
          await UserPreferencesService.saveUserName(finalUserName);
        } else {
          Log.info('✅ [PROFILE SYNC] ユーザー名は既に同期済み');
        }
      } else if (localUserName != null && localUserName.isNotEmpty) {
        // Firestoreにデータがなく、ローカルにある場合
        finalUserName = localUserName;
        Log.info('📤 [PROFILE SYNC] ローカルからFirestoreに同期: $finalUserName');
        await profileDoc.set({
          'userName': finalUserName,
          'userEmail': finalUserEmail,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } else {
        // 両方にデータがない場合
        Log.info('⚠️ [PROFILE SYNC] ユーザー名が未設定');
      }

      // メールアドレスとユーザーIDをローカルに保存
      if (finalUserEmail.isNotEmpty && finalUserEmail != localUserEmail) {
        await UserPreferencesService.saveUserEmail(finalUserEmail);
        Log.info('💾 [PROFILE SYNC] メールアドレスを保存: $finalUserEmail');
      }

      if (finalUserId != localUserId) {
        await UserPreferencesService.saveUserId(finalUserId);
        Log.info('💾 [PROFILE SYNC] ユーザーIDを保存: $finalUserId');
      }

      Log.info('✅ [PROFILE SYNC] ユーザープロフィール同期完了');
    } catch (e) {
      Log.error('❌ [PROFILE SYNC] プロフィール同期エラー: $e');
      // エラーがあっても初期化は続行
    }
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

      // デフォルトグループをAllGroupsNotifierで作成
      // ⚠️ 注意: Hive初期化は AllGroupsNotifier.build() 内で完了される
      Log.info('🔄 [INIT] AllGroupsNotifierでデフォルトグループを作成');
      final groupNotifier = _ref.read(allGroupsProvider.notifier);
      await groupNotifier.createDefaultGroup(user);

      // ⚠️ 重要: Firestore同期はデフォルトグループ作成後に実行しない
      // デフォルトグループはsyncStatus=localなので、同期処理で保護される
      Log.info('� [INIT] デフォルトグループ作成完了 - Firestore同期はスキップ（ローカル専用）');

      Log.info('✅ ユーザーデフォルト初期化完了');
    } catch (e) {
      Log.warning('⚠️ ユーザー初期化エラー: $e');
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
      // 新パス構造: purchaseGroupsルートコレクションを使用
      final purchaseGroupsRef = firestore.collection('purchaseGroups');
      final repository = _ref.read(purchaseGroupRepositoryProvider);

      final allHiveGroups = await repository.getAllGroups();
      int syncedCount = 0;

      for (final group in allHiveGroups) {
        // 削除済みグループはFirestoreに同期しない
        if (group.isDeleted) {
          Log.info('🗑️ [SYNC] 削除済みグループはスキップ: ${group.groupId}');
          continue;
        }

        final docRef = purchaseGroupsRef.doc(group.groupId);

        // 🔥 CRITICAL FIX: Firestoreの既存allowedUidをマージ（上書き防止）
        List<String> finalAllowedUid = List<String>.from(group.allowedUid);
        try {
          final existingDoc = await docRef.get();
          if (existingDoc.exists) {
            final existingData = existingDoc.data();
            final existingAllowedUid =
                List<String>.from(existingData?['allowedUid'] ?? []);

            // マージ（重複除去）
            final mergedSet = <String>{
              ...existingAllowedUid,
              ...group.allowedUid,
            };
            finalAllowedUid = mergedSet.toList();

            Log.info(
                '🔀 [SYNC] allowedUidマージ: Hive=${group.allowedUid.length}個, Firestore=${existingAllowedUid.length}個 → 最終=${finalAllowedUid.length}個');
          }
        } catch (e) {
          Log.warning('⚠️ [SYNC] Firestore読み取りエラー、Hiveのみ使用: $e');
        }

        await docRef.set({
          'groupId': group.groupId,
          'groupName': group.groupName,
          'ownerUid': group.ownerUid,
          'ownerName': group.ownerName,
          'ownerEmail': group.ownerEmail,
          'allowedUid': finalAllowedUid, // マージ後のallowedUid
          'members': group.members
                  ?.map((member) => {
                        'memberId': member.memberId,
                        'name': member.name,
                        'contact': member.contact,
                        'role': member.role.name,
                        'isSignedIn': member.isSignedIn,
                        'invitationStatus': member.invitationStatus.name,
                      })
                  .toList() ??
              [],
          'isDeleted': group.isDeleted,
          'lastAccessedAt': group.lastAccessedAt != null
              ? Timestamp.fromDate(group.lastAccessedAt!)
              : null,
          'createdAt': group.createdAt != null
              ? Timestamp.fromDate(group.createdAt!)
              : null,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        syncedCount++;
      }

      if (syncedCount > 0) {
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

      // purchaseGroupsルートコレクションからallowedUidでフィルタ
      final purchaseGroupsRef = firestore.collection('purchaseGroups');
      final snapshot = await purchaseGroupsRef
          .where('allowedUid', arrayContains: user.uid)
          .get();

      Log.info('📊 [SYNC] Firestoreクエリ完了: ${snapshot.docs.length}個のグループ');

      final repository = _ref.read(purchaseGroupRepositoryProvider);

      int syncedCount = 0;
      int skippedCount = 0;

      // 削除済みでないグループのIDを取得（isDeletedフィールドがない場合は有効とみなす）
      final firestoreGroupIds = snapshot.docs
          .where((doc) {
            final data = doc.data();
            final isDeleted = data['isDeleted'] as bool? ?? false;
            return !isDeleted;
          })
          .map((doc) => doc.id)
          .toSet();

      Log.info(
          '📊 [SYNC] Firestoreから取得したグループ: ${snapshot.docs.length}個 (削除済み除外後: ${firestoreGroupIds.length}個)');
      for (final groupId in firestoreGroupIds) {
        Log.info('  - $groupId');
      }

      // ⚠️ 重要: 直接Hiveリポジトリを使用（Hybridの初期化待機を回避）
      final hiveRepository = _ref.read(hivePurchaseGroupRepositoryProvider);
      final hiveGroups = await hiveRepository.getAllGroups();
      Log.info('📊 [SYNC] Hiveに存在するグループ: ${hiveGroups.length}個');
      for (final hiveGroup in hiveGroups) {
        Log.info(
            '  - ${hiveGroup.groupName} (${hiveGroup.groupId}), syncStatus=${hiveGroup.syncStatus}');
      }

      // ⚠️ STEP1: local状態のグループをFirestoreにアップロード
      int uploadedCount = 0;
      for (final hiveGroup in hiveGroups) {
        if (hiveGroup.syncStatus == models.SyncStatus.local) {
          // デフォルトグループはスキップ（各ユーザー固有でFirestoreに同期不要）
          final currentUser = FirebaseAuth.instance.currentUser;
          if (currentUser != null && hiveGroup.groupId == currentUser.uid) {
            Log.info(
                '📱 [SYNC] デフォルトグループはアップロードスキップ: ${hiveGroup.groupName} (${hiveGroup.groupId})');
            continue;
          }

          Log.info(
              '📤 [SYNC] local状態のグループをFirestoreにアップロード: ${hiveGroup.groupName}');
          try {
            await purchaseGroupsRef.doc(hiveGroup.groupId).set({
              'groupId': hiveGroup.groupId,
              'groupName': hiveGroup.groupName,
              'ownerUid': hiveGroup.ownerUid,
              'ownerName': hiveGroup.ownerName,
              'ownerEmail': hiveGroup.ownerEmail,
              'allowedUid': [hiveGroup.ownerUid],
              'members': (hiveGroup.members ?? [])
                  .map((m) => {
                        'memberId': m.memberId,
                        'name': m.name,
                        'contact': m.contact,
                        'role': m.role.name,
                        'isSignedIn': m.isSignedIn,
                        'isInvited': m.isInvited,
                        'isInvitationAccepted': m.isInvitationAccepted,
                      })
                  .toList(),
              'isDeleted': false,
              'createdAt': FieldValue.serverTimestamp(),
              'updatedAt': FieldValue.serverTimestamp(),
            });

            // syncStatusをsyncedに更新
            final syncedGroup =
                hiveGroup.copyWith(syncStatus: models.SyncStatus.synced);
            await hiveRepository.saveGroup(syncedGroup);

            // アップロードしたグループをFirestoreリストに追加（削除対象から除外）
            firestoreGroupIds.add(hiveGroup.groupId);

            uploadedCount++;
            Log.info('✅ [SYNC] アップロード完了: ${hiveGroup.groupName}');
          } catch (e) {
            Log.error('❌ [SYNC] アップロード失敗: ${hiveGroup.groupName}, $e');
          }
        }
      }

      if (uploadedCount > 0) {
        Log.info('📤 [SYNC] $uploadedCount個のlocalグループをFirestoreにアップロードしました');
      }

      // ⚠️ STEP2: Firestoreにないグループの処理
      for (final hiveGroup in hiveGroups) {
        if (!firestoreGroupIds.contains(hiveGroup.groupId) &&
            hiveGroup.groupId != 'default_group' &&
            hiveGroup.groupId != 'defaultGroup' &&
            hiveGroup.groupId != 'current_list') {
          Log.info(
              '🔍 [SYNC] グループ削除判定: ${hiveGroup.groupName}, syncStatus=${hiveGroup.syncStatus}');

          // pending状態のグループは削除しない（招待受諾中のプレースホルダー）
          if (hiveGroup.syncStatus == models.SyncStatus.pending) {
            Log.info(
                '⏳ [SYNC] pending状態のグループをスキップ: ${hiveGroup.groupName} (${hiveGroup.groupId})');
            skippedCount++;
            continue;
          }

          // ⚠️ 重要: local状態のグループは削除しない（ローカル専用グループ）
          if (hiveGroup.syncStatus == models.SyncStatus.local) {
            Log.info(
                '📱 [SYNC] local状態のグループをスキップ: ${hiveGroup.groupName} (${hiveGroup.groupId})');
            skippedCount++;
            continue;
          }

          // ⚠️ デフォルトグループがsynced状態でFirestoreにない場合はlocalに戻す
          if (hiveGroup.groupId == user.uid &&
              hiveGroup.syncStatus == models.SyncStatus.synced) {
            Log.warning(
                '⚠️ [SYNC] デフォルトグループがFirestoreにありません。syncStatus=localに戻します: ${hiveGroup.groupName}');
            final localGroup =
                hiveGroup.copyWith(syncStatus: models.SyncStatus.local);
            await hiveRepository.saveGroup(localGroup);
            skippedCount++;
            continue;
          }

          // ⚠️ 重要: 最近更新されたグループは保護（Firestore反映待ちの可能性）
          final updatedAt = hiveGroup.updatedAt ?? hiveGroup.createdAt;
          final isRecentlyUpdated = updatedAt != null &&
              DateTime.now().difference(updatedAt).inMinutes < 5;

          if (isRecentlyUpdated) {
            Log.warning(
                '🛡️ [SYNC] 最近更新されたグループを保護（Firestore反映待ち）: ${hiveGroup.groupName} (${hiveGroup.groupId})');
            skippedCount++;
            continue;
          }

          // その他のsynced状態グループはFirestoreから削除されたと判断して削除
          try {
            // ⚠️ CRITICAL: Hive専用削除（Firestore削除権限がない受諾者用）
            await hiveRepository.deleteGroup(hiveGroup.groupId);
            Log.info(
                '🗑️ [SYNC] Firestoreにないグループを削除: ${hiveGroup.groupName} (${hiveGroup.groupId})');
            skippedCount++;
          } catch (e) {
            Log.warning('⚠️ [SYNC] グループ削除失敗: ${hiveGroup.groupId}, $e');
          }
        }
      }

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final isDeleted = data['isDeleted'] as bool? ?? false;

        // 削除済みグループはスキップ（Hiveにあれば削除）
        if (isDeleted) {
          try {
            // ⚠️ CRITICAL: Hive専用削除（Firestore削除権限がない受諾者用）
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
          // Firestoreの Timestamp を DateTime に変換してから fromJson を使用
          final convertedData = FirestoreConverter.convertTimestamps(data);

          // PurchaseGroup.fromJson()を使用してallowedUidを含む全フィールドを正しく復元
          final group = models.PurchaseGroup.fromJson(convertedData).copyWith(
            groupId: doc.id, // ドキュメントIDを確実に設定
            updatedAt: DateTime.now(),
          );

          Log.info(
              '🔍 [SYNC] グループ同期: ${group.groupName}, allowedUid: ${group.allowedUid}');

          // 🔥 CRITICAL FIX: Hiveにのみ保存（Firestoreへの逆書き込みを防ぐ）
          if (repository is FirestorePurchaseGroupRepository) {
            // Hive Boxに直接書き込む
            final purchaseGroupBox = _ref.read(purchaseGroupBoxProvider);
            await purchaseGroupBox.put(group.groupId, group);
            Log.info('✅ [SYNC] HiveのみにGroup保存（Firestore書き戻し回避）');
          } else {
            // HiveRepositoryの場合は通常のupdateを使用
            await repository.updateGroup(group.groupId, group);
          }
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
