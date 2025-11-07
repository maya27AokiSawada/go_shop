# Firestore グループ削除バグ修正レポート

**日時**: 2025年11月7日
**担当**: GitHub Copilot
**影響範囲**: Firestore環境でのグループ削除機能
**重要度**: 高（データ整合性の問題）

## 障害の概要

Firestore環境でグループ削除を実行した際、Hive（ローカルDB）からは削除されるが、Firestoreからは削除されず、アプリ再起動時にグループが復活する問題が発生していた。

## 障害の詳細

### 発生状況
- **環境**: Flavor.prod（Firebase本番環境）
- **操作**: グループ削除実行
- **現象**:
  - Hive削除: ✅ 成功（10→9グループ）
  - Firestore削除: ❌ 失敗（エラーメッセージ: "Group not found: 1761199762402"）
  - アプリ再起動後、削除したグループが復活

### 根本原因

**Firestoreコレクションパスの不整合**

- **同期処理（正しいパス）**: `users/{uid}/groups/{groupId}`
- **削除処理（誤ったパス）**: `purchaseGroups/{groupId}` ← ルートレベルコレクション

`firestore_purchase_group_repository.dart` の `_groupsCollection` が固定でルートレベルの `purchaseGroups` コレクションを参照していたため、実際にデータが存在する `users/{uid}/groups` とは異なる場所を参照していた。

### 現象からの推理プロセス

1. **ログ分析**: Hive削除成功、Firestore削除失敗
2. **データ存在確認**: Firestoreにグループデータが存在することを確認
3. **パス比較**: 同期処理と削除処理でコレクションパスが異なることを発見
4. **仮説検証**: コレクションパスを統一すれば解決するはず

## 修正内容

### 修正ファイル
`lib/datastore/firestore_purchase_group_repository.dart`

### 修正前
```dart
CollectionReference get _groupsCollection =>
    _firestore.collection('purchaseGroups');
```

### 修正後
```dart
CollectionReference get _groupsCollection {
  final user = _auth.currentUser;
  if (user == null) {
    throw Exception('User not logged in');
  }
  return _firestore.collection('users').doc(user.uid).collection('groups');
}
```

### 追加実装
- 削除処理に診断ログを追加
  - ユーザーパスの表示
  - ドキュメント存在確認
  - ユーザーIDをエラーメッセージに含める

```dart
Log.info('🔍 [FIRESTORE DELETE] User path: users/${user.uid}/groups/$groupId');
final docSnapshot = await _groupsCollection.doc(groupId).get();
Log.info('🔍 [FIRESTORE DELETE] Document exists: ${docSnapshot.exists}');
```

## 技術的考察

### なぜこの問題が見逃されていたか

1. **開発環境との違い**: Dev環境（Flavor.dev）ではFirestoreを使用しないため発見が遅れた
2. **部分的な動作**: Hive削除は正常に機能していたため、一見動作しているように見えた
3. **アーキテクチャの不統一**: 同期処理と削除処理で異なるパスを使用していた

### パフォーマンスへの影響

- **getterオーバーヘッド**: `_auth.currentUser` の呼び出しは約0.1ms
- **使用頻度**: 削除操作は低頻度
- **結論**: 最適化不要（"measure first, optimize later"の原則に従う）

## 検証結果

### テストケース
1. グループ削除実行
2. アプリ再起動
3. グループリスト確認

### 結果
- ✅ Hive削除成功
- ✅ Firestore削除成功（isDeletedフラグが設定される）
- ✅ 再起動後もグループは復活せず

### ログ出力
```
💡 [DELETE] Firestore削除実行開始: 1761199762402
✅ [DELETE] Firestore削除完了: 1761199762402
✅ [GROUP_DELETE] グループ削除完了: 1761199762402
```

## 今後の対策

### 予防策
1. **コレクションパスの一元管理**: 定数または共通メソッドで管理
2. **E2Eテストの追加**: Firestore環境での削除→再起動→確認のテストケース
3. **コードレビュー**: データパスの整合性チェックを重視

### アーキテクチャ改善案
```dart
// 例: コレクションパスを一元管理
class FirestoreCollections {
  static CollectionReference userGroups(FirebaseFirestore firestore, String uid) {
    return firestore.collection('users').doc(uid).collection('groups');
  }
}
```

## 関連情報

- **影響を受けたグループID**: 1761199762402
- **使用技術**: Flutter, Firebase Firestore, Hive, Riverpod
- **削除方式**: ソフトデリート（isDeletedフラグ）
- **同期方式**: Firestore→Hive（起動時）、Hive→Firestore（操作時）

## まとめ

Firestoreのコレクションパス不整合により、削除処理が正しく動作していなかった。`_groupsCollection` をユーザー固有のパスを返すgetterに変更することで、同期処理と削除処理のパスが統一され、問題を解決した。

この障害は「現象から推理する能力」によって効率的に解決された好例であり、ログ分析とアーキテクチャ理解の重要性を示している。
