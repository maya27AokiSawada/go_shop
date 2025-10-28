# Riverpod 使用上の注意とベストプラクティス

## 📋 概要

このドキュメントは、Go Shopプロジェクトでの実際の経験に基づいたRiverpodの使用上の注意点とベストプラクティスをまとめています。特に、`abort() called` エラーの回避方法を中心に解説します。

## ⚠️ 重要な注意点

### 1. **AsyncNotifier.build()メソッドでの依存性管理**

#### ❌ 危険なパターン
```dart
@override
Future<List<PurchaseGroup>> build() async {
  final authState = ref.watch(authStateProvider);
  final repository = ref.read(purchaseGroupRepositoryProvider);
  
  // 非同期処理中...
  final allGroups = await repository.getAllGroups();
  
  // ❌ 危険: 非同期処理後の追加依存性取得
  final accessControl = ref.watch(accessControlServiceProvider);
  // これにより "abort() called" エラーが発生する
}
```

#### ✅ 正しいパターン
```dart
@override
Future<List<PurchaseGroup>> build() async {
  // ✅ 最初に全ての依存性を確定する
  final authState = ref.watch(authStateProvider);
  final hiveReady = ref.watch(hiveInitializationStatusProvider);
  final repository = ref.read(purchaseGroupRepositoryProvider);
  final accessControl = ref.read(accessControlServiceProvider);
  
  try {
    // ✅ その後で非同期処理を実行
    if (!hiveReady) {
      await ref.read(hiveUserInitializationProvider.future);
    }
    
    final allGroups = await repository.getAllGroups();
    final visibilityMode = await accessControl.getGroupVisibilityMode();
    
    // ... 処理続行
  } catch (e) {
    // エラー処理
  }
}
```

### 2. **ref.watch() vs ref.read() の使い分け**

| Provider型 | build()メソッド内 | 他のメソッド内 | 理由 |
|-----------|-----------------|-------------|------|
| **StreamProvider** | `ref.watch()` | `ref.watch()` | 非同期データの監視が必要 |
| **FutureProvider** | `ref.watch()` | `ref.watch()` | 非同期データの監視が必要 |
| **Provider<T>** | `ref.read()` | `ref.read()` | 同期的なサービス取得 |
| **AsyncNotifier** | × | `ref.watch()` | 他のNotifierの状態監視 |

#### 具体例
```dart
// ✅ 正しい使用法
final authState = ref.watch(authStateProvider);           // StreamProvider
final hiveReady = ref.watch(hiveInitializationStatusProvider); // FutureProvider
final repository = ref.read(purchaseGroupRepositoryProvider);   // Provider<T>
final accessControl = ref.read(accessControlServiceProvider);   // Provider<T>
```

### 3. **プライベートメソッドでの依存性注入**

#### ❌ 危険なパターン
```dart
Future<PurchaseGroup> _fixLegacyMemberRoles(PurchaseGroup group) async {
  // ❌ プライベートメソッド内でのref操作
  final repository = ref.read(purchaseGroupRepositoryProvider);
  // ...
}
```

#### ✅ 正しいパターン
```dart
Future<PurchaseGroup> _fixLegacyMemberRoles(
  PurchaseGroup group, 
  PurchaseGroupRepository repository
) async {
  // ✅ 引数として依存性を受け取る
  // ...
}

// 呼び出し側
@override
Future<PurchaseGroup?> build() async {
  final repository = ref.read(purchaseGroupRepositoryProvider);
  // ...
  final fixedGroup = await _fixLegacyMemberRoles(group, repository);
}
```

## 🛠️ プロジェクト固有のパターン

### Go Shopでの標準的なAsyncNotifierパターン

```dart
class AllGroupsNotifier extends AsyncNotifier<List<PurchaseGroup>> {
  @override
  Future<List<PurchaseGroup>> build() async {
    Log.info('🔄 [ALL GROUPS] AllGroupsNotifier.build() 開始');

    // ✅ 最初に全ての依存性を確定する
    // FutureProvider/StreamProviderは ref.watch() が必須（非同期データ監視）
    // Provider<T>は ref.read() で十分（同期的なサービス）
    final authState = ref.watch(authStateProvider);
    final hiveReady = ref.watch(hiveInitializationStatusProvider);
    final repository = ref.read(purchaseGroupRepositoryProvider);
    final accessControl = ref.read(accessControlServiceProvider);

    try {
      // Hive初期化待機
      if (!hiveReady) {
        Log.info('🔄 [ALL GROUPS] Hive初期化待機中...');
        await ref.read(hiveUserInitializationProvider.future);
        Log.info('🔄 [ALL GROUPS] Hive初期化完了、続行します');
      }

      // Auth状態に応じた処理
      await authState.whenOrNull(
        data: (user) async {
          if (user != null) {
            Log.info('🔄 [ALL GROUPS] ✅ サインイン状態でグループ取得');
            // バックグラウンド同期の実行
            if (repository is HybridPurchaseGroupRepository) {
              repository.syncFromFirestore().catchError((e) {
                Log.warning('⚠️ [ALL GROUPS] バックグラウンド同期エラー: $e');
              });
            }
          }
        }
      );

      // メインの処理
      final allGroups = await repository.getAllGroups();
      final visibilityMode = await accessControl.getGroupVisibilityMode();
      
      // フィルタリングとソート
      List<PurchaseGroup> filteredGroups;
      switch (visibilityMode) {
        case GroupVisibilityMode.all:
          filteredGroups = allGroups;
          break;
        // ... 他のケース
      }

      return filteredGroups;
    } catch (e, stackTrace) {
      Log.error('❌ [ALL GROUPS] エラー発生: $e');
      Log.error('❌ [ALL GROUPS] スタックトレース: $stackTrace');
      rethrow;
    }
  }
}
```

## 🚨 よくある間違いとその対策

### 1. **非同期処理中の依存性追加**
```dart
// ❌ 間違い
@override
Future<Data> build() async {
  final repo = ref.read(repositoryProvider);
  final data = await repo.getData();
  
  // 危険: 非同期処理後の依存性追加
  final service = ref.read(serviceProvider);
  return service.process(data);
}

// ✅ 正しい
@override
Future<Data> build() async {
  final repo = ref.read(repositoryProvider);
  final service = ref.read(serviceProvider); // 最初に全て取得
  
  final data = await repo.getData();
  return service.process(data);
}
```

### 2. **条件分岐での依存性取得**
```dart
// ❌ 間違い
@override
Future<Data> build() async {
  final condition = ref.watch(conditionProvider);
  
  if (condition) {
    // 危険: 条件分岐内での依存性取得
    final service = ref.read(serviceProvider);
    return service.getData();
  }
  return defaultData;
}

// ✅ 正しい
@override
Future<Data> build() async {
  final condition = ref.watch(conditionProvider);
  final service = ref.read(serviceProvider); // 最初に取得
  
  if (condition) {
    return service.getData();
  }
  return defaultData;
}
```

### 3. **エラーハンドリング内での依存性取得**
```dart
// ❌ 間違い
@override
Future<Data> build() async {
  final repo = ref.read(repositoryProvider);
  
  try {
    return await repo.getData();
  } catch (e) {
    // 危険: catch句内での依存性取得
    final logger = ref.read(loggerProvider);
    logger.error(e);
    rethrow;
  }
}

// ✅ 正しい
@override
Future<Data> build() async {
  final repo = ref.read(repositoryProvider);
  final logger = ref.read(loggerProvider); // 最初に取得
  
  try {
    return await repo.getData();
  } catch (e) {
    logger.error(e);
    rethrow;
  }
}
```

## 🔧 デバッグとトラブルシューティング

### abort() called エラーの特定方法

1. **エラーログの確認**
   ```
   [ERROR:flutter/runtime/dart_vm_initializer.cc(40)] Unhandled Exception: 
   abort() called
   ```

2. **発生箇所の特定**
   - `AsyncNotifier.build()` メソッドを確認
   - 非同期処理後の `ref` 操作を探す
   - 条件分岐内の `ref` 操作を確認

3. **修正方法**
   - 全ての `ref` 操作を `build()` メソッドの最初に移動
   - プライベートメソッドには依存性を引数として渡す

### デバッグ用ログ追加

```dart
@override
Future<Data> build() async {
  Log.info('🔄 [NOTIFIER] build() 開始');
  
  // 依存性取得のログ
  final repo = ref.read(repositoryProvider);
  Log.info('🔄 [NOTIFIER] リポジトリ取得完了');
  
  try {
    final data = await repo.getData();
    Log.info('🔄 [NOTIFIER] データ取得完了: ${data.length}件');
    return data;
  } catch (e, stackTrace) {
    Log.error('❌ [NOTIFIER] エラー発生: $e');
    Log.error('❌ [NOTIFIER] スタックトレース: $stackTrace');
    rethrow;
  }
}
```

## 📚 参考資料

### Riverpod公式ドキュメント
- [AsyncNotifier](https://riverpod.dev/docs/providers/async_notifier)
- [Provider vs AsyncNotifier](https://riverpod.dev/docs/providers/provider)

### Go Shop固有のProvider一覧
- `allGroupsProvider` - グループ一覧管理
- `selectedGroupNotifierProvider` - 選択グループ管理
- `memberPoolProvider` - メンバープール管理
- `authStateProvider` - 認証状態監視
- `hiveInitializationStatusProvider` - Hive初期化状態

## ✅ チェックリスト

新しいAsyncNotifierを作成する際は、以下をチェック：

- [ ] `build()` メソッドの最初に全ての `ref` 操作を配置
- [ ] `Provider<T>` には `ref.read()` を使用
- [ ] `FutureProvider/StreamProvider` には `ref.watch()` を使用
- [ ] プライベートメソッドには依存性を引数として渡す
- [ ] 非同期処理後に `ref` 操作を行わない
- [ ] 条件分岐内で `ref` 操作を行わない
- [ ] エラーハンドリング内で `ref` 操作を行わない
- [ ] 適切なログを追加してデバッグしやすくする

---

**最終更新**: 2025-10-28  
**作成者**: GitHub Copilot  
**プロジェクト**: Go Shop Flutter App