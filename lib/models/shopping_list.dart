import 'package:hive/hive.dart';
part 'shopping_list.g.dart';

@HiveType(typeId: 0)
class ShoppingItem {
  @HiveField(0)
  final String memberId;
  @HiveField(1)
  final String name; // 商品名
  @HiveField(2)
  final int quantity; // 数量
  @HiveField(3)
  final DateTime registeredDate; // 登録日
  @HiveField(4)
  final DateTime? purchaseDate; // 購入日
  @HiveField(5)
  final bool isPurchased; // true: 購入済み、 false: 未購入
  @HiveField(6)
  final int shoppingInterval; // 0:　繰り返し購入ではない　other:　繰り返し購入間隔（日数）

  ShoppingItem({
    required this.memberId,
    required this.name,
    this.quantity = 1,
    DateTime? registeredDate,
    DateTime? purchaseDate,
    this.isPurchased = false,
    required this.shoppingInterval,
  }) : registeredDate = registeredDate ?? DateTime.now(),
        purchaseDate = null;

  ShoppingItem copyWith({
    bool? isPurchased,
    DateTime? purchaseDate,
    bool? isEnableRepeat,
  }) {
    return ShoppingItem(
      // ... 他のフィールドはthisから継承
      memberId: memberId,
      name: name,
      quantity: quantity,
      registeredDate: registeredDate,
      shoppingInterval: shoppingInterval,
      // 指定されたフィールドのみ新しい値に置き換え
      isPurchased: isPurchased ?? false,
      purchaseDate : isPurchased == true ? (purchaseDate ?? DateTime.now()) : null,
    );
  }

  // json_serializableで自動生成されるメソッド
//  factory ShoppingItem.fromJson(Map<String, dynamic> json) => _$ShoppingItemFromJson(json);
//  Map<String, dynamic> toJson() => _$ShoppingItemToJson(this);

  @override
  String toString() {
    return 'ShoppingItem(memberId: $memberId, name: $name, quantity: $quantity, registeredDate: $registeredDate,'
        ' purchaseDate: $purchaseDate, isPurchased: $isPurchased, shoppingInterval: $shoppingInterval)';
  }
}

@HiveType(typeId: 1)
class ShoppingList {
  @HiveField(0)
  final List<ShoppingItem> items;

  ShoppingList({required this.items});


  @override
  String toString() {
    return 'ShoppingList(items: $items)';
  }
}
