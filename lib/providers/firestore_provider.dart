import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../flavors.dart';

/// Firestoreインスタンスを一元管理するProvider
/// 設定を一度だけ行い、アプリ全体で同じインスタンスを使用する
final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  final firestore = FirebaseFirestore.instance;

  // 開発環境では設定をスキップ
  if (F.appFlavor == Flavor.dev) {
    return firestore;
  }

  // 設定は初回のみ適用される
  // 既に設定済みの場合はエラーになるため、try-catchで保護
  try {
    // 必要に応じてFirestore設定を追加
    // firestore.settings = const Settings(
    //   persistenceEnabled: true,
    //   cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    // );
  } catch (e) {
    // 設定済みの場合はスキップ（エラーは無視）
    // AppLogger.debug('Firestore settings already configured: $e');
  }

  return firestore;
});
