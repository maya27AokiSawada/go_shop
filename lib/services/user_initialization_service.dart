// lib/services/user_initialization_service.dart
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/app_logger.dart';
import '../utils/firestore_converter.dart'; // Firestore変換ユーティリティ
import '../models/shared_group.dart' as models;
import '../providers/shared_group_provider.dart';
import '../providers/hive_provider.dart'; // Hive Box プロバイダー
import '../datastore/hive_shared_group_repository.dart'
    show hiveSharedGroupRepositoryProvider;
import '../datastore/firestore_shared_group_repository.dart'; // Repository型チェック用
import '../flavors.dart';
import 'notification_service.dart';
import 'list_notification_batch_service.dart';
import 'list_cleanup_service.dart';
import 'user_preferences_service.dart';

final userInitializationServiceProvider = Provider<UserInitializationService>((
  ref,
) {
  return UserInitializationService(ref);
});

/// 初期化完了状態を監視するStateProvider
/// 🔥 DEPRECATED (2026-03-05): このプロバイダーはどこからもtrueに設定されないため無効。
/// 後方互換性のため定義を残すが、使用しないこと。
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

        final batchService = _ref.read(listNotificationBatchServiceProvider);
        batchService.start();

        Log.info('🔔 [INIT] アプリ起動時 - 既存ユーザーで通知サービス起動');
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

          final batchService = _ref.read(listNotificationBatchServiceProvider);
          batchService.start();

          Log.info('🔔 [INIT] 認証状態変更 - 通知サービス起動');
        } else {
          // ログアウト時は通知リスナーを停止
          final notificationService = _ref.read(notificationServiceProvider);
          notificationService.stopListening();

          final batchService = _ref.read(listNotificationBatchServiceProvider);
          batchService.stop();

          Log.info('🔕 [INIT] ログアウト - 通知サービス停止');
        }
      });
    }
  }

  /// ユーザー状態に応じた初期化処理
  /// 1. AllGroupsProviderでグループ一覧を取得
  /// 2. Firebase認証済みの場合はFirestoreと同期
  /// 3. プロバイダーを更新
  ///
  /// ⚠️ デフォルトグループ機能は2026-02-12に廃止済み。
  /// グループ0個の場合は初回セットアップ画面(initial_setup_widget)を表示。
  Future<void> _initializeBasedOnUserState() async {
    try {
      // STEP1: AllGroupsProviderでグループ一覧を取得（内部でHive初期化を待機する）
      Log.info('🔄 [INIT] グループ一覧を初期化中...');
      final allGroups = await _ref.read(allGroupsProvider.future);
      Log.info('📊 [INIT] 現在のグループ数: ${allGroups.length}個');

      // STEP2: Firebase認証チェック
      final user = _auth?.currentUser;
      if (user == null) {
        Log.error('❌ [INIT] Firebase認証が必須です');
        return;
      }

      // グループが0個の場合はログのみ（UIはinitial_setup_widgetが表示）
      if (allGroups.isEmpty) {
        Log.info('🆕 [INIT] グループが0個→初回セットアップ画面表示');
      }

      // STEP3: Firestore同期
      Log.info('🔄 [INIT] Firebase認証済みユーザー - Firestoreとの同期を開始');
      await _syncWithFirestore(user);

      // STEP4: プロバイダーを更新
      _ref.invalidate(allGroupsProvider);
      Log.info('✅ [INIT] ユーザー状態初期化完了');

      // STEP5: バックグラウンドでクリーンアップ実行
      _performBackgroundCleanup();
    } catch (e) {
      Log.error('❌ [INIT] ユーザー状態初期化エラー: $e');
    }
  }

  /// Firestoreのユーザープロフィールとローカルのプリファレンスを同期
  Future<void> _syncUserProfile(User user) async {
    try {
      Log.info(
          '🔄 [PROFILE SYNC] ユーザープロフィール同期開始: UID=${AppLogger.maskUserId(user.uid)}');

      final firestore = FirebaseFirestore.instance;
      final userDoc = firestore.collection('users').doc(user.uid);

      // Firestoreからプロフィールを取得
      final userSnapshot = await userDoc.get();
      final firestoreData = userSnapshot.exists
          ? userSnapshot.data() as Map<String, dynamic>
          : null;

      // SharedPreferencesから現在のデータを取得
      final localUserName = await UserPreferencesService.getUserName();
      final localUserEmail = await UserPreferencesService.getUserEmail();
      final localUserId = await UserPreferencesService.getUserId();

      // Firebase Authのメールアドレスを取得
      final authEmail = user.email;

      Log.info(
          '📊 [PROFILE SYNC] Firestore: ${firestoreData != null ? firestoreData['displayName'] : 'なし'}');
      Log.info('📊 [PROFILE SYNC] Local: ${AppLogger.maskName(localUserName)}');

      // 同期の優先順位: Firestore > Local
      String? finalUserName;
      String finalUserEmail = authEmail ?? localUserEmail ?? '';
      String finalUserId = user.uid;

      if (firestoreData != null && firestoreData['displayName'] != null) {
        // Firestoreにデータがある場合
        finalUserName = firestoreData['displayName'] as String;

        // ローカルと異なる場合は更新
        if (finalUserName != localUserName) {
          Log.info(
              '📥 [PROFILE SYNC] Firestoreからローカルに同期: ${AppLogger.maskName(finalUserName)}');
          await UserPreferencesService.saveUserName(finalUserName);
        } else {
          Log.info('✅ [PROFILE SYNC] ユーザー名は既に同期済み');
        }
      } else if (localUserName != null && localUserName.isNotEmpty) {
        // Firestoreにデータがなく、ローカルにある場合
        finalUserName = localUserName;
        Log.info(
            '📤 [PROFILE SYNC] ローカルからFirestoreに同期: ${AppLogger.maskName(finalUserName)}');
        await userDoc.set({
          'displayName': finalUserName,
          'email': finalUserEmail,
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
        Log.info(
            '💾 [PROFILE SYNC] ユーザーIDを保存: ${AppLogger.maskUserId(finalUserId)}');
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

      // 🔥 REMOVED: デフォルトグループ機能廃止 - 初回セットアップ画面表示
      Log.info('✅ [INIT] 初回セットアップ画面へ');

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

      Log.info(
          '✅ [FIRESTORE] グループに削除フラグを設定: ${AppLogger.maskGroupId(groupId)}');
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
      // 新パス構造: SharedGroupsルートコレクションを使用
      final SharedGroupsRef = firestore.collection('SharedGroups');
      final repository = _ref.read(SharedGroupRepositoryProvider);

      final allHiveGroups = await repository.getAllGroups();
      int syncedCount = 0;

      for (final group in allHiveGroups) {
        // 削除済みグループはFirestoreに同期しない
        if (group.isDeleted) {
          Log.info('🗑️ [SYNC] 削除済みグループはスキップ: ${group.groupId}');
          continue;
        }

        final docRef = SharedGroupsRef.doc(group.groupId);

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
      Log.info('🔑 [SYNC] ユーザーUID: ${AppLogger.maskUserId(user.uid)}');
      Log.info('📧 [SYNC] ユーザーEmail: ${user.email}');

      final firestore = FirebaseFirestore.instance;

      // SharedGroupsルートコレクションからallowedUidでフィルタ
      final SharedGroupsRef = firestore.collection('SharedGroups');

      Log.info('🔍 [SYNC] Firestoreクエリ実行中...');
      Log.info('   collection: SharedGroups');
      Log.info(
          '   where: allowedUid arrayContains ${AppLogger.maskUserId(user.uid)}');

      final snapshot =
          await SharedGroupsRef.where('allowedUid', arrayContains: user.uid)
              .get();

      Log.info('📊 [SYNC] Firestoreクエリ完了: ${snapshot.docs.length}個のグループ');

      // クエリ結果がない場合、全SharedGroupsを確認
      if (snapshot.docs.isEmpty) {
        Log.warning(
            '⚠️ [SYNC] allowedUid=${AppLogger.maskUserId(user.uid)} のグループが見つかりません');
        Log.info('🔍 [SYNC] 全SharedGroupsをチェック...');

        final allSnapshot = await SharedGroupsRef.get();
        Log.info('📊 [SYNC] SharedGroups全体: ${allSnapshot.docs.length}個');

        for (final doc in allSnapshot.docs) {
          final data = doc.data();
          Log.info('  - ID: ${doc.id}');
          Log.info('    groupName: ${data['groupName']}');
          final allowedUidList = data['allowedUid'] as List<dynamic>?;
          Log.info(
              '    allowedUid: ${allowedUidList?.map((uid) => AppLogger.maskUserId(uid.toString())).toList() ?? []}');
          Log.info('    ownerUid: ${data['ownerUid']}');
        }
      }

      final repository = _ref.read(SharedGroupRepositoryProvider);

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
      final hiveRepository = _ref.read(hiveSharedGroupRepositoryProvider);
      final hiveGroups = await hiveRepository.getAllGroups();
      Log.info('📊 [SYNC] Hiveに存在するグループ: ${hiveGroups.length}個');
      for (final hiveGroup in hiveGroups) {
        Log.info(
            '  - ${hiveGroup.groupName} (${hiveGroup.groupId}), syncStatus=${hiveGroup.syncStatus}');
      }

      // ⚠️ STEP1: local状態のグループをFirestoreにアップロード
      // 🔥 CHANGED: デフォルトグループもアップロードする
      int uploadedCount = 0;
      for (final hiveGroup in hiveGroups) {
        if (hiveGroup.syncStatus == models.SyncStatus.local) {
          Log.info(
              '📤 [SYNC] local状態のグループをFirestoreにアップロード: ${hiveGroup.groupName}');
          try {
            await SharedGroupsRef.doc(hiveGroup.groupId).set({
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

          // 🔥 CHANGED: デフォルトグループもFirestore同期する（削除された場合のみ警告）

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
          Log.info('📥 [SYNC] グループ処理開始: ${doc.id}');

          // Firestoreの Timestamp を DateTime に変換してから fromJson を使用
          final convertedData = FirestoreConverter.convertTimestamps(data);

          // SharedGroup.fromJson()を使用してallowedUidを含む全フィールドを正しく復元
          final group = models.SharedGroup.fromJson(convertedData).copyWith(
            groupId: doc.id, // ドキュメントIDを確実に設定
            updatedAt: DateTime.now(),
          );

          Log.info('🔍 [SYNC] グループ同期: ${group.groupName}');
          Log.info('   groupId: ${group.groupId}');
          Log.info(
              '   allowedUid: ${group.allowedUid.map((uid) => AppLogger.maskUserId(uid)).toList()}');
          Log.info('   ownerUid: ${group.ownerUid}');

          // 🔥 CRITICAL FIX: Hiveにのみ保存（Firestoreへの逆書き込みを防ぐ）
          if (repository is FirestoreSharedGroupRepository) {
            // Hive Boxに直接書き込む
            final SharedGroupBox = _ref.read(SharedGroupBoxProvider);
            Log.info('💾 [SYNC] Hive Box に直接保存: ${group.groupId}');
            await SharedGroupBox.put(group.groupId, group);
            Log.info('✅ [SYNC] HiveのみにGroup保存（Firestore書き戻し回避）');
          } else {
            // HiveRepositoryの場合は通常のupdateを使用
            Log.info('💾 [SYNC] HiveRepository経由で保存: ${group.groupId}');
            await repository.updateGroup(group.groupId, group);
            Log.info('✅ [SYNC] HiveRepository経由で保存完了');
          }
          syncedCount++;
        } catch (e, stack) {
          Log.error('❌ [SYNC] グループ同期エラー（${doc.id}）: $e');
          Log.error('Stack trace: $stack');
        }
      }

      Log.info(
          '✅ [SYNC] Firestore→Hive同期完了: $syncedCount 同期, $skippedCount スキップ');
    } catch (e) {
      Log.error('❌ [SYNC] Firestore→Hive同期エラー: $e');
    }
  }

  /// 🆕 バックグラウンドでクリーンアップを実行
  /// アプリ起動時に1回だけ実行し、古い削除済みアイテムを物理削除
  void _performBackgroundCleanup() {
    // バックグラウンドで非同期実行（アプリ起動をブロックしない）
    Future.delayed(const Duration(seconds: 5), () async {
      try {
        Log.info('🧹 [CLEANUP] バックグラウンドクリーンアップ開始');
        final cleanupService = _ref.read(listCleanupServiceProvider);
        final cleanedCount = await cleanupService.cleanupAllLists(
          olderThanDays: 30,
          forceCleanup: false, // needsCleanup判定あり（10個以上のみ）
        );

        if (cleanedCount > 0) {
          Log.info('✅ [CLEANUP] バックグラウンドクリーンアップ完了: $cleanedCount個削除');
        } else {
          Log.info('ℹ️ [CLEANUP] クリーンアップ対象なし');
        }
      } catch (e) {
        Log.warning('⚠️ [CLEANUP] バックグラウンドクリーンアップエラー: $e');
        // エラーでもアプリ動作には影響しない
      }
    });
  }
}
