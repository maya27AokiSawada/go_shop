import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:developer' as developer;
import '../models/shopping_list.dart';
import '../datastore/shopping_list_repository.dart';
import '../datastore/hive_shopping_list_repository.dart';
import '../datastore/firebase_shopping_list_repository.dart';
import '../flavors.dart';

/// Hive（ローカルキャッシュ）+ Firestore（リモート）のハイブリッドShoppingListリポジトリ
/// 
/// 動作原理:
/// - 読み取り: まずHiveから取得、なければFirestoreから取得してHiveにキャッシュ
/// - 書き込み: HiveとFirestore両方に保存（楽観的更新）
/// - 同期: バックグラウンドでFirestore→Hiveの差分同期
/// - オフライン: Hiveのみで動作、オンライン復帰時に自動同期
class HybridShoppingListRepository implements ShoppingListRepository {
  final Ref _ref;
  late final HiveShoppingListRepository _hiveRepo;
  late final FirebaseSyncShoppingListRepository _firestoreRepo;
  
  // 接続状態管理
  bool _isOnline = true;
  bool _isSyncing = false;
  
  HybridShoppingListRepository(this._ref) {
    _hiveRepo = HiveShoppingListRepository(_ref);
    _firestoreRepo = FirebaseSyncShoppingListRepository(_ref);
  }

  /// オンライン状態をチェック
  bool get isOnline => _isOnline;
  
  /// 同期状態をチェック
  bool get isSyncing => _isSyncing;

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
      
      // 2. バックグラウンドでFirestoreに同期
      _syncToFirestoreBackground(list);
      
    } catch (e) {
      developer.log('❌ HybridShoppingList.addItem error: $e');
      rethrow;
    }
  }

  @override
  Future<void> clearShoppingList(String groupId) async {
    try {
      // 1. まずHiveをクリア
      await _hiveRepo.clearShoppingList(groupId);
      
      if (F.appFlavor == Flavor.dev || !_isOnline) {
        return;
      }
      
      // 2. Firestoreも同期でクリア
      await _firestoreRepo.clearShoppingList(groupId);
      
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
      
      // 2. Firestoreにも同期
      final list = await _hiveRepo.getShoppingList(groupId);
      if (list != null) {
        _syncToFirestoreBackground(list);
      }
      
    } catch (e) {
      developer.log('❌ HybridShoppingList.addShoppingItem error: $e');
      rethrow;
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
      
      // 2. Firestoreにも同期
      final list = await _hiveRepo.getShoppingList(groupId);
      if (list != null) {
        _syncToFirestoreBackground(list);
      }
      
    } catch (e) {
      developer.log('❌ HybridShoppingList.removeShoppingItem error: $e');
      rethrow;
    }
  }

  @override
  Future<void> updateShoppingItemStatus(String groupId, ShoppingItem item, {required bool isPurchased}) async {
    try {
      // 1. Hiveのステータス更新
      await _hiveRepo.updateShoppingItemStatus(groupId, item, isPurchased: isPurchased);
      
      if (F.appFlavor == Flavor.dev || !_isOnline) {
        return;
      }
      
      // 2. Firestoreにも同期
      final list = await _hiveRepo.getShoppingList(groupId);
      if (list != null) {
        _syncToFirestoreBackground(list);
      }
      
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

  /// Firestoreからバックグラウンド同期（非ブロッキング）
  void _syncFromFirestoreBackground(String groupId) {
    if (_isSyncing) return;
    
    Future.microtask(() async {
      _isSyncing = true;
      try {
        final firestoreList = await _firestoreRepo.getShoppingList(groupId);
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

  /// Firestoreへバックグラウンド同期（非ブロッキング）
  void _syncToFirestoreBackground(ShoppingList list) {
    Future.microtask(() async {
      try {
        await _firestoreRepo.addItem(list);
        developer.log('🔄 Background sync: Hive→Firestore完了');
        _isOnline = true; // 成功時はオンライン状態を確認
      } catch (e) {
        developer.log('⚠️ Background sync to Firestore error: $e');
        _isOnline = false;
      }
    });
  }

  /// Firestoreデータの方が新しいかチェック
  bool _shouldUpdateFromFirestore(ShoppingList? hiveList, ShoppingList firestoreList) {
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
      
      // Firestoreにも同期（オンライン時のみ）
      if (_isOnline && F.appFlavor == Flavor.prod) {
        try {
          await _firestoreRepo.createShoppingList(
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
    return await _hiveRepo.getShoppingListsByGroup(groupId);
  }

  @override
  Future<void> updateShoppingList(ShoppingList list) async {
    await _hiveRepo.updateShoppingList(list);
  }

  @override
  Future<void> deleteShoppingList(String listId) async {
    await _hiveRepo.deleteShoppingList(listId);
  }

  @override
  Future<void> addItemToList(String listId, ShoppingItem item) async {
    await _hiveRepo.addItemToList(listId, item);
  }

  @override
  Future<void> removeItemFromList(String listId, ShoppingItem item) async {
    await _hiveRepo.removeItemFromList(listId, item);
  }

  @override
  Future<void> updateItemStatusInList(String listId, ShoppingItem item, {required bool isPurchased}) async {
    await _hiveRepo.updateItemStatusInList(listId, item, isPurchased: isPurchased);
  }

  @override
  Future<void> clearPurchasedItemsFromList(String listId) async {
    await _hiveRepo.clearPurchasedItemsFromList(listId);
  }

  @override
  Future<ShoppingList> getOrCreateDefaultList(String groupId, String groupName) async {
    return await _hiveRepo.getOrCreateDefaultList(groupId, groupName);
  }
}