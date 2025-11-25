import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../models/shopping_list.dart';

const _uuid = Uuid();

/// ShoppingItemの後方互換性を持つカスタムアダプター
/// 古いデータ（itemId, isDeleted, deletedAtなし）を読み込めるようにする
class ShoppingItemAdapterOverride extends TypeAdapter<ShoppingItem> {
  @override
  final int typeId = 3;

  @override
  ShoppingItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };

    return ShoppingItem(
      memberId: fields[0] as String,
      name: fields[1] as String,
      quantity: fields[2] as int? ?? 1,
      registeredDate: fields[3] as DateTime,
      purchaseDate: fields[4] as DateTime?,
      isPurchased: fields[5] as bool? ?? false,
      shoppingInterval: fields[6] as int? ?? 0,
      deadline: fields[7] as DateTime?,
      // 🔥 後方互換性: itemIdがnullの場合は自動生成
      itemId: (fields[8] as String?) ?? _uuid.v4(),
      // 🔥 後方互換性: isDeletedがnullの場合はfalse
      isDeleted: fields[9] as bool? ?? false,
      // 🔥 後方互換性: deletedAtがnullの場合はnull
      deletedAt: fields[10] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, ShoppingItem obj) {
    writer
      ..writeByte(11) // フィールド数
      ..writeByte(0)
      ..write(obj.memberId)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.quantity)
      ..writeByte(3)
      ..write(obj.registeredDate)
      ..writeByte(4)
      ..write(obj.purchaseDate)
      ..writeByte(5)
      ..write(obj.isPurchased)
      ..writeByte(6)
      ..write(obj.shoppingInterval)
      ..writeByte(7)
      ..write(obj.deadline)
      ..writeByte(8)
      ..write(obj.itemId)
      ..writeByte(9)
      ..write(obj.isDeleted)
      ..writeByte(10)
      ..write(obj.deletedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShoppingItemAdapterOverride &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
