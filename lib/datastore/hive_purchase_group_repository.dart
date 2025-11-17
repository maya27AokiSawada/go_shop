import 'package:hive/hive.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'dart:developer' as developer;
import '../models/purchase_group.dart';
import '../models/user_settings.dart';
import '../datastore/purchase_group_repository.dart';
import '../providers/hive_provider.dart';
import '../providers/user_specific_hive_provider.dart';
import '../flavors.dart';
import '../helpers/validation_service.dart';
import '../utils/app_logger.dart';

class HivePurchaseGroupRepository implements PurchaseGroupRepository {
  // Riverpod Refを使用してBoxにアクセス
  final Ref _ref;

  // コンストラクタでRefを受け取る
  HivePurchaseGroupRepository(this._ref);

  // Boxへのアクセスをプロバイダ経由で取得（再試行機能付き安全性チェック）
  Future<Box<PurchaseGroup>> get _boxAsync async {
    // 最大5回、500ms間隔で再試行
    for (int attempt = 1; attempt <= 5; attempt++) {
      try {
        developer.log('🔍 [HIVE_REPO] _box アクセス開始 (試行 $attempt/5)');

        // Hive初期化が完了しているかチェック
        final isInitialized = _ref.read(hiveInitializationStatusProvider);
        developer.log('🔍 [HIVE_REPO] 初期化状態: $isInitialized');

        if (!isInitialized) {
          if (attempt < 5) {
            developer.log('🔄 [HIVE_REPO] 初期化待機中... ${attempt * 500}ms後に再試行');
            await Future.delayed(const Duration(milliseconds: 500));
            continue;
          }
          throw Exception(
              'Hive is not initialized yet after $attempt attempts. Please wait for initialization to complete.');
        }

        // Boxが利用可能かチェック
        final isBoxOpen = Hive.isBoxOpen('purchaseGroups');
        developer.log('🔍 [HIVE_REPO] Box開いているか: $isBoxOpen');

        if (!isBoxOpen) {
          if (attempt < 5) {
            developer.log('🔄 [HIVE_REPO] Box開封待機中... ${attempt * 500}ms後に再試行');
            await Future.delayed(const Duration(milliseconds: 500));
            continue;
          }
          throw StateError(
              'PurchaseGroup box is not open after $attempt attempts. This may occur during app restart.');
        }

        final box = _ref.read(purchaseGroupBoxProvider);
        developer.log('✅ [HIVE_REPO] Box取得成功 (試行 $attempt/5)');
        return box;
      } on StateError catch (e) {
        if (attempt == 5) {
          developer.log('⚠️ Box state error after $attempt attempts: $e');
          rethrow;
        }
        developer.log('⚠️ Box state error (attempt $attempt): $e - 再試行中...');
        await Future.delayed(const Duration(milliseconds: 500));
      } catch (e) {
        if (attempt == 5) {
          developer.log(
              '❌ Failed to access PurchaseGroup box after $attempt attempts: $e');
          rethrow;
        }
        developer.log('❌ Box access error (attempt $attempt): $e - 再試行中...');
        await Future.delayed(const Duration(milliseconds: 500));
      }
    }
    throw Exception('Unexpected error: should not reach here');
  }

  // CRUDメソッド

  Future<void> saveGroup(PurchaseGroup group) async {
    try {
      final box = await _boxAsync;
      developer.log(
          '🔍 [HIVE SAVE] groupId: ${group.groupId}, allowedUid: ${group.allowedUid}');
      await box.put(group.groupId, group);
      developer.log(
          '💾 PurchaseGroup保存完了: ${group.groupName} (${group.members?.length ?? 0}メンバー, allowedUid: ${group.allowedUid.length}個)');
    } on StateError catch (e) {
      developer.log(
          '⚠️ Box not available during saveGroup (app may be restarting): $e');
      rethrow;
    } catch (e) {
      developer.log('❌ PurchaseGroup保存エラー: $e');
      rethrow;
    }
  }

  @override
  Future<List<PurchaseGroup>> getAllGroups() async {
    try {
      // 安全なBox取得（再試行機能付き）
      final box = await _boxAsync;
      final groups = box.values.toList();

      // デバッグ: 全グループの削除フラグを確認
      developer.log('🔍 [HIVE_REPO] Box内の全グループ (${groups.length}個):');
      Log.info('🔍 [HIVE_REPO] Box内の全グループ (${groups.length}個):');
      for (final group in groups) {
        developer.log(
            '  - ${group.groupName} (${group.groupId}): isDeleted=${group.isDeleted}, allowedUid=${group.allowedUid}');
        Log.info(
            '  - ${group.groupName} (${group.groupId}): isDeleted=${group.isDeleted}, allowedUid=${group.allowedUid}');
      }

      // 隠しグループと削除済みグループを除外
      final visibleGroups = groups
          .where(
              (group) => group.groupId != '__member_pool__' && !group.isDeleted)
          .toList();

      developer.log(
          '📋 [HIVE_REPO] getAllGroups: ${visibleGroups.length}グループ取得 (削除済み除外)');
      Log.info(
          '📋 [HIVE_REPO] getAllGroups: ${visibleGroups.length}グループ取得 (削除済み除外)');

      return visibleGroups;
    } on StateError catch (e) {
      developer.log(
          '⚠️ Box not available during getAllGroups (app may be restarting): $e');
      return []; // 空のリストを返してクラッシュを防ぐ
    } catch (e) {
      developer.log('❌ 全グループ取得エラー: $e');
      rethrow;
    }
  }

  /// 削除済みHiveデータを物理削除してデータベースを最適化
  Future<int> cleanupDeletedGroups() async {
    try {
      final box = await _boxAsync;
      final allGroups = box.values.toList();

      final deletedGroups =
          allGroups.where((group) => group.isDeleted).toList();

      if (deletedGroups.isEmpty) {
        Log.info('✅ [CLEANUP] 削除済みグループなし');
        return 0;
      }

      Log.info('🧹 [CLEANUP] ${deletedGroups.length}個の削除済みグループを物理削除します');

      int count = 0;
      for (final group in deletedGroups) {
        try {
          await box.delete(group.groupId);
          count++;
          Log.info('  ✓ 削除: ${group.groupName} (${group.groupId})');
        } catch (e) {
          Log.error('  ✗ エラー: ${group.groupName} - $e');
        }
      }

      // Box最適化
      await box.compact();
      Log.info('✅ [CLEANUP] $count個削除、Box最適化完了');

      return count;
    } catch (e) {
      Log.error('❌ [CLEANUP] クリーンアップエラー: $e');
      return 0;
    }
  }

  @override
  Future<PurchaseGroup> getGroupById(String groupId) async {
    developer.log('🔍 [HIVE] グループ検索開始: $groupId');

    // 安全なBox取得（再試行機能付き）
    final box = await _boxAsync;
    developer.log('🔍 [HIVE] 利用可能なキー: ${box.keys.toList()}');

    final group = box.get(groupId);
    if (group != null) {
      developer.log('✅ [HIVE] グループ見つかりました: ${group.groupName}');
      return group;
    }

    developer.log('❌ [HIVE] グループが見つかりません: $groupId');

    // デフォルトグループが存在しない場合は作成
    if (groupId == 'default_group') {
      return await _createDefaultGroup();
    }

    throw Exception('Group not found');
  }

  // デフォルトグループを作成
  Future<PurchaseGroup> _createDefaultGroup() async {
    // UserSettingsから現在のユーザー情報を取得
    final userSettingsBox = Hive.box<UserSettings>('userSettings');
    final userSettings = userSettingsBox.get('settings');

    final userName = (userSettings?.userName.isNotEmpty == true)
        ? userSettings!.userName
        : 'デフォルトユーザー';
    final userEmail = (userSettings?.userEmail.isNotEmpty == true)
        ? userSettings!.userEmail
        : 'default@example.com';

    final defaultGroup = PurchaseGroup(
      groupId: 'default_group',
      groupName: 'デフォルトグループ',
      ownerName: userName,
      ownerEmail: userEmail,
      ownerUid: 'defaultUser',
      members: [
        PurchaseGroupMember(
          memberId: 'defaultUser',
          name: userName,
          contact: userEmail,
          role: PurchaseGroupRole.owner,
          isSignedIn: true,
        ),
      ],
    );

    // 安全なBox取得（再試行機能付き）
    final box = await _boxAsync;
    await box.put('default_group', defaultGroup);
    return defaultGroup;
  }

  @override
  Future<PurchaseGroup> updateGroup(String groupId, PurchaseGroup group) async {
    final box = await _boxAsync;
    await box.put(groupId, group);
    return group;
  }

  @override
  Future<PurchaseGroup> addMember(
      String groupId, PurchaseGroupMember member) async {
    try {
      final box = await _boxAsync;
      final group = box.get(groupId);
      if (group == null) {
        throw Exception('Group not found: $groupId');
      }

      // ValidationServiceを使った重複チェック
      final emailValidation = ValidationService.validateMemberEmail(
          member.contact, group.members ?? []);
      if (emailValidation.hasError) {
        throw Exception(emailValidation.errorMessage);
      }

      final nameValidation = ValidationService.validateMemberName(
          member.name, group.members ?? []);
      if (nameValidation.hasError) {
        throw Exception(nameValidation.errorMessage);
      }

      final updatedGroup = group.addMember(member);
      await box.put(groupId, updatedGroup);
      developer.log('👥 メンバー追加: ${member.name} to ${group.groupName}');
      return updatedGroup;
    } catch (e) {
      developer.log('❌ メンバー追加エラー: $e');
      rethrow;
    }
  }

  @override
  Future<PurchaseGroup> removeMember(
      String groupId, PurchaseGroupMember member) async {
    try {
      final box = await _boxAsync;
      final group = box.get(groupId);
      if (group == null) {
        throw Exception('Group not found: $groupId');
      }

      // メンバー存在チェック
      final memberExists = group.members?.any(
            (existingMember) => existingMember.memberId == member.memberId,
          ) ??
          false;

      if (!memberExists) {
        throw Exception('Member not found: ${member.name}');
      }

      final updatedGroup = group.removeMember(member);
      await box.put(groupId, updatedGroup);
      developer.log('🚫 メンバー削除: ${member.name} from ${group.groupName}');
      return updatedGroup;
    } catch (e) {
      developer.log('❌ メンバー削除エラー: $e');
      rethrow;
    }
  }

  @override
  Future<PurchaseGroup> createGroup(
      String groupId, String groupName, PurchaseGroupMember member) async {
    try {
      developer.log('🆕 [HIVE_REPO] createGroup開始: $groupId, $groupName');
      developer.log('🔍 [HIVE_REPO] 安全なBoxアクセス開始...');

      // 安全なBox取得（再試行機能付き）
      final box = await _boxAsync;
      developer.log('✅ [HIVE_REPO] 安全なBoxアクセス成功');

      // 既存グループチェック
      developer.log('🔍 [HIVE_REPO] 既存グループチェック開始...');
      final existingGroup = box.get(groupId);
      developer.log('✅ [HIVE_REPO] 既存グループチェック完了');
      developer.log('🔍 [HIVE_REPO] 既存グループ存在: ${existingGroup != null}');

      if (existingGroup != null) {
        throw Exception('Group already exists: $groupId');
      }

      // グループ名の重複チェック（デフォルトグループ以外）
      // デッドロック回避: box.valuesから直接取得して重複チェック
      if (groupId != 'default_group') {
        developer.log('🔍 [HIVE_REPO] グループ名重複チェック開始');
        final allGroupsFromBox = box.values.toList();
        final validation =
            ValidationService.validateGroupName(groupName, allGroupsFromBox);
        if (validation.hasError) {
          developer.log('❌ [HIVE_REPO] グループ名重複エラー: ${validation.errorMessage}');
          throw Exception(validation.errorMessage);
        }
        developer.log('✅ [HIVE_REPO] グループ名重複チェック完了 - OK');
      }

      developer.log('🔍 [HIVE_REPO] PurchaseGroup作成開始');

      // PurchaseGroup.create()ファクトリーを使用してallowedUidを自動設定
      final newGroup = PurchaseGroup.create(
        groupId: groupId,
        groupName: groupName,
        members: [member],
      ).copyWith(
        syncStatus: SyncStatus.local, // ⚠️ ローカル専用グループとして作成
      );
      developer.log(
          '✅ [HIVE_REPO] PurchaseGroupオブジェクト作成完了 (syncStatus=local, allowedUid=[${member.memberId}])');

      developer.log('🔍 [HIVE_REPO] Box.put()実行開始');
      await box.put(groupId, newGroup);
      developer.log('✅ [HIVE_REPO] Box.put()実行完了');

      developer.log('🆕 グループ作成: $groupName ($groupId)');
      return newGroup;
    } catch (e) {
      developer.log('❌ グループ作成エラー: $e');
      rethrow;
    }
  }

  @override
  Future<PurchaseGroup> deleteGroup(String groupId) async {
    try {
      // デフォルトグループは削除不可
      if (groupId == 'default_group') {
        throw Exception('Cannot delete default group');
      }

      final box = await _boxAsync;
      final group = box.get(groupId);
      if (group == null) {
        throw Exception('Group not found: $groupId');
      }

      // 論理削除: isDeletedフラグを立てる（物理削除はしない）
      final deletedGroup = group.copyWith(
        isDeleted: true,
        updatedAt: DateTime.now(),
      );
      await box.put(groupId, deletedGroup);

      // 確認のため保存後のデータを取得
      final savedGroup = box.get(groupId);
      developer.log('🚫 グループを論理削除: ${group.groupName} ($groupId)');
      Log.warning('🚫 [HIVE_REPO] グループを論理削除: ${group.groupName} ($groupId)');
      Log.warning('   スタックトレース: ${StackTrace.current}');
      developer.log('   保存前 isDeleted: ${group.isDeleted}');
      developer.log('   保存後 isDeleted: ${savedGroup?.isDeleted}');

      return deletedGroup;
    } catch (e) {
      developer.log('❌ グループ削除エラー: $e');
      rethrow;
    }
  }

  @override
  Future<PurchaseGroup> setMemberId(
      String oldId, String newId, String? contact) async {
    try {
      const groupId = 'default_group';
      final box = await _boxAsync;
      final group = box.get(groupId);
      if (group == null) {
        throw Exception('Default group not found');
      }

      final updatedMembers = group.members?.map((member) {
        if (member.memberId == oldId || member.contact == contact) {
          developer.log('🔄 MemberID更新: ${member.name} ($oldId → $newId)');
          return member.copyWith(memberId: newId, isSignedIn: true);
        }
        return member;
      }).toList();

      final updatedGroup = group.copyWith(members: updatedMembers);
      await box.put(groupId, updatedGroup);
      return updatedGroup;
    } catch (e) {
      developer.log('❌ MemberID更新エラー: $e');
      rethrow;
    }
  }

  Future<PurchaseGroup> updateMembers(
      String groupId, List<PurchaseGroupMember> members) async {
    final box = await _boxAsync;
    final group = box.get(groupId);
    if (group != null) {
      final updatedGroup = group.copyWith(members: members);
      await box.put(groupId, updatedGroup);
      return updatedGroup;
    }
    throw Exception('Group not found');
  }

  Future<PurchaseGroup> getGroup(String groupId) async {
    return await getGroupById(groupId);
  }

  // 招待によるメンバー追加（メールアドレスベース）
  Future<PurchaseGroup> addMemberByInvitation({
    required String groupId,
    required String uid,
    required String email,
    required String name,
    required PurchaseGroupRole role,
  }) async {
    try {
      final box = await _boxAsync;
      final group = box.get(groupId);
      if (group == null) throw Exception('Group not found: $groupId');

      // 既にメールアドレスで仮メンバーが存在するかチェック
      final existingMemberIndex = group.members?.indexWhere(
            (member) => member.contact == email,
          ) ??
          -1;

      if (existingMemberIndex >= 0) {
        // 既存の仮メンバーをアクティブ化
        final updatedMembers = List<PurchaseGroupMember>.from(group.members!);
        updatedMembers[existingMemberIndex] =
            updatedMembers[existingMemberIndex].copyWith(
          memberId: uid,
          name: name,
          isSignedIn: true,
        );

        final updatedGroup = group.copyWith(members: updatedMembers);
        await box.put(groupId, updatedGroup);
        developer.log('🎉 仮メンバーアクティビーション: $name ($email)');
        return updatedGroup;
      } else {
        // 新規メンバーとして追加
        final newMember = PurchaseGroupMember(
          memberId: uid,
          name: name,
          contact: email,
          role: role,
          isSignedIn: true,
        );

        final updatedMembers = <PurchaseGroupMember>[
          ...(group.members ?? []),
          newMember
        ];
        final updatedGroup = group.copyWith(members: updatedMembers);
        await box.put(groupId, updatedGroup);
        developer.log('👥 新規招待メンバー: $name ($email)');
        return updatedGroup;
      }
    } catch (e) {
      developer.log('❌ 招待メンバー追加エラー: $e');
      rethrow;
    }
  }

  // 仮メンバーを作成（招待送信時）
  Future<PurchaseGroup> addPendingMember({
    required String groupId,
    required String email,
    required String name,
    required PurchaseGroupRole role,
  }) async {
    try {
      final box = await _boxAsync;
      final group = box.get(groupId);
      if (group == null) throw Exception('Group not found: $groupId');

      // 既にメンバーが存在するかチェック
      final memberExists = group.members?.any(
            (member) => member.contact == email,
          ) ??
          false;

      if (memberExists) {
        throw Exception('Member already exists: $email');
      }

      // 仮のmemberIdを生成（UUIDベース）
      final tempMemberId = 'temp_${const Uuid().v4()}';

      final pendingMember = PurchaseGroupMember(
        memberId: tempMemberId,
        name: name,
        contact: email,
        role: role,
        isSignedIn: false, // 招待ペンディング状態
      );

      final updatedMembers = <PurchaseGroupMember>[
        ...(group.members ?? []),
        pendingMember
      ];
      final updatedGroup = group.copyWith(members: updatedMembers);
      await box.put(groupId, updatedGroup);
      developer.log('📨 仮メンバー追加: $name ($email) - 招待ペンディング');
      return updatedGroup;
    } catch (e) {
      developer.log('❌ 仮メンバー追加エラー: $e');
      rethrow;
    }
  }

  // ============ メンバープール管理メソッド ============

  /// 隠しグループ（メンバープール）の取得・作成
  @override
  Future<PurchaseGroup> getOrCreateMemberPool() async {
    try {
      const poolGroupId = '__member_pool__';
      final box = await _boxAsync;
      final existingPool = box.get(poolGroupId);

      if (existingPool != null) {
        return existingPool;
      }

      // 新しいメンバープールを作成
      const memberPool = PurchaseGroup(
        groupId: poolGroupId,
        groupName: 'Member Pool (Hidden)',
        ownerUid: 'system',
        ownerName: 'System',
        ownerEmail: 'system@app.local',
        members: [],
      );

      await box.put(poolGroupId, memberPool);
      developer.log('🔒 メンバープール作成完了');
      return memberPool;
    } catch (e) {
      developer.log('❌ メンバープール取得エラー: $e');
      rethrow;
    }
  }

  /// すべてのグループから一意のメンバーを収集してプールに追加
  @override
  Future<void> syncMemberPool() async {
    try {
      final allGroups = await getAllGroups();
      final memberPool = await getOrCreateMemberPool();

      // 全グループから一意のメンバーを収集
      final Map<String, PurchaseGroupMember> uniqueMembers = {};

      for (final group in allGroups) {
        // 隠しグループは除外
        if (group.groupId == '__member_pool__') continue;

        if (group.members != null) {
          for (final member in group.members!) {
            // メールアドレスでユニーク性を判定
            if (member.contact.isNotEmpty) {
              uniqueMembers[member.contact] = member;
            }
          }
        }
      }

      // プールを更新
      final updatedPool = memberPool.copyWith(
        members: uniqueMembers.values.toList(),
      );

      final box = await _boxAsync;
      await box.put('__member_pool__', updatedPool);
      developer.log('🔄 メンバープール同期完了: ${uniqueMembers.length}件');
    } catch (e) {
      developer.log('❌ メンバープール同期エラー: $e');
      rethrow;
    }
  }

  /// メンバープール内でメンバーを検索
  @override
  Future<List<PurchaseGroupMember>> searchMembersInPool(String query) async {
    try {
      final memberPool = await getOrCreateMemberPool();
      final members = memberPool.members ?? [];

      if (query.isEmpty) {
        return members;
      }

      // 名前または連絡先で部分一致検索
      return members
          .where((member) =>
              member.name.toLowerCase().contains(query.toLowerCase()) ||
              member.contact.toLowerCase().contains(query.toLowerCase()))
          .toList();
    } catch (e) {
      developer.log('❌ プール内検索エラー: $e');
      return [];
    }
  }

  /// プール内でメールアドレスからメンバーを検索
  @override
  Future<PurchaseGroupMember?> findMemberByEmail(String email) async {
    try {
      final memberPool = await getOrCreateMemberPool();
      final members = memberPool.members ?? [];

      for (final member in members) {
        if (member.contact.toLowerCase() == email.toLowerCase()) {
          return member;
        }
      }
      return null;
    } catch (e) {
      developer.log('❌ メールアドレス検索エラー: $e');
      return null;
    }
  }
}

// HivePurchaseGroupRepositoryのプロバイダー
final hivePurchaseGroupRepositoryProvider =
    Provider<HivePurchaseGroupRepository>((ref) {
  return HivePurchaseGroupRepository(ref);
});

// 抽象インターフェース用のプロバイダー（フレーバー切り替え対応）
final purchaseGroupRepositoryProvider =
    Provider<PurchaseGroupRepository>((ref) {
  if (F.appFlavor == Flavor.prod) {
    // 本番環境: 現在はHiveを使用（Firestore連携は将来実装予定）
    return ref.read(hivePurchaseGroupRepositoryProvider);
  } else {
    // 開発環境: Hiveのみ
    return ref.read(hivePurchaseGroupRepositoryProvider);
  }
});

// 現在のグループIDプロバイダー（デフォルトグループ用）
final currentGroupIdProvider = Provider<String>((ref) => 'default_group');

// デフォルトグループ保存用のプロバイダー
final saveDefaultGroupProvider =
    FutureProvider.family<void, PurchaseGroup>((ref, group) async {
  final repository = ref.read(purchaseGroupRepositoryProvider);
  await repository.updateGroup(group.groupId, group);
});
