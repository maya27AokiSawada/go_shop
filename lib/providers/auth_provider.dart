// lib/providers/auth_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../helper/mock_auth_service.dart';
import '../flavors.dart';

// Mock認証状態を管理するProvider
final mockAuthStateProvider = StateProvider<MockUser?>((ref) => null);

final authProvider = Provider<dynamic>((ref) {
  // 本番環境では実際のFirebase Authを使用
  if (F.appFlavor == Flavor.prod) {
    throw UnimplementedError('Production AuthService not implemented yet');
  }
  // 開発環境ではMockAuthServiceを使用（Singleton）
  return _mockAuthServiceInstance ??= MockAuthService();
});

// MockAuthServiceのSingletonインスタンス
MockAuthService? _mockAuthServiceInstance;

final authStateProvider = StreamProvider<dynamic>((ref) {
  // 本番環境では実際のFirebase Auth状態を監視
  if (F.appFlavor == Flavor.prod) {
    // 本番環境でのみFirebaseAuth.instanceを使用
    throw UnimplementedError('Production Firebase Auth not implemented yet');
  }
  // 開発環境ではMockAuthServiceの状態を監視（nullを返す）
  return Stream.value(null);
});
