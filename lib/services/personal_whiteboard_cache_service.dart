import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/whiteboard.dart';
import '../utils/app_logger.dart';

class PersonalWhiteboardCacheService {
  static final Map<String, Whiteboard> _memoryCache = {};
  static const String _cachePrefix = 'personal_whiteboard_cache:';

  static String buildCacheKey({
    required String currentUserId,
    required String groupId,
    required String memberId,
  }) {
    return '$currentUserId:$groupId:$memberId';
  }

  static Whiteboard? getMemoryCachedWhiteboard(String cacheKey) {
    return _memoryCache[cacheKey];
  }

  static Future<Whiteboard?> loadWhiteboard(String cacheKey) async {
    final memoryCached = _memoryCache[cacheKey];
    if (memoryCached != null) {
      return memoryCached;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString('$_cachePrefix$cacheKey');
      if (json == null || json.isEmpty) {
        return null;
      }

      final whiteboard = Whiteboard.fromJson(
        Map<String, dynamic>.from(jsonDecode(json) as Map),
      );
      _memoryCache[cacheKey] = whiteboard;
      return whiteboard;
    } catch (e) {
      AppLogger.warning('⚠️ [PERSONAL_WB] キャッシュ読込失敗: $e');
      return null;
    }
  }

  static Future<void> saveWhiteboard(
    String cacheKey,
    Whiteboard whiteboard,
  ) async {
    _memoryCache[cacheKey] = whiteboard;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        '$_cachePrefix$cacheKey',
        jsonEncode(whiteboard.toJson()),
      );
    } catch (e) {
      AppLogger.warning('⚠️ [PERSONAL_WB] キャッシュ保存失敗: $e');
    }
  }

  static Future<void> clearAllCaches() async {
    _memoryCache.clear();

    try {
      final prefs = await SharedPreferences.getInstance();
      final keysToRemove = prefs
          .getKeys()
          .where((key) => key.startsWith(_cachePrefix))
          .toList(growable: false);

      for (final key in keysToRemove) {
        await prefs.remove(key);
      }

      AppLogger.info(
        '🧹 [PERSONAL_WB] 個人ホワイトボードキャッシュ削除完了: ${keysToRemove.length}件',
      );
    } catch (e) {
      AppLogger.warning('⚠️ [PERSONAL_WB] キャッシュ削除失敗: $e');
    }
  }
}
