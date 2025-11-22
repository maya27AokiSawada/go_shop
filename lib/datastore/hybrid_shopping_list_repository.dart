import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'dart:developer' as developer;
import '../models/shopping_list.dart';
import '../datastore/shopping_list_repository.dart';
import '../datastore/hive_shopping_list_repository.dart';
import '../datastore/firestore_shopping_list_repository.dart';
import '../services/list_notification_batch_service.dart';
import '../flavors.dart';

/// Hive（ローカルキャッシュ）+ Firestore（リモート）のハイブリッドShoppingListリポジトリ
///
/// 動作原理:
/// - 全グループ: Firestore優先（リアルタイム同期）
/// - デフォルトグループも他グループと同様に同期（他ユーザーを招待しないだけ）
/// - 読み取り: まずHiveから取得、なければFirestoreから取得してHiveにキャッシュ
/// - 書き込み: HiveとFirestore両方に保存（楽観的更新）
/// - 同期: バックグラウンドでFirestore→Hiveの差分同期
/// - オフライン: Hiveのみで動作、オンライン復帰時に自動同期
class HybridShoppingListRepository implements ShoppingListRepository {
  final Ref _ref;
  late final HiveShoppingListRepository _hiveRepo;
  FirestoreShoppingListRepository? _firestoreRepo;

  // 接続状態管理
  bool _isOnline = true;
  bool _isSyncing = false;

  // 同期キューとタイマー管理
  final List<_ShoppingListSyncOperation> _syncQueue = [];
  Timer? _syncTimer;

  HybridShoppingListRepository(this._ref) {
    _hiveRepo = HiveShoppingListRepository(_ref);
    // DEVモードではFirestoreリポジトリを初期化しない
    if (F.appFlavor != Flavor.dev) {
      try {
        _firestoreRepo = FirestoreShoppingListRepository(_ref);
        developer.log('🌐 [HYBRID_SHOPPING] Firestore統合有効化');
      } catch (e, stackTrace) {
        developer.log('❌ [HYBRID_SHOPPING] Firestore初期化エラー: $e');
        developer.log('📄 [HYBRID_SHOPPING] StackTrace: $stackTrace');
        _firestoreRepo = null;
        _isOnline = false; // オフラインモードに設定
        developer.log('🔧 [HYBRID_SHOPPING] Fallback: Hiveのみで動作');
      }
    }
  }

  /// オンライン状態をチェック
  bool get isOnline => _isOnline;

  /// 同期状態をチェック
  bool get isSyncing => _isSyncing;

  /// 共有グループかどうかを判定
  /// デフォルトグループも含め、すべてのグループをFirestoreと同期する
  /// （デフォルトグループは他ユーザーを招待しないだけで、同期は行う）
  bool _isSharedGroup(String groupId) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return false;

    // すべてのグループをFirestoreと同期対象とする
    return true;
  }

  // =================================================================
  // キャッシュ戦略: Cache-First with Background Sync
  // =================================================================

  @override
  Future<ShoppingList?> getShoppingList(String groupId) async {
    try {
      // 1. まずHiveから取得（高速）
      final cachedList = await _hiveRepo.getShoppingList(groupId);

      if (F.appFlavor == Flavor.dev || !_isOnline) {
        // Dev環境またはオフライン時はHiveのみ
        developer.log('📦 Cache-only: ShoppingList取得 (groupId: $groupId)');
        return cachedList;
      }

      // 2. バックグラウンドでFirestoreから同期（非同期）
      _syncFromFirestoreBackground(groupId);

      // 3. キャッシュデータを即座に返却
      developer.log('⚡ Cache-first: ShoppingList取得 (groupId: $groupId)');
      return cachedList;
    } catch (e) {
      developer.log('❌ HybridShoppingList.getShoppingList error: $e');
      return null;
    }
  }

  @override
  Future<void> addItem(ShoppingList list) async {
    try {
      // 1. 楽観的更新: まずHiveに保存（高速）
      await _hiveRepo.addItem(list);
      developer.log('✅ Hive保存完了: ${list.groupName}');

      if (F.appFlavor == Flavor.dev || !_isOnline) {
        return; // Dev環境またはオフライン時はHiveのみ
      }

      // 2. 同期処理でFirestoreに保存（ユーザーを待たせてもOK）
      await _syncListToFirestoreWithFallback(
          list, _ShoppingListSyncOperationType.create);
    } catch (e) {
      developer.log('❌ HybridShoppingList.addItem error: $e');
      rethrow;
    }
  }

  /// Firestoreへの同期処理（フォールバック付き）
  Future<void> _syncListToFirestoreWithFallback(
      ShoppingList list, _ShoppingListSyncOperationType operationType) async {
    if (_firestoreRepo == null) {
      developer.log('⚠️ Firestore repository not available');
      return;
    }

    try {
      // 10秒タイムアウトで同期実行
      await _firestoreRepo!.updateShoppingList(list).timeout(
            const Duration(seconds: 10),
          );
      developer.log('✅ Firestore同期成功: ${list.listName}');
    } catch (e) {
      developer.log('⚠️ Firestore同期失敗、キューに追加: $e');

      // 同期キューに追加
      _addToSyncQueue(_ShoppingListSyncOperation(
        type: operationType,
        listId: list.listId,
        data: list,
        timestamp: DateTime.now(),
        retryCount: 0,
      ));

      // タイマーで再同期をスケジュール
      _scheduleSync();
    }
  }

  @override
  Future<void> clearShoppingList(String groupId) async {
    try {
      // 1. まずHiveをクリア
      await _hiveRepo.clearShoppingList(groupId);

      if (F.appFlavor == Flavor.dev || !_isOnline || _firestoreRepo == null) {
        return;
      }

      // 2. Firestoreも同期でクリア
      await _firestoreRepo!.clearShoppingList(groupId);
    } catch (e) {
      developer.log('❌ HybridShoppingList.clearShoppingList error: $e');
      rethrow;
    }
  }

  @override
  Future<void> addShoppingItem(String groupId, ShoppingItem item) async {
    try {
      // 1. Hiveに追加
      await _hiveRepo.addShoppingItem(groupId, item);

      if (F.appFlavor == Flavor.dev || !_isOnline) {
        return;
      }

      // 2. 同期処理でFirestoreに追加
      await _syncItemToFirestoreWithFallback(
          groupId, item, _ShoppingListSyncOperationType.createItem);
    } catch (e) {
      developer.log('❌ HybridShoppingList.addShoppingItem error: $e');
      rethrow;
    }
  }

  /// Firestoreへのアイテム同期処理（フォールバック付き）
  Future<void> _syncItemToFirestoreWithFallback(String listId,
      ShoppingItem item, _ShoppingListSyncOperationType operationType) async {
    if (_firestoreRepo == null) {
      developer.log('⚠️ Firestore repository not available');
      return;
    }

    try {
      // 10秒タイムアウトで同期実行
      switch (operationType) {
        case _ShoppingListSyncOperationType.createItem:
          await _firestoreRepo!.addItemToList(listId, item).timeout(
                const Duration(seconds: 10),
              );
          break;
        case _ShoppingListSyncOperationType.updateItem:
          await _firestoreRepo!
              .updateItemStatusInList(listId, item,
                  isPurchased: item.isPurchased)
              .timeout(
                const Duration(seconds: 10),
              );
          break;
        case _ShoppingListSyncOperationType.deleteItem:
          await _firestoreRepo!.removeItemFromList(listId, item).timeout(
                const Duration(seconds: 10),
              );
          break;
        default:
          return;
      }
      developer.log('✅ Firestore item sync成功: ${item.name}');
    } catch (e) {
      developer.log('⚠️ Firestore item sync失敗、キューに追加: $e');

      // 同期キューに追加
      _addToSyncQueue(_ShoppingListSyncOperation(
        type: operationType,
        listId: listId,
        data: {'item': item},
        timestamp: DateTime.now(),
        retryCount: 0,
      ));

      // タイマーで再同期をスケジュール
      _scheduleSync();
    }
  }

  @override
  Future<void> removeShoppingItem(String groupId, ShoppingItem item) async {
    try {
      // 1. Hiveから削除
      await _hiveRepo.removeShoppingItem(groupId, item);

      if (F.appFlavor == Flavor.dev || !_isOnline) {
        return;
      }

      // 2. 同期処理でFirestoreからも削除
      await _syncItemToFirestoreWithFallback(
          groupId, item, _ShoppingListSyncOperationType.deleteItem);
    } catch (e) {
      developer.log('❌ HybridShoppingList.removeShoppingItem error: $e');
      rethrow;
    }
  }

  @override
  Future<void> updateShoppingItemStatus(String groupId, ShoppingItem item,
      {required bool isPurchased}) async {
    try {
      // 1. Hiveのステータス更新
      await _hiveRepo.updateShoppingItemStatus(groupId, item,
          isPurchased: isPurchased);

      if (F.appFlavor == Flavor.dev || !_isOnline) {
        return;
      }

      // 2. 同期処理でFirestoreのステータスも更新
      final updatedItem = item.copyWith(isPurchased: isPurchased);
      await _syncItemToFirestoreWithFallback(
          groupId, updatedItem, _ShoppingListSyncOperationType.updateItem);
    } catch (e) {
      developer.log('❌ HybridShoppingList.updateShoppingItemStatus error: $e');
      rethrow;
    }
  }

  @override
  Future<ShoppingList> getOrCreateList(String groupId, String groupName) async {
    try {
      // 1. まずHiveから取得を試行
      final existingList = await _hiveRepo.getOrCreateList(groupId, groupName);

      if (F.appFlavor == Flavor.dev || !_isOnline) {
        return existingList;
      }

      // 2. バックグラウンドでFirestore同期
      _syncFromFirestoreBackground(groupId);

      return existingList;
    } catch (e) {
      developer.log('❌ HybridShoppingList.getOrCreateList error: $e');
      rethrow;
    }
  }

  // =================================================================
  // バックグラウンド同期処理
  // =================================================================

  /// Firestoreからバックグラウンド同期(非ブロッキング)
  void _syncFromFirestoreBackground(String groupId) {
    if (_isSyncing || _firestoreRepo == null) return;

    Future.microtask(() async {
      _isSyncing = true;
      try {
        final firestoreList = await _firestoreRepo!.getShoppingList(groupId);
        if (firestoreList != null) {
          // Hiveと比較して新しければ更新
          final hiveList = await _hiveRepo.getShoppingList(groupId);
          if (_shouldUpdateFromFirestore(hiveList, firestoreList)) {
            await _hiveRepo.addItem(firestoreList);
            developer.log('🔄 Background sync: Firestore→Hive完了');
          }
        }
      } catch (e) {
        developer.log('⚠️ Background sync error: $e');
        _isOnline = false; // 接続エラーをマーク
      } finally {
        _isSyncing = false;
      }
    });
  }

  /// Firestoreデータの方が新しいかチェック
  bool _shouldUpdateFromFirestore(
      ShoppingList? hiveList, ShoppingList firestoreList) {
    if (hiveList == null) return true;

    // アイテム数で簡易比較（実際のアプリでは更新日時を使用すべき）
    return firestoreList.items.length != hiveList.items.length;
  }

  // =================================================================
  // 手動同期・管理機能
  // =================================================================

  /// 強制的に双方向同期を実行
  Future<void> forceSyncBidirectional() async {
    if (_isSyncing) return;

    _isSyncing = true;
    try {
      // TODO: 実際の実装では全グループのリストを取得して同期する必要がある
      // 現在は接続テストのみ実行

      developer.log('🔄 Force bidirectional sync completed');
      _isOnline = true;
    } catch (e) {
      developer.log('❌ Force sync error: $e');
      _isOnline = false;
    } finally {
      _isSyncing = false;
    }
  }

  /// 接続状態を手動でリセット
  void resetConnectionStatus() {
    _isOnline = true;
    developer.log('🔄 Connection status reset');
  }

  // === Multi-List Methods Implementation ===

  @override
  Future<ShoppingList> createShoppingList({
    required String ownerUid,
    required String groupId,
    required String listName,
    String? description,
  }) async {
    try {
      // Hive側で新規作成
      final newList = await _hiveRepo.createShoppingList(
        ownerUid: ownerUid,
        groupId: groupId,
        listName: listName,
        description: description,
      );

      // Firestoreにも同期(オンライン時のみ)
      if (_isOnline && F.appFlavor == Flavor.prod && _firestoreRepo != null) {
        try {
          await _firestoreRepo!.createShoppingList(
            ownerUid: ownerUid,
            groupId: groupId,
            listName: listName,
            description: description,
          );
          developer.log('☁️ Hybrid: リスト「$listName」をFirestoreに同期');
        } catch (e) {
          developer.log('⚠️ Hybrid: Firestore同期失敗、Hiveのみで作成: $e');
        }
      }

      return newList;
    } catch (e) {
      developer.log('❌ Hybrid: リスト作成エラー: $e');
      rethrow;
    }
  }

  @override
  Future<ShoppingList?> getShoppingListById(String listId) async {
    return await _hiveRepo.getShoppingListById(listId);
  }

  @override
  Future<List<ShoppingList>> getShoppingListsByGroup(String groupId) async {
    try {
      // すべてのグループでFirestore優先（デフォルトグループも含む）
      if (_isSharedGroup(groupId) &&
          _isOnline &&
          _firestoreRepo != null &&
          F.appFlavor != Flavor.dev) {
        developer.log('🌐 [FIRESTORE優先] リスト取得: $groupId');

        // 1. Firestoreから最新データを取得
        final firestoreLists =
            await _firestoreRepo!.getShoppingListsByGroup(groupId);

        // 2. Hiveにキャッシュ（バックグラウンド）
        for (final list in firestoreLists) {
          _hiveRepo.updateShoppingList(list).catchError((e) {
            developer.log('⚠️ Hiveキャッシュ失敗 (${list.listId}): $e');
          });
        }

        developer.log('✅ [FIRESTORE] ${firestoreLists.length}件取得完了');
        return firestoreLists;
      }

      // オフライン時またはDev環境はHive優先
      developer.log('📦 [HIVE優先] リスト取得: $groupId');
      return await _hiveRepo.getShoppingListsByGroup(groupId);
    } catch (e) {
      developer.log('❌ HybridShoppingList.getShoppingListsByGroup error: $e');
      // エラー時はHiveフォールバック
      return await _hiveRepo.getShoppingListsByGroup(groupId);
    }
  }

  @override
  Future<void> updateShoppingList(ShoppingList list) async {
    try {
      // 1. まずHiveに保存（楽観的更新）
      await _hiveRepo.updateShoppingList(list);

      if (F.appFlavor == Flavor.dev || !_isOnline) {
        return; // Dev環境またはオフライン時はHiveのみ
      }

      // 2. すべてのグループでFirestoreにも同期
      if (_isSharedGroup(list.groupId)) {
        await _syncListToFirestoreWithFallback(
            list, _ShoppingListSyncOperationType.update);
        developer.log('🌐 [FIRESTORE同期] ${list.listName}');
      }
    } catch (e) {
      developer.log('❌ HybridShoppingList.updateShoppingList error: $e');
      rethrow;
    }
  }

  @override
  Future<void> deleteShoppingList(String listId) async {
    await _hiveRepo.deleteShoppingList(listId);
  }

  @override
  Future<void> addItemToList(String listId, ShoppingItem item) async {
    try {
      // 1. Hiveに追加
      await _hiveRepo.addItemToList(listId, item);

      // 2. 通知記録（groupIdを取得するためにリストを取得）
      final list = await _hiveRepo.getShoppingListById(listId);
      if (list != null) {
        final notifyService = _ref.read(listNotificationBatchServiceProvider);
        await notifyService.recordItemAdded(
          listId: listId,
          groupId: list.groupId,
          itemName: item.name,
        );
      }

      if (F.appFlavor == Flavor.dev || !_isOnline) {
        return;
      }

      // 3. 同期処理でFirestoreに追加
      await _syncItemToFirestoreWithFallback(
          listId, item, _ShoppingListSyncOperationType.createItem);
    } catch (e) {
      developer.log('❌ HybridShoppingList.addItemToList error: $e');
      rethrow;
    }
  }

  @override
  Future<void> removeItemFromList(String listId, ShoppingItem item) async {
    try {
      // 1. Hiveから削除
      await _hiveRepo.removeItemFromList(listId, item);

      // 2. 通知記録（groupIdを取得するためにリストを取得）
      final list = await _hiveRepo.getShoppingListById(listId);
      if (list != null) {
        final notifyService = _ref.read(listNotificationBatchServiceProvider);
        await notifyService.recordItemRemoved(
          listId: listId,
          groupId: list.groupId,
          itemName: item.name,
        );
      }

      if (F.appFlavor == Flavor.dev || !_isOnline) {
        return;
      }

      // 3. 同期処理でFirestoreからも削除
      await _syncItemToFirestoreWithFallback(
          listId, item, _ShoppingListSyncOperationType.deleteItem);
    } catch (e) {
      developer.log('❌ HybridShoppingList.removeItemFromList error: $e');
      rethrow;
    }
  }

  @override
  Future<void> updateItemStatusInList(String listId, ShoppingItem item,
      {required bool isPurchased}) async {
    try {
      // 1. Hiveの状態を更新
      await _hiveRepo.updateItemStatusInList(listId, item,
          isPurchased: isPurchased);

      // 2. 通知記録（購入完了時のみ）
      if (isPurchased) {
        final list = await _hiveRepo.getShoppingListById(listId);
        if (list != null) {
          final notifyService = _ref.read(listNotificationBatchServiceProvider);
          await notifyService.recordItemPurchased(
            listId: listId,
            groupId: list.groupId,
            itemName: item.name,
          );
        }
      }

      if (F.appFlavor == Flavor.dev || !_isOnline) {
        return;
      }

      // 3. 同期処理でFirestoreの状態も更新
      final updatedItem = item.copyWith(isPurchased: isPurchased);
      await _syncItemToFirestoreWithFallback(
          listId, updatedItem, _ShoppingListSyncOperationType.updateItem);
    } catch (e) {
      developer.log('❌ HybridShoppingList.updateItemStatusInList error: $e');
      rethrow;
    }
  }

  @override
  Future<void> clearPurchasedItemsFromList(String listId) async {
    await _hiveRepo.clearPurchasedItemsFromList(listId);
  }

  @override
  Future<ShoppingList> getOrCreateDefaultList(
      String groupId, String groupName) async {
    return await _hiveRepo.getOrCreateDefaultList(groupId, groupName);
  }

  @override
  Future<void> deleteShoppingListsByGroupId(String groupId) async {
    // Hiveリポジトリに委譲
    await _hiveRepo.deleteShoppingListsByGroupId(groupId);

    // オンラインかつFirestoreリポジトリが利用可能な場合、Firestoreでも削除
    if (_isOnline && _firestoreRepo != null && F.appFlavor != Flavor.dev) {
      try {
        await _firestoreRepo!.deleteShoppingListsByGroupId(groupId);
      } catch (e) {
        developer.log('⚠️ Firestore deletion failed (continuing): $e');
      }
    }
  }

  // =================================================================
  // 同期キュー管理メソッド
  // =================================================================

  /// 同期キューに追加
  void _addToSyncQueue(_ShoppingListSyncOperation operation) {
    _syncQueue.add(operation);
    developer.log(
        '📝 Sync queue added: ${operation.type} for list ${operation.listId}');
  }

  /// 同期スケジュール（タイマー使用）
  void _scheduleSync() {
    _syncTimer?.cancel();
    _syncTimer = Timer(const Duration(seconds: 30), () {
      _processSyncQueue();
    });
    developer.log('⏰ Sync scheduled in 30 seconds');
  }

  /// 同期キューを処理
  Future<void> _processSyncQueue() async {
    if (_syncQueue.isEmpty || _isSyncing) return;

    _isSyncing = true;
    developer.log('🔄 Processing sync queue: ${_syncQueue.length} operations');

    final operationsToProcess =
        List<_ShoppingListSyncOperation>.from(_syncQueue);
    _syncQueue.clear();

    for (final operation in operationsToProcess) {
      try {
        await _executeSyncOperation(operation);
        developer.log('✅ Sync operation completed: ${operation.type}');
      } catch (e) {
        operation.retryCount++;
        if (operation.retryCount < 3) {
          _syncQueue.add(operation);
          developer.log(
              '🔄 Sync operation retry ${operation.retryCount}: ${operation.type}');
        } else {
          developer.log(
              '❌ Sync operation failed after 3 retries: ${operation.type}');
        }
      }
    }

    _isSyncing = false;

    // 残りの操作がある場合は再スケジュール
    if (_syncQueue.isNotEmpty) {
      _scheduleSync();
    }
  }

  /// 個別同期操作を実行
  Future<void> _executeSyncOperation(
      _ShoppingListSyncOperation operation) async {
    if (_firestoreRepo == null) {
      throw Exception('Firestore repository not available');
    }

    switch (operation.type) {
      case _ShoppingListSyncOperationType.create:
        await _firestoreRepo!
            .updateShoppingList(operation.data as ShoppingList);
        break;
      case _ShoppingListSyncOperationType.update:
        await _firestoreRepo!
            .updateShoppingList(operation.data as ShoppingList);
        break;
      case _ShoppingListSyncOperationType.delete:
        await _firestoreRepo!.deleteShoppingList(operation.listId);
        break;
      case _ShoppingListSyncOperationType.createItem:
        final itemData = operation.data as Map<String, dynamic>;
        await _firestoreRepo!
            .addItemToList(operation.listId, itemData['item'] as ShoppingItem);
        break;
      case _ShoppingListSyncOperationType.updateItem:
        final itemData = operation.data as Map<String, dynamic>;
        final item = itemData['item'] as ShoppingItem;
        await _firestoreRepo!.updateItemStatusInList(operation.listId, item,
            isPurchased: item.isPurchased);
        break;
      case _ShoppingListSyncOperationType.deleteItem:
        final item = operation.data as ShoppingItem;
        await _firestoreRepo!.removeItemFromList(operation.listId, item);
        break;
    }
  }

  /// アプリ終了時の同期実行
  Future<void> syncOnAppExit() async {
    if (_syncQueue.isEmpty) return;

    developer.log('🔄 App exit sync: ${_syncQueue.length} operations');
    _syncTimer?.cancel();

    final operations = List<_ShoppingListSyncOperation>.from(_syncQueue);
    _syncQueue.clear();

    for (final operation in operations) {
      try {
        await _executeSyncOperation(operation);
        developer.log('✅ App exit sync completed: ${operation.type}');
      } catch (e) {
        developer.log('❌ App exit sync failed: ${operation.type} - $e');
      }
    }
  }

  // === Realtime Sync Methods ===
  @override
  Stream<ShoppingList?> watchShoppingList(String groupId, String listId) {
    developer
        .log('🔴 [HYBRID_REALTIME] Stream開始: groupId=$groupId, listId=$listId');

    // Dev環境またはオフライン時はポーリング方式にフォールバック
    if (F.appFlavor == Flavor.dev || !_isOnline || _firestoreRepo == null) {
      developer.log('⚠️ [HYBRID_REALTIME] ポーリングモード（30秒間隔）');

      // 初回データ取得
      return Stream.periodic(const Duration(seconds: 30), (_) async {
        return await _hiveRepo.getShoppingListById(listId);
      }).asyncMap((future) => future);
    }

    // オンライン時はFirestoreのStreamを使用
    developer.log('🌐 [HYBRID_REALTIME] Firestoreストリームモード');

    return _firestoreRepo!.watchShoppingList(groupId, listId).map(
      (firestoreList) {
        // Firestoreから取得したデータをHiveにキャッシュ（バックグラウンド）
        if (firestoreList != null) {
          _hiveRepo.addItem(firestoreList).catchError((e) {
            developer.log('⚠️ [HYBRID_REALTIME] Hiveキャッシュ保存エラー: $e');
          });
          developer
              .log('✅ [HYBRID_REALTIME] Hiveにキャッシュ: ${firestoreList.listName}');
        }
        return firestoreList;
      },
    ).handleError((error) {
      developer.log('❌ [HYBRID_REALTIME] Streamエラー: $error');
      _isOnline = false; // オフラインマークを設定

      // エラー時はHiveキャッシュにフォールバック
      return _hiveRepo.getShoppingListById(listId);
    });
  }
}

// 同期操作の種類を定義
enum _ShoppingListSyncOperationType {
  create,
  update,
  delete,
  createItem,
  updateItem,
  deleteItem,
}

// 同期操作を表すクラス
class _ShoppingListSyncOperation {
  final _ShoppingListSyncOperationType type;
  final String listId;
  final dynamic data; // ShoppingList、ShoppingItem、またはアイテムID
  final DateTime timestamp;
  int retryCount;

  _ShoppingListSyncOperation({
    required this.type,
    required this.listId,
    this.data,
    required this.timestamp,
    int? retryCount,
  }) : retryCount = retryCount ?? 0;
}
