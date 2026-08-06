import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'shared_list.freezed.dart';
part 'shared_list.g.dart';

const uuid = Uuid();

// リストタイプを定義するenum
@HiveType(typeId: 12)
enum ListType {
  @HiveField(0)
  shopping, // 買い物リスト（デフォルト）
  @HiveField(1)
  todo, // TODOタスクリスト
}

@HiveType(typeId: 3)
@freezed
class SharedItem with _$SharedItem {
  const factory SharedItem({
    @HiveField(0) required String memberId,
    @HiveField(1) required String name, // 商品名
    @HiveField(2) @Default(1) int quantity, // 数量
    @HiveField(3) required DateTime registeredDate, // 登録日
    @HiveField(4) DateTime? purchaseDate, // 購入日
    @HiveField(5) @Default(false) bool isPurchased, // true: 購入済み、 false: 未購入
    @HiveField(6)
    @Default(0)
    int shoppingInterval, // 0:　繰り返し購入ではない　other:　繰り返し購入間隔（日数）
    @HiveField(7) DateTime? deadline, // 購入期限
    @HiveField(8) required String itemId, // 🆕 アイテム固有ID
    @HiveField(9) @Default(false) bool isDeleted, // 🆕 論理削除フラグ
    @HiveField(10) DateTime? deletedAt, // 🆕 削除日時
  }) = _SharedItem;

  // ファクトリーコンストラクタでカスタムロジック
  factory SharedItem.createNow({
    required String memberId,
    required String name,
    String? itemId, // 🆕 オプショナル、未指定なら自動生成
    int quantity = 1,
    bool isPurchased = false,
    int shoppingInterval = 0,
    DateTime? deadline, // 購入期限を追加
  }) {
    return SharedItem(
      memberId: memberId,
      name: name,
      itemId: itemId ?? uuid.v4(), // 🆕 自動生成
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
class SharedList with _$SharedList {
  const SharedList._(); // 🆕 カスタムメソッド用

  const factory SharedList({
    @HiveField(0) required String ownerUid,
    @HiveField(1) required String groupId,
    @HiveField(2) required String groupName,
    @HiveField(3) @Default({}) Map<String, SharedItem> items, // 🆕 Map形式に変更
    @HiveField(4) required String listId, // 追加: リストID
    @HiveField(5) required String listName, // 追加: リスト名
    @HiveField(6) @Default('') String description, // 追加: リスト説明
    @HiveField(7) required DateTime createdAt, // 追加: 作成日時
    @HiveField(8) DateTime? updatedAt, // 追加: 更新日時
    @HiveField(9) @Default(ListType.shopping) ListType listType, // リストタイプ追加
  }) = _SharedList;

  // 🆕 アクティブなアイテムのみ取得（isDeleted=falseのみ）
  List<SharedItem> get activeItems {
    final activeItems = items.values.where((item) => !item.isDeleted).toList();

    activeItems.sort((a, b) {
      final purchaseOrder = a.isPurchased == b.isPurchased
          ? 0
          : a.isPurchased
              ? 1
              : -1;
      if (purchaseOrder != 0) {
        return purchaseOrder;
      }

      final aDeadline = a.deadline;
      final bDeadline = b.deadline;
      final aHasDeadline = aDeadline != null;
      final bHasDeadline = bDeadline != null;

      if (aHasDeadline != bHasDeadline) {
        return aHasDeadline ? -1 : 1;
      }

      if (aHasDeadline && bHasDeadline) {
        final deadlineOrder = aDeadline.compareTo(bDeadline);
        if (deadlineOrder != 0) {
          return deadlineOrder;
        }
      }

      final registeredOrder = a.registeredDate.compareTo(b.registeredDate);
      if (registeredOrder != 0) {
        return registeredOrder;
      }

      return a.name.compareTo(b.name);
    });

    return activeItems;
  }

  // 🆕 削除済みアイテム数
  int get deletedItemCount =>
      items.values.where((item) => item.isDeleted).length;

  // 🆕 アクティブアイテム数
  int get activeItemCount =>
      items.values.where((item) => !item.isDeleted).length;

  // 🆕 クリーンアップが必要か（削除済みが10個以上）
  bool get needsCleanup => deletedItemCount > 10;

  // ファクトリーコンストラクタでIDと日時を自動生成
  factory SharedList.create({
    required String ownerUid,
    required String groupId,
    required String groupName,
    required String listName,
    String? listId,
    String description = '',
    Map<String, SharedItem> items = const {}, // 🆕 Map形式に変更
  }) {
    final now = DateTime.now();
    return SharedList(
      ownerUid: ownerUid,
      groupId: groupId,
      groupName: groupName,
      listName: listName,
      listId: listId ?? uuid.v4(),
      description: description,
      items: items,
      createdAt: now,
      updatedAt: now,
    );
  }
}
