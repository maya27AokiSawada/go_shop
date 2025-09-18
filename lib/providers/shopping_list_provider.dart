// lib/providers/hive_shopping_list_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/shopping_list.dart';

class ShoppingListNotifier extends StateNotifier<ShoppingList> {
  final Box<ShoppingList> _box;
  static const String _key = 'current_list';

  ShoppingListNotifier(this._box) : super(ShoppingList(items: [])) {
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final savedList = _box.get(_key);
    if (savedList != null) {
      state = savedList;
    }
  }

  Future<void> addItem(ShoppingItem item) async {
    final updatedItems = [...state.items, item];
    state = ShoppingList(items: updatedItems);
    await _box.put(_key, state);
  }

  Future<void> removeItem(ShoppingItem item) async {
    final updatedItems = state.items.where((i) =>
    i.memberId != item.memberId || i.name != item.name
    ).toList();
    state = ShoppingList(items: updatedItems);
    await _box.put(_key, state);
  }

  Future<void> updateItem(ShoppingItem oldItem, ShoppingItem newItem) async {
    final updatedItems = state.items.map((item) {
      if (item.memberId == oldItem.memberId && item.name == oldItem.name) {
        return newItem;
      }
      return item;
    }).toList();
    state = ShoppingList(items: updatedItems);
    await _box.put(_key, state);
  }

  Future<void> togglePurchased(ShoppingItem item) async {
    final updatedItems = state.items.map((i) {
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
    state = ShoppingList(items: updatedItems);
    await _box.put(_key, state);
  }
}

final shoppingListBoxProvider = Provider<Box<ShoppingList>>((ref) {
  throw UnimplementedError('Boxを初期化してから使用してください');
});

final shoppingListProvider = StateNotifierProvider<ShoppingListNotifier, ShoppingList>((ref) {
  final box = ref.watch(shoppingListBoxProvider);
  return ShoppingListNotifier(box);
});