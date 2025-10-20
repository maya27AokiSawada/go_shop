import 'package:hive_flutter/hive_flutter.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_logger.dart';
import 'dart:io';
import '../models/purchase_group.dart';
import '../models/shopping_list.dart';
import '../models/user_settings.dart';
import '../models/invitation.dart';
import '../models/accepted_invitation.dart';



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
    if (uid.startsWith('local_') || uid.startsWith('temp_') || uid.startsWith('dev_')) {
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
      Hive.registerAdapter(PurchaseGroupRoleAdapter());
      Hive.registerAdapter(PurchaseGroupMemberAdapter());
      Hive.registerAdapter(PurchaseGroupAdapter());
      Hive.registerAdapter(ShoppingItemAdapter());
      Hive.registerAdapter(ShoppingListAdapter());
      Hive.registerAdapter(InvitationStatusAdapter()); // 追加
      Hive.registerAdapter(InvitationAdapter());
      Hive.registerAdapter(AcceptedInvitationAdapter());
      Hive.registerAdapter(UserSettingsAdapter());
      Log.info('📝 Hive adapters registered globally (including InvitationStatus)');
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
      Log.info('🔄 有効なUID未発見（${targetUserId ?? "null"}） - デフォルトHiveを使用');
      return initializeForDefaultUser();
    }

    Log.info('🗂️ Initializing Hive for user: $targetUserId');
    
    // 既存のinitializeForUserを利用
    await initializeForUser(targetUserId);
    
    // 使用UIDを保存（仮設定UIDでない場合のみ）
    await saveLastUsedUid(targetUserId);
    
    Log.info('✅ Hive initialized for Windows user: $targetUserId');
  }
  
  /// ユーザー固有のHiveデータベースを初期化
  Future<void> initializeForUser(String userId) async {
    if (_currentUserId == userId && _isInitialized) {
      Log.info('✅ Already initialized for user: $userId');
      return;
    }
    
    try {
      // 安全にすべてのBoxを閉じる
      await _closeAllBoxesSafely();
      
      // Box閉じた後少し待つ（プロバイダー競合を防ぐ）
      await Future.delayed(const Duration(milliseconds: 300));
      
      // ユーザー固有のディレクトリパスを作成
      final userDataPath = await _getUserDataPath(userId);
      Log.info('📁 User data path: $userDataPath');
      
      // Hiveをユーザー固有のパスで初期化
      Hive.init(userDataPath);
      
      // Boxを開く
      await _openUserBoxes();
      
      _currentUserId = userId;
      _isInitialized = true;
      
      Log.info('✅ Hive initialized successfully for user: $userId');
      
    } catch (e) {
      Log.error('❌ Failed to initialize Hive for user $userId: $e');
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
      
      // Hiveをデフォルトパスで初期化
      Hive.init(defaultPath);
      
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
      final boxesToClose = ['purchaseGroups', 'shoppingLists', 'userSettings', 'subscriptions'];
      
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
  
  /// 必要なBoxをすべて開く（順番に開いて競合を回避）
  Future<void> _openUserBoxes() async {
    try {
      Log.info('📦 Opening PurchaseGroup box...');
      await Hive.openBox<PurchaseGroup>('purchaseGroups');
      
      Log.info('📦 Opening ShoppingList box...');
      await Hive.openBox<ShoppingList>('shoppingLists');
      
      Log.info('📦 Opening UserSettings box...');
      await Hive.openBox<UserSettings>('userSettings');
      
      Log.info('📦 Opening Subscriptions box...');
      await Hive.openBox<Map>('subscriptions');
      
      Log.info('📦 All user-specific boxes opened successfully');
    } catch (e) {
      Log.error('❌ Failed to open user boxes: $e');
      rethrow;
    }
  }
}