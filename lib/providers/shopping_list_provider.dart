import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../utils/app_logger.dart';
import '../models/shopping_list.dart';
import '../providers/purchase_group_provider.dart';
import '../datastore/shopping_list_repository.dart';
import '../datastore/hive_shopping_list_repository.dart';
import '../datastore/hybrid_shopping_list_repository.dart';
import '../flavors.dart';

// ShoppingListのBox管理
final shoppingListBoxProvider = Provider<Box<ShoppingList>>((ref) {
  return Hive.box<ShoppingList>('shoppingLists');
});

// ShoppingListRepositoryのプロバイダー - ハイブリッド構成に統一
final shoppingListRepositoryProvider = Provider<ShoppingListRepository>((ref) {
  if (F.appFlavor == Flavor.prod) {
    // 本番環境: ハイブリッド（Hive + Firestore）を使用
    return HybridShoppingListRepository(ref);
  } else {
    // 開発環境: Hiveリポジトリを使用（ローカルのみ）
    return HiveShoppingListRepository(ref);
  }
});

// ShoppingListの状態管理
final shoppingListProvider =
    AsyncNotifierProvider<ShoppingListNotifier, ShoppingList>(
  () => ShoppingListNotifier(),
);

// グループ別のShoppingListプロバイダー
final shoppingListForGroupProvider = AsyncNotifierProvider.family<
    ShoppingListForGroupNotifier, ShoppingList, String>(
  () => ShoppingListForGroupNotifier(),
);

class ShoppingListNotifier extends AsyncNotifier<ShoppingList> {
  static const String _key = 'current_list';

  @override
  Future<ShoppingList> build() async {
    final repository = ref.read(shoppingListRepositoryProvider);
    final SharedGroupAsync = ref.watch(selectedGroupProvider);

    return await SharedGroupAsync.when(
      data: (SharedGroup) async {
        // SharedGroup が null の場合はデフォルトリストを返す
        if (SharedGroup == null) {
          final defaultList = ShoppingList.create(
            ownerUid: '',
            groupId: 'default',
            groupName: 'デフォルトグループ',
            listName: 'デフォルトリスト',
            description: '',
            items: [],
          );
          return defaultList;
        }

        final savedList = await repository.getShoppingList(_key);
        if (savedList != null) {
          Log.info(
              '🛒 ShoppingListNotifier: Hiveから既存リストを読み込み (${savedList.items.length}アイテム)');
          // 既存リストのグループ情報を更新
          final updatedList = savedList.copyWith(
            ownerUid: SharedGroup.ownerUid ?? savedList.ownerUid,
            groupId: SharedGroup.groupId,
            groupName: SharedGroup.groupName,
            items: savedList.items,
          );
          // 更新された情報をHiveに保存
          await repository.addItem(updatedList.copyWith(groupId: _key));
          return updatedList;
        } else {
          Log.info('🛒 ShoppingListNotifier: 新しいリストを作成');
          // 新しいリストを作成してHiveに保存
          final newList = ShoppingList.create(
            ownerUid: SharedGroup.ownerUid ?? '',
            groupId: SharedGroup.groupId,
            groupName: SharedGroup.groupName,
            listName: SharedGroup.groupName,
            description: '',
            items: [],
          );
          await repository.addItem(newList.copyWith(groupId: _key));
          return newList;
        }
      },
      loading: () => ShoppingList.create(
        ownerUid: '',
        groupId: 'loading',
        groupName: 'Loading...',
        listName: 'Loading...',
        description: '',
        items: [],
      ),
      error: (error, stack) => ShoppingList.create(
        ownerUid: '',
        groupId: 'error',
        groupName: 'Error',
        listName: 'Error',
        description: '',
        items: [],
      ),
    );
  }

  Future<void> addItem(ShoppingItem item) async {
    state = await AsyncValue.guard(() async {
      final repository = ref.read(shoppingListRepositoryProvider);
      final currentList = await future;
      final updatedItems = [...currentList.items, item];
      final updatedList = currentList.copyWith(items: updatedItems);

      // Hiveに保存
      await repository.addItem(updatedList.copyWith(groupId: _key));
      Log.info('🛒 ShoppingListNotifier: アイテム「${item.name}」を追加してHiveに保存');

      return updatedList;
    });
  }

  Future<void> removeItem(ShoppingItem item) async {
    state = await AsyncValue.guard(() async {
      final repository = ref.read(shoppingListRepositoryProvider);
      final currentList = await future;
      final updatedItems = currentList.items
          .where((i) => i.memberId != item.memberId || i.name != item.name)
          .toList();

      final updatedList = currentList.copyWith(items: updatedItems);

      // Hiveに保存
      await repository.addItem(updatedList.copyWith(groupId: _key));
      Log.info('🛒 ShoppingListNotifier: アイテム「${item.name}」を削除してHiveに保存');

      return updatedList;
    });
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

      final updatedList = currentList.copyWith(items: updatedItems);

      // Hiveに保存
      await repository.addItem(updatedList.copyWith(groupId: _key));
      Log.info('🛒 ShoppingListNotifier: アイテム「${newItem.name}」を更新してHiveに保存');

      // 状態を更新
      state = AsyncValue.data(updatedList);
    } catch (e) {
      Log.info('❌ ShoppingListNotifier: アイテム更新エラー: $e');
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> togglePurchased(ShoppingItem item) async {
    state = await AsyncValue.guard(() async {
      final repository = ref.read(shoppingListRepositoryProvider);
      final currentList = await future;
      final updatedItems = currentList.items.map((i) {
        if (i.memberId == item.memberId && i.name == item.name) {
          // 未購入に戻す時のdeadline処理
          DateTime? newDeadline;
          if (i.isPurchased) {
            // 購入済み → 未購入に戻す場合
            if (i.shoppingInterval > 0 && i.shoppingInterval <= 7) {
              // 1週間以内の間隔の場合、deadline を1日後に設定
              newDeadline = DateTime.now().add(const Duration(days: 1));
            } else {
              // 元のdeadlineを保持
              newDeadline = i.deadline;
            }
          } else {
            // 未購入 → 購入済みの場合、元のdeadlineを保持
            newDeadline = i.deadline;
          }

          return ShoppingItem(
            memberId: i.memberId,
            name: i.name,
            quantity: i.quantity,
            registeredDate: i.registeredDate,
            purchaseDate: i.isPurchased ? null : DateTime.now(), // 購入時に現在日時を設定
            isPurchased: !i.isPurchased,
            shoppingInterval: i.shoppingInterval,
            deadline: newDeadline,
          );
        }
        return i;
      }).toList();

      final updatedList = currentList.copyWith(items: updatedItems);

      // Hiveに保存
      await repository.addItem(updatedList.copyWith(groupId: _key));
      Log.info('🛒 ShoppingListNotifier: アイテム「${item.name}」の購入状態を変更してHiveに保存');

      return updatedList;
    });
  }

  Future<void> clearPurchasedItems() async {
    try {
      final repository = ref.read(shoppingListRepositoryProvider);
      final currentList = await future;
      final unpurchasedItems =
          currentList.items.where((item) => !item.isPurchased).toList();

      final updatedList = currentList.copyWith(items: unpurchasedItems);

      // Hiveに保存
      await repository.addItem(updatedList.copyWith(groupId: _key));
      Log.info('🛒 ShoppingListNotifier: 購入済みアイテムを削除してHiveに保存');

      // 状態を更新
      state = AsyncValue.data(updatedList);
    } catch (e) {
      Log.info('❌ ShoppingListNotifier: 購入済みアイテム削除エラー: $e');
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  // ShoppingList全体を更新するメソッド
  Future<void> updateShoppingList(ShoppingList newShoppingList) async {
    try {
      final repository = ref.read(shoppingListRepositoryProvider);
      // Hiveに保存
      await repository.addItem(newShoppingList.copyWith(groupId: _key));
      Log.info('🛒 ShoppingListNotifier: ShoppingList全体を更新してHiveに保存');

      // 状態を更新
      state = AsyncValue.data(newShoppingList);
    } catch (e) {
      Log.info('❌ ShoppingListNotifier: ShoppingList更新エラー: $e');
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
final itemsByMemberProvider =
    Provider.family<List<ShoppingItem>, String>((ref, memberId) {
  final shoppingListAsync = ref.watch(shoppingListProvider);
  return shoppingListAsync.when(
    data: (list) =>
        list.items.where((item) => item.memberId == memberId).toList(),
    loading: () => [],
    error: (error, stack) => [],
  );
});

// グループ別のShoppingListNotifier
class ShoppingListForGroupNotifier
    extends FamilyAsyncNotifier<ShoppingList, String> {
  @override
  Future<ShoppingList> build(String groupId) async {
    final repository = ref.read(shoppingListRepositoryProvider);

    try {
      // 指定されたグループIDのリストを取得または作成
      final existingList =
          await repository.getOrCreateList(groupId, '$groupIdのリスト');
      Log.info(
          '🛒 ShoppingListForGroupNotifier: グループ$groupId のリストを読み込み (${existingList.items.length}アイテム)');
      return existingList;
    } catch (e) {
      Log.error('❌ ShoppingListForGroupNotifier: グループ$groupId のリスト読み込みエラー: $e');
      // エラー時は空のリストを作成
      return ShoppingList.create(
        ownerUid: '',
        groupId: groupId,
        groupName: '$groupIdのリスト',
        listName: '$groupIdのリスト',
        description: '',
        items: [],
      );
    }
  }

  Future<void> addItem(ShoppingItem item) async {
    try {
      final repository = ref.read(shoppingListRepositoryProvider);
      final currentList = await future;
      final updatedItems = [...currentList.items, item];
      final updatedList = currentList.copyWith(items: updatedItems);

      // リポジトリに保存
      await repository.addItem(updatedList);
      Log.info('🛒 ShoppingListForGroupNotifier: アイテム「${item.name}」を追加');

      // 状態を更新
      state = AsyncValue.data(updatedList);
    } catch (e) {
      Log.error('❌ ShoppingListForGroupNotifier: アイテム追加エラー: $e');
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> removeItem(ShoppingItem item) async {
    try {
      final repository = ref.read(shoppingListRepositoryProvider);
      final currentList = await future;
      final updatedItems = currentList.items
          .where((i) => i.memberId != item.memberId || i.name != item.name)
          .toList();
      final updatedList = currentList.copyWith(items: updatedItems);

      // リポジトリに保存
      await repository.addItem(updatedList);
      Log.info('🛒 ShoppingListForGroupNotifier: アイテム「${item.name}」を削除');

      // 状態を更新
      state = AsyncValue.data(updatedList);
    } catch (e) {
      Log.error('❌ ShoppingListForGroupNotifier: アイテム削除エラー: $e');
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> togglePurchased(ShoppingItem item) async {
    try {
      final repository = ref.read(shoppingListRepositoryProvider);
      final currentList = await future;
      final updatedItems = currentList.items.map((i) {
        if (i.memberId == item.memberId && i.name == item.name) {
          return i.copyWith(isPurchased: !i.isPurchased);
        }
        return i;
      }).toList();
      final updatedList = currentList.copyWith(items: updatedItems);

      // リポジトリに保存
      await repository.addItem(updatedList);
      Log.info('🛒 ShoppingListForGroupNotifier: アイテム「${item.name}」の購入状態を切り替え');

      // 状態を更新
      state = AsyncValue.data(updatedList);
    } catch (e) {
      Log.error('❌ ShoppingListForGroupNotifier: 購入状態切り替えエラー: $e');
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> updateItem(ShoppingItem oldItem, ShoppingItem newItem) async {
    try {
      final repository = ref.read(shoppingListRepositoryProvider);
      final currentList = await future;
      final updatedItems = currentList.items.map((i) {
        if (i.memberId == oldItem.memberId && i.name == oldItem.name) {
          return newItem;
        }
        return i;
      }).toList();
      final updatedList = currentList.copyWith(items: updatedItems);

      // リポジトリに保存
      await repository.addItem(updatedList);
      Log.info(
          '🛒 ShoppingListForGroupNotifier: アイテム「${oldItem.name}」を「${newItem.name}」に更新');

      // 状態を更新
      state = AsyncValue.data(updatedList);
    } catch (e) {
      Log.error('❌ ShoppingListForGroupNotifier: アイテム更新エラー: $e');
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> clearPurchasedItems() async {
    try {
      final repository = ref.read(shoppingListRepositoryProvider);
      final currentList = await future;
      final updatedItems =
          currentList.items.where((item) => !item.isPurchased).toList();
      final updatedList = currentList.copyWith(items: updatedItems);

      // リポジトリに保存
      await repository.addItem(updatedList);
      Log.info('🛒 ShoppingListForGroupNotifier: 購入済みアイテムをクリア');

      // 状態を更新
      state = AsyncValue.data(updatedList);
    } catch (e) {
      Log.error('❌ ShoppingListForGroupNotifier: 購入済みアイテムクリアエラー: $e');
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
}
