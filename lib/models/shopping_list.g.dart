// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shopping_list.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ShoppingItemAdapter extends TypeAdapter<ShoppingItem> {
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
      quantity: fields[2] as int,
      registeredDate: fields[3] as DateTime,
      purchaseDate: fields[4] as DateTime?,
      isPurchased: fields[5] as bool,
      shoppingInterval: fields[6] as int,
      deadline: fields[7] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, ShoppingItem obj) {
    writer
      ..writeByte(8)
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
      ..write(obj.deadline);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShoppingItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ShoppingListAdapter extends TypeAdapter<ShoppingList> {
  @override
  final int typeId = 4;

  @override
  ShoppingList read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ShoppingList(
      ownerUid: fields[0] as String,
      groupId: fields[1] as String,
      groupName: fields[2] as String,
      items: (fields[3] as List).cast<ShoppingItem>(),
      listId: fields[4] as String,
      listName: fields[5] as String,
      description: fields[6] as String,
      createdAt: fields[7] as DateTime,
      updatedAt: fields[8] as DateTime?,
      listType: fields[9] as ListType,
    );
  }

  @override
  void write(BinaryWriter writer, ShoppingList obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.ownerUid)
      ..writeByte(1)
      ..write(obj.groupId)
      ..writeByte(2)
      ..write(obj.groupName)
      ..writeByte(3)
      ..write(obj.items)
      ..writeByte(4)
      ..write(obj.listId)
      ..writeByte(5)
      ..write(obj.listName)
      ..writeByte(6)
      ..write(obj.description)
      ..writeByte(7)
      ..write(obj.createdAt)
      ..writeByte(8)
      ..write(obj.updatedAt)
      ..writeByte(9)
      ..write(obj.listType);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShoppingListAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ListTypeAdapter extends TypeAdapter<ListType> {
  @override
  final int typeId = 12;

  @override
  ListType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return ListType.shopping;
      case 1:
        return ListType.todo;
      default:
        return ListType.shopping;
    }
  }

  @override
  void write(BinaryWriter writer, ListType obj) {
    switch (obj) {
      case ListType.shopping:
        writer.writeByte(0);
        break;
      case ListType.todo:
        writer.writeByte(1);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ListTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
