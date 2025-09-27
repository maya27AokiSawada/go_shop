import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/purchase_group.dart';
import 'models/shopping_list.dart';
import 'screens/home_screen.dart';
import 'flavors.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // フレーバーの設定
  F.appFlavor = Flavor.dev;
  
  // Hive初期化
  await _initializeHive();
  
  runApp(
    ProviderScope(
      child: MyApp(),
    ),
  );
}

Future<void> _initializeHive() async {
  try {
    // Hive初期化
    await Hive.initFlutter();
    
    // アダプター登録
    Hive.registerAdapter(PurchaseGroupRoleAdapter());
    Hive.registerAdapter(PurchaseGroupMemberAdapter());
    Hive.registerAdapter(PurchaseGroupAdapter());
    Hive.registerAdapter(ShoppingItemAdapter());
    Hive.registerAdapter(ShoppingListAdapter());
    
    // 全てのBoxを事前に開く
    await Future.wait([
      Hive.openBox<PurchaseGroup>('purchaseGroups'),
      Hive.openBox<ShoppingList>('shoppingLists'),
    ]);
    
    print('Hive initialization completed successfully');
  } catch (e) {
    print('Hive initialization failed: $e');
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
