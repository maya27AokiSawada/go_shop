// テスト用のグループデータを作成するスクリプト
import '../services/hive_initialization_service.dart';
import '../models/shared_group.dart';
import '../datastore/hive_purchase_group_repository.dart';
import '../utils/app_logger.dart';
import '../flavors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() async {
  F.appFlavor = Flavor.dev;

  // Hive初期化
  await HiveInitializationService.initialize();

  // テスト用のコンテナ
  final container = ProviderContainer();

  try {
    final groupRepo = HiveSharedGroupRepository(container as Ref);

    // テスト用グループを作成
    final testGroups = [
      SharedGroup.create(
        groupName: '家族グループ',
        members: [
          const SharedGroupMember(
            memberId: 'test_user',
            name: 'テストユーザー',
            contact: '',
            role: SharedGroupRole.owner,
          ),
          const SharedGroupMember(
            memberId: 'family_member',
            name: '家族メンバー',
            contact: '',
            role: SharedGroupRole.member,
          ),
        ],
      ),
      SharedGroup.create(
        groupName: '友達グループ',
        members: [
          const SharedGroupMember(
            memberId: 'test_user',
            name: 'テストユーザー',
            contact: '',
            role: SharedGroupRole.owner,
          ),
          const SharedGroupMember(
            memberId: 'friend1',
            name: '友達1',
            contact: '',
            role: SharedGroupRole.member,
          ),
        ],
      ),
      SharedGroup.create(
        groupName: '職場グループ',
        members: [
          const SharedGroupMember(
            memberId: 'test_user',
            name: 'テストユーザー',
            contact: '',
            role: SharedGroupRole.owner,
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
