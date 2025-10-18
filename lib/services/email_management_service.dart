// lib/services/email_management_service.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import '../providers/device_settings_provider.dart';

final emailManagementServiceProvider = Provider<EmailManagementService>((ref) {
  return EmailManagementService(ref);
});

/// メールアドレスの保存・読み込みを管理するサービス
class EmailManagementService {
  final Ref _ref;
  final Logger _logger = Logger();

  EmailManagementService(this._ref);

  /// 保存されたメールアドレスを読み込む
  Future<SavedEmailResult> loadSavedEmail() async {
    try {
      final deviceSettings = _ref.read(deviceSettingsServiceProvider);
      final savedEmail = await deviceSettings.getSavedEmail();
      
      if (savedEmail != null && savedEmail.isNotEmpty) {
        _logger.i('📧 保存されたメールアドレスを復元: $savedEmail');
        return SavedEmailResult(
          email: savedEmail,
          shouldRemember: true,
        );
      }
      
      return SavedEmailResult(
        email: null,
        shouldRemember: false,
      );
    } catch (e) {
      _logger.e('❌ メールアドレス読み込みエラー: $e');
      return SavedEmailResult(
        email: null,
        shouldRemember: false,
      );
    }
  }

  /// メールアドレスを保存または削除
  Future<void> saveOrClearEmail({
    required String email,
    required bool shouldRemember,
  }) async {
    try {
      final deviceSettings = _ref.read(deviceSettingsServiceProvider);
      
      if (shouldRemember && email.isNotEmpty) {
        await deviceSettings.saveEmail(email);
        _logger.i('💾 メールアドレスを保存: $email');
      } else {
        await deviceSettings.clearSavedEmail();
        _logger.i('🗑️ 保存されたメールアドレスを削除');
      }
    } catch (e) {
      _logger.e('❌ メールアドレス保存エラー: $e');
      rethrow;
    }
  }

  /// メールアドレスを保存（簡易版）
  Future<void> saveEmail(String email) async {
    await saveOrClearEmail(email: email, shouldRemember: true);
  }

  /// 保存されたメールアドレスを削除
  Future<void> clearEmail() async {
    await saveOrClearEmail(email: '', shouldRemember: false);
  }
}

/// 保存されたメールアドレスの読み込み結果
class SavedEmailResult {
  final String? email;
  final bool shouldRemember;

  SavedEmailResult({
    required this.email,
    required this.shouldRemember,
  });
}
