# datastore — ファイル一覧と役割

データ永続化層（Repository パターン）の実装を格納するフォルダです。
Firestore（クラウド）・Hive（ローカルキャッシュ）・ハイブリッドの 3 種類の実装を提供します。

---

## アーキテクチャ概要

```
抽象インターフェース
  └─ shared_group_repository.dart  / shared_list_repository.dart

具体実装
  ├─ Hive（ローカル）   : hive_shared_group_repository.dart
  │                       hive_shared_list_repository.dart
  ├─ Firestore（クラウド）: firestore_shared_group_repository.dart
  │                        firestore_shared_list_repository.dart
  └─ Hybrid（本番使用） : hybrid_shared_group_repository.dart  ← プロダクションで使用
                          hybrid_shared_list_repository.dart   ← プロダクションで使用
```

---

## ファイル一覧

| ファイル名                                                                       | 役割                                                                                                                                                                                                                                                  |
| -------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [shared_group_repository.dart](shared_group_repository.dart)                     | `SharedGroupRepository` の抽象インターフェース。`createGroup` / `getAllGroups` / `addMember` / `removeMember` / `updateGroup` / `deleteGroup` など全 CRUD 操作を定義する。                                                                            |
| [shared_list_repository.dart](shared_list_repository.dart)                       | `SharedListRepository` の抽象インターフェース。`createSharedList` / `getSharedListsByGroup` / 差分アイテム更新メソッド / `watchSharedList` ストリームなどを定義する。                                                                                 |
| [hybrid_shared_group_repository.dart](hybrid_shared_group_repository.dart)       | **本番で使用するグループリポジトリ**。Hive（ローカルキャッシュ）と Firestore（信頼できるソース）をオーケストレーションし、初期化ステートマシン・ネットワーク監視・オフラインフォールバックを実装する。                                                |
| [hybrid_shared_list_repository.dart](hybrid_shared_list_repository.dart)         | **本番で使用するリストリポジトリ**。Firestore 優先の書き込みと Hive キャッシュ・バックグラウンド同期キュー・デバイス ID プレフィックスによるリスト ID 生成を実装する。                                                                                |
| [firestore_shared_group_repository.dart](firestore_shared_group_repository.dart) | `SharedGroupRepository` の Firestore 実装。`SharedGroups` ルートコレクションに対して完全な CRUD を実行する。テスト用に `FirebaseFirestore` インスタンスを注入可能。                                                                                   |
| [firestore_shared_list_repository.dart](firestore_shared_list_repository.dart)   | `SharedListRepository` の Firestore 実装。`SharedGroups/{groupId}/sharedLists` サブコレクションを操作する。`addSingleItem` / `updateSingleItem` / `removeSingleItem` による差分更新でネットワーク転送量を約 90% 削減する。                            |
| [hive_shared_group_repository.dart](hive_shared_group_repository.dart)           | `SharedGroupRepository` の Hive（ローカル）実装。Hive ボックスの初期化完了まで最大 10 回（500 ms 間隔）リトライするループを含む。                                                                                                                     |
| [hive_shared_list_repository.dart](hive_shared_list_repository.dart)             | `SharedListRepository` の Hive（ローカル）実装。UID / メールアドレスからユーザー固有のストレージキーを生成し、`Hive.isBoxOpen()` ガードでボックスアクセスを保護する。                                                                                 |
| [firestore_shared_group_adapter.dart](firestore_shared_group_adapter.dart)       | `SharedGroupRepository` インターフェースを Firestore のドキュメント操作に変換するアダプター。`ValidationService` によるメンバー検証機能を含む。                                                                                                       |
| [firebase_shared_list_repository.dart](firebase_shared_list_repository.dart)     | 旧来の互換レイヤー。dev フレーバーでは `HiveSharedListRepository` に委譲し、prod では旧 Firebase Auth バックエンドを使用していた過渡期の実装。現在は非推奨。                                                                                          |
| [user_settings_repository.dart](user_settings_repository.dart)                   | `UserSettingsRepository` インターフェースとその Hive 実装 `HiveUserSettingsRepository` を定義する。ユーザー名・最終使用グループ／リスト ID・アプリモード・UID 変更検知などを Hive ボックスに永続化する。                                              |
| [whiteboard_repository.dart](whiteboard_repository.dart)                         | ホワイトボードの Firestore リポジトリ。`SharedGroups/{groupId}/whiteboards` のグループ共有／個人用ホワイトボードの CRUD・リアルタイム `watchWhiteboard` ストリーム（`hasPendingWrites` フィルター付き）・Windows 互換のストローク追加処理を実装する。 |
| [whiteboard_conflict_resolution.dart](whiteboard_conflict_resolution.dart)       | `WhiteboardConflictResolver` を提供する。Firestore ホワイトボードドキュメントへの並行描画ストローク追加を安全に処理する。Android / iOS では `runTransaction`、Windows では SDK クラッシュ回避のため通常の `update` を使用する。                       |
| [firestore_architecture.dart](firestore_architecture.dart)                       | Firestore のコレクション構造（パス定数・ロール・招待フロー）を記述したドキュメント兼定数ファイル。`FirestoreCollections` ヘルパークラスに静的パス定数を定義する。                                                                                     |

---

## 重要なパターン

### Firestore-First Hybrid

本番環境では Hybrid リポジトリを使用する。Firestore が source of truth で、Hive はキャッシュとして機能する。

```dart
// Hybrid パターン（簡略）
try {
  final data = await firestoreRepo.getData();  // Firestore 優先
  await hiveRepo.save(data);                   // Hive にキャッシュ
  return data;
} catch (_) {
  return await hiveRepo.getData();             // オフライン時は Hive フォールバック
}
```

### 差分同期（Differential Sync）

`SharedItem` の更新はリスト全体ではなく変更されたアイテムのフィールドのみを Firestore に送信する。

```dart
// ❌ 旧来: リスト全体を送信（~5KB）
await repository.updateSharedList(list.copyWith(items: updatedItems));

// ✅ 差分同期: 変更アイテムのみ送信（~500B）
await repository.addSingleItem(listId, newItem);
await repository.updateSingleItem(listId, updatedItem);
await repository.removeSingleItem(listId, itemId);
```

### Windows 対応

`runTransaction()` が Windows の Firestore SDK でクラッシュするため、`Platform.isWindows` で条件分岐して通常の `update()` を使用する（`whiteboard_repository.dart` / `whiteboard_conflict_resolution.dart`）。
