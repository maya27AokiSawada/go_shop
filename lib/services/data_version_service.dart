import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'user_preferences_service.dart';

/// データバージョン管理サービス
/// 
/// 【開発段階】: バージョン不一致時は削除&新規作成
/// 【Playストア公開時】: データマイグレーション機能を追加予定
/// 
/// 予定機能:
/// - InvitationStatus.pending をデフォルト値として既存データに設定
/// - 既存メンバーのroleに基づいてinvitationStatusを適切に設定  
/// - データ構造の段階的変換機能
/// - 失敗時のロールバック機能
class DataVersionService {
  static const String _dataVersionKey = 'data_version';
  static const int _currentDataVersion = 2; // invitationStatus追加により2に変更
  
  final Logger _logger = Logger();
  
  /// 現在のデータバージョンを取得
  static int get currentDataVersion => _currentDataVersion;
  
  /// 保存されているデータバージョンを取得
  Future<int> getSavedDataVersion() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final version = prefs.getInt(_dataVersionKey) ?? 1; // デフォルトは1
      _logger.i('📊 保存されているデータバージョン: $version');
      return version;
    } catch (e) {
      _logger.e('❌ データバージョン取得エラー: $e');
      return 1; // エラー時はバージョン1とみなす
    }
  }
  
  /// データバージョンを保存
  Future<void> saveDataVersion(int version) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_dataVersionKey, version);
      _logger.i('✅ データバージョン保存完了: $version');
    } catch (e) {
      _logger.e('❌ データバージョン保存エラー: $e');
    }
  }
  
  /// データバージョンをチェックし、必要に応じて古いデータを削除
  Future<bool> checkAndMigrateData() async {
    try {
      // SharedPreferences経由でデータバージョンを管理
      final savedVersion = await UserPreferencesService.getDataVersion();
      final currentVersion = currentDataVersion;
      
      _logger.i('🔍 データバージョンチェック: 保存済み=$savedVersion, 現在=$currentVersion');
      
      if (savedVersion < currentVersion) {
        _logger.w('⚠️ データバージョンが古いため、データを削除して新規作成します');
        _logger.i('🔮 TODO: Playストア公開時にマイグレーション機能を実装予定');
        _logger.i('   - v1→v2: InvitationStatus.pendingをデフォルト値として設定');
        _logger.i('   - 既存メンバーのroleベースでinvitationStatus適切設定');
        _logger.i('   - データ構造の段階的変換とロールバック機能');
        
        await _clearAllHiveData();
        await UserPreferencesService.clearAllUserInfo(); // ユーザー名とメールもクリア
        await UserPreferencesService.saveDataVersion(currentVersion);
        return true; // データ削除が実行された
      } else if (savedVersion > currentVersion) {
        _logger.w('⚠️ 保存されているデータバージョンが新しすぎます。現在バージョンに合わせます');
        await _clearAllHiveData();
        await UserPreferencesService.clearAllUserInfo(); // ユーザー名とメールもクリア
        await UserPreferencesService.saveDataVersion(currentVersion);
        return true; // データ削除が実行された
      } else {
        _logger.i('✅ データバージョンは最新です');
        return false; // データ削除は不要
      }
    } catch (e) {
      _logger.e('❌ データバージョンチェックエラー: $e');
      return false;
    }
  }
  
  /// 全てのHiveデータを削除 (開発段階用)
  /// 
  /// 【Playストア公開時】に以下のマイグレーション機能を追加:
  /// - _migrateFromV1ToV2(): InvitationStatus追加マイグレーション
  /// - _migrateFromV2ToV3(): 将来の機能追加時のマイグレーション
  /// - _backupDataBeforeMigration(): マイグレーション前のデータバックアップ
  /// - _rollbackOnFailure(): マイグレーション失敗時のロールバック
  Future<void> _clearAllHiveData() async {
    try {
      _logger.i('🗑️ 古いHiveデータを削除中...');
      
      // 各Boxを削除
      final boxNames = [
        'purchaseGroupBox',
        'shoppingListBox',
        'shoppingItemBox',
        'memberPoolBox',
      ];
      
      for (final boxName in boxNames) {
        try {
          if (Hive.isBoxOpen(boxName)) {
            final box = Hive.box(boxName);
            await box.clear();
            _logger.i('✅ $boxName を削除しました');
          }
        } catch (e) {
          _logger.w('⚠️ $boxName の削除でエラー: $e');
        }
      }
      
      _logger.i('✅ 全てのHiveデータ削除完了');
    } catch (e) {
      _logger.e('❌ Hiveデータ削除エラー: $e');
    }
  }
  
  /// 開発用：データバージョンをリセット
  Future<void> resetDataVersion() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_dataVersionKey);
      _logger.i('🔄 データバージョンをリセットしました');
    } catch (e) {
      _logger.e('❌ データバージョンリセットエラー: $e');
    }
  }

  // ===== Playストア公開時に実装予定の機能 =====
  
  /// データマイグレーション機能 (Playストア公開時実装予定)
  /// 
  /// 段階的なマイグレーション戦略:
  /// 1. データバックアップ作成
  /// 2. バージョン別マイグレーション実行
  /// 3. 検証とエラーハンドリング
  /// 4. 失敗時のロールバック
  /*
  Future<bool> _executeDataMigration(int fromVersion, int toVersion) async {
    try {
      _logger.i('🔄 データマイグレーション開始: v$fromVersion → v$toVersion');
      
      // 1. バックアップ作成
      await _backupDataBeforeMigration();
      
      // 2. バージョン別マイグレーション
      for (int version = fromVersion; version < toVersion; version++) {
        await _migrateFromVersionToNext(version);
      }
      
      // 3. 検証
      final isValid = await _validateMigratedData();
      if (!isValid) {
        await _rollbackOnFailure();
        return false;
      }
      
      await saveDataVersion(toVersion);
      _logger.i('✅ データマイグレーション完了');
      return true;
      
    } catch (e) {
      _logger.e('❌ データマイグレーションエラー: $e');
      await _rollbackOnFailure();
      return false;
    }
  }
  
  /// v1→v2マイグレーション: InvitationStatus追加
  Future<void> _migrateFromV1ToV2() async {
    // 既存のPurchaseGroupMemberにInvitationStatusを追加
    // role基準で適切な値を設定:
    // - owner → InvitationStatus.self
    // - member → InvitationStatus.accepted
  }
  */
}