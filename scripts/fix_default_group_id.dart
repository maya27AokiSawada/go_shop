// fix_default_group_id.dart - デフォルトグループIDをタイムスタンプからUIDに修正

import 'package:hive_flutter/hive_flutter.dart';
import 'package:go_shop/models/shared_group.dart';
import 'package:go_shop/services/user_specific_hive_service.dart';

Future<void> main() async {
  await Hive.initFlutter();

  // Register all adapters
  await UserSpecificHiveService.initializeAdapters();

  print('📋 デフォルトグループID修正スクリプト開始');
  print('─────────────────────────────────────');

  // Open SharedGroup box
  final box = await Hive.openBox<SharedGroup>('sharedGroups');

  print('\n🔍 現在のグループ一覧:');
  for (var i = 0; i < box.length; i++) {
    final group = box.getAt(i);
    if (group != null) {
      print('  [$i] ${group.groupName} (${group.groupId})');
      print('      ownerUid: ${group.ownerUid}');
      print('      allowedUid: ${group.allowedUid}');
      print('      syncStatus: ${group.syncStatus}');
      print('      isDeleted: ${group.isDeleted}');
    }
  }

  // Find groups with timestamp-style IDs (numeric only)
  final problematicGroups = <int, SharedGroup>{};

  for (var i = 0; i < box.length; i++) {
    final group = box.getAt(i);
    if (group != null && !group.isDeleted) {
      // Check if groupId is all digits (timestamp)
      if (RegExp(r'^\d+$').hasMatch(group.groupId)) {
        problematicGroups[i] = group;
      }
    }
  }

  if (problematicGroups.isEmpty) {
    print('\n✅ 修正が必要なグループはありません');
    await box.close();
    return;
  }

  print('\n⚠️  修正が必要なグループ (タイムスタンプID):');
  for (var entry in problematicGroups.entries) {
    final group = entry.value;
    print('  [${entry.key}] ${group.groupName} (${group.groupId})');
    print('      ownerUid: ${group.ownerUid}');

    // Determine correct groupId
    String? correctGroupId;
    if (group.allowedUid.isNotEmpty) {
      correctGroupId = group.allowedUid.first;
    } else if (group.ownerUid?.isNotEmpty ?? false) {
      correctGroupId = group.ownerUid;
    } else if (group.members?.isNotEmpty ?? false) {
      correctGroupId = group.members!.first.memberId;
    }

    if (correctGroupId == null || correctGroupId.isEmpty) {
      print('      ❌ 修正用UIDが見つかりません - スキップ');
      continue;
    }

    print('      ✅ 修正後のgroupId: $correctGroupId');

    // Create corrected group
    final correctedGroup = group.copyWith(
      groupId: correctGroupId,
      syncStatus: SyncStatus.local, // Force local to avoid Firestore conflicts
    );

    // Update in Hive
    await box.putAt(entry.key, correctedGroup);
    print('      ✅ Hiveに保存完了');
  }

  print('\n✅ 修正完了！');
  print('─────────────────────────────────────');
  print('\n🔍 修正後のグループ一覧:');
  for (var i = 0; i < box.length; i++) {
    final group = box.getAt(i);
    if (group != null) {
      print('  [$i] ${group.groupName} (${group.groupId})');
      print('      ownerUid: ${group.ownerUid}');
      print('      syncStatus: ${group.syncStatus}');
    }
  }

  await box.close();
  print('\n✅ スクリプト終了');
}
