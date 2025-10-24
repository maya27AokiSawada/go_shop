// テスト用のグループデータを作成するスクリプト
import '../services/hive_initialization_service.dart';
import '../models/purchase_group.dart';
import '../models/shopping_list.dart';
import '../datastore/hive_purchase_group_repository.dart';
import '../datastore/hive_shopping_list_repository.dart';
import '../utils/app_logger.dart';
import '../flavors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() async {
  F.appFlavor = Flavor.dev;

  // Hive初期化
  await HiveInitializationService.initialize();

  // テスト用のコンテナ
  final container = ProviderContainer();

  try {
    final groupRepo = HivePurchaseGroupRepository(container.ref);

    // テスト用グループを作成
    final testGroups = [
      PurchaseGroup.create(
        groupId: 'family_group',
        groupName: '家族グループ',
        ownerUid: 'test_user',
        description: 'テスト用の家族グループ',
        members: [
          PurchaseGroupMember(
            memberId: 'test_user',
            name: 'テストユーザー',
            role: PurchaseGroupRole.admin,
          ),
          PurchaseGroupMember(
            memberId: 'family_member',
            name: '家族メンバー',
            role: PurchaseGroupRole.member,
          ),
        ],
      ),
      PurchaseGroup.create(
        groupId: 'friends_group',
        groupName: '友達グループ',
        ownerUid: 'test_user',
        description: 'テスト用の友達グループ',
        members: [
          PurchaseGroupMember(
            memberId: 'test_user',
            name: 'テストユーザー',
            role: PurchaseGroupRole.admin,
          ),
          PurchaseGroupMember(
            memberId: 'friend1',
            name: '友達1',
            role: PurchaseGroupRole.member,
          ),
        ],
      ),
      PurchaseGroup.create(
        groupId: 'work_group',
        groupName: '職場グループ',
        ownerUid: 'test_user',
        description: 'テスト用の職場グループ',
        members: [
          PurchaseGroupMember(
            memberId: 'test_user',
            name: 'テストユーザー',
            role: PurchaseGroupRole.admin,
          ),
        ],
      ),
    ];

    // グループを保存
    for (final group in testGroups) {
      await groupRepo.saveGroup(group);
      Log.info('✅ テストグループ作成: ${group.groupName} (${group.groupId})');
    }

    Log.info('🎉 テスト用グループデータの作成完了！');
    Log.info('シークレットモード機能のテストが可能になりました。');

    // 作成されたグループを確認
    final allGroups = await groupRepo.getAllGroups();
    Log.info('📊 総グループ数: ${allGroups.length}');
    for (final group in allGroups) {
      Log.info('  - ${group.groupName} (${group.groupId})');
    }
  } catch (e, stackTrace) {
    Log.error('❌ エラー: $e');
    Log.error('スタックトレース: $stackTrace');
  } finally {
    container.dispose();
  }
}
