import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive/hive.dart';

part 'shopping_list.freezed.dart';
part 'shopping_list.g.dart';

@HiveType(typeId: 3)
@freezed
class ShoppingItem with _$ShoppingItem {
  const factory ShoppingItem({
    @HiveField(0) required String memberId,
    @HiveField(1) required String name, // 商品名
    @HiveField(2) @Default(1) int quantity, // 数量
    @HiveField(3) required DateTime registeredDate, // 登録日
    @HiveField(4) DateTime? purchaseDate, // 購入日
    @HiveField(5) @Default(false) bool isPurchased, // true: 購入済み、 false: 未購入
    @HiveField(6) @Default(0) int shoppingInterval, // 0:　繰り返し購入ではない　other:　繰り返し購入間隔（日数）
    @HiveField(7) DateTime? deadline, // 購入期限
  }) = _ShoppingItem;

  // ファクトリーコンストラクタでカスタムロジック
  factory ShoppingItem.createNow({
    required String memberId,
    required String name,
    int quantity = 1,
    bool isPurchased = false,
    int shoppingInterval = 0,
    DateTime? deadline, // 購入期限を追加
  }) {
    return ShoppingItem(
      memberId: memberId,
      name: name,
      quantity: quantity,
      registeredDate: DateTime.now(),
      isPurchased: isPurchased,
      shoppingInterval: shoppingInterval,
      deadline: deadline,
    );
  }
}

@HiveType(typeId: 4)
@freezed
class ShoppingList with _$ShoppingList {
  const factory ShoppingList({
    @HiveField(0) required String ownerUid,
    @HiveField(1) required String groupId,
    @HiveField(2) required String groupName,
    @HiveField(3) @Default([]) List<ShoppingItem> items,
  }) = _ShoppingList;
}
