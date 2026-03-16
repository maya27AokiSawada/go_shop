import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../datastore/whiteboard_repository.dart';
import '../models/whiteboard.dart';

/// WhiteboardRepositoryプロバイダー
final whiteboardRepositoryProvider = Provider<WhiteboardRepository>((ref) {
  return WhiteboardRepository();
});

/// グループ共通ホワイトボードプロバイダー
final groupWhiteboardProvider = FutureProvider.autoDispose
    .family<Whiteboard?, String>((ref, groupId) async {
  final repository = ref.read(whiteboardRepositoryProvider);
  return await repository.getGroupWhiteboard(groupId);
});

/// 🔥 NEW: グループ共通ホワイトボードリアルタイム監視プロバイダー
final watchGroupWhiteboardProvider =
    StreamProvider.autoDispose.family<Whiteboard?, String>((ref, groupId) {
  final repository = ref.read(whiteboardRepositoryProvider);

  // 🔥 FIX: コレクション全体を監視してownerIdがnullのものをフィルタリング
  // これによりホワイトボードの新規作成も自動的に検知できる
  return repository.watchGroupWhiteboard(groupId);
});

/// 個人用ホワイトボードリアルタイム監視プロバイダー
final personalWhiteboardProvider = StreamProvider.autoDispose
    .family<Whiteboard?, ({String groupId, String userId})>(
  (ref, params) {
    final repository = ref.read(whiteboardRepositoryProvider);
    return repository.watchPersonalWhiteboard(params.groupId, params.userId);
  },
);

/// ホワイトボードリアルタイム監視プロバイダー
final watchWhiteboardProvider = StreamProvider.autoDispose
    .family<Whiteboard?, ({String groupId, String whiteboardId})>(
  (ref, params) {
    final repository = ref.read(whiteboardRepositoryProvider);
    return repository.watchWhiteboard(params.groupId, params.whiteboardId);
  },
);

/// グループの全ホワイトボード取得プロバイダー
final allWhiteboardsProvider = FutureProvider.autoDispose
    .family<List<Whiteboard>, String>((ref, groupId) async {
  final repository = ref.read(whiteboardRepositoryProvider);
  return await repository.getAllWhiteboards(groupId);
});
