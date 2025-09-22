// lib/providers/purchase_group_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../models/purchase_group.dart';
import '../flavors.dart';
import '../datastore/purchase_group_repository.dart';
import '../datastore/hive_purchase_group_repository.dart';

final purchaseGroupProvider = StateNotifierProvider<PurchaseGroupNotifier,
 AsyncValue<PurchaseGroup>>((ref) {
  if(F.appFlavor == Flavor.dev) {
    final repository = HivePurchaseGroupRepository(ref);
    return PurchaseGroupNotifier(repository);
  } else {    // 本番環境用のリポジトリを返す
    throw UnimplementedError('Production repository not implemented yet');
  }
 });
 
class PurchaseGroupNotifier extends StateNotifier<AsyncValue<PurchaseGroup>> {
  final PurchaseGroupRepository repository;

  PurchaseGroupNotifier(this.repository) : super(const AsyncValue.loading()) {
    _initializeGroup();
  }

  Future<void> _initializeGroup() async {
    final group = await repository.initializeGroup();
    state = AsyncValue.data(group);
  }

  Future<void> addMember(PurchaseGroupMember member) async {
    final updatedGroup = await repository.addMember(member);
    state = AsyncValue.data(updatedGroup);
  }

  Future<void> removeMember(PurchaseGroupMember member) async {
    final updatedGroup = await repository.removeMember(member);
    state = AsyncValue.data(updatedGroup);
  }
  Future<void> setMemberId(PurchaseGroupMember member, String newId) async {
    final updatedGroup = await repository.setMemberId(member, newId);
    state = AsyncValue.data(updatedGroup);
  }
  Future<String> signedIn({
    required String userName,
    required String email,
    String? groupName
  }) async {
  //
  //
    if (F.appFlavor == Flavor.dev) {
      // 開発環境用のサインイン処理
      // uuidを生成して返す
      return DateTime.now().millisecondsSinceEpoch.toString();
      } else {
      // 本番環境用のサインイン処理
        return 'Error';
      }
  }

  Future<void> updateGroup(PurchaseGroup group) async {
    final updatedGroup = await repository.updateGroup(group);
    state = AsyncValue.data(updatedGroup);
  }
  Future<void> updateMembers(List<PurchaseGroupMember> members) async {
    final updatedGroup = await repository.updateMembers(members);
    state = AsyncValue.data(updatedGroup);
  }
}
