// lib/providers/auth_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../helper/auth_service.dart';
import '../helper/mock_auth_service.dart';
import '../flavors.dart';

// Mock認証状態を管理するProvider
final mockAuthStateProvider = StateProvider<User?>((ref) => null);

final authProvider = Provider<AuthService>((ref) {
  // 本番環境では実際のFirebase Authを使用
  if (F.appFlavor == Flavor.prod) {
    return AuthService();
  }
  // 開発環境ではMockAuthServiceを使用（Singleton）
  return _mockAuthServiceInstance ??= MockAuthService();
});

// MockAuthServiceのSingletonインスタンス
MockAuthService? _mockAuthServiceInstance;

final authStateProvider = StreamProvider<User?>((ref) {
  // 本番環境では実際のFirebase Auth状態を監視
  if (F.appFlavor == Flavor.prod) {
    return FirebaseAuth.instance.authStateChanges();
  }
  // 開発環境ではMockAuthServiceの状態を監視
  final mockUser = ref.watch(mockAuthStateProvider);
  return Stream.value(mockUser);
});
