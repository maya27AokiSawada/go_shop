import 'package:hive/hive.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:developer' as developer;
import '../models/purchase_group.dart';
import '../datastore/purchase_group_repository.dart';
import '../providers/hive_provider.dart';
import '../flavors.dart';

class HivePurchaseGroupRepository implements PurchaseGroupRepository {
  // Riverpod Refを使用してBoxにアクセス
  final Ref _ref;

  // コンストラクタでRefを受け取る
  HivePurchaseGroupRepository(this._ref);

  // Boxへのアクセスをプロバイダ経由で取得
  Box<PurchaseGroup> get _box => _ref.read(purchaseGroupBoxProvider);

  // CRUDメソッド
  Future<void> saveGroup(PurchaseGroup group) async {
    try {
      await _box.put(group.groupId, group);
      developer.log('💾 PurchaseGroup保存: ${group.groupName} (${group.members?.length ?? 0}メンバー)');
    } catch (e) {
      developer.log('❌ PurchaseGroup保存エラー: $e');
      rethrow;
    }
  }

  @override
  Future<List<PurchaseGroup>> getAllGroups() async {
    try {
      final groups = _box.values.toList();
      developer.log('📋 全グループ取得: ${groups.length}グループ');
      return groups;
    } catch (e) {
      developer.log('❌ 全グループ取得エラー: $e');
      rethrow;
    }
  }

  @override
  Future<PurchaseGroup> getGroupById(String groupId) async {
    final group =  _box.get(groupId);
    if (group != null) {
      return group;
    }
    
    // デフォルトグループが存在しない場合は作成
    if (groupId == 'defaultGroup') {
      return await _createDefaultGroup();
    }
    
    throw Exception('Group not found');
  }

  // デフォルトグループを作成
  Future<PurchaseGroup> _createDefaultGroup() async {
    const defaultGroup = PurchaseGroup(
      groupId: 'defaultGroup',
      groupName: 'デフォルトグループ',
      ownerName: 'デフォルトユーザー',
      ownerEmail: 'default@example.com',
      ownerUid: 'defaultUser',
      members: [
        PurchaseGroupMember(
          memberId: 'defaultUser',
          name: 'デフォルトユーザー',
          contact: 'default@example.com',
          role: PurchaseGroupRole.owner,
          isSignedIn: true,
        ),
      ],
    );
    
    await _box.put('defaultGroup', defaultGroup);
    return defaultGroup;
  }

  @override
  Future<PurchaseGroup> updateGroup(String groupId, PurchaseGroup group) async {
    await _box.put(groupId, group);
    return group;
  }

  @override
  Future<PurchaseGroup> addMember(String groupId, PurchaseGroupMember member) async {
    try {
      final group = _box.get(groupId);
      if (group == null) {
        throw Exception('Group not found: $groupId');
      }
      
      // 重複メンバーチェック
      final memberExists = group.members?.any(
        (existingMember) => existingMember.memberId == member.memberId || 
                           existingMember.contact == member.contact,
      ) ?? false;
      
      if (memberExists) {
        throw Exception('Member already exists: ${member.name}');
      }
      
      final updatedGroup = group.addMember(member);
      await _box.put(groupId, updatedGroup);
      developer.log('👥 メンバー追加: ${member.name} to ${group.groupName}');
      return updatedGroup;
    } catch (e) {
      developer.log('❌ メンバー追加エラー: $e');
      rethrow;
    }
  }

  @override
  Future<PurchaseGroup> removeMember(String groupId, PurchaseGroupMember member) async {
    try {
      final group = _box.get(groupId);
      if (group == null) {
        throw Exception('Group not found: $groupId');
      }
      
      // メンバー存在チェック
      final memberExists = group.members?.any(
        (existingMember) => existingMember.memberId == member.memberId,
      ) ?? false;
      
      if (!memberExists) {
        throw Exception('Member not found: ${member.name}');
      }
      
      final updatedGroup = group.removeMember(member);
      await _box.put(groupId, updatedGroup);
      developer.log('🚫 メンバー削除: ${member.name} from ${group.groupName}');
      return updatedGroup;
    } catch (e) {
      developer.log('❌ メンバー削除エラー: $e');
      rethrow;
    }
  }

  @override
  Future<PurchaseGroup> createGroup(String groupId, String groupName, PurchaseGroupMember member) async {
    try {
      // 既存グループチェック
      final existingGroup = _box.get(groupId);
      if (existingGroup != null) {
        throw Exception('Group already exists: $groupId');
      }
      
      final newGroup = PurchaseGroup(
        groupId: groupId,
        groupName: groupName,
        ownerUid: member.memberId,
        ownerName: member.name,
        ownerEmail: member.contact,
        members: [member],
      );
      await _box.put(groupId, newGroup);
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
      if (groupId == 'defaultGroup') {
        throw Exception('Cannot delete default group');
      }
      
      final group = _box.get(groupId);
      if (group == null) {
        throw Exception('Group not found: $groupId');
      }
      
      await _box.delete(groupId);
      developer.log('🚫 グループ削除: ${group.groupName} ($groupId)');
      return group;
    } catch (e) {
      developer.log('❌ グループ削除エラー: $e');
      rethrow;
    }
  }

  @override
  Future<PurchaseGroup> setMemberId(String oldId, String newId, String? contact) async {
    try {
      const groupId = 'defaultGroup';
      final group = _box.get(groupId);
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
      await _box.put(groupId, updatedGroup);
      return updatedGroup;
    } catch (e) {
      developer.log('❌ MemberID更新エラー: $e');
      rethrow;
    }
  }

  Future<PurchaseGroup> updateMembers(String groupId, List<PurchaseGroupMember> members) async {
    final group = _box.get(groupId);
    if (group != null) {
      final updatedGroup = group.copyWith(members: members);
      await _box.put(groupId, updatedGroup);
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
      final group = _box.get(groupId);
      if (group == null) throw Exception('Group not found: $groupId');
      
      // 既にメールアドレスで仮メンバーが存在するかチェック
      final existingMemberIndex = group.members?.indexWhere(
        (member) => member.contact == email,
      ) ?? -1;

      if (existingMemberIndex >= 0) {
        // 既存の仮メンバーをアクティブ化
        final updatedMembers = List<PurchaseGroupMember>.from(group.members!);
        updatedMembers[existingMemberIndex] = updatedMembers[existingMemberIndex].copyWith(
          memberId: uid,
          name: name,
          isSignedIn: true,
        );
        
        final updatedGroup = group.copyWith(members: updatedMembers);
        await _box.put(groupId, updatedGroup);
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
        
        final updatedMembers = <PurchaseGroupMember>[...(group.members ?? []), newMember];
        final updatedGroup = group.copyWith(members: updatedMembers);
        await _box.put(groupId, updatedGroup);
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
      final group = _box.get(groupId);
      if (group == null) throw Exception('Group not found: $groupId');
      
      // 既にメンバーが存在するかチェック
      final memberExists = group.members?.any(
        (member) => member.contact == email,
      ) ?? false;

      if (memberExists) {
        throw Exception('Member already exists: $email');
      }

      // 仮のmemberIdを生成
      final tempMemberId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
      
      final pendingMember = PurchaseGroupMember(
        memberId: tempMemberId,
        name: name,
        contact: email,
        role: role,
        isSignedIn: false, // 招待ペンディング状態
      );
      
      final updatedMembers = <PurchaseGroupMember>[...(group.members ?? []), pendingMember];
      final updatedGroup = group.copyWith(members: updatedMembers);
      await _box.put(groupId, updatedGroup);
      developer.log('📨 仮メンバー追加: $name ($email) - 招待ペンディング');
      return updatedGroup;
    } catch (e) {
      developer.log('❌ 仮メンバー追加エラー: $e');
      rethrow;
    }
  }
}

// HivePurchaseGroupRepositoryのプロバイダー
final hivePurchaseGroupRepositoryProvider = Provider<HivePurchaseGroupRepository>((ref) {
  return HivePurchaseGroupRepository(ref);
});

// 抽象インターフェース用のプロバイダー（フレーバー切り替え対応）
final purchaseGroupRepositoryProvider = Provider<PurchaseGroupRepository>((ref) {
  if (F.appFlavor == Flavor.prod) {
    // 本番環境: Firestore + Hive hybrid repository （TODO: 実装予定）
    // return FirestorePurchaseGroupRepository(ref);
    throw UnimplementedError('FirestorePurchaseGroupRepository integration not implemented yet');
  } else {
    // 開発環境: Hiveのみ
    return ref.read(hivePurchaseGroupRepositoryProvider);
  }
});

// 現在のグループIDプロバイダー（デフォルトグループ用）
final currentGroupIdProvider = Provider<String>((ref) => 'defaultGroup');

// デフォルトグループ保存用のプロバイダー
final saveDefaultGroupProvider = FutureProvider.family<void, PurchaseGroup>((ref, group) async {
  final repository = ref.read(purchaseGroupRepositoryProvider);
  await repository.updateGroup(group.groupId, group);
});
