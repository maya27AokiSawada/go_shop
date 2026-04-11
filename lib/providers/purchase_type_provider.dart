import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/purchase_type.dart';
import '../services/firestore_user_name_service.dart';
import '../services/purchase_service.dart';

/// 課金タイプを Firestore からリアルタイム監視するプロバイダー
final purchaseTypeProvider = StreamProvider<PurchaseType>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return Stream.value(PurchaseType.free);
  return FirestoreUserNameService.watchPurchaseType();
});

/// PurchaseService のシングルトンプロバイダー
final purchaseServiceProvider = Provider<PurchaseService>((ref) {
  final service = PurchaseService();
  ref.onDispose(service.dispose);
  return service;
});
