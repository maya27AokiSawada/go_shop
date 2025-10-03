// lib/providers/shopping_list_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/shopping_list.dart';
import '../providers/purchase_group_provider.dart';
import '../datastore/shopping_list_repository.dart';
import '../datastore/firebase_shopping_list_repository.dart';
import '../flavors.dart';

// ShoppingListのBox管理
final shoppingListBoxProvider = Provider<Box<ShoppingList>>((ref) {
  return Hive.box<ShoppingList>('shoppingLists');
});

// ShoppingListRepositoryのプロバイダー
final shoppingListRepositoryProvider = Provider<ShoppingListRepository>((ref) {
  if (F.appFlavor == Flavor.prod) {
    throw UnimplementedError('Firestore ShoppingListRepository is not implemented yet');
  } else {
    // 開発環境でもFirebase同期リポジトリを使用
    return FirebaseSyncShoppingListRepository(ref);
  }
});

// ShoppingListの状態管理
final shoppingListProvider = AsyncNotifierProvider<ShoppingListNotifier, ShoppingList>(
  () => ShoppingListNotifier(),
);

class ShoppingListNotifier extends AsyncNotifier<ShoppingList> {
  static const String _key = 'current_list';

  @override
  Future<ShoppingList> build() async {
    final repository = ref.read(shoppingListRepositoryProvider);
    final purchaseGroupAsync = ref.watch(purchaseGroupProvider);
    
    return await purchaseGroupAsync.when(
      data: (purchaseGroup) async {
        final savedList = await repository.getShoppingList(_key);
        if (savedList != null) {
          print('🛒 ShoppingListNotifier: Hiveから既存リストを読み込み (${savedList.items.length}アイテム)');
          // 既存リストのグループ情報を更新
          final updatedList = ShoppingList(
            ownerUid: purchaseGroup.ownerUid ?? '',
            groupId: purchaseGroup.groupId,
            groupName: purchaseGroup.groupName,
            items: savedList.items,
          );
          // 更新された情報をHiveに保存
          await repository.addItem(updatedList.copyWith(groupId: _key));
          return updatedList;
        } else {
          print('🛒 ShoppingListNotifier: 新しいリストを作成');
          // 新しいリストを作成してHiveに保存
          final newList = ShoppingList(
            ownerUid: purchaseGroup.ownerUid ?? '',
            groupId: purchaseGroup.groupId,
            groupName: purchaseGroup.groupName,
            items: [],
          );
          await repository.addItem(newList.copyWith(groupId: _key));
          return newList;
        }
      },
      loading: () => const ShoppingList(
        ownerUid: '',
        groupId: 'loading',
        groupName: 'Loading...',
        items: [],
      ),
      error: (error, stack) => const ShoppingList(
        ownerUid: '',
        groupId: 'error',
        groupName: 'Error',
        items: [],
      ),
    );
  }

  Future<void> addItem(ShoppingItem item) async {
    try {
      final repository = ref.read(shoppingListRepositoryProvider);
      final currentList = await future;
      final updatedItems = [...currentList.items, item];
      final updatedList = ShoppingList(
        ownerUid: currentList.ownerUid,
        groupId: currentList.groupId,
        groupName: currentList.groupName,
        items: updatedItems,
      );
      
      // Hiveに保存
      await repository.addItem(updatedList.copyWith(groupId: _key));
      print('🛒 ShoppingListNotifier: アイテム「${item.name}」を追加してHiveに保存');
      
      // 状態を更新
      state = AsyncValue.data(updatedList);
    } catch (e) {
      print('❌ ShoppingListNotifier: アイテム追加エラー: $e');
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> removeItem(ShoppingItem item) async {
    try {
      final repository = ref.read(shoppingListRepositoryProvider);
      final currentList = await future;
      final updatedItems = currentList.items.where((i) =>
        i.memberId != item.memberId || i.name != item.name
      ).toList();
      
      final updatedList = ShoppingList(
        ownerUid: currentList.ownerUid,
        groupId: currentList.groupId,
        groupName: currentList.groupName,
        items: updatedItems,
      );
      
      // Hiveに保存
      await repository.addItem(updatedList.copyWith(groupId: _key));
      print('🛒 ShoppingListNotifier: アイテム「${item.name}」を削除してHiveに保存');
      
      // 状態を更新
      state = AsyncValue.data(updatedList);
    } catch (e) {
      print('❌ ShoppingListNotifier: アイテム削除エラー: $e');
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> updateItem(ShoppingItem oldItem, ShoppingItem newItem) async {
    try {
      final repository = ref.read(shoppingListRepositoryProvider);
      final currentList = await future;
      final updatedItems = currentList.items.map((item) {
        if (item.memberId == oldItem.memberId && item.name == oldItem.name) {
          return newItem;
        }
        return item;
      }).toList();
      
      final updatedList = ShoppingList(
        ownerUid: currentList.ownerUid,
        groupId: currentList.groupId,
        groupName: currentList.groupName,
        items: updatedItems,
      );
      
      // Hiveに保存
      await repository.addItem(updatedList.copyWith(groupId: _key));
      print('🛒 ShoppingListNotifier: アイテム「${newItem.name}」を更新してHiveに保存');
      
      // 状態を更新
      state = AsyncValue.data(updatedList);
    } catch (e) {
      print('❌ ShoppingListNotifier: アイテム更新エラー: $e');
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> togglePurchased(ShoppingItem item) async {
    try {
      final repository = ref.read(shoppingListRepositoryProvider);
      final currentList = await future;
      final updatedItems = currentList.items.map((i) {
        if (i.memberId == item.memberId && i.name == item.name) {
          return ShoppingItem(
            memberId: i.memberId,
            name: i.name,
            quantity: i.quantity,
            registeredDate: i.registeredDate,
            purchaseDate: i.isPurchased ? null : DateTime.now(),
            isPurchased: !i.isPurchased,
            shoppingInterval: i.shoppingInterval,
          );
        }
        return i;
      }).toList();
      
      final updatedList = ShoppingList(
        ownerUid: currentList.ownerUid,
        groupId: currentList.groupId,
        groupName: currentList.groupName,
        items: updatedItems,
      );
      
      // Hiveに保存
      await repository.addItem(updatedList.copyWith(groupId: _key));
      print('🛒 ShoppingListNotifier: アイテム「${item.name}」の購入状態を変更してHiveに保存');
      
      // 状態を更新
      state = AsyncValue.data(updatedList);
    } catch (e) {
      print('❌ ShoppingListNotifier: 購入状態変更エラー: $e');
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> clearPurchasedItems() async {
    try {
      final repository = ref.read(shoppingListRepositoryProvider);
      final currentList = await future;
      final unpurchasedItems = currentList.items.where((item) => !item.isPurchased).toList();
      
      final updatedList = ShoppingList(
        ownerUid: currentList.ownerUid,
        groupId: currentList.groupId,
        groupName: currentList.groupName,
        items: unpurchasedItems,
      );
      
      // Hiveに保存
      await repository.addItem(updatedList.copyWith(groupId: _key));
      print('🛒 ShoppingListNotifier: 購入済みアイテムを削除してHiveに保存');
      
      // 状態を更新
      state = AsyncValue.data(updatedList);
    } catch (e) {
      print('❌ ShoppingListNotifier: 購入済みアイテム削除エラー: $e');
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  // ShoppingList全体を更新するメソッド
  Future<void> updateShoppingList(ShoppingList newShoppingList) async {
    try {
      final repository = ref.read(shoppingListRepositoryProvider);
      // Hiveに保存
      await repository.addItem(newShoppingList.copyWith(groupId: _key));
      print('🛒 ShoppingListNotifier: ShoppingList全体を更新してHiveに保存');
      
      // 状態を更新
      state = AsyncValue.data(newShoppingList);
    } catch (e) {
      print('❌ ShoppingListNotifier: ShoppingList更新エラー: $e');
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  // リポジトリ経由でHive保存を行うため、_saveToBoxメソッドは削除
}

// 購入済みアイテムのフィルタープロバイダー
final purchasedItemsProvider = Provider<List<ShoppingItem>>((ref) {
  final shoppingListAsync = ref.watch(shoppingListProvider);
  return shoppingListAsync.when(
    data: (list) => list.items.where((item) => item.isPurchased).toList(),
    loading: () => [],
    error: (error, stack) => [],
  );
});

// 未購入アイテムのフィルタープロバイダー
final unpurchasedItemsProvider = Provider<List<ShoppingItem>>((ref) {
  final shoppingListAsync = ref.watch(shoppingListProvider);
  return shoppingListAsync.when(
    data: (list) => list.items.where((item) => !item.isPurchased).toList(),
    loading: () => [],
    error: (error, stack) => [],
  );
});

// メンバー別アイテムのフィルタープロバイダー
final itemsByMemberProvider = Provider.family<List<ShoppingItem>, String>((ref, memberId) {
  final shoppingListAsync = ref.watch(shoppingListProvider);
  return shoppingListAsync.when(
    data: (list) => list.items.where((item) => item.memberId == memberId).toList(),
    loading: () => [],
    error: (error, stack) => [],
  );
});