import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:logger/logger.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'models/purchase_group.dart';
import 'models/shopping_list.dart';
import 'screens/home_screen.dart';
import 'flavors.dart';

final logger = Logger();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Firebase初期化
  final firebaseApp = await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  final logger = Logger();
  logger.i("Firebase initialized: ${firebaseApp.name}");
  logger.i("Firebase options: ${DefaultFirebaseOptions.currentPlatform.projectId}");
  
  // フレーバーの設定 - 一時的にMockを使用
  F.appFlavor = Flavor.dev;
  
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
    logger.i('📝 Hive adapters registered');
    
    // 全てのBoxを事前に開く
    await Future.wait([
      Hive.openBox<PurchaseGroup>('purchaseGroups'),
      Hive.openBox<ShoppingList>('shoppingLists'),
      Hive.openBox('userSettings'), // ユーザー設定用のBox
    ]);
    
    // データ保存状況をデバッグ出力
    final purchaseGroupBox = Hive.box<PurchaseGroup>('purchaseGroups');
    final shoppingListBox = Hive.box<ShoppingList>('shoppingLists');
    final userSettingsBox = Hive.box('userSettings');
    
    logger.i('📊 Hive boxes opened successfully:');
    logger.i('  - PurchaseGroups: ${purchaseGroupBox.length} items');
    logger.i('  - ShoppingLists: ${shoppingListBox.length} items');
    logger.i('  - UserSettings: ${userSettingsBox.length} items');
    
    // UserSettings内容の詳細確認
    if (userSettingsBox.isNotEmpty) {
      logger.i('👤 UserSettings contents:');
      for (final key in userSettingsBox.keys) {
        final value = userSettingsBox.get(key);
        logger.i('  - Key: $key, Value: $value (${value.runtimeType})');
      }
    } else {
      logger.w('⚠️  UserSettings box is empty - no saved data found');
    }
    
    // ShoppingLists内容の詳細確認
    if (shoppingListBox.isNotEmpty) {
      logger.i('🛒 ShoppingLists contents:');
      for (int i = 0; i < shoppingListBox.length; i++) {
        final shoppingList = shoppingListBox.getAt(i);
        logger.i('  - Index $i: ${shoppingList?.groupName} (${shoppingList?.items.length} items)');
      }
    } else {
      logger.w('⚠️  ShoppingLists box is empty - no saved lists found');
    }
    
    // IndexedDBの状況確認（ブラウザのみ）
    logger.i('🌐 Browser storage info:');
    logger.i('  - Current URL: ${Uri.base}');
    logger.i('  - Storage path: ${Hive.box('userSettings').path ?? "IndexedDB"}');
    
    logger.i('✅ Hive initialization completed successfully');
  } catch (e) {
    logger.e('❌ Hive initialization failed: $e');
    rethrow;
  }
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
