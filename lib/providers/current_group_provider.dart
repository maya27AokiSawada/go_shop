// lib/providers/current_group_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/purchase_group.dart';
import '../utils/app_logger.dart';

/// 現在選択されているグループを管理するProvider
class CurrentGroupNotifier extends StateNotifier<PurchaseGroup?> {
  static const String _currentGroupIdKey = 'current_group_id';

  CurrentGroupNotifier() : super(null);

  /// グループを選択
  Future<void> selectGroup(PurchaseGroup group) async {
    Log.info('📦 カレントグループを設定: ${group.groupName} (${group.groupId})');
    state = group;

    // SharedPreferencesに保存（アプリ再起動時に復元）
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_currentGroupIdKey, group.groupId);
      Log.info('✅ カレントグループIDを保存: ${group.groupId}');
    } catch (e) {
      Log.error('❌ カレントグループID保存エラー: $e');
    }
  }

  /// 保存されているグループIDを取得
  Future<String?> getSavedGroupId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_currentGroupIdKey);
    } catch (e) {
      Log.error('❌ カレントグループID取得エラー: $e');
      return null;
    }
  }

  /// グループ選択をクリア
  void clearSelection() {
    Log.info('🔄 カレントグループをクリア');
    state = null;
  }
}

final currentGroupProvider =
    StateNotifierProvider<CurrentGroupNotifier, PurchaseGroup?>((ref) {
  return CurrentGroupNotifier();
});
