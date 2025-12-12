# SharedList リアルタイム同期設計書

## 目的

複数デバイス間でSharedListの変更をリアルタイムに同期する機能を実装する。

## 現状の問題点

- **現在**: デバイスAでアイテムを追加しても、デバイスBでは画面遷移するまで反映されない
- **原因**: FirestoreからのデータはFutureベースの1回取得のみで、Streamリスナーが未実装
- **既存の通知機能**: 5分間隔のバッチ通知は「通知送信」のみで、「データ変更受信」には対応していない

## 既存の成功実装（グループ招待）

```dart
// lib/widgets/group_invitation_dialog.dart (line 123-130)
StreamBuilder<QuerySnapshot>(
  stream: FirebaseFirestore.instance
      .collection('SharedGroups')
      .doc(widget.group.groupId)
      .collection('invitations')
      .snapshots(),
  builder: (context, snapshot) {
    // Firestoreの変更を即座に受信してUIを更新
  }
)
```

## 設計方針

### 1. Firestore構造（変更なし）

```
/SharedGroups/{groupId}/sharedLists/{listId}
  ├─ listId: String
  ├─ listName: String
  ├─ items: List<SharedItem>
  ├─ createdAt: Timestamp
  └─ updatedAt: Timestamp
```

### 2. アーキテクチャ

#### 2-1. Repository層（データ取得）

**FirestoreSharedListRepository**に追加:

```dart
// 新規メソッド
Stream<SharedList?> watchSharedList(String groupId, String listId) {
  return _firestore
      .collection('SharedGroups')
      .doc(groupId)
      .collection('sharedLists')
      .doc(listId)
      .snapshots()
      .map((snapshot) {
        if (!snapshot.exists) return null;
        return SharedList.fromFirestore(snapshot);
      });
}
```

**HybridSharedListRepository**に追加:

```dart
Stream<SharedList?> watchSharedList(String groupId, String listId) {
  // Dev環境またはオフライン時はポーリング方式にフォールバック
  if (F.appFlavor == Flavor.dev || !_isOnline || _firestoreRepo == null) {
    // 定期的にHiveから取得（30秒間隔）
    return Stream.periodic(Duration(seconds: 30), (_) {
      return _hiveRepo.getSharedList(groupId);
    }).asyncMap((future) => future);
  }

  // オンライン時はFirestoreのStreamを使用
  return _firestoreRepo!.watchSharedList(groupId, listId).map((firestoreList) {
    // Firestoreから取得したデータをHiveにキャッシュ（バックグラウンド）
    if (firestoreList != null) {
      _hiveRepo.addItem(firestoreList).catchError((e) {
        developer.log('⚠️ Hiveキャッシュ保存エラー: $e');
      });
    }
    return firestoreList;
  });
}
```

#### 2-2. UI層（StreamBuilder）

**shopping_list_page_v2.dart**を修正:

**パターンA（推奨）: StreamBuilderを直接使用**

```dart
// _SharedItemsListWidget の build メソッド内
@override
Widget build(BuildContext context, WidgetRef ref) {
  final currentList = ref.watch(currentListProvider);
  final selectedGroupId = ref.watch(selectedGroupIdProvider);

  if (currentList == null || selectedGroupId == null) {
    return Center(child: Text('リストを選択してください'));
  }

  final repository = ref.read(sharedListRepositoryProvider) as HybridSharedListRepository;

  return StreamBuilder<SharedList?>(
    stream: repository.watchSharedList(selectedGroupId, currentList.listId),
    initialData: currentList, // 初期データは既存のcurrentListを使用
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return Center(child: Text('エラー: ${snapshot.error}'));
      }

      final liveList = snapshot.data ?? currentList;

      if (liveList.items.isEmpty) {
        return Center(child: Text('買い物アイテムがありません'));
      }

      return ListView.builder(
        itemCount: liveList.items.length,
        itemBuilder: (context, index) {
          final item = liveList.items[index];
          return _SharedItemTile(item: item, index: index);
        },
      );
    },
  );
}
```

**パターンB: StreamProviderを使用（より複雑）**

```dart
// lib/providers/shopping_list_provider.dart に追加
final liveSharedListProvider = StreamProvider.family<SharedList?, (String, String)>(
  (ref, params) {
    final (groupId, listId) = params;
    final repository = ref.watch(sharedListRepositoryProvider) as HybridSharedListRepository;
    return repository.watchSharedList(groupId, listId);
  },
);

// shopping_list_page_v2.dart で使用
final liveListAsync = ref.watch(liveSharedListProvider((selectedGroupId, currentList.listId)));
return liveListAsync.when(
  data: (liveList) => /* UI */,
  loading: () => CircularProgressIndicator(),
  error: (e, _) => Text('エラー: $e'),
);
```

### 3. データフロー

```
[デバイスA] アイテム追加
    ↓
Hiveに保存（即座）
    ↓
Firestoreに保存（非同期）
    ↓
Firestore snapshots() が変更を検知
    ↓
[デバイスB] StreamBuilder が自動更新
    ↓
UIに即座に反映
    ↓
Hiveにキャッシュ（バックグラウンド）
```

### 4. エラーハンドリング

#### オフライン対応

```dart
// HybridSharedListRepository
Stream<SharedList?> watchSharedList(String groupId, String listId) {
  return _firestoreRepo!
      .watchSharedList(groupId, listId)
      .handleError((error) {
        developer.log('⚠️ Firestore Stream エラー: $error');
        _isOnline = false; // オフラインマークを設定

        // Hiveキャッシュにフォールバック
        return _hiveRepo.getSharedList(groupId);
      });
}
```

#### Stream破棄

```dart
// _SharedItemsListWidget を StatefulWidget に変更
class _SharedItemsListWidget extends ConsumerStatefulWidget {
  // ...
}

class _SharedItemsListWidgetState extends ConsumerState<_SharedItemsListWidget> {
  StreamSubscription? _subscription;

  @override
  void dispose() {
    _subscription?.cancel(); // Stream を明示的にキャンセル
    super.dispose();
  }

  // ...
}
```

※ ただし、`StreamBuilder`を使う場合は自動で破棄されるため不要

### 5. パフォーマンス考慮事項

#### メリット

- ✅ リアルタイム性: 他デバイスの変更が即座に反映
- ✅ ネットワーク効率: Firestoreが差分のみ送信
- ✅ オフライン対応: Hiveキャッシュにフォールバック

#### デメリット・リスク

- ⚠️ Firestoreコスト: 読み取り回数が増加（snapshots()は変更のたびに課金）
- ⚠️ バッテリー消費: 常時接続でバッテリー消費増
- ⚠️ メモリ使用量: Streamリスナーがメモリに常駐

#### コスト削減策

```dart
// 画面が非アクティブ時はStreamを一時停止
class _SharedItemsListWidgetState extends ConsumerState<_SharedItemsListWidget>
    with WidgetsBindingObserver {

  StreamSubscription? _subscription;
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _subscription?.pause(); // バックグラウンド時はStream一時停止
    } else if (state == AppLifecycleState.resumed) {
      _subscription?.resume();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _subscription?.cancel();
    super.dispose();
  }
}
```

### 6. 実装の優先順位

#### Phase 1（最小実装）

1. `FirestoreSharedListRepository.watchSharedList()` メソッド追加
2. `HybridSharedListRepository.watchSharedList()` メソッド追加
3. `shopping_list_page_v2.dart`の`_SharedItemsListWidget`を`StreamBuilder`に変更

#### Phase 2（最適化）

1. オフライン検出とHiveフォールバック
2. エラーハンドリング強化
3. ログ追加

#### Phase 3（パフォーマンス最適化）

1. アプリライフサイクル検出でStream一時停止
2. メモリリーク対策
3. コスト削減策の実装

### 7. テスト計画

#### 基本テスト

1. **Windows → Android同期**: Windowsでアイテム追加 → Androidで即座に表示されるか
2. **Android → Windows同期**: Androidでチェックボックス変更 → Windowsで即座に反映されるか
3. **削除同期**: 片方でアイテム削除 → もう片方で即座に消えるか

#### オフライン・リカバリーテスト

1. **オフライン時の動作**: Wi-Fi OFFでアイテム追加 → Hiveに保存されるか
2. **オンライン復帰**: Wi-Fi ON → Firestoreに自動同期されるか
3. **競合解決**: 両デバイスでオフライン編集 → 最後の変更が勝つか（Last Write Wins）

#### パフォーマンステスト

1. **アイテム100件**: 大量アイテムで動作確認
2. **頻繁な更新**: 連続してアイテム追加・削除
3. **複数リスト**: 複数リストを高速切り替え

### 8. リスク・制約事項

#### 技術的制約

- Firestoreの無料枠: 1日5万回読み取りまで（snapshots()は変更ごとに1回カウント）
- Riverpodの制約: StreamProviderとAsyncNotifierProviderの混在は複雑化

#### 運用上の考慮事項

- ユーザーに「リアルタイム同期」の説明が必要
- オフライン時の動作をユーザーに明示
- コスト増加の監視が必要

### 9. 代替案（検討済み）

#### 案A: ポーリング方式（30秒間隔）

- メリット: 実装簡単、コスト予測可能
- デメリット: リアルタイム性なし、最大30秒遅延

#### 案B: WebSocket独自実装

- メリット: 完全制御可能
- デメリット: 開発コスト大、保守困難

#### 案C: Firebase Cloud Messaging（FCM）

- メリット: プッシュ通知と連携
- デメリット: データ送信に制約、複雑

**結論**: Firestore snapshots()が最適（Firebase標準機能、実装シンプル、高信頼性）

---

## 実装開始前チェックリスト

- [ ] FirestoreのSharedListコレクション構造を確認
- [ ] 現在のFirestore Rulesで`sharedLists`サブコレクションの読み取り権限を確認
- [ ] `shopping_list_repository.dart`インターフェースに`watchSharedList`メソッドを追加
- [ ] Phase 1の実装範囲を最終確認
- [ ] テスト用のグループ・リストを準備
- [ ] Firestore使用量の現状を確認（Firebase Console）

## 実装後の検証項目

- [ ] Windows → Android リアルタイム同期
- [ ] Android → Windows リアルタイム同期
- [ ] オフライン時の動作（Hiveフォールバック）
- [ ] エラー時の挙動（ログ確認）
- [ ] メモリリーク確認
- [ ] Firestore読み取り回数の確認（Firebase Console）
- [ ] バッテリー消費の体感確認

---

**更新履歴**:

- 2025-11-22: 初版作成
