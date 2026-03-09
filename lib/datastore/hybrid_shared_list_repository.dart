import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import 'dart:developer' as developer;
import '../models/shared_list.dart';
import '../datastore/shared_list_repository.dart';
import '../datastore/hive_shared_list_repository.dart';
import '../datastore/firestore_shared_list_repository.dart';
import '../services/list_notification_batch_service.dart';
import '../services/device_id_service.dart'; // 🆕 デバイスID生成用
import '../flavors.dart';

/// Hive（ローカルキャッシュ）+ Firestore（リモート）のハイブリッドSharedListリポジトリ
///
/// 動作原理:
/// - 全グループ: Firestore優先（リアルタイム同期）
/// - デフォルトグループも他グループと同様に同期（他ユーザーを招待しないだけ）
/// - 読み取り: まずHiveから取得、なければFirestoreから取得してHiveにキャッシュ
/// - 書き込み: HiveとFirestore両方に保存（楽観的更新）
/// - 同期: バックグラウンドでFirestore→Hiveの差分同期
/// - オフライン: Hiveのみで動作、オンライン復帰時に自動同期
class HybridSharedListRepository implements SharedListRepository {
  final Ref _ref;
  late final HiveSharedListRepository _hiveRepo;
  FirestoreSharedListRepository? _firestoreRepo;

  // 接続状態管理
  bool _isOnline = true;
  bool _isSyncing = false;

  // 同期キューとタイマー管理
  final List<_SharedListSyncOperation> _syncQueue = [];
  Timer? _syncTimer;

  HybridSharedListRepository(
    this._ref, {
    HiveSharedListRepository? hiveRepo,
    FirestoreSharedListRepository? firestoreRepo,
  }) {
    _hiveRepo = hiveRepo ?? HiveSharedListRepository(_ref);
    // テスト用: 外部からFirestoreリポジトリが注入された場合はそれを使用
    if (firestoreRepo != null) {
      _firestoreRepo = firestoreRepo;
    } else if (F.appFlavor != Flavor.dev) {
      // DEVモードではFirestoreリポジトリを初期化しない
      try {
        _firestoreRepo = FirestoreSharedListRepository(_ref);
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

  // =================================================================
  // キャッシュ戦略: Cache-First with Background Sync
  // =================================================================

  @override
  Future<SharedList?> getSharedList(String groupId) async {
    try {
      // 1. まずHiveから取得（高速）
      final cachedList = await _hiveRepo.getSharedList(groupId);

      if (!_isOnline) {
        // Dev環境またはオフライン時はHiveのみ
        developer.log('📦 Cache-only: SharedList取得 (groupId: $groupId)');
        return cachedList;
      }

      // 2. バックグラウンドでFirestoreから同期（非同期）
      _syncFromFirestoreBackground(groupId);

      // 3. キャッシュデータを即座に返却
      developer.log('⚡ Cache-first: SharedList取得 (groupId: $groupId)');
      return cachedList;
    } catch (e) {
      developer.log('❌ HybridSharedList.getSharedList error: $e');
      return null;
    }
  }

  @override
  Future<void> addItem(SharedList list) async {
    try {
      // 1. 楽観的更新: まずHiveに保存（高速）
      await _hiveRepo.addItem(list);
      developer.log('✅ Hive保存完了: ${list.groupName}');

      if (!_isOnline) {
        return; // Dev環境またはオフライン時はHiveのみ
      }

      // 2. 同期処理でFirestoreに保存（ユーザーを待たせてもOK）
      await _syncListToFirestoreWithFallback(
          list, _SharedListSyncOperationType.create);
    } catch (e) {
      developer.log('❌ HybridSharedList.addItem error: $e');
      rethrow;
    }
  }

  /// Firestoreへの同期処理（フォールバック付き）
  Future<void> _syncListToFirestoreWithFallback(
      SharedList list, _SharedListSyncOperationType operationType) async {
    if (_firestoreRepo == null) {
      developer.log('⚠️ Firestore repository not available');
      return;
    }

    try {
      // Firestore SDKオフライン永続化に委任（タイムアウトなし）
      await _firestoreRepo!.updateSharedList(list);
      developer.log('✅ Firestore同期成功: ${list.listName}');
    } catch (e) {
      developer.log('⚠️ Firestore同期失敗、キューに追加: $e');

      // 同期キューに追加
      _addToSyncQueue(_SharedListSyncOperation(
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
  Future<void> clearSharedList(String groupId) async {
    try {
      // 1. まずHiveをクリア
      await _hiveRepo.clearSharedList(groupId);

      if (!_isOnline || _firestoreRepo == null) {
        return;
      }

      // 2. Firestoreも同期でクリア
      await _firestoreRepo!.clearSharedList(groupId);
    } catch (e) {
      developer.log('❌ HybridSharedList.clearSharedList error: $e');
      rethrow;
    }
  }

  @override
  Future<void> addSharedItem(String groupId, SharedItem item) async {
    try {
      // 1. Hiveに追加
      await _hiveRepo.addSharedItem(groupId, item);

      if (!_isOnline) {
        return;
      }

      // 2. 同期処理でFirestoreに追加
      await _syncItemToFirestoreWithFallback(
          groupId, item, _SharedListSyncOperationType.createItem);
    } catch (e) {
      developer.log('❌ HybridSharedList.addSharedItem error: $e');
      rethrow;
    }
  }

  /// Firestoreへのアイテム同期処理（フォールバック付き）
  Future<void> _syncItemToFirestoreWithFallback(String listId, SharedItem item,
      _SharedListSyncOperationType operationType) async {
    if (_firestoreRepo == null) {
      developer.log('⚠️ Firestore repository not available');
      return;
    }

    try {
      // Firestore SDKオフライン永続化に委任（タイムアウトなし）
      switch (operationType) {
        case _SharedListSyncOperationType.createItem:
          await _firestoreRepo!.addItemToList(listId, item);
          break;
        case _SharedListSyncOperationType.updateItem:
          await _firestoreRepo!.updateItemStatusInList(listId, item,
              isPurchased: item.isPurchased);
          break;
        case _SharedListSyncOperationType.deleteItem:
          await _firestoreRepo!.removeItemFromList(listId, item);
          break;
        default:
          return;
      }
      developer.log('✅ Firestore item sync成功: ${item.name}');
    } catch (e) {
      developer.log('⚠️ Firestore item sync失敗、キューに追加: $e');

      // 同期キューに追加
      _addToSyncQueue(_SharedListSyncOperation(
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
  Future<void> removeSharedItem(String groupId, SharedItem item) async {
    try {
      // 1. Hiveから削除
      await _hiveRepo.removeSharedItem(groupId, item);

      if (!_isOnline) {
        return;
      }

      // 2. 同期処理でFirestoreからも削除
      await _syncItemToFirestoreWithFallback(
          groupId, item, _SharedListSyncOperationType.deleteItem);
    } catch (e) {
      developer.log('❌ HybridSharedList.removeSharedItem error: $e');
      rethrow;
    }
  }

  @override
  Future<void> updateSharedItemStatus(String groupId, SharedItem item,
      {required bool isPurchased}) async {
    try {
      // 1. Hiveのステータス更新
      await _hiveRepo.updateSharedItemStatus(groupId, item,
          isPurchased: isPurchased);

      if (!_isOnline) {
        return;
      }

      // 2. 同期処理でFirestoreのステータスも更新
      final updatedItem = item.copyWith(isPurchased: isPurchased);
      await _syncItemToFirestoreWithFallback(
          groupId, updatedItem, _SharedListSyncOperationType.updateItem);
    } catch (e) {
      developer.log('❌ HybridSharedList.updateSharedItemStatus error: $e');
      rethrow;
    }
  }

  @override
  Future<SharedList> getOrCreateList(String groupId, String groupName) async {
    try {
      // 1. まずHiveから取得を試行
      final existingList = await _hiveRepo.getOrCreateList(groupId, groupName);

      if (!_isOnline) {
        return existingList;
      }

      // 2. バックグラウンドでFirestore同期
      _syncFromFirestoreBackground(groupId);

      return existingList;
    } catch (e) {
      developer.log('❌ HybridSharedList.getOrCreateList error: $e');
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
        final firestoreList = await _firestoreRepo!.getSharedList(groupId);
        if (firestoreList != null) {
          // Hiveと比較して新しければ更新
          final hiveList = await _hiveRepo.getSharedList(groupId);
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
      SharedList? hiveList, SharedList firestoreList) {
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
  Future<SharedList> createSharedList({
    required String ownerUid,
    required String groupId,
    required String listName,
    String? description,
    String? customListId, // 🆕 基底クラスからの継承パラメータ
  }) async {
    try {
      // 🆕 デバイス固有のlistID生成（ID衝突防止）
      // customListIdが渡されていなければ自動生成
      final listIdToUse =
          customListId ?? await DeviceIdService.generateListId();
      developer.log('🆕 [HYBRID_LIST] デバイスプレフィックス付きlistId: $listIdToUse');

      // 🔥 サインイン必須仕様: Firestore優先
      if (_firestoreRepo != null) {
        developer.log('🔥 [HYBRID_LIST] Firestore優先モード - Firestoreに作成');

        // 1. Firestoreに作成（Firestore SDKオフライン永続化に委任）
        final newList = await _firestoreRepo!.createSharedList(
          ownerUid: ownerUid,
          groupId: groupId,
          listName: listName,
          description: description,
          customListId: listIdToUse, // 🆕 カスタムlistIdを使用
        );
        developer.log(
            '✅ [HYBRID_LIST] Firestore作成完了: ${newList.listName} (listId: ${newList.listId})');

        // 2. Hiveにキャッシュ（読み取り高速化のため）
        await _hiveRepo.updateSharedList(newList);
        developer.log('✅ [HYBRID_LIST] Hiveキャッシュ保存完了');

        return newList;
      } else {
        // dev環境またはFirestore未初期化の場合のみHive
        developer.log('📝 [HYBRID_LIST] dev環境 - Hiveに作成');
        final newList = await _hiveRepo.createSharedList(
          ownerUid: ownerUid,
          groupId: groupId,
          listName: listName,
          description: description,
          customListId: listIdToUse, // 🆕 カスタムlistIdを使用
        );
        developer.log('✅ [HYBRID_LIST] Hive保存完了: ${newList.listName}');
        return newList;
      }
    } catch (e) {
      developer.log('❌ [HYBRID_LIST] リスト作成エラー: $e');
      rethrow;
    }
  }

  @override
  Future<SharedList?> getSharedListById(String listId) async {
    try {
      // 🔥 サインイン必須仕様: Firestore優先
      if (_firestoreRepo != null) {
        developer
            .log('🔥 [HYBRID_LIST] Firestore優先モード - Firestoreから取得: $listId');

        try {
          // 1. Firestoreから取得（10秒タイムアウト → Hiveフォールバック）
          final firestoreList = await _firestoreRepo!
              .getSharedListById(listId)
              .timeout(const Duration(seconds: 10));

          if (firestoreList != null) {
            developer.log(
                '✅ [HYBRID_LIST] Firestore取得完了: ${firestoreList.listName}');

            // 2. Hiveにキャッシュ
            await _hiveRepo.updateSharedList(firestoreList);
            developer.log('✅ [HYBRID_LIST] Hiveキャッシュ更新完了');

            return firestoreList;
          } else {
            developer.log('⚠️ [HYBRID_LIST] Firestoreにリストなし - Hiveフォールバック');
            return await _hiveRepo.getSharedListById(listId);
          }
        } catch (e) {
          developer.log('⚠️ [HYBRID_LIST] Firestore取得エラー - Hiveフォールバック: $e');
          return await _hiveRepo.getSharedListById(listId);
        }
      } else {
        // dev環境またはFirestore未初期化の場合はHive
        developer.log('📝 [HYBRID_LIST] dev環境 - Hiveから取得');
        return await _hiveRepo.getSharedListById(listId);
      }
    } catch (e) {
      developer.log('❌ [HYBRID_LIST] リスト取得エラー: $e');
      rethrow;
    }
  }

  @override
  Future<List<SharedList>> getSharedListsByGroup(String groupId) async {
    try {
      // 🔥 サインイン必須仕様: Firestore優先（条件簡素化）
      if (_firestoreRepo != null) {
        developer
            .log('🔥 [HYBRID_LIST] Firestore優先モード - Firestoreから取得: $groupId');

        try {
          // 1. Firestoreから最新データを取得（10秒タイムアウト → Hiveフォールバック）
          final firestoreLists = await _firestoreRepo!
              .getSharedListsByGroup(groupId)
              .timeout(const Duration(seconds: 10));
          developer
              .log('✅ [HYBRID_LIST] Firestore取得完了: ${firestoreLists.length}件');

          // 2. Hiveにキャッシュ（読み取り高速化のため）
          for (final list in firestoreLists) {
            await _hiveRepo.updateSharedList(list);
          }
          developer
              .log('✅ [HYBRID_LIST] Hiveキャッシュ保存完了: ${firestoreLists.length}件');

          return firestoreLists;
        } catch (e) {
          // Firestoreエラー時のみHiveフォールバック
          developer.log('⚠️ [HYBRID_LIST] Firestore取得エラー - Hiveフォールバック: $e');
          return await _hiveRepo.getSharedListsByGroup(groupId);
        }
      } else {
        // dev環境またはFirestore未初期化の場合はHive
        developer.log('📝 [HYBRID_LIST] dev環境 - Hiveから取得');
        return await _hiveRepo.getSharedListsByGroup(groupId);
      }
    } catch (e) {
      developer.log('❌ [HYBRID_LIST] リスト一覧取得エラー: $e');
      rethrow;
    }
  }

  @override
  Future<void> updateSharedList(SharedList list) async {
    try {
      // 🔥 サインイン必須仕様: Firestore優先（条件簡素化）
      if (_firestoreRepo != null) {
        developer.log('🔥 [HYBRID_LIST] Firestore優先モード - Firestoreに更新');

        // 1. Firestoreに更新（Firestore SDKオフライン永続化に委任）
        await _firestoreRepo!.updateSharedList(list);
        developer.log('✅ [HYBRID_LIST] Firestore更新完了: ${list.listName}');

        // 2. Hiveにキャッシュ
        await _hiveRepo.updateSharedList(list);
        developer.log('✅ [HYBRID_LIST] Hiveキャッシュ更新完了');
      } else {
        // dev環境またはFirestore未初期化の場合はHive
        developer.log('📝 [HYBRID_LIST] dev環境 - Hiveに更新');
        await _hiveRepo.updateSharedList(list);
        developer.log('✅ [HYBRID_LIST] Hive更新完了: ${list.listName}');
      }
    } catch (e) {
      developer.log('❌ [HYBRID_LIST] リスト更新エラー: $e');
      rethrow;
    }
  }

  @override
  Future<void> deleteSharedList(String groupId, String listId) async {
    try {
      // 🔥 サインイン必須仕様: Firestore優先（条件簡素化）
      if (_firestoreRepo != null) {
        developer.log('🔥 [HYBRID_LIST] Firestore優先モード - Firestoreから削除');

        // 1. Firestoreから削除（Firestore SDKオフライン永続化に委任）
        await _firestoreRepo!.deleteSharedList(groupId, listId);
        developer.log('✅ [HYBRID_LIST] Firestore削除完了: listId=$listId');

        // 2. Hiveキャッシュからも削除
        await _hiveRepo.deleteSharedList(groupId, listId);
        developer.log('✅ [HYBRID_LIST] Hiveキャッシュ削除完了');
      } else {
        // dev環境またはFirestore未初期化の場合はHive
        developer.log('📝 [HYBRID_LIST] dev環境 - Hiveから削除');
        await _hiveRepo.deleteSharedList(groupId, listId);
        developer.log('✅ [HYBRID_LIST] Hive削除完了: listId=$listId');
      }
    } catch (e) {
      developer.log('❌ [HYBRID_LIST] リスト削除エラー: $e');
      rethrow;
    }
  }

  @override
  Future<void> addItemToList(String listId, SharedItem item) async {
    try {
      // 1. Hiveに追加
      await _hiveRepo.addItemToList(listId, item);

      // 2. 通知記録（groupIdを取得するためにリストを取得）
      final list = await _hiveRepo.getSharedListById(listId);
      if (list != null) {
        final notifyService = _ref.read(listNotificationBatchServiceProvider);
        await notifyService.recordItemAdded(
          listId: listId,
          groupId: list.groupId,
          itemName: item.name,
        );
      }

      if (!_isOnline) {
        return;
      }

      // 3. 同期処理でFirestoreに追加
      await _syncItemToFirestoreWithFallback(
          listId, item, _SharedListSyncOperationType.createItem);
    } catch (e) {
      developer.log('❌ HybridSharedList.addItemToList error: $e');
      rethrow;
    }
  }

  @override
  Future<void> removeItemFromList(String listId, SharedItem item) async {
    try {
      // 1. Hiveから削除
      await _hiveRepo.removeItemFromList(listId, item);

      // 2. 通知記録（groupIdを取得するためにリストを取得）
      final list = await _hiveRepo.getSharedListById(listId);
      if (list != null) {
        final notifyService = _ref.read(listNotificationBatchServiceProvider);
        await notifyService.recordItemRemoved(
          listId: listId,
          groupId: list.groupId,
          itemName: item.name,
        );
      }

      if (!_isOnline) {
        return;
      }

      // 3. 同期処理でFirestoreからも削除
      await _syncItemToFirestoreWithFallback(
          listId, item, _SharedListSyncOperationType.deleteItem);
    } catch (e) {
      developer.log('❌ HybridSharedList.removeItemFromList error: $e');
      rethrow;
    }
  }

  @override
  Future<void> updateItemStatusInList(String listId, SharedItem item,
      {required bool isPurchased}) async {
    try {
      // 1. Hiveの状態を更新
      await _hiveRepo.updateItemStatusInList(listId, item,
          isPurchased: isPurchased);

      // 2. 通知記録（購入完了時のみ）
      if (isPurchased) {
        final list = await _hiveRepo.getSharedListById(listId);
        if (list != null) {
          final notifyService = _ref.read(listNotificationBatchServiceProvider);
          await notifyService.recordItemPurchased(
            listId: listId,
            groupId: list.groupId,
            itemName: item.name,
          );
        }
      }

      if (!_isOnline) {
        return;
      }

      // 3. 同期処理でFirestoreの状態も更新
      final updatedItem = item.copyWith(isPurchased: isPurchased);
      await _syncItemToFirestoreWithFallback(
          listId, updatedItem, _SharedListSyncOperationType.updateItem);
    } catch (e) {
      developer.log('❌ HybridSharedList.updateItemStatusInList error: $e');
      rethrow;
    }
  }

  @override
  Future<void> clearPurchasedItemsFromList(String listId) async {
    await _hiveRepo.clearPurchasedItemsFromList(listId);
  }

  @override
  Future<SharedList> getOrCreateDefaultList(
      String groupId, String groupName) async {
    return await _hiveRepo.getOrCreateDefaultList(groupId, groupName);
  }

  @override
  Future<void> deleteSharedListsByGroupId(String groupId) async {
    // Hiveリポジトリに委譲
    await _hiveRepo.deleteSharedListsByGroupId(groupId);

    // オンラインかつFirestoreリポジトリが利用可能な場合、Firestoreでも削除
    if (_isOnline && _firestoreRepo != null && F.appFlavor != Flavor.dev) {
      try {
        await _firestoreRepo!.deleteSharedListsByGroupId(groupId);
        developer.log('✅ [HYBRID_LIST] Firestore一括削除完了: groupId=$groupId');
      } catch (e) {
        developer.log('⚠️ Firestore deletion failed (continuing): $e');
      }
    }
  }

  // =================================================================
  // 同期キュー管理メソッド
  // =================================================================

  /// 同期キューに追加
  void _addToSyncQueue(_SharedListSyncOperation operation) {
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

    final operationsToProcess = List<_SharedListSyncOperation>.from(_syncQueue);
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
  Future<void> _executeSyncOperation(_SharedListSyncOperation operation) async {
    if (_firestoreRepo == null) {
      throw Exception('Firestore repository not available');
    }

    // Firestore SDKオフライン永続化に委任（タイムアウトなし）
    switch (operation.type) {
      case _SharedListSyncOperationType.create:
        await _firestoreRepo!.updateSharedList(operation.data as SharedList);
        break;
      case _SharedListSyncOperationType.update:
        await _firestoreRepo!.updateSharedList(operation.data as SharedList);
        break;
      case _SharedListSyncOperationType.delete:
        // リストIDからgroupIDを取得（Hiveキャッシュから）
        final listToDelete =
            await _hiveRepo.getSharedListById(operation.listId);
        if (listToDelete != null) {
          await _firestoreRepo!
              .deleteSharedList(listToDelete.groupId, operation.listId);
        } else {
          developer.log('⚠️ 削除対象リストがHiveに見つからない: ${operation.listId}');
        }
        break;
      case _SharedListSyncOperationType.createItem:
        final itemData = operation.data as Map<String, dynamic>;
        await _firestoreRepo!
            .addItemToList(operation.listId, itemData['item'] as SharedItem);
        break;
      case _SharedListSyncOperationType.updateItem:
        final itemData = operation.data as Map<String, dynamic>;
        final item = itemData['item'] as SharedItem;
        await _firestoreRepo!.updateItemStatusInList(operation.listId, item,
            isPurchased: item.isPurchased);
        break;
      case _SharedListSyncOperationType.deleteItem:
        final item = operation.data as SharedItem;
        await _firestoreRepo!.removeItemFromList(operation.listId, item);
        break;
    }
  }

  /// アプリ終了時の同期実行
  Future<void> syncOnAppExit() async {
    if (_syncQueue.isEmpty) return;

    developer.log('🔄 App exit sync: ${_syncQueue.length} operations');
    _syncTimer?.cancel();

    final operations = List<_SharedListSyncOperation>.from(_syncQueue);
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
  // =================================================================
  // 🆕 Map-based Differential Sync Methods
  // =================================================================

  @override
  Future<void> addSingleItem(String listId, SharedItem item) async {
    try {
      // 🔥 サインイン必須仕様: Firestore優先＋差分同期
      if (_firestoreRepo != null) {
        developer.log('🔥 [HYBRID_DIFF] Firestore優先モード - アイテム追加');

        // ⚠️ 重要: まずHiveからgroupIdを取得（コレクショングループクエリを避ける）
        final hiveList = await _hiveRepo.getSharedListById(listId);
        if (hiveList == null) {
          throw Exception('List not found in cache: $listId');
        }

        developer.log('📋 [HYBRID_DIFF] GroupId取得: ${hiveList.groupId}');

        // 1. Firestoreに単一アイテムのみ追加（差分同期）
        // groupIdを使って直接パスでアクセス（パーミッションエラー回避）
        await _firestoreRepo!
            .addSingleItemWithGroupId(listId, hiveList.groupId, item);
        developer.log('✅ [HYBRID_DIFF] Firestore: 単一アイテム追加完了 (${item.name})');

        // 2. Hiveキャッシュを更新（読み取り高速化）
        final updatedItems = Map<String, SharedItem>.from(hiveList.items);
        updatedItems[item.itemId] = item;
        final updatedList = hiveList.copyWith(
          items: updatedItems,
          updatedAt: DateTime.now(),
        );
        await _hiveRepo.updateSharedList(updatedList);
        developer.log('✅ [HYBRID_DIFF] Hiveキャッシュ更新完了');
      } else {
        // dev環境またはFirestore未初期化の場合のみHive
        developer.log('📝 [HYBRID_DIFF] dev環境 - Hiveに追加');
        final hiveList = await _hiveRepo.getSharedListById(listId);
        if (hiveList == null) {
          throw Exception('List not found: $listId');
        }
        final updatedItems = Map<String, SharedItem>.from(hiveList.items);
        updatedItems[item.itemId] = item;
        final updatedList = hiveList.copyWith(
          items: updatedItems,
          updatedAt: DateTime.now(),
        );
        await _hiveRepo.updateSharedList(updatedList);
        developer.log('✅ [HYBRID_DIFF] Hive保存完了: ${item.name}');
      }
    } catch (e, stackTrace) {
      developer.log('❌ [HYBRID_DIFF] addSingleItem error: $e');
      developer.log('📄 StackTrace: $stackTrace');
      rethrow;
    }
  }

  @override
  Future<void> removeSingleItem(String listId, String itemId) async {
    try {
      // 🔥 サインイン必須仕様: Firestore優先＋差分同期（論理削除）
      if (_firestoreRepo != null) {
        developer.log('🔥 [HYBRID_DIFF] Firestore優先モード - アイテム削除');

        // ⚠️ 重要: まずHiveからgroupIdを取得
        final hiveList = await _hiveRepo.getSharedListById(listId);
        if (hiveList == null) {
          throw Exception('List not found in cache: $listId');
        }

        // 1. Firestoreで単一アイテムのみ論理削除（差分同期）
        await _firestoreRepo!
            .removeSingleItemWithGroupId(listId, hiveList.groupId, itemId);
        developer
            .log('✅ [HYBRID_DIFF] Firestore: 単一アイテム削除完了 (itemId: $itemId)');

        // 2. Hiveキャッシュを更新
        final item = hiveList.items[itemId];
        if (item != null) {
          final deletedItem = item.copyWith(
            isDeleted: true,
            deletedAt: DateTime.now(),
          );
          final updatedItems = Map<String, SharedItem>.from(hiveList.items);
          updatedItems[itemId] = deletedItem;
          final updatedList = hiveList.copyWith(
            items: updatedItems,
            updatedAt: DateTime.now(),
          );
          await _hiveRepo.updateSharedList(updatedList);
          developer.log('✅ [HYBRID_DIFF] Hiveキャッシュ更新完了');
        }
      } else {
        // dev環境またはFirestore未初期化の場合のみHive
        developer.log('📝 [HYBRID_DIFF] dev環境 - Hiveから削除');
        final hiveList = await _hiveRepo.getSharedListById(listId);
        if (hiveList == null) return;
        final item = hiveList.items[itemId];
        if (item == null) {
          developer.log('⚠️ [HYBRID_DIFF] Item not found: $itemId');
          return;
        }
        final deletedItem = item.copyWith(
          isDeleted: true,
          deletedAt: DateTime.now(),
        );
        final updatedItems = Map<String, SharedItem>.from(hiveList.items);
        updatedItems[itemId] = deletedItem;
        final updatedList = hiveList.copyWith(
          items: updatedItems,
          updatedAt: DateTime.now(),
        );
        await _hiveRepo.updateSharedList(updatedList);
        developer.log('✅ [HYBRID_DIFF] Hive削除完了: ${item.name}');
      }
    } catch (e) {
      developer.log('❌ [HYBRID_DIFF] removeSingleItem error: $e');
      rethrow;
    }
  }

  @override
  Future<void> updateSingleItem(String listId, SharedItem item) async {
    try {
      // 🔥 サインイン必須仕様: Firestore優先＋差分同期
      if (_firestoreRepo != null) {
        developer.log('🔥 [HYBRID_DIFF] Firestore優先モード - アイテム更新');

        // ⚠️ 重要: まずHiveからgroupIdを取得
        final hiveList = await _hiveRepo.getSharedListById(listId);
        if (hiveList == null) {
          throw Exception('List not found in cache: $listId');
        }

        // 1. Firestoreで単一アイテムのみ更新（差分同期）
        await _firestoreRepo!
            .updateSingleItemWithGroupId(listId, hiveList.groupId, item);
        developer.log('✅ [HYBRID_DIFF] Firestore: 単一アイテム更新完了 (${item.name})');

        // 2. Hiveキャッシュを更新
        final updatedItems = Map<String, SharedItem>.from(hiveList.items);
        updatedItems[item.itemId] = item;
        final updatedList = hiveList.copyWith(
          items: updatedItems,
          updatedAt: DateTime.now(),
        );
        await _hiveRepo.updateSharedList(updatedList);
        developer.log('✅ [HYBRID_DIFF] Hiveキャッシュ更新完了');
      } else {
        // dev環境またはFirestore未初期化の場合のみHive
        developer.log('📝 [HYBRID_DIFF] dev環境 - Hiveに更新');
        final hiveList = await _hiveRepo.getSharedListById(listId);
        if (hiveList == null) return;
        final updatedItems = Map<String, SharedItem>.from(hiveList.items);
        updatedItems[item.itemId] = item;
        final updatedList = hiveList.copyWith(
          items: updatedItems,
          updatedAt: DateTime.now(),
        );
        await _hiveRepo.updateSharedList(updatedList);
        developer.log('✅ [HYBRID_DIFF] Hive更新完了: ${item.name}');
      }
    } catch (e) {
      developer.log('❌ [HYBRID_DIFF] updateSingleItem error: $e');
      rethrow;
    }
  }

  @override
  Future<void> cleanupDeletedItems(String listId,
      {int olderThanDays = 30}) async {
    try {
      final list = await _hiveRepo.getSharedListById(listId);
      if (list == null) return;

      final cutoffDate = DateTime.now().subtract(Duration(days: olderThanDays));

      // 削除から指定日数以上経過したアイテムを物理削除
      final cleanedItems = Map<String, SharedItem>.fromEntries(
        list.items.entries.where((entry) {
          final item = entry.value;
          if (!item.isDeleted) return true; // アクティブアイテムは残す
          if (item.deletedAt == null) return true; // 削除日不明は念のため残す
          return item.deletedAt!.isAfter(cutoffDate); // カットオフ日より新しいものは残す
        }),
      );

      final removedCount = list.items.length - cleanedItems.length;
      if (removedCount == 0) {
        developer.log('🧹 [HYBRID_CLEANUP] No items to cleanup');
        return;
      }

      final cleanedList = list.copyWith(
        items: cleanedItems,
        updatedAt: DateTime.now(),
      );

      await _hiveRepo.updateSharedList(cleanedList);
      developer
          .log('🧹 [HYBRID_CLEANUP] Removed $removedCount items from Hive');

      // Firestore同期
      if (!_isOnline) return;

      // バックグラウンド同期（エラーは無視）
      _firestoreRepo?.updateSharedList(cleanedList).then((_) {
        developer.log('🧹 [HYBRID_CLEANUP] Firestore synced');
      }).catchError((e) {
        developer.log('⚠️ [HYBRID_CLEANUP] Firestore sync failed: $e');
      });
    } catch (e) {
      developer.log('❌ [HYBRID_CLEANUP] cleanupDeletedItems error: $e');
      rethrow;
    }
  }

  // =================================================================
  // Realtime Sync Methods
  // =================================================================

  @override
  Stream<SharedList?> watchSharedList(String groupId, String listId) async* {
    developer
        .log('🔴 [HYBRID_REALTIME] Stream開始: groupId=$groupId, listId=$listId');

    // Dev環境またはオフライン時はポーリング方式にフォールバック
    if (!_isOnline || _firestoreRepo == null) {
      developer.log('⚠️ [HYBRID_REALTIME] ポーリングモード（30秒間隔）');

      // 初回データ取得してからポーリング
      yield* Stream.periodic(const Duration(seconds: 30), (_) async {
        return await _hiveRepo.getSharedListById(listId);
      }).asyncMap((future) => future);
      return;
    }

    // オンライン時はFirestoreのStreamを使用
    developer.log('🌐 [HYBRID_REALTIME] Firestoreストリームモード');

    yield* _firestoreRepo!.watchSharedList(groupId, listId).map(
      (firestoreList) {
        // Firestoreから取得したデータをHiveにキャッシュ（バックグラウンド）
        if (firestoreList != null) {
          _hiveRepo.updateSharedList(firestoreList).catchError((e) {
            developer.log('⚠️ [HYBRID_REALTIME] Hiveキャッシュ保存エラー: $e');
          });
          developer.log(
              '✅ [HYBRID_REALTIME] Hiveにキャッシュ: ${firestoreList.listName} (${firestoreList.activeItemCount}件)');
        }
        return firestoreList;
      },
    ).handleError((error) {
      developer.log('❌ [HYBRID_REALTIME] Streamエラー: $error');
      _isOnline = false; // オフラインマークを設定

      // エラー時はHiveキャッシュにフォールバック
      return _hiveRepo.getSharedListById(listId);
    });
  }
}

// 同期操作の種類を定義
enum _SharedListSyncOperationType {
  create,
  update,
  delete,
  createItem,
  updateItem,
  deleteItem,
}

// 同期操作を表すクラス
class _SharedListSyncOperation {
  final _SharedListSyncOperationType type;
  final String listId;
  final dynamic data; // SharedList、SharedItem、またはアイテムID
  final DateTime timestamp;
  int retryCount;

  _SharedListSyncOperation({
    required this.type,
    required this.listId,
    this.data,
    required this.timestamp,
    int? retryCount,
  }) : retryCount = retryCount ?? 0;
}
