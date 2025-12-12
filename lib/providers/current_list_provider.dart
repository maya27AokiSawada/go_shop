// lib/providers/current_list_provider.dart
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/shared_list.dart';
import '../utils/app_logger.dart';

/// 現在選択されている買い物リストを管理するProvider
class CurrentListNotifier extends StateNotifier<SharedList?> {
  static const String _currentListIdKey = 'current_list_id'; // 後方互換用（非推奨）
  static const String _groupListMapKey = 'group_list_map'; // グループごとの最終使用リストマップ

  CurrentListNotifier() : super(null);

  /// リストを選択（グループIDと紐付けて保存）
  Future<void> selectList(SharedList list, {String? groupId}) async {
    Log.info('📝 カレントリストを設定: ${list.listName} (${list.listId})');
    Log.info('🔧 [DEBUG] selectList - groupId: $groupId');
    state = list;

    // グループIDが指定されている場合はマップに保存
    if (groupId != null) {
      await _saveListForGroup(groupId, list.listId);
    } else {
      Log.info('⚠️ [DEBUG] groupIdがnullなので後方互換モードで保存');
      // 後方互換用：グループIDがない場合は従来の方法で保存
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_currentListIdKey, list.listId);
        Log.info('✅ カレントリストIDを保存（後方互換）: ${list.listId}');
      } catch (e) {
        Log.error('❌ カレントリストID保存エラー: $e');
      }
    }
  }

  /// グループごとにリストIDを保存
  Future<void> _saveListForGroup(String groupId, String listId) async {
    try {
      Log.info(
          '🔧 [DEBUG] _saveListForGroup開始 - groupId: $groupId, listId: $listId');
      final prefs = await SharedPreferences.getInstance();

      // 既存のマップを取得
      final mapJson = prefs.getString(_groupListMapKey);
      Log.info('🔧 [DEBUG] 既存のマップJSON: $mapJson');
      final Map<String, String> groupListMap =
          mapJson != null ? Map<String, String>.from(json.decode(mapJson)) : {};

      // グループのリストIDを更新
      groupListMap[groupId] = listId;
      Log.info('🔧 [DEBUG] 更新後のマップ: $groupListMap');

      // マップを保存
      final savedJson = json.encode(groupListMap);
      await prefs.setString(_groupListMapKey, savedJson);
      Log.info('🔧 [DEBUG] 保存したJSON: $savedJson');
      Log.info('✅ グループ[$groupId]の最終使用リストを保存: $listId');
    } catch (e) {
      Log.error('❌ グループリストマップ保存エラー: $e');
    }
  }

  /// グループの最終使用リストIDを取得
  Future<String?> getSavedListIdForGroup(String groupId) async {
    try {
      Log.info('🔍 [DEBUG] getSavedListIdForGroup開始 - groupId: $groupId');
      final prefs = await SharedPreferences.getInstance();
      final mapJson = prefs.getString(_groupListMapKey);
      Log.info('🔍 [DEBUG] 取得したマップJSON: $mapJson');

      if (mapJson != null) {
        final Map<String, String> groupListMap =
            Map<String, String>.from(json.decode(mapJson));
        Log.info('🔍 [DEBUG] デコード後のマップ: $groupListMap');
        final listId = groupListMap[groupId];

        if (listId != null) {
          Log.info('📖 グループ[$groupId]の最終使用リスト取得: $listId');
          return listId;
        }
      }

      Log.info('💡 グループ[$groupId]の最終使用リスト情報なし');
      return null;
    } catch (e) {
      Log.error('❌ グループリストマップ取得エラー: $e');
      return null;
    }
  }

  /// 保存されているリストIDを取得（後方互換用）
  Future<String?> getSavedListId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_currentListIdKey);
    } catch (e) {
      Log.error('❌ カレントリストID取得エラー: $e');
      return null;
    }
  }

  /// リスト選択をクリア
  void clearSelection() {
    Log.info('🔄 カレントリストをクリア');
    state = null;
  }

  /// 特定グループの最終使用リストをクリア（新規グループ作成時用）
  Future<void> clearListForGroup(String groupId) async {
    try {
      Log.info('🔄 [CLEAR] グループ[$groupId]の最終使用リストをクリア開始');
      final prefs = await SharedPreferences.getInstance();

      // 既存のマップを取得
      final mapJson = prefs.getString(_groupListMapKey);
      if (mapJson != null) {
        final Map<String, String> groupListMap =
            Map<String, String>.from(json.decode(mapJson));

        // 該当グループのエントリを削除
        groupListMap.remove(groupId);

        // 更新したマップを保存
        await prefs.setString(_groupListMapKey, json.encode(groupListMap));
        Log.info('✅ [CLEAR] グループ[$groupId]の最終使用リストをクリア完了');
      } else {
        Log.info('💡 [CLEAR] マップが存在しないため、クリア不要');
      }

      // stateもクリア
      if (state != null) {
        Log.info('🔄 [CLEAR] state = null に設定');
        state = null;
      }
    } catch (e) {
      Log.error('❌ [CLEAR] グループリストマップクリアエラー: $e');
    }
  }

  /// リスト内容を更新（SharedPreferencesにも保存）
  Future<void> updateList(SharedList updatedList, {String? groupId}) async {
    Log.info('🔄 カレントリストを更新: ${updatedList.listName}');
    state = updatedList;

    // グループIDが指定されている場合はマップに保存
    if (groupId != null) {
      await _saveListForGroup(groupId, updatedList.listId);
    } else {
      // 後方互換用：グループIDがない場合は従来の方法で保存
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_currentListIdKey, updatedList.listId);
        Log.info('✅ カレントリストID更新保存（後方互換）: ${updatedList.listId}');
      } catch (e) {
        Log.error('❌ カレントリストID更新保存エラー: $e');
      }
    }
  }
}

final currentListProvider =
    StateNotifierProvider<CurrentListNotifier, SharedList?>((ref) {
  return CurrentListNotifier();
});
