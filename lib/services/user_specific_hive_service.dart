import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_logger.dart';
import 'dart:io';
import '../models/shared_group.dart';
import '../models/shared_list.dart';
import '../models/user_settings.dart';
import '../models/whiteboard.dart'; // 🆕 Whiteboard用
// import '../models/invitation.dart';  // 削除済み - QRコードシステムに移行
// import '../models/accepted_invitation.dart';  // 削除済み - QRコードシステムに移行

/// UID別のHiveデータベース管理サービス（改良版）
class UserSpecificHiveService {
  static UserSpecificHiveService? _instance;
  static UserSpecificHiveService get instance =>
      _instance ??= UserSpecificHiveService._();

  UserSpecificHiveService._();

  String? _currentUserId;
  bool _isInitialized = false;

  // 前回使用したUIDの保存・復元用キー
  static const String _lastUserIdKey = 'last_used_uid';

  // スキーマバージョンの管理
  static const String _schemaVersionKey = 'hive_schema_version';
  static const int _currentSchemaVersion =
      3; // Version 3: 最低バージョン（v1/v2データはFirestore上に存在しない）

  /// 前回使用したUIDを保存
  Future<void> saveLastUsedUid(String uid) async {
    // 仮設定UIDは保存しない
    if (_isTemporaryUid(uid)) {
      Log.info('🔄 仮設定UID検出 - 保存をスキップ: $uid');
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastUserIdKey, uid);
    Log.info('💾 Last used UID saved: $uid');
  }

  // 仮設定UID（開発・テスト用）かどうかを判定するヘルパーメソッド
  bool _isTemporaryUid(String uid) {
    // MockAuthServiceが生成する仮設定UIDパターンを検出
    if (uid.startsWith('mock_')) {
      return true;
    }

    // ローカルテスト用の仮設定UIDパターンを検出
    if (uid.startsWith('local_') ||
        uid.startsWith('temp_') ||
        uid.startsWith('dev_')) {
      return true;
    }

    // 空文字列や明らかに無効なUIDも仮設定として扱う
    if (uid.isEmpty || uid.length < 10) {
      return true;
    }

    return false;
  }

  /// 前回使用したUIDを取得
  Future<String?> getLastUsedUid() async {
    final prefs = await SharedPreferences.getInstance();
    final uid = prefs.getString(_lastUserIdKey);
    Log.info('📂 Last used UID retrieved: $uid');
    return uid;
  }

  /// 現在のユーザーIDを取得
  String? get currentUserId => _currentUserId;

  /// Hiveが初期化されているかどうか
  bool get isInitialized => _isInitialized;

  /// グローバルなHive初期化（アダプター登録のみ）
  static Future<void> initializeAdapters() async {
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(SharedGroupRoleAdapter());
      Hive.registerAdapter(SharedGroupMemberAdapter());
      Hive.registerAdapter(SharedGroupAdapter());
      // 🔥 後方互換性のためカスタムアダプターを使用
      // Hive.registerAdapter(SharedItemAdapter()); // デフォルトアダプターは使用しない (typeId=3)
      Hive.registerAdapter(SharedListAdapter());
      Hive.registerAdapter(InvitationStatusAdapter()); // 継続使用
      Hive.registerAdapter(InvitationTypeAdapter()); // InvitationType用
      Hive.registerAdapter(
          SyncStatusAdapter()); // ⚠️ 追加: SharedGroupのsyncStatusフィールド用
      Hive.registerAdapter(GroupTypeAdapter()); // 🆕 GroupType用
      Hive.registerAdapter(ListTypeAdapter()); // 🆕 ListType用
      // 🆕 Whiteboard用アダプター (typeId 15-17)
      Hive.registerAdapter(DrawingStrokeAdapter());
      Hive.registerAdapter(DrawingPointAdapter());
      Hive.registerAdapter(WhiteboardAdapter());
      // Hive.registerAdapter(InvitationAdapter());  // 削除済み - QRコードシステムに移行
      // Hive.registerAdapter(AcceptedInvitationAdapter());  // 削除済み - QRコードシステムに移行
      // 🔥 UserSettingsAdapter登録をスキップ（main.dartでUserSettingsAdapterOverride使用）
      // Hive.registerAdapter(UserSettingsAdapter()); // デフォルトアダプターは使用しない (typeId=6)
      Log.info(
          '📝 Hive adapters registered globally (GroupType, ListType, Whiteboard追加)');
    }
  }

  /// Windows用: 前回使用UIDまたは指定UIDでHiveを初期化
  Future<void> initializeForWindowsUser([String? userId]) async {
    if (!Platform.isWindows) {
      Log.warning('⚠️ User-specific folders are only supported on Windows');
      return initializeForDefaultUser();
    }

    // UIDが指定されていない場合は前回使用UIDを取得
    final targetUserId = userId ?? await getLastUsedUid();

    // 仮設定UIDまたは無効UIDの場合はデフォルトHiveを使用
    if (targetUserId == null || _isTemporaryUid(targetUserId)) {
      Log.info(
          '🔄 有効なUID未発見（${AppLogger.maskUserId(targetUserId ?? "null")}） - デフォルトHiveを使用');
      return initializeForDefaultUser();
    }

    Log.info(
        '🗂️ Initializing Hive for user: ${AppLogger.maskUserId(targetUserId)}');

    // 既存のinitializeForUserを利用
    await initializeForUser(targetUserId);

    // 使用UIDを保存（仮設定UIDでない場合のみ）
    await saveLastUsedUid(targetUserId);

    Log.info(
        '✅ Hive initialized for Windows user: ${AppLogger.maskUserId(targetUserId)}');
  }

  /// ユーザー固有のHiveデータベースを初期化
  Future<void> initializeForUser(String userId) async {
    if (_currentUserId == userId && _isInitialized) {
      Log.info(
          '✅ Already initialized for user: ${AppLogger.maskUserId(userId)}');
      return;
    }

    try {
      // 安全にすべてのBoxを閉じる
      await _closeAllBoxesSafely();

      // Box閉じた後少し待つ（プロバイダー競合を防ぐ）
      await Future.delayed(const Duration(milliseconds: 500));

      // ユーザー固有のディレクトリパスを作成
      final userDataPath = await _getUserDataPath(userId);
      Log.info('📁 User data path: $userDataPath');

      // Hiveの再初期化を安全に実行
      await _safeReinitializeHive(userDataPath);

      // ★★★ データマイグレーションを実行 ★★★
      await _runMigrationIfNeeded();

      // Boxを開く
      await _openUserBoxes();

      _currentUserId = userId;
      _isInitialized = true;

      Log.info(
          '✅ Hive initialized successfully for user: ${AppLogger.maskUserId(userId)}');
    } catch (e) {
      Log.error(
          '❌ Failed to initialize Hive for user ${AppLogger.maskUserId(userId)}: $e');
      rethrow;
    }
  }

  /// デフォルトユーザー（UID未設定）用のHive初期化
  Future<void> initializeForDefaultUser() async {
    if (_currentUserId == 'default' && _isInitialized) {
      Log.info('✅ Already initialized for default user');
      return;
    }

    try {
      // 安全にすべてのBoxを閉じる
      await _closeAllBoxesSafely();

      // Box閉じた後少し待つ
      await Future.delayed(const Duration(milliseconds: 300));

      // デフォルトのHiveパスを設定
      final directory = await getApplicationDocumentsDirectory();
      final defaultPath = '${directory.path}/hive_db';

      Log.info('📁 Default Hive path: $defaultPath');

      // ディレクトリが存在しない場合は作成
      final hiveDir = Directory(defaultPath);
      if (!await hiveDir.exists()) {
        await hiveDir.create(recursive: true);
        Log.info('📁 Created Hive directory: $defaultPath');
      }

      // Hiveの再初期化を安全に実行
      await _safeReinitializeHive(defaultPath);

      // ★★★ データマイグレーションを実行 ★★★
      await _runMigrationIfNeeded();

      // Boxを順番に開く
      await _openUserBoxes();

      _currentUserId = 'default';
      _isInitialized = true;

      Log.info('✅ Hive initialized successfully for default user');
    } catch (e) {
      Log.error('❌ Failed to initialize Hive for default user: $e');
      rethrow;
    }
  }

  /// すべてのBoxを安全に閉じる（競合回避改良版）
  Future<void> _closeAllBoxesSafely() async {
    try {
      Log.info('📦 Attempting to close all Hive boxes safely...');

      // 個別のBoxを順次閉じる（Hive.close()は使わない）
      final boxesToClose = [
        'SharedGroups',
        'sharedLists',
        'userSettings',
        'subscriptions'
      ];

      for (String boxName in boxesToClose) {
        try {
          if (Hive.isBoxOpen(boxName)) {
            final box = Hive.box(boxName);
            await box.close();
            Log.info('🔒 Successfully closed box: $boxName');
          }
        } catch (e) {
          Log.warning('⚠️ Warning closing box $boxName (continuing): $e');
        }
        // Box閉じる間に少し待つ
        await Future.delayed(const Duration(milliseconds: 50));
      }

      Log.info('🔄 All Hive boxes closed successfully');
    } catch (e) {
      Log.warning('⚠️ Warning during box closing (will continue): $e');
    }
  }

  /// ユーザー固有のデータパスを取得
  Future<String> _getUserDataPath(String userId) async {
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/go_shop_data/users/$userId';
  }

  /// Hiveの安全な再初期化
  Future<void> _safeReinitializeHive(String path) async {
    try {
      Log.info('🔄 Safe Hive reinitialization to: $path');

      // Hiveが既に初期化されている場合は、既存のパスと比較
      try {
        // Hiveが既に同じパスで初期化されている場合はスキップ
        Hive.init(path);
        Log.info('✅ Hive initialized/verified with path: $path');
      } catch (e) {
        // エラーが発生した場合は強制的に再初期化
        Log.warning('⚠️ Hive init error (will retry): $e');

        // 少し待ってから再試行
        await Future.delayed(const Duration(milliseconds: 300));
        try {
          Hive.init(path);
          Log.info('✅ Hive reinitialized successfully after retry');
        } catch (retryError) {
          Log.error('❌ Hive reinit failed even after retry: $retryError');
          // 最終手段として例外を発生させずに処理を続行
          Log.warning('⚠️ Continuing with existing Hive state...');
        }
      }
    } catch (e) {
      Log.error('❌ Safe reinitialize error: $e');
      rethrow;
    }
  }

  /// 必要なBoxをすべて開く（順番に開いて競合を回避）
  Future<void> _openUserBoxes() async {
    try {
      Log.info('📦 Opening user boxes with safety checks...');

      // SharedGroupBox
      await _safeOpenBox<SharedGroup>('SharedGroups', '📁 SharedGroup');

      // SharedListBox
      await _safeOpenBox<SharedList>('sharedLists', '🛒 SharedList');

      // UserSettingsBox
      await _safeOpenBox<UserSettings>('userSettings', '⚙️ UserSettings');

      // SubscriptionsBox
      await _safeOpenBox<Map>('subscriptions', '📡 Subscriptions');

      Log.info('✅ All user-specific boxes opened successfully');
    } catch (e) {
      Log.error('❌ Failed to open user boxes: $e');
      rethrow;
    }
  }

  /// Boxを安全に開く（重複開封チェック付き）
  Future<void> _safeOpenBox<T>(String boxName, String displayName) async {
    try {
      if (Hive.isBoxOpen(boxName)) {
        Log.info('✅ $displayName box already open: $boxName');
        return;
      }

      Log.info('🔄 Opening $displayName box: $boxName');
      await Hive.openBox<T>(boxName);
      Log.info('✅ $displayName box opened successfully: $boxName');

      // Box開封間の間隔を確保
      await Future.delayed(const Duration(milliseconds: 100));
    } catch (e) {
      Log.error('❌ Failed to open $displayName box ($boxName): $e');

      // 🔥 SharedList Boxのエラーは特別処理（データフォーマット破損の可能性）
      if (boxName == 'sharedLists') {
        Log.warning('⚠️ SharedList box corrupted. Deleting and recreating...');
        try {
          // 破損したBoxを削除
          await Hive.deleteBoxFromDisk(boxName);
          Log.info('🗑️ Deleted corrupted SharedList box');

          // 再作成
          await Hive.openBox<T>(boxName);
          Log.info('✅ Recreated SharedList box successfully');
          return;
        } catch (deleteError) {
          Log.error('❌ Failed to recreate SharedList box: $deleteError');
        }
      }

      rethrow;
    }
  }

  /// 必要に応じてデータマイグレーションを実行
  /// Firestore優先設計：スキーマバージョン不一致時はHive全削除→Firestoreから自動再同期
  Future<void> _runMigrationIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey(_schemaVersionKey)) {
      await prefs.setInt(_schemaVersionKey, _currentSchemaVersion);
      Log.info(
          '🆕 Hive schema version未保存のため現在バージョンを保存: $_currentSchemaVersion');
      return;
    }

    final currentVersion =
        prefs.getInt(_schemaVersionKey) ?? _currentSchemaVersion;
    Log.info(
        '🔄 Current Hive schema version: $currentVersion, App schema version: $_currentSchemaVersion');

    if (currentVersion == _currentSchemaVersion) {
      Log.info('✅ Schema is up to date.');
      return;
    }

    Log.info('🔥 Schema version mismatch detected. Clearing all Hive cache...');
    Log.info(
        '💡 Firestore data will be automatically re-synced after cache clear.');

    try {
      // 🔥 Firestore優先：Hiveキャッシュを全削除（複雑なマイグレーション不要）
      await _clearAllHiveBoxes();

      // バージョン番号を更新（Firestoreからの自動再同期を待つ）
      await prefs.setInt(_schemaVersionKey, _currentSchemaVersion);
      Log.info(
          '✅ Schema migration completed by clearing cache. New version: $_currentSchemaVersion');
      Log.info('📥 Firestore sync will populate data automatically.');
    } catch (e, stackTrace) {
      Log.error('❌ Schema migration failed: $e');
      Log.error('Stack trace: $stackTrace');
      // エラー時はバージョンを保存しない（次回起動時に再試行）
      rethrow;
    }
  }

  /// 全てのHive Boxをクリア（スキーマバージョン不一致時の対応）
  /// Firestore優先設計：キャッシュを捨ててFirestoreから再取得する方針
  Future<void> _clearAllHiveBoxes() async {
    Log.info('🗑️ Clearing all Hive boxes...');

    final boxNames = [
      'SharedGroups',
      'sharedLists',
      'userSettings',
      'subscriptions'
    ];

    for (final boxName in boxNames) {
      try {
        if (Hive.isBoxOpen(boxName)) {
          final box = Hive.box(boxName);
          await box.clear();
          Log.info('✅ Cleared box: $boxName');
        } else {
          // Boxが開いていない場合は開いてクリア
          await Hive.openBox(boxName);
          final box = Hive.box(boxName);
          await box.clear();
          await box.close();
          Log.info('✅ Opened, cleared, and closed box: $boxName');
        }
      } catch (e) {
        Log.warning('⚠️ Failed to clear box $boxName: $e');
        // 個別のBoxクリア失敗は続行（他のBoxは処理）
      }
    }

    Log.info('✅ All Hive boxes cleared successfully.');
  }
}
