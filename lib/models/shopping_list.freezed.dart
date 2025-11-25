// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'shopping_list.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$ShoppingItem {
  @HiveField(0)
  String get memberId => throw _privateConstructorUsedError;
  @HiveField(1)
  String get name => throw _privateConstructorUsedError; // 商品名
  @HiveField(2)
  int get quantity => throw _privateConstructorUsedError; // 数量
  @HiveField(3)
  DateTime get registeredDate => throw _privateConstructorUsedError; // 登録日
  @HiveField(4)
  DateTime? get purchaseDate => throw _privateConstructorUsedError; // 購入日
  @HiveField(5)
  bool get isPurchased =>
      throw _privateConstructorUsedError; // true: 購入済み、 false: 未購入
  @HiveField(6)
  int get shoppingInterval =>
      throw _privateConstructorUsedError; // 0:　繰り返し購入ではない　other:　繰り返し購入間隔（日数）
  @HiveField(7)
  DateTime? get deadline => throw _privateConstructorUsedError; // 購入期限
  @HiveField(8)
  String get itemId => throw _privateConstructorUsedError; // 🆕 アイテム固有ID
  @HiveField(9)
  bool get isDeleted => throw _privateConstructorUsedError; // 🆕 論理削除フラグ
  @HiveField(10)
  DateTime? get deletedAt => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $ShoppingItemCopyWith<ShoppingItem> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ShoppingItemCopyWith<$Res> {
  factory $ShoppingItemCopyWith(
          ShoppingItem value, $Res Function(ShoppingItem) then) =
      _$ShoppingItemCopyWithImpl<$Res, ShoppingItem>;
  @useResult
  $Res call(
      {@HiveField(0) String memberId,
      @HiveField(1) String name,
      @HiveField(2) int quantity,
      @HiveField(3) DateTime registeredDate,
      @HiveField(4) DateTime? purchaseDate,
      @HiveField(5) bool isPurchased,
      @HiveField(6) int shoppingInterval,
      @HiveField(7) DateTime? deadline,
      @HiveField(8) String itemId,
      @HiveField(9) bool isDeleted,
      @HiveField(10) DateTime? deletedAt});
}

/// @nodoc
class _$ShoppingItemCopyWithImpl<$Res, $Val extends ShoppingItem>
    implements $ShoppingItemCopyWith<$Res> {
  _$ShoppingItemCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? memberId = null,
    Object? name = null,
    Object? quantity = null,
    Object? registeredDate = null,
    Object? purchaseDate = freezed,
    Object? isPurchased = null,
    Object? shoppingInterval = null,
    Object? deadline = freezed,
    Object? itemId = null,
    Object? isDeleted = null,
    Object? deletedAt = freezed,
  }) {
    return _then(_value.copyWith(
      memberId: null == memberId
          ? _value.memberId
          : memberId // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      quantity: null == quantity
          ? _value.quantity
          : quantity // ignore: cast_nullable_to_non_nullable
              as int,
      registeredDate: null == registeredDate
          ? _value.registeredDate
          : registeredDate // ignore: cast_nullable_to_non_nullable
              as DateTime,
      purchaseDate: freezed == purchaseDate
          ? _value.purchaseDate
          : purchaseDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      isPurchased: null == isPurchased
          ? _value.isPurchased
          : isPurchased // ignore: cast_nullable_to_non_nullable
              as bool,
      shoppingInterval: null == shoppingInterval
          ? _value.shoppingInterval
          : shoppingInterval // ignore: cast_nullable_to_non_nullable
              as int,
      deadline: freezed == deadline
          ? _value.deadline
          : deadline // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      itemId: null == itemId
          ? _value.itemId
          : itemId // ignore: cast_nullable_to_non_nullable
              as String,
      isDeleted: null == isDeleted
          ? _value.isDeleted
          : isDeleted // ignore: cast_nullable_to_non_nullable
              as bool,
      deletedAt: freezed == deletedAt
          ? _value.deletedAt
          : deletedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ShoppingItemImplCopyWith<$Res>
    implements $ShoppingItemCopyWith<$Res> {
  factory _$$ShoppingItemImplCopyWith(
          _$ShoppingItemImpl value, $Res Function(_$ShoppingItemImpl) then) =
      __$$ShoppingItemImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@HiveField(0) String memberId,
      @HiveField(1) String name,
      @HiveField(2) int quantity,
      @HiveField(3) DateTime registeredDate,
      @HiveField(4) DateTime? purchaseDate,
      @HiveField(5) bool isPurchased,
      @HiveField(6) int shoppingInterval,
      @HiveField(7) DateTime? deadline,
      @HiveField(8) String itemId,
      @HiveField(9) bool isDeleted,
      @HiveField(10) DateTime? deletedAt});
}

/// @nodoc
class __$$ShoppingItemImplCopyWithImpl<$Res>
    extends _$ShoppingItemCopyWithImpl<$Res, _$ShoppingItemImpl>
    implements _$$ShoppingItemImplCopyWith<$Res> {
  __$$ShoppingItemImplCopyWithImpl(
      _$ShoppingItemImpl _value, $Res Function(_$ShoppingItemImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? memberId = null,
    Object? name = null,
    Object? quantity = null,
    Object? registeredDate = null,
    Object? purchaseDate = freezed,
    Object? isPurchased = null,
    Object? shoppingInterval = null,
    Object? deadline = freezed,
    Object? itemId = null,
    Object? isDeleted = null,
    Object? deletedAt = freezed,
  }) {
    return _then(_$ShoppingItemImpl(
      memberId: null == memberId
          ? _value.memberId
          : memberId // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      quantity: null == quantity
          ? _value.quantity
          : quantity // ignore: cast_nullable_to_non_nullable
              as int,
      registeredDate: null == registeredDate
          ? _value.registeredDate
          : registeredDate // ignore: cast_nullable_to_non_nullable
              as DateTime,
      purchaseDate: freezed == purchaseDate
          ? _value.purchaseDate
          : purchaseDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      isPurchased: null == isPurchased
          ? _value.isPurchased
          : isPurchased // ignore: cast_nullable_to_non_nullable
              as bool,
      shoppingInterval: null == shoppingInterval
          ? _value.shoppingInterval
          : shoppingInterval // ignore: cast_nullable_to_non_nullable
              as int,
      deadline: freezed == deadline
          ? _value.deadline
          : deadline // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      itemId: null == itemId
          ? _value.itemId
          : itemId // ignore: cast_nullable_to_non_nullable
              as String,
      isDeleted: null == isDeleted
          ? _value.isDeleted
          : isDeleted // ignore: cast_nullable_to_non_nullable
              as bool,
      deletedAt: freezed == deletedAt
          ? _value.deletedAt
          : deletedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc

class _$ShoppingItemImpl implements _ShoppingItem {
  const _$ShoppingItemImpl(
      {@HiveField(0) required this.memberId,
      @HiveField(1) required this.name,
      @HiveField(2) this.quantity = 1,
      @HiveField(3) required this.registeredDate,
      @HiveField(4) this.purchaseDate,
      @HiveField(5) this.isPurchased = false,
      @HiveField(6) this.shoppingInterval = 0,
      @HiveField(7) this.deadline,
      @HiveField(8) required this.itemId,
      @HiveField(9) this.isDeleted = false,
      @HiveField(10) this.deletedAt});

  @override
  @HiveField(0)
  final String memberId;
  @override
  @HiveField(1)
  final String name;
// 商品名
  @override
  @JsonKey()
  @HiveField(2)
  final int quantity;
// 数量
  @override
  @HiveField(3)
  final DateTime registeredDate;
// 登録日
  @override
  @HiveField(4)
  final DateTime? purchaseDate;
// 購入日
  @override
  @JsonKey()
  @HiveField(5)
  final bool isPurchased;
// true: 購入済み、 false: 未購入
  @override
  @JsonKey()
  @HiveField(6)
  final int shoppingInterval;
// 0:　繰り返し購入ではない　other:　繰り返し購入間隔（日数）
  @override
  @HiveField(7)
  final DateTime? deadline;
// 購入期限
  @override
  @HiveField(8)
  final String itemId;
// 🆕 アイテム固有ID
  @override
  @JsonKey()
  @HiveField(9)
  final bool isDeleted;
// 🆕 論理削除フラグ
  @override
  @HiveField(10)
  final DateTime? deletedAt;

  @override
  String toString() {
    return 'ShoppingItem(memberId: $memberId, name: $name, quantity: $quantity, registeredDate: $registeredDate, purchaseDate: $purchaseDate, isPurchased: $isPurchased, shoppingInterval: $shoppingInterval, deadline: $deadline, itemId: $itemId, isDeleted: $isDeleted, deletedAt: $deletedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ShoppingItemImpl &&
            (identical(other.memberId, memberId) ||
                other.memberId == memberId) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.quantity, quantity) ||
                other.quantity == quantity) &&
            (identical(other.registeredDate, registeredDate) ||
                other.registeredDate == registeredDate) &&
            (identical(other.purchaseDate, purchaseDate) ||
                other.purchaseDate == purchaseDate) &&
            (identical(other.isPurchased, isPurchased) ||
                other.isPurchased == isPurchased) &&
            (identical(other.shoppingInterval, shoppingInterval) ||
                other.shoppingInterval == shoppingInterval) &&
            (identical(other.deadline, deadline) ||
                other.deadline == deadline) &&
            (identical(other.itemId, itemId) || other.itemId == itemId) &&
            (identical(other.isDeleted, isDeleted) ||
                other.isDeleted == isDeleted) &&
            (identical(other.deletedAt, deletedAt) ||
                other.deletedAt == deletedAt));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      memberId,
      name,
      quantity,
      registeredDate,
      purchaseDate,
      isPurchased,
      shoppingInterval,
      deadline,
      itemId,
      isDeleted,
      deletedAt);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ShoppingItemImplCopyWith<_$ShoppingItemImpl> get copyWith =>
      __$$ShoppingItemImplCopyWithImpl<_$ShoppingItemImpl>(this, _$identity);
}

abstract class _ShoppingItem implements ShoppingItem {
  const factory _ShoppingItem(
      {@HiveField(0) required final String memberId,
      @HiveField(1) required final String name,
      @HiveField(2) final int quantity,
      @HiveField(3) required final DateTime registeredDate,
      @HiveField(4) final DateTime? purchaseDate,
      @HiveField(5) final bool isPurchased,
      @HiveField(6) final int shoppingInterval,
      @HiveField(7) final DateTime? deadline,
      @HiveField(8) required final String itemId,
      @HiveField(9) final bool isDeleted,
      @HiveField(10) final DateTime? deletedAt}) = _$ShoppingItemImpl;

  @override
  @HiveField(0)
  String get memberId;
  @override
  @HiveField(1)
  String get name;
  @override // 商品名
  @HiveField(2)
  int get quantity;
  @override // 数量
  @HiveField(3)
  DateTime get registeredDate;
  @override // 登録日
  @HiveField(4)
  DateTime? get purchaseDate;
  @override // 購入日
  @HiveField(5)
  bool get isPurchased;
  @override // true: 購入済み、 false: 未購入
  @HiveField(6)
  int get shoppingInterval;
  @override // 0:　繰り返し購入ではない　other:　繰り返し購入間隔（日数）
  @HiveField(7)
  DateTime? get deadline;
  @override // 購入期限
  @HiveField(8)
  String get itemId;
  @override // 🆕 アイテム固有ID
  @HiveField(9)
  bool get isDeleted;
  @override // 🆕 論理削除フラグ
  @HiveField(10)
  DateTime? get deletedAt;
  @override
  @JsonKey(ignore: true)
  _$$ShoppingItemImplCopyWith<_$ShoppingItemImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$ShoppingList {
  @HiveField(0)
  String get ownerUid => throw _privateConstructorUsedError;
  @HiveField(1)
  String get groupId => throw _privateConstructorUsedError;
  @HiveField(2)
  String get groupName => throw _privateConstructorUsedError;
  @HiveField(3)
  Map<String, ShoppingItem> get items =>
      throw _privateConstructorUsedError; // 🆕 Map形式に変更
  @HiveField(4)
  String get listId => throw _privateConstructorUsedError; // 追加: リストID
  @HiveField(5)
  String get listName => throw _privateConstructorUsedError; // 追加: リスト名
  @HiveField(6)
  String get description => throw _privateConstructorUsedError; // 追加: リスト説明
  @HiveField(7)
  DateTime get createdAt => throw _privateConstructorUsedError; // 追加: 作成日時
  @HiveField(8)
  DateTime? get updatedAt => throw _privateConstructorUsedError; // 追加: 更新日時
  @HiveField(9)
  ListType get listType => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $ShoppingListCopyWith<ShoppingList> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ShoppingListCopyWith<$Res> {
  factory $ShoppingListCopyWith(
          ShoppingList value, $Res Function(ShoppingList) then) =
      _$ShoppingListCopyWithImpl<$Res, ShoppingList>;
  @useResult
  $Res call(
      {@HiveField(0) String ownerUid,
      @HiveField(1) String groupId,
      @HiveField(2) String groupName,
      @HiveField(3) Map<String, ShoppingItem> items,
      @HiveField(4) String listId,
      @HiveField(5) String listName,
      @HiveField(6) String description,
      @HiveField(7) DateTime createdAt,
      @HiveField(8) DateTime? updatedAt,
      @HiveField(9) ListType listType});
}

/// @nodoc
class _$ShoppingListCopyWithImpl<$Res, $Val extends ShoppingList>
    implements $ShoppingListCopyWith<$Res> {
  _$ShoppingListCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? ownerUid = null,
    Object? groupId = null,
    Object? groupName = null,
    Object? items = null,
    Object? listId = null,
    Object? listName = null,
    Object? description = null,
    Object? createdAt = null,
    Object? updatedAt = freezed,
    Object? listType = null,
  }) {
    return _then(_value.copyWith(
      ownerUid: null == ownerUid
          ? _value.ownerUid
          : ownerUid // ignore: cast_nullable_to_non_nullable
              as String,
      groupId: null == groupId
          ? _value.groupId
          : groupId // ignore: cast_nullable_to_non_nullable
              as String,
      groupName: null == groupName
          ? _value.groupName
          : groupName // ignore: cast_nullable_to_non_nullable
              as String,
      items: null == items
          ? _value.items
          : items // ignore: cast_nullable_to_non_nullable
              as Map<String, ShoppingItem>,
      listId: null == listId
          ? _value.listId
          : listId // ignore: cast_nullable_to_non_nullable
              as String,
      listName: null == listName
          ? _value.listName
          : listName // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      listType: null == listType
          ? _value.listType
          : listType // ignore: cast_nullable_to_non_nullable
              as ListType,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ShoppingListImplCopyWith<$Res>
    implements $ShoppingListCopyWith<$Res> {
  factory _$$ShoppingListImplCopyWith(
          _$ShoppingListImpl value, $Res Function(_$ShoppingListImpl) then) =
      __$$ShoppingListImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@HiveField(0) String ownerUid,
      @HiveField(1) String groupId,
      @HiveField(2) String groupName,
      @HiveField(3) Map<String, ShoppingItem> items,
      @HiveField(4) String listId,
      @HiveField(5) String listName,
      @HiveField(6) String description,
      @HiveField(7) DateTime createdAt,
      @HiveField(8) DateTime? updatedAt,
      @HiveField(9) ListType listType});
}

/// @nodoc
class __$$ShoppingListImplCopyWithImpl<$Res>
    extends _$ShoppingListCopyWithImpl<$Res, _$ShoppingListImpl>
    implements _$$ShoppingListImplCopyWith<$Res> {
  __$$ShoppingListImplCopyWithImpl(
      _$ShoppingListImpl _value, $Res Function(_$ShoppingListImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? ownerUid = null,
    Object? groupId = null,
    Object? groupName = null,
    Object? items = null,
    Object? listId = null,
    Object? listName = null,
    Object? description = null,
    Object? createdAt = null,
    Object? updatedAt = freezed,
    Object? listType = null,
  }) {
    return _then(_$ShoppingListImpl(
      ownerUid: null == ownerUid
          ? _value.ownerUid
          : ownerUid // ignore: cast_nullable_to_non_nullable
              as String,
      groupId: null == groupId
          ? _value.groupId
          : groupId // ignore: cast_nullable_to_non_nullable
              as String,
      groupName: null == groupName
          ? _value.groupName
          : groupName // ignore: cast_nullable_to_non_nullable
              as String,
      items: null == items
          ? _value._items
          : items // ignore: cast_nullable_to_non_nullable
              as Map<String, ShoppingItem>,
      listId: null == listId
          ? _value.listId
          : listId // ignore: cast_nullable_to_non_nullable
              as String,
      listName: null == listName
          ? _value.listName
          : listName // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      listType: null == listType
          ? _value.listType
          : listType // ignore: cast_nullable_to_non_nullable
              as ListType,
    ));
  }
}

/// @nodoc

class _$ShoppingListImpl extends _ShoppingList {
  const _$ShoppingListImpl(
      {@HiveField(0) required this.ownerUid,
      @HiveField(1) required this.groupId,
      @HiveField(2) required this.groupName,
      @HiveField(3) final Map<String, ShoppingItem> items = const {},
      @HiveField(4) required this.listId,
      @HiveField(5) required this.listName,
      @HiveField(6) this.description = '',
      @HiveField(7) required this.createdAt,
      @HiveField(8) this.updatedAt,
      @HiveField(9) this.listType = ListType.shopping})
      : _items = items,
        super._();

  @override
  @HiveField(0)
  final String ownerUid;
  @override
  @HiveField(1)
  final String groupId;
  @override
  @HiveField(2)
  final String groupName;
  final Map<String, ShoppingItem> _items;
  @override
  @JsonKey()
  @HiveField(3)
  Map<String, ShoppingItem> get items {
    if (_items is EqualUnmodifiableMapView) return _items;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_items);
  }

// 🆕 Map形式に変更
  @override
  @HiveField(4)
  final String listId;
// 追加: リストID
  @override
  @HiveField(5)
  final String listName;
// 追加: リスト名
  @override
  @JsonKey()
  @HiveField(6)
  final String description;
// 追加: リスト説明
  @override
  @HiveField(7)
  final DateTime createdAt;
// 追加: 作成日時
  @override
  @HiveField(8)
  final DateTime? updatedAt;
// 追加: 更新日時
  @override
  @JsonKey()
  @HiveField(9)
  final ListType listType;

  @override
  String toString() {
    return 'ShoppingList(ownerUid: $ownerUid, groupId: $groupId, groupName: $groupName, items: $items, listId: $listId, listName: $listName, description: $description, createdAt: $createdAt, updatedAt: $updatedAt, listType: $listType)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ShoppingListImpl &&
            (identical(other.ownerUid, ownerUid) ||
                other.ownerUid == ownerUid) &&
            (identical(other.groupId, groupId) || other.groupId == groupId) &&
            (identical(other.groupName, groupName) ||
                other.groupName == groupName) &&
            const DeepCollectionEquality().equals(other._items, _items) &&
            (identical(other.listId, listId) || other.listId == listId) &&
            (identical(other.listName, listName) ||
                other.listName == listName) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            (identical(other.listType, listType) ||
                other.listType == listType));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      ownerUid,
      groupId,
      groupName,
      const DeepCollectionEquality().hash(_items),
      listId,
      listName,
      description,
      createdAt,
      updatedAt,
      listType);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ShoppingListImplCopyWith<_$ShoppingListImpl> get copyWith =>
      __$$ShoppingListImplCopyWithImpl<_$ShoppingListImpl>(this, _$identity);
}

abstract class _ShoppingList extends ShoppingList {
  const factory _ShoppingList(
      {@HiveField(0) required final String ownerUid,
      @HiveField(1) required final String groupId,
      @HiveField(2) required final String groupName,
      @HiveField(3) final Map<String, ShoppingItem> items,
      @HiveField(4) required final String listId,
      @HiveField(5) required final String listName,
      @HiveField(6) final String description,
      @HiveField(7) required final DateTime createdAt,
      @HiveField(8) final DateTime? updatedAt,
      @HiveField(9) final ListType listType}) = _$ShoppingListImpl;
  const _ShoppingList._() : super._();

  @override
  @HiveField(0)
  String get ownerUid;
  @override
  @HiveField(1)
  String get groupId;
  @override
  @HiveField(2)
  String get groupName;
  @override
  @HiveField(3)
  Map<String, ShoppingItem> get items;
  @override // 🆕 Map形式に変更
  @HiveField(4)
  String get listId;
  @override // 追加: リストID
  @HiveField(5)
  String get listName;
  @override // 追加: リスト名
  @HiveField(6)
  String get description;
  @override // 追加: リスト説明
  @HiveField(7)
  DateTime get createdAt;
  @override // 追加: 作成日時
  @HiveField(8)
  DateTime? get updatedAt;
  @override // 追加: 更新日時
  @HiveField(9)
  ListType get listType;
  @override
  @JsonKey(ignore: true)
  _$$ShoppingListImplCopyWith<_$ShoppingListImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
