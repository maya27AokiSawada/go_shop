import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/purchase_type.dart';
import 'auth_provider.dart';
import '../services/firestore_user_name_service.dart';
import '../services/purchase_service.dart';
import '../services/user_preferences_service.dart';

/// 課金タイプを Firestore からリアルタイム監視するプロバイダー
///
/// Firestoreを課金権限の正として扱う。ローカルキャッシュは最終確認値の記録用で、
/// Firestoreが明示した`free`を上書きする権限判定には使用しない。
final purchaseTypeProvider = StreamProvider<PurchaseType>((ref) {
  final authState = ref.watch(authStateProvider);

  return authState.when(
    loading: () => const Stream<PurchaseType>.empty(),
    error: (_, __) => const Stream<PurchaseType>.empty(),
    data: (user) {
      if (user == null) return Stream.value(PurchaseType.free);

      return FirestoreUserNameService.watchPurchaseType()
          .asyncMap((firestoreType) async {
        await UserPreferencesService.savePurchaseTypeCache(
          firestoreType.firestoreValue,
        );
        return firestoreType;
      });
    },
  );
});

/// PurchaseService のシングルトンプロバイダー
final purchaseServiceProvider = Provider<PurchaseService>((ref) {
  final service = PurchaseService();
  ref.onDispose(service.dispose);
  return service;
});
