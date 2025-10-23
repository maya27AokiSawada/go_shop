/// Firestoreのnewsコレクションにダミーニュースを追加するための手順
///
/// Firebase Console を使用して手動で追加してください:
///
/// 1. https://console.firebase.google.com/ を開く
/// 2. プロジェクト「gotoshop-572b7」を選択
/// 3. 左メニューから「Firestore Database」を選択
/// 4. 「コレクションを開始」をクリック (既に存在する場合はスキップ)
/// 5. コレクションID: furestorenews
/// 6. ドキュメントID: current_news
/// 7. フィールドを追加:
///    - title (string): "Go Shopへようこそ！"
///    - content (string): "Go Shopをご利用いただき、ありがとうございます。このアプリは家族やグループで買い物リストを共有できる便利なアプリです。"
///    - timestamp (timestamp): 現在の日時
///    - isActive (boolean): true
///    - priority (number): 1
/// 8. 「保存」をクリック

import 'package:go_shop/utils/app_logger.dart';

void main() {
  AppLogger.info('📰 ダミーニュース追加手順');
  AppLogger.info('');
  AppLogger.info('Firebase Console を使用して手動で追加してください:');
  AppLogger.info('');
  AppLogger.info('1. https://console.firebase.google.com/ を開く');
  AppLogger.info('2. プロジェクト「gotoshop-572b7」を選択');
  AppLogger.info('3. 左メニューから「Firestore Database」を選択');
  AppLogger.info('4. 「コレクションを開始」をクリック');
  AppLogger.info('');
  AppLogger.info('コレクションID: furestorenews');
  AppLogger.info('ドキュメントID: current_news');
  AppLogger.info('');
  AppLogger.info('フィールド:');
  AppLogger.info('  - title (string): "Go Shopへようこそ！"');
  AppLogger.info('  - content (string): "Go Shopをご利用いただき、ありがとうございます。"');
  AppLogger.info('  - timestamp (timestamp): 現在の日時');
  AppLogger.info('  - isActive (boolean): true');
  AppLogger.info('  - priority (number): 1');
  AppLogger.info('');
  AppLogger.info('💡 Firestoreのルールで読み取りを許可してください:');
  AppLogger.info('   allow read: if true;');
}
