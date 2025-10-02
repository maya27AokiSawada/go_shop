// lib/providers/hive_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../models/purchase_group.dart';
import '../models/shopping_list.dart';

// Boxが既に開いているので同期的にアクセス可能
final purchaseGroupBoxProvider = Provider<Box<PurchaseGroup>>((ref) {
  return Hive.box<PurchaseGroup>('purchaseGroups');
});

final shoppingListBoxProvider = Provider<Box<ShoppingList>>((ref) {
  return Hive.box<ShoppingList>('shoppingLists');
});
