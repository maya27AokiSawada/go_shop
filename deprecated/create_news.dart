// create_news.dart
// Flutterアプリのコンテキストで実行するニュース作成スクリプト
// 使い方: このファイルをmain.dartから一時的に呼び出す

import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> createNewsDocument() async {
  final firestore = FirebaseFirestore.instance;

  try {
    print('📰 ニュースドキュメントを作成中...');

    await firestore.collection('furestorenews').doc('current_news').set({
      'title': 'GoShoppingへようこそ！',
      'content': '買い物リストを家族やグループで共有できるアプリです。メンバーを招待して、みんなで買い物を効率化しましょう！',
      'createdAt': FieldValue.serverTimestamp(),
      'isActive': true,
      'actionText': 'はじめる',
    });

    print('✅ ニュースドキュメント作成完了！');
    print('📋 コレクション: furestorenews');
    print('📄 ドキュメント: current_news');
  } catch (e) {
    print('❌ エラー: $e');
  }
}
