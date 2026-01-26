import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../datastore/whiteboard_repository.dart';
import '../models/whiteboard.dart';

/// WhiteboardRepositoryプロバイダー
final whiteboardRepositoryProvider = Provider<WhiteboardRepository>((ref) {
  return WhiteboardRepository();
});

/// グループ共通ホワイトボードプロバイダー
final groupWhiteboardProvider =
    FutureProvider.family<Whiteboard?, String>((ref, groupId) async {
  final repository = ref.read(whiteboardRepositoryProvider);
  return await repository.getGroupWhiteboard(groupId);
});

/// 🔥 NEW: グループ共通ホワイトボードリアルタイム監視プロバイダー
final watchGroupWhiteboardProvider =
    StreamProvider.family<Whiteboard?, String>((ref, groupId) async* {
  final repository = ref.read(whiteboardRepositoryProvider);

  // まず現在のホワイトボードを取得
  final currentWhiteboard = await repository.getGroupWhiteboard(groupId);
  if (currentWhiteboard == null) {
    yield null;
    return;
  }

  // whiteboardIdが分かったのでリアルタイム監視開始
  yield* repository.watchWhiteboard(groupId, currentWhiteboard.whiteboardId);
});

/// 個人用ホワイトボードプロバイダー
final personalWhiteboardProvider =
    FutureProvider.family<Whiteboard?, ({String groupId, String userId})>(
  (ref, params) async {
    final repository = ref.read(whiteboardRepositoryProvider);
    return await repository.getPersonalWhiteboard(
        params.groupId, params.userId);
  },
);

/// ホワイトボードリアルタイム監視プロバイダー
final watchWhiteboardProvider =
    StreamProvider.family<Whiteboard?, ({String groupId, String whiteboardId})>(
  (ref, params) {
    final repository = ref.read(whiteboardRepositoryProvider);
    return repository.watchWhiteboard(params.groupId, params.whiteboardId);
  },
);

/// グループの全ホワイトボード取得プロバイダー
final allWhiteboardsProvider =
    FutureProvider.family<List<Whiteboard>, String>((ref, groupId) async {
  final repository = ref.read(whiteboardRepositoryProvider);
  return await repository.getAllWhiteboards(groupId);
});
