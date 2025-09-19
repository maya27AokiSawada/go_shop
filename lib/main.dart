import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import '../screens/home_screen.dart';
import './flavors.dart';
// ...existing code...

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final appDocumentDir = await getApplicationDocumentsDirectory();
  F.appFlavor = Flavor.dev; // ここでフレーバーを設定
  
  Hive.initFlutter(appDocumentDir.path);
  await Hive.openBox('DeviceUser');
  await Hive.openBox('PurchaseGroup');
  await Hive.openBox('ShoppingList'); // 'myBox'は任意のボックス名

  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    Hive.close(); // アプリ終了時にHiveをクローズ
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached) {
      Hive.close(); // バックグラウンド終了時にもクローズ
    }
  }

  @override
  Widget build(BuildContext context) {
    // ...existing code...
    return HomeScreen();
  }
}
