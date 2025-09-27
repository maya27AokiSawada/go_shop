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
  int get shoppingInterval => throw _privateConstructorUsedError;

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
      @HiveField(6) int shoppingInterval});
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
      @HiveField(6) int shoppingInterval});
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
      @HiveField(6) this.shoppingInterval = 0});

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

  @override
  String toString() {
    return 'ShoppingItem(memberId: $memberId, name: $name, quantity: $quantity, registeredDate: $registeredDate, purchaseDate: $purchaseDate, isPurchased: $isPurchased, shoppingInterval: $shoppingInterval)';
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
                other.shoppingInterval == shoppingInterval));
  }

  @override
  int get hashCode => Object.hash(runtimeType, memberId, name, quantity,
      registeredDate, purchaseDate, isPurchased, shoppingInterval);

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
      @HiveField(6) final int shoppingInterval}) = _$ShoppingItemImpl;

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
  List<ShoppingItem> get items => throw _privateConstructorUsedError;

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
      @HiveField(3) List<ShoppingItem> items});
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
              as List<ShoppingItem>,
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
      @HiveField(3) List<ShoppingItem> items});
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
              as List<ShoppingItem>,
    ));
  }
}

/// @nodoc

class _$ShoppingListImpl implements _ShoppingList {
  const _$ShoppingListImpl(
      {@HiveField(0) required this.ownerUid,
      @HiveField(1) required this.groupId,
      @HiveField(2) required this.groupName,
      @HiveField(3) final List<ShoppingItem> items = const []})
      : _items = items;

  @override
  @HiveField(0)
  final String ownerUid;
  @override
  @HiveField(1)
  final String groupId;
  @override
  @HiveField(2)
  final String groupName;
  final List<ShoppingItem> _items;
  @override
  @JsonKey()
  @HiveField(3)
  List<ShoppingItem> get items {
    if (_items is EqualUnmodifiableListView) return _items;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_items);
  }

  @override
  String toString() {
    return 'ShoppingList(ownerUid: $ownerUid, groupId: $groupId, groupName: $groupName, items: $items)';
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
            const DeepCollectionEquality().equals(other._items, _items));
  }

  @override
  int get hashCode => Object.hash(runtimeType, ownerUid, groupId, groupName,
      const DeepCollectionEquality().hash(_items));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ShoppingListImplCopyWith<_$ShoppingListImpl> get copyWith =>
      __$$ShoppingListImplCopyWithImpl<_$ShoppingListImpl>(this, _$identity);
}

abstract class _ShoppingList implements ShoppingList {
  const factory _ShoppingList(
      {@HiveField(0) required final String ownerUid,
      @HiveField(1) required final String groupId,
      @HiveField(2) required final String groupName,
      @HiveField(3) final List<ShoppingItem> items}) = _$ShoppingListImpl;

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
  List<ShoppingItem> get items;
  @override
  @JsonKey(ignore: true)
  _$$ShoppingListImplCopyWith<_$ShoppingListImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
