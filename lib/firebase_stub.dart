// lib/firebase_stub.dart
// devフレーバー用のFirebase stubs

// Firebase Core stub
class Firebase {
  static Future<FirebaseApp> initializeApp({Map<String, dynamic>? options}) async {
    throw UnimplementedError('Firebase not available in dev mode');
  }
}

class FirebaseApp {
  final String name = 'dev-stub';
}

// Firebase Options stub  
class FirebaseOptions {
  const FirebaseOptions({
    required this.projectId,
    required this.appId,
    required this.apiKey,
    required this.messagingSenderId,
  });
  
  final String projectId;
  final String appId;
  final String apiKey;
  final String messagingSenderId;
}

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform => const FirebaseOptions(
    projectId: 'dev-stub',
    appId: 'dev-stub',
    apiKey: 'dev-stub',
    messagingSenderId: 'dev-stub',
  );
}