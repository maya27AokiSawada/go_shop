import 'package:hive_flutter/hive_flutter.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import '../models/purchase_group.dart';
import '../models/shopping_list.dart';
import '../models/user_settings.dart';
import '../models/invitation.dart';

final logger = Logger();

/// UID別のHiveデータベース管理サービス（改良版）
class UserSpecificHiveService {
  static UserSpecificHiveService? _instance;
  static UserSpecificHiveService get instance => _instance ??= UserSpecificHiveService._();
  
  UserSpecificHiveService._();
  
  String? _currentUserId;
  bool _isInitialized = false;
  
  // 前回使用したUIDの保存・復元用キー
  static const String _lastUserIdKey = 'last_used_uid';
  
  /// 前回使用したUIDを保存
  Future<void> saveLastUsedUid(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastUserIdKey, uid);
    logger.i('💾 Last used UID saved: $uid');
  }
  
  /// 前回使用したUIDを取得
  Future<String?> getLastUsedUid() async {
    final prefs = await SharedPreferences.getInstance();
    final uid = prefs.getString(_lastUserIdKey);
    logger.i('📂 Last used UID retrieved: $uid');
    return uid;
  }
  
  /// 現在のユーザーIDを取得
  String? get currentUserId => _currentUserId;
  
  /// Hiveが初期化されているかどうか
  bool get isInitialized => _isInitialized;
  
  /// グローバルなHive初期化（アダプター登録のみ）
  static Future<void> initializeAdapters() async {
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(PurchaseGroupRoleAdapter());
      Hive.registerAdapter(PurchaseGroupMemberAdapter());
      Hive.registerAdapter(PurchaseGroupAdapter());
      Hive.registerAdapter(ShoppingItemAdapter());
      Hive.registerAdapter(ShoppingListAdapter());
      Hive.registerAdapter(InvitationAdapter());
      Hive.registerAdapter(UserSettingsAdapter());
      logger.i('📝 Hive adapters registered globally (including Invitation)');
    }
  }
  
  /// Windows用: 前回使用UIDまたは指定UIDでHiveを初期化
  Future<void> initializeForWindowsUser([String? userId]) async {
    if (!Platform.isWindows) {
      logger.w('⚠️ User-specific folders are only supported on Windows');
      return initializeForDefaultUser();
    }

    // UIDが指定されていない場合は前回使用UIDを取得
    final targetUserId = userId ?? await getLastUsedUid();
    
    if (targetUserId == null) {
      logger.i('🔄 No previous UID found, using default Hive');
      return initializeForDefaultUser();
    }

    logger.i('🗂️ Initializing Hive for user: $targetUserId');
    
    // 既存のinitializeForUserを利用
    await initializeForUser(targetUserId);
    
    // 使用UIDを保存
    await saveLastUsedUid(targetUserId);
    
    logger.i('✅ Hive initialized for Windows user: $targetUserId');
  }
  
  /// ユーザー固有のHiveデータベースを初期化
  Future<void> initializeForUser(String userId) async {
    if (_currentUserId == userId && _isInitialized) {
      logger.i('✅ Already initialized for user: $userId');
      return;
    }
    
    try {
      // 安全にすべてのBoxを閉じる
      await _closeAllBoxesSafely();
      
      // Box閉じた後少し待つ（プロバイダー競合を防ぐ）
      await Future.delayed(const Duration(milliseconds: 300));
      
      // ユーザー固有のディレクトリパスを作成
      final userDataPath = await _getUserDataPath(userId);
      logger.i('📁 User data path: $userDataPath');
      
      // Hiveをユーザー固有のパスで初期化
      Hive.init(userDataPath);
      
      // Boxを開く
      await _openUserBoxes();
      
      _currentUserId = userId;
      _isInitialized = true;
      
      logger.i('✅ Hive initialized successfully for user: $userId');
      
    } catch (e) {
      logger.e('❌ Failed to initialize Hive for user $userId: $e');
      rethrow;
    }
  }
  
  /// デフォルトユーザー（UID未設定）用のHive初期化
  Future<void> initializeForDefaultUser() async {
    if (_currentUserId == 'default' && _isInitialized) {
      logger.i('✅ Already initialized for default user');
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
      
      logger.i('📁 Default Hive path: $defaultPath');
      
      // ディレクトリが存在しない場合は作成
      final hiveDir = Directory(defaultPath);
      if (!await hiveDir.exists()) {
        await hiveDir.create(recursive: true);
        logger.i('📁 Created Hive directory: $defaultPath');
      }
      
      // Hiveをデフォルトパスで初期化
      Hive.init(defaultPath);
      
      // Boxを順番に開く
      await _openUserBoxes();
      
      _currentUserId = 'default';
      _isInitialized = true;
      
      logger.i('✅ Hive initialized successfully for default user');
      
    } catch (e) {
      logger.e('❌ Failed to initialize Hive for default user: $e');
      rethrow;
    }
  }
  
  /// すべてのBoxを安全に閉じる（競合回避改良版）
  Future<void> _closeAllBoxesSafely() async {
    try {
      logger.i('📦 Attempting to close all Hive boxes safely...');
      
      // 個別のBoxを順次閉じる（Hive.close()は使わない）
      final boxesToClose = ['purchaseGroups', 'shoppingLists', 'userSettings', 'subscriptions'];
      
      for (String boxName in boxesToClose) {
        try {
          if (Hive.isBoxOpen(boxName)) {
            final box = Hive.box(boxName);
            await box.close();
            logger.i('🔒 Successfully closed box: $boxName');
          }
        } catch (e) {
          logger.w('⚠️ Warning closing box $boxName (continuing): $e');
        }
        // Box閉じる間に少し待つ
        await Future.delayed(const Duration(milliseconds: 50));
      }
      
      logger.i('🔄 All Hive boxes closed successfully');
    } catch (e) {
      logger.w('⚠️ Warning during box closing (will continue): $e');
    }
  }
  
  /// ユーザー固有のデータパスを取得
  Future<String> _getUserDataPath(String userId) async {
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/go_shop_data/users/$userId';
  }
  
  /// 必要なBoxをすべて開く（順番に開いて競合を回避）
  Future<void> _openUserBoxes() async {
    try {
      logger.i('📦 Opening PurchaseGroup box...');
      await Hive.openBox<PurchaseGroup>('purchaseGroups');
      
      logger.i('📦 Opening ShoppingList box...');
      await Hive.openBox<ShoppingList>('shoppingLists');
      
      logger.i('📦 Opening UserSettings box...');
      await Hive.openBox<UserSettings>('userSettings');
      
      logger.i('📦 Opening Subscriptions box...');
      await Hive.openBox<Map>('subscriptions');
      
      logger.i('📦 All user-specific boxes opened successfully');
    } catch (e) {
      logger.e('❌ Failed to open user boxes: $e');
      rethrow;
    }
  }
}