import 'package:cloud_firestore/cloud_firestore.dart';

// Firestore用SharedListクラス（簡素化版）
class FirestoreSharedList {
  final String id;                              // ドキュメントID
  final String ownerUid;                        // オーナーUID
  final String groupId;                         // 所属グループID（アクセス権限はSharedGroupから取得）
  final String listName;                        // リスト名
  final List<Map<String, dynamic>> items;      // 買い物アイテム
  final Map<String, dynamic> metadata;         // その他のメタデータ

  const FirestoreSharedList({
    required this.id,
    required this.ownerUid,
    required this.groupId,
    required this.listName,
    this.items = const [],
    this.metadata = const {},
  });

  FirestoreSharedList copyWith({
    String? id,
    String? ownerUid,
    String? groupId,
    String? listName,
    List<Map<String, dynamic>>? items,
    Map<String, dynamic>? metadata,
  }) {
    return FirestoreSharedList(
      id: id ?? this.id,
      ownerUid: ownerUid ?? this.ownerUid,
      groupId: groupId ?? this.groupId,
      listName: listName ?? this.listName,
      items: items ?? this.items,
      metadata: metadata ?? this.metadata,
    );
  }

  // Firestore用のMap変換メソッド
  factory FirestoreSharedList.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FirestoreSharedList(
      id: doc.id,
      ownerUid: data['ownerUid'] ?? '',
      groupId: data['groupId'] ?? '',
      listName: data['listName'] ?? '',
      items: List<Map<String, dynamic>>.from(data['items'] ?? []),
      metadata: data['metadata'] ?? {},
    );
  }

  // Firestoreへの保存用Map変換
  Map<String, dynamic> toFirestore() {
    return {
      'ownerUid': ownerUid,
      'groupId': groupId,
      'listName': listName,
      'items': items,
      'metadata': metadata,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  // ユーザーがアクセス権限を持つかチェック（SharedGroupで確認が必要）
  bool hasOwnerAccess(String uid) {
    return ownerUid == uid;
  }

  // アイテムを追加
  FirestoreSharedList addItem(Map<String, dynamic> item) {
    return copyWith(items: [...items, item]);
  }

  // アイテムを更新
  FirestoreSharedList updateItem(int index, Map<String, dynamic> updatedItem) {
    if (index < 0 || index >= items.length) return this;
    
    final updatedItems = [...items];
    updatedItems[index] = updatedItem;
    return copyWith(items: updatedItems);
  }

  // アイテムを削除
  FirestoreSharedList removeItem(int index) {
    if (index < 0 || index >= items.length) return this;
    
    final updatedItems = [...items];
    updatedItems.removeAt(index);
    return copyWith(items: updatedItems);
  }
}
