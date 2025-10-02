import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:logger/logger.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'models/purchase_group.dart';
import 'models/shopping_list.dart';
import 'models/user_settings.dart';
import 'screens/home_screen.dart';
import 'flavors.dart';

final logger = Logger();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final logger = Logger();
  
  // フレーバーの設定
  F.appFlavor = Flavor.dev;
  
  // Firebase初期化
  if (F.appFlavor == Flavor.prod) {
    logger.i("🔥 Starting Go Shop app in PRODUCTION mode with Firebase");
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    logger.i("✅ Firebase initialized successfully");
  } else {
    logger.i("Starting Go Shop app in DEV mode (Hive only, no Firebase)");
  }
  
  // Hive初期化
  await _initializeHive();
  
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

Future<void> _initializeHive() async {
  try {
    // Hive初期化
    await Hive.initFlutter();
    logger.i('📦 Hive initFlutter completed');
    
    // アダプター登録
    Hive.registerAdapter(PurchaseGroupRoleAdapter());
    Hive.registerAdapter(PurchaseGroupMemberAdapter());
    Hive.registerAdapter(PurchaseGroupAdapter());
    Hive.registerAdapter(ShoppingItemAdapter());
    Hive.registerAdapter(ShoppingListAdapter());
    Hive.registerAdapter(UserSettingsAdapter());
    logger.i('📝 Hive adapters registered');
    
    // 全てのBoxを事前に開く（エラー時はクリアして再試行）
    await _openHiveBoxesSafely();
    
    logger.i('✅ Hive initialization completed successfully');
  } catch (e) {
    logger.e('❌ Hive initialization failed: $e');
    rethrow;
  }
}

Future<void> _openHiveBoxesSafely() async {
  try {
    await Future.wait([
      Hive.openBox<PurchaseGroup>('purchaseGroups'),
      Hive.openBox<ShoppingList>('shoppingLists'),
      Hive.openBox<UserSettings>('userSettings'),
    ]);
    
    // データ保存状況をデバッグ出力
    final purchaseGroupBox = Hive.box<PurchaseGroup>('purchaseGroups');
    final shoppingListBox = Hive.box<ShoppingList>('shoppingLists');
    final userSettingsBox = Hive.box<UserSettings>('userSettings');
    
    logger.i('📊 Hive boxes opened successfully:');
    logger.i('  - PurchaseGroups: ${purchaseGroupBox.length} items');
    logger.i('  - ShoppingLists: ${shoppingListBox.length} items');
    logger.i('  - UserSettings: ${userSettingsBox.length} items');
    
    await _validateAndCleanBoxes();
    
  } catch (e) {
    logger.w('⚠️ Hive box opening failed (likely schema change): $e');
    logger.i('🧹 Clearing all Hive data and retrying...');
    
    // データをクリアして再試行
    await _clearAndReopenBoxes();
  }
}

Future<void> _clearAndReopenBoxes() async {
  try {
    // 既存のBoxをクリア
    await Hive.deleteBoxFromDisk('purchaseGroups');
    await Hive.deleteBoxFromDisk('shoppingLists');
    await Hive.deleteBoxFromDisk('userSettings');
    
    logger.i('🗑️ Cleared existing Hive data');
    
    // 再度開く
    await Future.wait([
      Hive.openBox<PurchaseGroup>('purchaseGroups'),
      Hive.openBox<ShoppingList>('shoppingLists'),
      Hive.openBox<UserSettings>('userSettings'),
    ]);
    
    logger.i('✅ Successfully reopened Hive boxes with clean data');
    
  } catch (e) {
    logger.e('❌ Failed to clear and reopen Hive boxes: $e');
    rethrow;
  }
}

Future<void> _validateAndCleanBoxes() async {
  final userSettingsBox = Hive.box<UserSettings>('userSettings');
  final shoppingListBox = Hive.box<ShoppingList>('shoppingLists');

  // UserSettings内容の詳細確認と修復
  if (userSettingsBox.isNotEmpty) {
    logger.i('👤 UserSettings contents:');
    bool needsClearing = false;
    for (final key in userSettingsBox.keys) {
      try {
        final dynamic value = userSettingsBox.get(key);
        logger.i('  - Key: $key, Value: $value (${value.runtimeType})');
        
        // 期待されるUserSettings型でない場合
        if (value is String || (value != null && value is! UserSettings)) {
          logger.w('  - Invalid type found, will clear box');
          needsClearing = true;
        }
      } catch (e) {
        logger.e('  - Error reading key $key: $e');
        needsClearing = true;
      }
    }
    
    // 不正なデータがある場合はボックスをクリア
    if (needsClearing) {
      logger.w('🧹 Clearing corrupted UserSettings box');
      await userSettingsBox.clear();
    }
  } else {
    logger.w('⚠️ UserSettings box is empty - no saved data found');
  }
  
  // ShoppingLists内容の詳細確認
  if (shoppingListBox.isNotEmpty) {
    logger.i('🛒 ShoppingLists contents:');
    for (int i = 0; i < shoppingListBox.length; i++) {
      final shoppingList = shoppingListBox.getAt(i);
      logger.i('  - Index $i: ${shoppingList?.groupName} (${shoppingList?.items.length} items)');
    }
  } else {
    logger.w('⚠️ ShoppingLists box is empty - no saved lists found');
  }
  
  // IndexedDBの状況確認（ブラウザのみ）
  logger.i('🌐 Browser storage info:');
  logger.i('  - Current URL: ${Uri.base}');
  logger.i('  - Storage path: ${Hive.box('userSettings').path ?? "IndexedDB"}');
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: F.title,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: F.appFlavor != Flavor.prod,
      home: const HomeScreen(),
    );
  }
}
