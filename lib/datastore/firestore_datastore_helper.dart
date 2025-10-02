import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';

var log = Logger();
Future<void> createNewUserCollections(String userId) async {
  // Firestoreのインスタンスを取得
  final firestore = FirebaseFirestore.instance;

  // ユーザーのUIDをドキュメントIDとして使用
  final userDocument = firestore.collection('users').doc(userId);

  try {
    // 1. allowedUsersドキュメントを作成
    // このドキュメントには、初期データとしてcurrentUserのUIDを含めます。
    await userDocument.collection('shared_lists').doc('allowedUsers').set({
      'users': [userId], // 初期ユーザーとして自分自身を追加
      'last_updated': FieldValue.serverTimestamp(), // サーバータイムスタンプ
    });

    // 2. invitedUsersドキュメントを作成
    // このドキュメントは、最初は空にしておきます。
    await userDocument.collection('shared_lists').doc('invitedUsers').set({
      'users': [],
      'last_updated': FieldValue.serverTimestamp(),
    });

    // 3. ShoppingListドキュメントを作成
    // 買い物リストのアイテムを配列で保持する例
    await userDocument.collection('shopping_lists').doc('ShoppingList').set({
      'items': [], // 最初は空のリスト
      'created_by': userId,
      'created_at': FieldValue.serverTimestamp(),
    });

    log.i('Successfully created collections for user: $userId');

  } catch (e) {
    log.e('Error creating user collections: $e');
  }
}
