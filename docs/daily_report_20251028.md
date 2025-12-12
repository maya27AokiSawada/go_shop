# 作業日報 - 2025年10月28日

## 作業概要
Firestore同期の診断とHive優先アーキテクチャの確認を実施しました。

## 実施内容

### 1. Firestore構造の確認
- **発見事項**: Firebase Consoleで確認したところ、`/SharedGroups` と `/sharedLists` のコレクションが存在しない
- **原因調査**: Firestore書き込みが実行されていない可能性を調査

### 2. Firestore同期診断のためのデバッグログ追加
- **ファイル**: `lib/datastore/hybrid_purchase_group_repository.dart`
- **変更内容**:
  ```dart
  // createGroup()メソッド内に以下のログを追加（167-178行目）
  developer.log('🔍 [HYBRID_REPO] Firestore sync check:');
  developer.log('  - Flavor: ${F.appFlavor}');
  developer.log('  - isOnline: $_isOnline');
  developer.log('  - _firestoreRepo null?: ${_firestoreRepo == null}');

  if (F.appFlavor == Flavor.dev || !_isOnline || _firestoreRepo == null) {
    developer.log('⚠️ [HYBRID_REPO] Skipping Firestore sync - Hive only');
    return newGroup;
  }

  developer.log('🔄 [HYBRID_REPO] Starting Firestore sync for: $groupName');
  ```

### 3. リポジトリタイプ診断ログの追加
- **ファイル**: `lib/providers/purchase_group_provider.dart`
- **変更内容**:
  ```dart
  // AllGroupsNotifier.createNewGroup()内に追加
  Log.info('🔍 [CREATE GROUP] Repository type: ${repository.runtimeType}');
  Log.info('🔍 [CREATE GROUP] Flavor: ${F.appFlavor}');
  ```

### 4. 現状の把握
- **アーキテクチャ**: Hive優先、Firestore同期は限定的なタイミングのみ
  - アプリ起動時
  - 明示的な同期ボタン押下時
  - グループCRUD操作時の個別同期
- **Firestore同期方針**:
  - `build()` メソッド内では同期しない（無限ループリスク回避）
  - UI応答性優先のため、Hiveから即座にデータを返す
  - Firestore同期は非同期・バックグラウンドで実行

### 5. Hot Reload/Restartの問題
- **発見**: 追加したデバッグログが出力されない
- **原因**: Hot ReloadはRepositoryレイヤーのコード変更を反映しない場合がある
- **対策**: 完全なアプリ再起動が必要

## 判明した課題

### 1. Firestore書き込みが実行されていない
- **症状**: Firebase Consoleに `/SharedGroups` コレクションが存在しない
- **考えられる原因**:
  1. `HybridSharedGroupRepository.createGroup()` が呼ばれていない
  2. Flavorが `Flavor.dev` になっている
  3. `_firestoreRepo` が `null` のまま
  4. `_isOnline` が `false` になっている

### 2. デバッグログが表示されない
- **症状**: 追加した `🔍 [HYBRID_REPO]` ログが出力されない
- **原因**: コード変更がHot Reloadで反映されていない可能性
- **次回対応**: アプリ完全再起動後にログ確認

## 次回作業予定

### 優先度: 高
1. **Firestore同期診断**
   - アプリを完全再起動（`flutter run -d windows`）
   - グループ作成時のログを確認:
     - `🔍 [CREATE GROUP] Repository type:` → HybridかHiveか
     - `🔍 [CREATE GROUP] Flavor:` → prodかdevか
     - `🔍 [HYBRID_REPO] Firestore sync check:` → 同期スキップ条件
   - スキップ条件に応じた修正実施

2. **Firestore書き込み修正**
   - 根本原因特定後、適切な修正を実施
   - `/SharedGroups/{groupId}` への書き込み確認
   - Firebase Consoleでデータ確認

3. **Firestore構造の最終確認**
   - 現在の実装: `/SharedGroups/{groupId}` (centralized)
   - コード上の実装と実際の挙動の整合性確認

### 優先度: 中
4. **他のCRUD操作の確認**
   - `updateGroup()`, `deleteGroup()` のFirestore同期
   - `getAllGroups()` の動作確認

5. **SharedLists処理の確認**
   - `/sharedLists` コレクションの取扱い確認

## 技術メモ

### Hive優先アーキテクチャの設計意図
- **理由1**: `build()` が頻繁に呼ばれるため、毎回Firestore同期すると無限ループのリスク
- **理由2**: グループ管理はリアルタイム性が低いため、定期同期で十分
- **理由3**: UI応答性を優先（Hiveは同期的に即座にデータを返す）

### HybridSharedGroupRepository の同期条件
```dart
if (F.appFlavor == Flavor.dev || !_isOnline || _firestoreRepo == null) {
  // Firestore同期スキップ
  return newGroup;
}
```

## コード変更サマリー
- `lib/datastore/hybrid_purchase_group_repository.dart`: デバッグログ追加（167-178行目）
- `lib/providers/purchase_group_provider.dart`: リポジトリタイプ診断ログ追加

## 備考
- Hot Reloadの制限により、Repositoryレイヤーの変更は完全再起動が必要
- 次回はアプリ再起動後、診断ログから根本原因を特定予定
