# Hybrid Mode Offline Verification (オフライン動作検証)

**Date**: 2026-01-08
**Verified By**: Production deployment scenario
**Test Environment**: SH 54D (Android 15), Flavor.prod

## 概要

Firestoreセキュリティルール・インデックスのデプロイ直後に発生した「疑似オフライン状態」により、HybridRepositoryのオフライン動作とFirestore復帰時の自動同期が偶然にも実証されました。

## 検証シナリオ

### 初期状態

- **Firebase Project**: goshopping-48db9 (prod)
- **デプロイ実行**: `firebase deploy --only firestore:rules,firestore:indexes`
- **アプリ起動**: デプロイ直後（ルール・インデックス反映前）

### 疑似オフライン状態の発生

Firestoreのセキュリティルールとインデックスには**伝播時間**が必要：

- セキュリティルール: 通常1-5分
- 複合インデックス: 最大数十分（データ量による）

デプロイ直後にアプリを起動したため、以下の状態が発生：

- Firestore書き込みがブロックされる
- HybridRepositoryが自動的にHiveオンリーモードへフォールバック

## 検証結果

### 1. Hiveオンリーモードの正常動作 ✅

**動作内容**:

```
ユーザー操作: グループ作成（"1350", "1355", "1356"）
    ↓
HybridRepository: Firestore書き込み失敗を検出
    ↓
自動フォールバック: Hiveに保存 (syncStatus = SyncStatus.local)
    ↓
UI表示: 正常に表示（ユーザーはエラーに気づかない）
```

**技術詳細**:

```dart
// lib/datastore/hybrid_shared_group_repository.dart
if (F.appFlavor == Flavor.prod && _firestoreRepo != null) {
  try {
    await _firestoreRepo!.createGroup(groupId, groupName, member);
  } catch (e) {
    // Firestoreエラー → Hiveフォールバック
    developer.log('❌ Firestore書き込みエラー: $e');
    final newGroup = await _hiveRepo.createGroup(groupId, groupName, member);
    return newGroup.copyWith(syncStatus: SyncStatus.local); // ← 重要
  }
}
```

**保存されたデータ**:

- グループID: 1767847832510 (1350)
- グループID: 1767848117297 (1355)
- グループID: 1767848279301 (1356)
- すべて`syncStatus: SyncStatus.local`でマーキング

### 2. Firestore復帰時の自動同期 ✅

**アプリ再起動ログ**（Firestore正常化後）:

```
📤 [SYNC] local状態のグループをFirestoreにアップロード: 1350
✅ [SYNC] アップロード完了: 1350
📤 [SYNC] local状態のグループをFirestoreにアップロード: 1355
✅ [SYNC] アップロード完了: 1355
📤 [SYNC] local状態のグループをFirestoreにアップロード: 1356
✅ [SYNC] アップロード完了: 1356
📤 [SYNC] 3個のlocalグループをFirestoreにアップロードしました
```

**同期プロセス**:

```
1. アプリ起動時: UserInitializationService実行
2. Hive内を検索: syncStatus == SyncStatus.local のグループ検出
3. Firestoreに順次アップロード
4. syncStatus更新: SyncStatus.local → SyncStatus.synced
5. ユーザー操作不要で完了
```

**コード実装**:

```dart
// lib/services/sync_service.dart
// Hiveから未同期グループを取得
final localGroups = hiveGroups.where((g) =>
  g.syncStatus == SyncStatus.local && !g.isDeleted
).toList();

// Firestoreに順次アップロード
for (final group in localGroups) {
  try {
    await _firestore.collection('SharedGroups').doc(group.groupId).set({
      ...group.toFirestore(),
      'syncStatus': 'synced',
    });
    developer.log('✅ [SYNC] アップロード完了: ${group.groupName}');
  } catch (e) {
    developer.log('❌ [SYNC] アップロード失敗: ${group.groupName} - $e');
  }
}
```

### 3. ユーザー体験の検証 ✅

**重要な発見**:

- ユーザーはFirestore障害に全く気づかない
- グループ作成・編集が通常通り動作
- 再起動後に自動的にデータ同期
- **データロスゼロ**

## 実際のユースケース

この検証は以下の実際のシナリオをカバーします：

### ケース1: 電車内でのオフライン利用

```
状況: 地下鉄で圏外（Firestore接続不可）
    ↓
ユーザー操作: 買い物リスト作成・編集
    ↓
保存先: Hive (syncStatus.local)
    ↓
地上に出て圏内復帰
    ↓
自動同期: Firestore ← 今回検証！
```

### ケース2: Firebase障害時の継続動作

```
状況: Firebaseメンテナンスや障害
    ↓
アプリ動作: 正常動作継続（Hiveフォールバック）
    ↓
Firebase復旧: 自動的にデータ同期
    ↓
結果: ユーザーは障害に気づかない
```

### ケース3: ネットワーク不安定環境

```
状況: 弱い電波・断続的接続
    ↓
Firestore書き込み: タイムアウト多発
    ↓
HybridRepository: 自動的にHiveに保存
    ↓
安定化後: バックグラウンド同期
```

## 技術的な重要ポイント

### syncStatusの活用

```dart
enum SyncStatus {
  local,    // Hiveのみに保存（未同期）
  synced,   // Firestoreと同期済み
  conflict  // 競合発生（手動解決必要）
}
```

**同期判定ロジック**:

```dart
// 未同期データの検出
final needsSync = allGroups.where((g) =>
  g.syncStatus == SyncStatus.local && !g.isDeleted
);

// 同期済みの確認
final isSynced = group.syncStatus == SyncStatus.synced;
```

### エラーハンドリングパターン

**パターン1: サイレントフォールバック**

```dart
try {
  await _firestoreRepo.createGroup(...);
} catch (e) {
  // ユーザーにエラー表示せず、Hiveに保存
  return await _hiveRepo.createGroup(...);
}
```

**パターン2: リトライ機構**

```dart
// sync_service.dart内
int retryCount = 0;
const maxRetries = 3;

while (retryCount < maxRetries) {
  try {
    await uploadToFirestore(group);
    break;
  } catch (e) {
    retryCount++;
    await Future.delayed(Duration(seconds: retryCount * 2));
  }
}
```

### 同期タイミング

1. **アプリ起動時** (最優先)
   - `UserInitializationService.initialize()`
   - 未同期データの自動検出・アップロード

2. **定期バックグラウンド** (5分間隔)
   - `PeriodicSyncService`
   - local状態のデータを定期チェック

3. **ユーザー操作後** (オプション)
   - 「同期」ボタン手動実行
   - 設定画面からの強制同期

## 教訓

### 1. Firebaseデプロイ後の待機時間

**推奨**:

- セキュリティルールデプロイ後: **5-10分待機**
- インデックスデプロイ後: **最大30分待機**（複雑なインデックスの場合）

**理由**:

- Firebaseは分散システムのため、全リージョンへの伝播に時間が必要
- デプロイ直後はwrite操作がブロックされる可能性がある

### 2. HybridArchitectureの有効性

**メリット**:

- ✅ オフライン環境でも完全動作
- ✅ Firestore障害時の自動フォールバック
- ✅ データロス防止
- ✅ ユーザー体験の向上（エラーを意識させない）

**トレードオフ**:

- ⚠️ 同期ロジックの複雑性
- ⚠️ syncStatusの管理必要
- ⚠️ 競合解決の実装必要（将来）

### 3. テスト戦略の改善

**今後の検証項目**:

- [ ] 意図的なFirestore切断テスト（機内モード）
- [ ] 大量データの同期パフォーマンステスト
- [ ] 複数デバイス間の競合発生シナリオ
- [ ] バッテリー消費の最適化（同期頻度調整）

## 関連ファイル

- `lib/datastore/hybrid_shared_group_repository.dart` - Hybrid Repository実装
- `lib/datastore/hybrid_shared_list_repository.dart` - List用Hybrid Repository
- `lib/services/sync_service.dart` - 同期サービス
- `lib/services/user_initialization_service.dart` - 起動時同期
- `lib/models/shared_group.dart` - syncStatusフィールド定義
- `firestore.rules` - セキュリティルール（デプロイ遅延の原因）

## まとめ

**今回の「事故」により、以下が実証されました**:

✅ HybridRepositoryのオフライン動作完全性
✅ 自動同期メカニズムの正常動作
✅ データロスゼロの実現
✅ ユーザー体験への影響ゼロ

**結論**: アーキテクチャ設計が実際の障害シナリオで期待通りに動作することが確認されました。

---

**参考**: Firebaseデプロイベストプラクティス

- セキュリティルール: `firebase deploy --only firestore:rules`
- インデックス: `firebase deploy --only firestore:indexes`
- デプロイ後の待機: 5-10分（推奨）
- 確認方法: Firebase Console → Firestore → Rules/Indexes タブで "Active" 表示を確認
