import 'package:hive/hive.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'dart:developer' as developer;
import 'dart:io' show FileSystemException, Platform;
import '../models/shared_group.dart';
import '../datastore/shared_group_repository.dart';
import '../providers/hive_provider.dart';
import '../providers/user_specific_hive_provider.dart';

import '../helpers/validation_service.dart';
import '../utils/app_logger.dart';

class HiveSharedGroupRepository implements SharedGroupRepository {
  // Riverpod Refを使用してBoxにアクセス
  final Ref _ref;

  // コンストラクタでRefを受け取る
  HiveSharedGroupRepository(this._ref);

  // Boxへのアクセスをプロバイダ経由で取得（再試行機能付き安全性チェック）
  Future<Box<SharedGroup>> get _boxAsync async {
    // 最大5回、500ms間隔で再試行
    for (int attempt = 1; attempt <= 10; attempt++) {
      try {
        developer.log('🔍 [HIVE_REPO] _box アクセス開始 (試行 $attempt/10)');

        // Hive初期化が完了しているかチェック
        final isInitialized = _ref.read(hiveInitializationStatusProvider);
        developer.log('🔍 [HIVE_REPO] 初期化状態: $isInitialized');

        if (!isInitialized) {
          if (attempt < 10) {
            // 待機時間を段階的に増加: 500ms → 1000ms → 1500ms...
            final waitMs = attempt * 500;
            developer.log('🔄 [HIVE_REPO] 初期化待機中... ${waitMs}ms後に再試行');
            await Future.delayed(Duration(milliseconds: waitMs));
            continue;
          }
          throw Exception(
              'Hive is not initialized yet after $attempt attempts (waited ${attempt * 500}ms). Please wait for initialization to complete.');
        }

        // Boxが利用可能かチェック
        final isBoxOpen = Hive.isBoxOpen('SharedGroups');
        developer.log('🔍 [HIVE_REPO] Box開いているか: $isBoxOpen');

        if (!isBoxOpen) {
          if (attempt < 10) {
            final waitMs = attempt * 500;
            developer.log('🔄 [HIVE_REPO] Box開封待機中... ${waitMs}ms後に再試行');
            await Future.delayed(Duration(milliseconds: waitMs));
            continue;
          }
          throw StateError(
              'SharedGroup box is not open after $attempt attempts (waited ${attempt * 500}ms). This may occur during app restart.');
        }

        final box = _ref.read(SharedGroupBoxProvider);
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
              '❌ Failed to access SharedGroup box after $attempt attempts: $e');
          rethrow;
        }
        developer.log('❌ Box access error (attempt $attempt): $e - 再試行中...');
        await Future.delayed(const Duration(milliseconds: 500));
      }
    }
    throw Exception('Unexpected error: should not reach here');
  }

  bool _isRecoverableBoxClosedError(Object error) {
    if (error is FileSystemException) {
      return error.message.contains('File closed') ||
          error.toString().contains('File closed');
    }
    final text = error.toString();
    return text.contains('File closed') || text.contains('box is not open');
  }

  Future<void> _recoverSharedGroupsBox() async {
    final hiveService = _ref.read(userSpecificHiveProvider);

    if (Platform.isWindows) {
      final uid = hiveService.currentUserId;
      if (uid != null && uid.isNotEmpty && uid != 'default') {
        await hiveService.initializeForUser(uid);
        return;
      }
    }

    await hiveService.initializeForDefaultUser();
  }

  // CRUDメソッド

  Future<void> saveGroup(SharedGroup group) async {
    try {
      final box = await _boxAsync;
      developer.log(
          '🔍 [HIVE SAVE] groupId: ${group.groupId}, allowedUid: ${group.allowedUid}');
      await box.put(group.groupId, group);
      developer.log(
          '💾 SharedGroup保存完了: ${group.groupName} (${group.members?.length ?? 0}メンバー, allowedUid: ${group.allowedUid.length}個)');
    } on StateError catch (e) {
      developer.log(
          '⚠️ Box not available during saveGroup (app may be restarting): $e');
      rethrow;
    } catch (e) {
      developer.log('❌ SharedGroup保存エラー: $e');
      rethrow;
    }
  }

  @override
  Future<List<SharedGroup>> getAllGroups() async {
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
  @override
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
  Future<SharedGroup> getGroupById(String groupId) async {
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

    // 🔥 REMOVED: デフォルトグループ作成機能削除
    throw Exception('Group not found');
  }

  // 🔥 REMOVED: _createDefaultGroup() - デフォルトグループ機能削除

  @override
  Future<SharedGroup> updateGroup(String groupId, SharedGroup group) async {
    final box = await _boxAsync;
    await box.put(groupId, group);
    return group;
  }

  @override
  Future<SharedGroup> addMember(
      String groupId, SharedGroupMember member) async {
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
  Future<SharedGroup> removeMember(
      String groupId, SharedGroupMember member) async {
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
  Future<SharedGroup> createGroup(
      String groupId, String groupName, SharedGroupMember member) async {
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

        // 🔥 論理削除されたグループを除外して重複チェック
        final activeGroups =
            allGroupsFromBox.where((g) => !g.isDeleted).toList();
        developer.log(
            '🔍 [HIVE_REPO] アクティブグループ数: ${activeGroups.length} (削除済み除外前: ${allGroupsFromBox.length})');

        final validation =
            ValidationService.validateGroupName(groupName, activeGroups);
        if (validation.hasError) {
          developer.log('❌ [HIVE_REPO] グループ名重複エラー: ${validation.errorMessage}');
          throw Exception(validation.errorMessage);
        }
        developer.log('✅ [HIVE_REPO] グループ名重複チェック完了 - OK');
      }

      developer.log('🔍 [HIVE_REPO] SharedGroup作成開始');

      // SharedGroup.create()ファクトリーを使用してallowedUidを自動設定
      final newGroup = SharedGroup.create(
        groupId: groupId,
        groupName: groupName,
        members: [member],
      ).copyWith(
        syncStatus: SyncStatus.local, // ⚠️ ローカル専用グループとして作成
      );
      developer.log(
          '✅ [HIVE_REPO] SharedGroupオブジェクト作成完了 (syncStatus=local, allowedUid=[${member.memberId}])');

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
  Future<SharedGroup> deleteGroup(String groupId) async {
    for (int attempt = 1; attempt <= 2; attempt++) {
      try {
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
        final isRetryable = _isRecoverableBoxClosedError(e);
        if (isRetryable && attempt < 2) {
          developer.log(
              '⚠️ [HIVE_REPO] deleteGroupでBox close検知。Hive再初期化後にリトライします: $e');
          await _recoverSharedGroupsBox();
          continue;
        }

        developer.log('❌ グループ削除エラー: $e');
        rethrow;
      }
    }

    throw Exception('Unexpected deleteGroup retry flow');
  }

  @override
  Future<SharedGroup> setMemberId(
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

  Future<SharedGroup> updateMembers(
      String groupId, List<SharedGroupMember> members) async {
    final box = await _boxAsync;
    final group = box.get(groupId);
    if (group != null) {
      final updatedGroup = group.copyWith(members: members);
      await box.put(groupId, updatedGroup);
      return updatedGroup;
    }
    throw Exception('Group not found');
  }

  Future<SharedGroup> getGroup(String groupId) async {
    return await getGroupById(groupId);
  }

  // 招待によるメンバー追加（メールアドレスベース）
  Future<SharedGroup> addMemberByInvitation({
    required String groupId,
    required String uid,
    required String email,
    required String name,
    required SharedGroupRole role,
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
        final updatedMembers = List<SharedGroupMember>.from(group.members!);
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
        final newMember = SharedGroupMember(
          memberId: uid,
          name: name,
          contact: email,
          role: role,
          isSignedIn: true,
        );

        final updatedMembers = <SharedGroupMember>[
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
  Future<SharedGroup> addPendingMember({
    required String groupId,
    required String email,
    required String name,
    required SharedGroupRole role,
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

      final pendingMember = SharedGroupMember(
        memberId: tempMemberId,
        name: name,
        contact: email,
        role: role,
        isSignedIn: false, // 招待ペンディング状態
      );

      final updatedMembers = <SharedGroupMember>[
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
  Future<SharedGroup> getOrCreateMemberPool() async {
    try {
      const poolGroupId = '__member_pool__';
      final box = await _boxAsync;
      final existingPool = box.get(poolGroupId);

      if (existingPool != null) {
        return existingPool;
      }

      // 新しいメンバープールを作成
      const memberPool = SharedGroup(
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
      final Map<String, SharedGroupMember> uniqueMembers = {};

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
  Future<List<SharedGroupMember>> searchMembersInPool(String query) async {
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
  Future<SharedGroupMember?> findMemberByEmail(String email) async {
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

// HiveSharedGroupRepositoryのプロバイダー
final hiveSharedGroupRepositoryProvider =
    Provider<HiveSharedGroupRepository>((ref) {
  return HiveSharedGroupRepository(ref);
});

// 現在のグループIDプロバイダー（デフォルトグループ用）
final currentGroupIdProvider = Provider<String>((ref) => 'default_group');
