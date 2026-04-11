import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../utils/app_logger.dart';

/// デバイス固有IDサービス
/// グループIDとリストIDの衝突を防ぐため、デバイス識別子プレフィックスを提供
class DeviceIdService {
  static const String _prefixKey = 'device_id_prefix';
  static String? _cachedPrefix;

  /// デバイスIDプレフィックスを取得（8文字）
  ///
  /// 例: "a3f8c9d2" (Android), "win7a2c4" (Windows), "ios9f3e1" (iOS)
  ///
  /// プラットフォーム別の実装:
  /// - Android: androidId（ファクトリーリセットで変更）
  /// - iOS: identifierForVendor（アプリ削除で変更）
  /// - Windows/Linux/macOS: SharedPreferences永続UUID
  static Future<String> getDevicePrefix() async {
    // キャッシュがあれば返す
    if (_cachedPrefix != null) {
      return _cachedPrefix!;
    }

    try {
      final prefs = await SharedPreferences.getInstance();

      // SharedPreferencesに既に保存されている場合は再利用
      final savedPrefix = prefs.getString(_prefixKey);
      if (savedPrefix != null && savedPrefix.length == 8) {
        AppLogger.info(
            '📱 [DEVICE_ID] SharedPreferencesからデバイスプレフィックス取得: $savedPrefix');
        _cachedPrefix = savedPrefix;
        return savedPrefix;
      }

      // プラットフォーム別にデバイスIDを取得
      String prefix;
      final deviceInfo = DeviceInfoPlugin();

      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        final androidId = androidInfo.id; // Android固有ID

        // androidIdの最初の8文字を使用（短縮）。8文字未満の場合は全文字を使用
        final useLength = androidId.length >= 8 ? 8 : androidId.length;
        prefix = _sanitizePrefix(androidId.substring(0, useLength));
        AppLogger.info(
            '📱 [DEVICE_ID] Android ID取得: $androidId → プレフィックス: $prefix');
      } else if (Platform.isIOS) {
        try {
          final iosInfo = await deviceInfo.iosInfo;
          final vendorId = iosInfo.identifierForVendor;

          if (vendorId != null && vendorId.isNotEmpty) {
            // vendorIdの最初の8文字を使用（ハイフン除去）
            final cleanId = vendorId.replaceAll('-', '');
            if (cleanId.length >= 8) {
              prefix = _sanitizePrefix(cleanId.substring(0, 8));
              AppLogger.info(
                  '📱 [DEVICE_ID] iOS Vendor ID取得: $vendorId → プレフィックス: $prefix');
            } else {
              // vendorIdが短すぎる場合はフォールバック
              throw Exception('iOS Vendor ID too short: $vendorId');
            }
          } else {
            // vendorIdがnullの場合はフォールバック
            throw Exception('iOS Vendor ID is null');
          }
        } catch (iosError) {
          // iOS固有エラー時のフォールバック: iOS + UUID
          final uuid = const Uuid().v4().replaceAll('-', '');
          prefix = 'ios${uuid.substring(0, 5)}'; // "ios" + 5文字 = 8文字
          AppLogger.warning(
              '⚠️ [DEVICE_ID] iOS Vendor ID取得失敗、フォールバック使用: $iosError');
          AppLogger.info('📱 [DEVICE_ID] iOS フォールバックUUID生成: $prefix');
        }
      } else if (Platform.isWindows) {
        // Windows: SharedPreferences永続UUID生成
        final uuid = const Uuid().v4().replaceAll('-', '');
        prefix = 'win${uuid.substring(0, 5)}'; // "win" + 5文字 = 8文字
        AppLogger.info('📱 [DEVICE_ID] Windows UUID生成: $prefix');
      } else if (Platform.isLinux) {
        // Linux: SharedPreferences永続UUID生成
        final uuid = const Uuid().v4().replaceAll('-', '');
        prefix = 'lnx${uuid.substring(0, 5)}'; // "lnx" + 5文字 = 8文字
        AppLogger.info('📱 [DEVICE_ID] Linux UUID生成: $prefix');
      } else if (Platform.isMacOS) {
        // macOS: SharedPreferences永続UUID生成
        final uuid = const Uuid().v4().replaceAll('-', '');
        prefix = 'mac${uuid.substring(0, 5)}'; // "mac" + 5文字 = 8文字
        AppLogger.info('📱 [DEVICE_ID] macOS UUID生成: $prefix');
      } else {
        // その他のプラットフォーム: UUID生成
        final uuid = const Uuid().v4().replaceAll('-', '');
        prefix = uuid.substring(0, 8);
        AppLogger.info('📱 [DEVICE_ID] 不明なプラットフォーム - UUID生成: $prefix');
      }

      // SharedPreferencesに保存（永続化）
      await prefs.setString(_prefixKey, prefix);
      AppLogger.info('✅ [DEVICE_ID] デバイスプレフィックスをSharedPreferencesに保存: $prefix');

      _cachedPrefix = prefix;
      return prefix;
    } catch (e, stackTrace) {
      AppLogger.error('❌ [DEVICE_ID] デバイスID取得エラー: $e');
      AppLogger.error('📄 [DEVICE_ID] StackTrace: $stackTrace');

      // エラー時はフォールバック: ランダムUUID
      final fallbackPrefix =
          const Uuid().v4().replaceAll('-', '').substring(0, 8);
      AppLogger.info('⚠️ [DEVICE_ID] フォールバックUUID使用: $fallbackPrefix');

      // SharedPreferencesに保存して次回起動でも同じIDを使う
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_prefixKey, fallbackPrefix);
      } catch (_) {}

      _cachedPrefix = fallbackPrefix;
      return fallbackPrefix;
    }
  }

  /// グループIDを生成（デバイスプレフィックス + タイムスタンプ）
  ///
  /// 例: "a3f8c9d2_1707835200000"
  static Future<String> generateGroupId() async {
    final prefix = await getDevicePrefix();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final groupId = '${prefix}_$timestamp';

    AppLogger.info('🆕 [DEVICE_ID] グループID生成: $groupId');
    return groupId;
  }

  /// リストIDを生成（デバイスプレフィックス + UUID短縮版）
  ///
  /// 例: "a3f8c9d2_f3e1a7b4"
  static Future<String> generateListId() async {
    final prefix = await getDevicePrefix();
    final uuid = const Uuid().v4().replaceAll('-', '').substring(0, 8);
    final listId = '${prefix}_$uuid';

    AppLogger.info('🆕 [DEVICE_ID] リストID生成: $listId');
    return listId;
  }

  /// プレフィックスをサニタイズ（英数字のみ、小文字化）
  static String _sanitizePrefix(String input) {
    final sanitized = input.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    final length = sanitized.length < 8 ? sanitized.length : 8;
    // サニタイズ後の文字列の長さを基準にsubstringを呼び出す
    return sanitized.substring(0, length);
  }

  /// キャッシュをクリア（テスト用）
  static void clearCache() {
    _cachedPrefix = null;
    AppLogger.info('🗑️ [DEVICE_ID] キャッシュクリア');
  }
}
