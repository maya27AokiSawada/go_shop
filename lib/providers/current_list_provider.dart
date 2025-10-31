// lib/providers/current_list_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/shopping_list.dart';
import '../utils/app_logger.dart';

/// 現在選択されている買い物リストを管理するProvider
class CurrentListNotifier extends StateNotifier<ShoppingList?> {
  static const String _currentListIdKey = 'current_list_id';

  CurrentListNotifier() : super(null);

  /// リストを選択
  Future<void> selectList(ShoppingList list) async {
    Log.info('📝 カレントリストを設定: ${list.listName} (${list.listId})');
    state = list;

    // SharedPreferencesに保存
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_currentListIdKey, list.listId);
      Log.info('✅ カレントリストIDを保存: ${list.listId}');
    } catch (e) {
      Log.error('❌ カレントリストID保存エラー: $e');
    }
  }

  /// 保存されているリストIDを取得
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

  /// リスト内容を更新（SharedPreferencesにも保存）
  Future<void> updateList(ShoppingList updatedList) async {
    Log.info('🔄 カレントリストを更新: ${updatedList.listName}');
    state = updatedList;

    // SharedPreferencesにも保存
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_currentListIdKey, updatedList.listId);
      Log.info('✅ カレントリストID更新保存: ${updatedList.listId}');
    } catch (e) {
      Log.error('❌ カレントリストID更新保存エラー: $e');
    }
  }
}

final currentListProvider =
    StateNotifierProvider<CurrentListNotifier, ShoppingList?>((ref) {
  return CurrentListNotifier();
});
