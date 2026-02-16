import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../utils/app_logger.dart';
import '../models/shared_list.dart';
import '../providers/purchase_group_provider.dart';
import '../datastore/shared_list_repository.dart';
import '../datastore/hybrid_shared_list_repository.dart';

// SharedListのBox管理
final sharedListBoxProvider = Provider<Box<SharedList>>((ref) {
  return Hive.box<SharedList>('sharedLists');
});

// SharedListRepositoryのプロバイダー - ハイブリッド構成に統一
final sharedListRepositoryProvider = Provider<SharedListRepository>((ref) {
  // 🔥 devフレーバーもprodフレーバーも同じ機能（Firestore + Hive）を使用
  // 違いはFirebaseプロジェクトのみ（gotoshop-572b7 vs goshopping-48db9）
  return HybridSharedListRepository(ref);
});

// SharedListの状態管理
final sharedListProvider =
    AsyncNotifierProvider<SharedListNotifier, SharedList>(
  () => SharedListNotifier(),
);

// グループ別のSharedListプロバイダー
final sharedListForGroupProvider = AsyncNotifierProvider.family<
    SharedListForGroupNotifier, SharedList, String>(
  () => SharedListForGroupNotifier(),
);

class SharedListNotifier extends AsyncNotifier<SharedList> {
  static const String _key = 'current_list';

  @override
  Future<SharedList> build() async {
    final repository = ref.read(sharedListRepositoryProvider);
    final SharedGroupAsync = ref.watch(selectedGroupProvider);

    return await SharedGroupAsync.when(
      data: (SharedGroup) async {
        // SharedGroup が null の場合はデフォルトリストを返す
        if (SharedGroup == null) {
          final defaultList = SharedList.create(
            ownerUid: '',
            groupId: 'default',
            groupName: 'デフォルトグループ',
            listName: 'デフォルトリスト',
            description: '',
            items: {},
          );
          return defaultList;
        }

        final savedList = await repository.getSharedList(_key);
        if (savedList != null) {
          Log.info(
              '🛍️ SharedListNotifier: Hiveから既存リストを読み込み (${savedList.activeItems.length}アイテム)'); // 🆕 activeItems使用
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
          Log.info('🛒 SharedListNotifier: 新しいリストを作成');
          // 新しいリストを作成してHiveに保存
          final newList = SharedList.create(
            ownerUid: SharedGroup.ownerUid ?? '',
            groupId: SharedGroup.groupId,
            groupName: SharedGroup.groupName,
            listName: SharedGroup.groupName,
            description: '',
            items: {},
          );
          await repository.addItem(newList.copyWith(groupId: _key));
          return newList;
        }
      },
      loading: () => SharedList.create(
        ownerUid: '',
        groupId: 'loading',
        groupName: 'Loading...',
        listName: 'Loading...',
        description: '',
        items: {},
      ),
      error: (error, stack) => SharedList.create(
        ownerUid: '',
        groupId: 'error',
        groupName: 'Error',
        listName: 'Error',
        description: '',
        items: {},
      ),
    );
  }

  Future<void> addItem(SharedItem item) async {
    state = await AsyncValue.guard(() async {
      final repository = ref.read(sharedListRepositoryProvider);
      final currentList = await future;
      final updatedItems = {...currentList.items, item.itemId: item};
      final updatedList = currentList.copyWith(items: updatedItems);

      // Hiveに保存
      await repository.addItem(updatedList.copyWith(groupId: _key));
      Log.info('🛒 SharedListNotifier: アイテム「${item.name}」を追加してHiveに保存');

      return updatedList;
    });
  }

  Future<void> removeItem(SharedItem item) async {
    state = await AsyncValue.guard(() async {
      final repository = ref.read(sharedListRepositoryProvider);
      final currentList = await future;
      final updatedItems = Map<String, SharedItem>.from(currentList.items)
        ..remove(item.itemId);

      final updatedList = currentList.copyWith(items: updatedItems);

      // Hiveに保存
      await repository.addItem(updatedList.copyWith(groupId: _key));
      Log.info('🛒 SharedListNotifier: アイテム「${item.name}」を削除してHiveに保存');

      return updatedList;
    });
  }

  Future<void> updateItem(SharedItem oldItem, SharedItem newItem) async {
    try {
      final repository = ref.read(sharedListRepositoryProvider);
      final currentList = await future;

      // 🆕 Map形式対応: itemIdで直接更新
      final updatedItems = Map<String, SharedItem>.from(currentList.items);
      updatedItems[newItem.itemId] = newItem;

      final updatedList = currentList.copyWith(items: updatedItems);

      // Hiveに保存
      await repository.addItem(updatedList.copyWith(groupId: _key));
      Log.info('🛒 SharedListNotifier: アイテム「${newItem.name}」を更新してHiveに保存');

      // 状態を更新
      state = AsyncValue.data(updatedList);
    } catch (e) {
      Log.info('❌ SharedListNotifier: アイテム更新エラー: $e');
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> togglePurchased(SharedItem item) async {
    state = await AsyncValue.guard(() async {
      final repository = ref.read(sharedListRepositoryProvider);
      final currentList = await future;

      // 🆕 Map形式対応: itemIdで直接アクセス
      final updatedItems = Map<String, SharedItem>.from(currentList.items);

      if (updatedItems.containsKey(item.itemId)) {
        final i = updatedItems[item.itemId]!;
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

        updatedItems[item.itemId] = SharedItem(
          memberId: i.memberId,
          name: i.name,
          quantity: i.quantity,
          registeredDate: i.registeredDate,
          purchaseDate: i.isPurchased ? null : DateTime.now(), // 購入時に現在日時を設定
          isPurchased: !i.isPurchased,
          shoppingInterval: i.shoppingInterval,
          deadline: newDeadline,
          itemId: i.itemId, // 🆕 必須フィールド
        );
      }

      final updatedList = currentList.copyWith(items: updatedItems);

      // Hiveに保存
      await repository.addItem(updatedList.copyWith(groupId: _key));
      Log.info('🛒 SharedListNotifier: アイテム「${item.name}」の購入状態を変更してHiveに保存');

      return updatedList;
    });
  }

  Future<void> clearPurchasedItems() async {
    try {
      final repository = ref.read(sharedListRepositoryProvider);
      final currentList = await future;

      // 🆕 activeItemsから未購入のみ残す（Map形式）
      final remainingItems = <String, SharedItem>{};
      currentList.activeItems
          .where((item) => !item.isPurchased)
          .forEach((item) {
        remainingItems[item.itemId] = item;
      });

      final updatedList = currentList.copyWith(items: remainingItems);

      // Hiveに保存
      await repository.addItem(updatedList.copyWith(groupId: _key));
      Log.info('🛍️ SharedListNotifier: 購入済みアイテムを削除してHiveに保存');

      // 状態を更新
      state = AsyncValue.data(updatedList);
    } catch (e) {
      Log.info('❌ SharedListNotifier: 購入済みアイテム削除エラー: $e');
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  // SharedList全体を更新するメソッド
  Future<void> updateSharedList(SharedList newSharedList) async {
    try {
      final repository = ref.read(sharedListRepositoryProvider);
      // Hiveに保存
      await repository.addItem(newSharedList.copyWith(groupId: _key));
      Log.info('🛒 SharedListNotifier: SharedList全体を更新してHiveに保存');

      // 状態を更新
      state = AsyncValue.data(newSharedList);
    } catch (e) {
      Log.info('❌ SharedListNotifier: SharedList更新エラー: $e');
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  // リポジトリ経由でHive保存を行うため、_saveToBoxメソッドは削除
}

// 購入済みアイテムのフィルタープロバイダー
final purchasedItemsProvider = Provider<List<SharedItem>>((ref) {
  final sharedListAsync = ref.watch(sharedListProvider);
  return sharedListAsync.when(
    data: (list) => list.activeItems
        .where((item) => item.isPurchased)
        .toList(), // 🆕 activeItems使用
    loading: () => [],
    error: (error, stack) => [],
  );
});

// 未購入アイテムのフィルタープロバイダー
final unpurchasedItemsProvider = Provider<List<SharedItem>>((ref) {
  final sharedListAsync = ref.watch(sharedListProvider);
  return sharedListAsync.when(
    data: (list) => list.activeItems
        .where((item) => !item.isPurchased)
        .toList(), // 🆕 activeItems使用
    loading: () => [],
    error: (error, stack) => [],
  );
});

// メンバー別アイテムのフィルタープロバイダー
final itemsByMemberProvider =
    Provider.family<List<SharedItem>, String>((ref, memberId) {
  final sharedListAsync = ref.watch(sharedListProvider);
  return sharedListAsync.when(
    data: (list) => list.activeItems
        .where((item) => item.memberId == memberId)
        .toList(), // 🆕 activeItems使用
    loading: () => [],
    error: (error, stack) => [],
  );
});

// グループ別のSharedListNotifier
class SharedListForGroupNotifier
    extends FamilyAsyncNotifier<SharedList, String> {
  @override
  Future<SharedList> build(String groupId) async {
    final repository = ref.read(sharedListRepositoryProvider);

    try {
      // 指定されたグループIDのリストを取得または作成
      final existingList =
          await repository.getOrCreateList(groupId, '$groupIdのリスト');
      Log.info(
          '🛒 SharedListForGroupNotifier: グループ$groupId のリストを読み込み (${existingList.items.length}アイテム)');
      return existingList;
    } catch (e) {
      Log.error('❌ SharedListForGroupNotifier: グループ$groupId のリスト読み込みエラー: $e');
      // エラー時は空のリストを作成
      return SharedList.create(
        ownerUid: '',
        groupId: groupId,
        groupName: '$groupIdのリスト',
        listName: '$groupIdのリスト',
        description: '',
        items: {}, // 🆕 Map形式
      );
    }
  }

  Future<void> addItem(SharedItem item) async {
    try {
      final repository = ref.read(sharedListRepositoryProvider);
      final currentList = await future;

      // 🆕 Map形式対応
      final updatedItems = Map<String, SharedItem>.from(currentList.items);
      updatedItems[item.itemId] = item;

      final updatedList = currentList.copyWith(items: updatedItems);

      // リポジトリに保存
      await repository.addItem(updatedList);
      Log.info('🛍️ SharedListForGroupNotifier: アイテム「${item.name}」を追加');

      // 状態を更新
      state = AsyncValue.data(updatedList);
    } catch (e) {
      Log.error('❌ SharedListForGroupNotifier: アイテム追加エラー: $e');
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> removeItem(SharedItem item) async {
    try {
      final repository = ref.read(sharedListRepositoryProvider);
      final currentList = await future;

      // 🆕 Map形式対応: itemIdで削除
      final updatedItems = Map<String, SharedItem>.from(currentList.items);
      updatedItems.remove(item.itemId);

      final updatedList = currentList.copyWith(items: updatedItems);

      // リポジトリに保存
      await repository.addItem(updatedList);
      Log.info('🛍️ SharedListForGroupNotifier: アイテム「${item.name}」を削除');

      // 状態を更新
      state = AsyncValue.data(updatedList);
    } catch (e) {
      Log.error('❌ SharedListForGroupNotifier: アイテム削除エラー: $e');
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> togglePurchased(SharedItem item) async {
    try {
      final repository = ref.read(sharedListRepositoryProvider);
      final currentList = await future;

      // 🆕 Map形式対応
      final updatedItems = Map<String, SharedItem>.from(currentList.items);
      if (updatedItems.containsKey(item.itemId)) {
        updatedItems[item.itemId] =
            updatedItems[item.itemId]!.copyWith(isPurchased: !item.isPurchased);
      }

      final updatedList = currentList.copyWith(items: updatedItems);

      // リポジトリに保存
      await repository.addItem(updatedList);
      Log.info('🛍️ SharedListForGroupNotifier: アイテム「${item.name}」の購入状態を切り替え');

      // 状態を更新
      state = AsyncValue.data(updatedList);
    } catch (e) {
      Log.error('❌ SharedListForGroupNotifier: 購入状態切り替えエラー: $e');
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> updateItem(SharedItem oldItem, SharedItem newItem) async {
    try {
      final repository = ref.read(sharedListRepositoryProvider);
      final currentList = await future;

      // 🆕 Map形式対応: itemIdで更新
      final updatedItems = Map<String, SharedItem>.from(currentList.items);
      updatedItems[newItem.itemId] = newItem;

      final updatedList = currentList.copyWith(items: updatedItems);

      // リポジトリに保存
      await repository.addItem(updatedList);
      Log.info(
          '🛍️ SharedListForGroupNotifier: アイテム「${oldItem.name}」を「${newItem.name}」に更新');

      // 状態を更新
      state = AsyncValue.data(updatedList);
    } catch (e) {
      Log.error('❌ SharedListForGroupNotifier: アイテム更新エラー: $e');
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> clearPurchasedItems() async {
    try {
      final repository = ref.read(sharedListRepositoryProvider);
      final currentList = await future;

      // 🆕 activeItemsから未購入のみ残す（Map形式）
      final remainingItems = <String, SharedItem>{};
      currentList.activeItems
          .where((item) => !item.isPurchased)
          .forEach((item) {
        remainingItems[item.itemId] = item;
      });

      final updatedList = currentList.copyWith(items: remainingItems);

      // リポジトリに保存
      await repository.addItem(updatedList);
      Log.info('🛍️ SharedListForGroupNotifier: 購入済みアイテムをクリア');

      // 状態を更新
      state = AsyncValue.data(updatedList);
    } catch (e) {
      Log.error('❌ SharedListForGroupNotifier: 購入済みアイテムクリアエラー: $e');
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
}
