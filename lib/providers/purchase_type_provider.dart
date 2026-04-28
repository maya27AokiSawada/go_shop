import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/purchase_type.dart';
import '../services/firestore_user_name_service.dart';
import '../services/purchase_service.dart';
import '../services/user_preferences_service.dart';

/// 課金タイプを Firestore からリアルタイム監視するプロバイダー
///
/// Firestoreデータがロスト（null or 'free'）した場合は、
/// ローカルキャッシュ（SharedPreferences）の値でフォールバックする。
final purchaseTypeProvider = StreamProvider<PurchaseType>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return Stream.value(PurchaseType.free);

  return FirestoreUserNameService.watchPurchaseType()
      .asyncMap((firestoreType) async {
    // Firestoreが有料状態を返している場合はそのまま使用し、キャッシュを更新
    if (firestoreType != PurchaseType.free) {
      await UserPreferencesService.savePurchaseTypeCache(
          firestoreType.firestoreValue);
      return firestoreType;
    }

    // Firestoreがfreeを返した場合はローカルキャッシュを確認
    final cached = await UserPreferencesService.loadPurchaseTypeCache();
    if (cached != null && cached != 'free') {
      final cachedType = PurchaseTypeExt.fromFirestoreValue(cached);
      if (cachedType != PurchaseType.free) {
        // キャッシュに有料状態が残っている → Firestoreロストの可能性
        // キャッシュ値を返してプレミアム機能を維持する
        return cachedType;
      }
    }

    return PurchaseType.free;
  });
});

/// PurchaseService のシングルトンプロバイダー
final purchaseServiceProvider = Provider<PurchaseService>((ref) {
  final service = PurchaseService();
  ref.onDispose(service.dispose);
  return service;
});
