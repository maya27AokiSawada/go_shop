// lib/firebase_options.dart
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    // 開発用の仮の設定
    return const FirebaseOptions(
      apiKey: 'dummy-api-key',  // Firebase Consoleから取得
      appId: '',    // Firebase Consoleから取得
      messagingSenderId: 'dummy-sender-id',  // Firebase Consoleから取得
      projectId: 'dummy-project-id',  // Firebase Consoleから取得
    );
  }
}