import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/whiteboard.dart';
import '../utils/app_logger.dart';

class PersonalWhiteboardCacheService {
  static final Map<String, Whiteboard> _memoryCache = {};
  static final Map<String, Set<String>> _pendingStrokeIdsMemoryCache = {};
  static const String _cachePrefix = 'personal_whiteboard_cache:';
  static const String _pendingStrokeIdsPrefix =
      'personal_whiteboard_pending_stroke_ids:';

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

  static Future<void> clearWhiteboard(String cacheKey) async {
    _memoryCache.remove(cacheKey);

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('$_cachePrefix$cacheKey');
    } catch (e) {
      AppLogger.warning('⚠️ [PERSONAL_WB] ホワイトボードキャッシュ削除失敗: $e');
    }
  }

  static Set<String> getMemoryCachedPendingStrokeIds(String cacheKey) {
    return Set<String>.from(_pendingStrokeIdsMemoryCache[cacheKey] ?? const {});
  }

  static Future<Set<String>> loadPendingStrokeIds(String cacheKey) async {
    final memoryCached = _pendingStrokeIdsMemoryCache[cacheKey];
    if (memoryCached != null) {
      return Set<String>.from(memoryCached);
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final strokeIds =
          prefs.getStringList('$_pendingStrokeIdsPrefix$cacheKey');
      final restored = Set<String>.from(strokeIds ?? const <String>[]);
      _pendingStrokeIdsMemoryCache[cacheKey] = restored;
      return Set<String>.from(restored);
    } catch (e) {
      AppLogger.warning('⚠️ [PERSONAL_WB] 未保存strokeId読込失敗: $e');
      return <String>{};
    }
  }

  static Future<void> savePendingStrokeIds(
    String cacheKey,
    Iterable<String> strokeIds,
  ) async {
    final normalized = Set<String>.from(strokeIds);
    _pendingStrokeIdsMemoryCache[cacheKey] = normalized;

    try {
      final prefs = await SharedPreferences.getInstance();
      if (normalized.isEmpty) {
        await prefs.remove('$_pendingStrokeIdsPrefix$cacheKey');
        return;
      }

      await prefs.setStringList(
        '$_pendingStrokeIdsPrefix$cacheKey',
        normalized.toList(growable: false),
      );
    } catch (e) {
      AppLogger.warning('⚠️ [PERSONAL_WB] 未保存strokeId保存失敗: $e');
    }
  }

  static Future<void> clearPendingStrokeIds(String cacheKey) async {
    _pendingStrokeIdsMemoryCache.remove(cacheKey);

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('$_pendingStrokeIdsPrefix$cacheKey');
    } catch (e) {
      AppLogger.warning('⚠️ [PERSONAL_WB] 未保存strokeId削除失敗: $e');
    }
  }

  static Future<void> clearAllCaches() async {
    _memoryCache.clear();
    _pendingStrokeIdsMemoryCache.clear();

    try {
      final prefs = await SharedPreferences.getInstance();
      final keysToRemove = prefs.getKeys().where((key) {
        return key.startsWith(_cachePrefix) ||
            key.startsWith(_pendingStrokeIdsPrefix);
      }).toList(growable: false);

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
