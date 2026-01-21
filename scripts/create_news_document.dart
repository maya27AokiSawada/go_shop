// scripts/create_news_document.dart
// Firebase Firestoreにニュースドキュメントを作成するスクリプト

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:goshopping/firebase_options.dart';
import 'package:goshopping/flavors.dart';

void main() async {
  // Firebase初期化
  F.appFlavor = Flavor.prod; // prodプロジェクトを使用
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

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
