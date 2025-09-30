// lib/providers/auth_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../helper/auth_service.dart';
import '../helper/mock_auth_service.dart';
import '../flavors.dart';

// Mock認証状態を管理するProvider
final mockAuthStateProvider = StateProvider<User?>((ref) => null);

final authProvider = Provider<AuthService>((ref) {
  // 開発環境ではMockAuthServiceを使用
  if (F.appFlavor == Flavor.dev) {
    return MockAuthService();
  }
  return AuthService();
});

final authStateProvider = StreamProvider<User?>((ref) {
  if (F.appFlavor == Flavor.dev) {
    // MockAuthServiceの場合はmockAuthStateProviderの値を監視
    final mockUser = ref.watch(mockAuthStateProvider);
    return Stream.value(mockUser);
  }
  return FirebaseAuth.instance.authStateChanges();
});
