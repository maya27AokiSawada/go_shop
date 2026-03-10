# ネットワーク障害時の処理フロー設計書

## 1. 概要

GoShoppingアプリのネットワーク障害（オフライン・タイムアウト）時における、データ操作の信頼性とUI応答性を確保するための設計書。

### 1.1 設計方針

**Firestore SDKのオフライン永続化機能を最大限活用する。**

Firestore SDKは以下の機能を内蔵している：

- **書き込み（Write）**: オフライン時もSDKローカルキャッシュに即座に書き込み、接続復帰後に自動同期
- **読み取り（Read）**: デフォルトでキャッシュ優先（キャッシュがあればキャッシュから返す）

現在の実装では `.timeout()` を多用しており、タイムアウト発生時に `TimeoutException` が UI層まで伝播してスピナーが固まる問題がある。Firestore SDKの内蔵機能を活用することで、この問題を根本的に解消する。

### 1.2 現状の問題

| 問題             | 詳細                                                                                    |
| ---------------- | --------------------------------------------------------------------------------------- |
| スピナー固まり   | Write操作で `.timeout(5s)` → `TimeoutException` → rethrow → UIがcatchできずスピナー停止 |
| SDK機能の無効化  | `.timeout()` がFirestoreSDKのオフラインキュー機能を殺している                           |
| 不整合なパターン | 同じ種類の操作で fire-and-forget / rethrow / sync queue が混在                          |
| Read操作のハング | 一部のRead操作にtimeoutが無く、Firestoreが応答しない場合に無限待機                      |

---

## 2. 現状のコード分析

### 2.1 hybrid_shared_group_repository.dart（15箇所のtimeout）

#### Write操作 — rethrowパターン（❌ UI固まりの原因）

| メソッド                                    | 行   | timeout | 動作               | 問題             |
| ------------------------------------------- | ---- | ------- | ------------------ | ---------------- |
| `createGroup()`                             | L439 | 5s      | rethrow            | スピナー固まり   |
| `_syncCreateGroupToFirestoreWithFallback()` | L642 | 15s     | rethrow            | スピナー固まり   |
| `updateGroup()`                             | L713 | 5s      | rethrow            | スピナー固まり   |
| `deleteGroup()`                             | L779 | 5s      | catch→Hive削除続行 | △ 比較的問題なし |

#### Write操作 — fire-and-forgetパターン（✅ 問題なし）

| メソッド         | 行   | timeout | 動作                           |
| ---------------- | ---- | ------- | ------------------------------ |
| `addMember()`    | L817 | 10s     | `_unawaited` + `.catchError()` |
| `removeMember()` | L847 | 10s     | `_unawaited` + `.catchError()` |
| `setMemberId()`  | L914 | 10s     | `_unawaited` + `.catchError()` |

#### Write操作 — Sync Queueパターン

| メソッド                              | 行   | timeout | 動作             |
| ------------------------------------- | ---- | ------- | ---------------- |
| `_executeSyncOperation()` createGroup | L593 | 10s     | sync queue再試行 |

#### Read操作 — バックグラウンド同期

| メソッド                           | 行                        | timeout | 用途                  |
| ---------------------------------- | ------------------------- | ------- | --------------------- |
| `createGroup()` 書き込み後検証read | L448, L460                | 5s      | Firestore書き込み確認 |
| `_syncFromFirestoreInBackground()` | L948                      | 10s     | バックグラウンド同期  |
| `forceSyncFromFirestore()`         | L991, L1034, L1074, L1133 | 10s     | 手動同期              |

### 2.2 hybrid_shared_list_repository.dart（14箇所のtimeout）

#### Write操作 — rethrowパターン（❌ UI固まりの原因）

| メソッド                       | 行   | timeout | 動作    | 問題           |
| ------------------------------ | ---- | ------- | ------- | -------------- |
| `createSharedList()`           | L399 | 5s      | rethrow | スピナー固まり |
| `updateSharedList()`           | L527 | 5s      | rethrow | スピナー固まり |
| `deleteSharedList()`           | L566 | 5s      | rethrow | スピナー固まり |
| `deleteSharedListsByGroupId()` | L710 | 5s      | rethrow | スピナー固まり |

#### Write操作 — Sync Queue fallbackパターン（✅ 良いパターン）

| メソッド                                        | 行   | timeout | 動作                        |
| ----------------------------------------------- | ---- | ------- | --------------------------- |
| `_syncListToFirestoreWithFallback()`            | L116 | 10s     | timeout時にsync queueに追加 |
| `_syncItemToFirestoreWithFallback()` addItem    | L202 | 10s     | timeout時にsync queueに追加 |
| `_syncItemToFirestoreWithFallback()` updateItem | L210 | 10s     | timeout時にsync queueに追加 |
| `_syncItemToFirestoreWithFallback()` removeItem | L215 | 10s     | timeout時にsync queueに追加 |

#### Write操作 — Sync Queue実行

| メソッド                             | 行   | timeout |
| ------------------------------------ | ---- | ------- |
| `_executeSyncOperation()` create     | L792 | 10s     |
| `_executeSyncOperation()` update     | L797 | 10s     |
| `_executeSyncOperation()` delete     | L806 | 10s     |
| `_executeSyncOperation()` createItem | L815 | 10s     |
| `_executeSyncOperation()` updateItem | L823 | 10s     |
| `_executeSyncOperation()` deleteItem | L829 | 10s     |

#### Read操作 — timeoutなし（⚠️ 無限待機リスク）

| メソッド                  | timeout | 動作                           |
| ------------------------- | ------- | ------------------------------ |
| `getSharedListById()`     | なし    | try-catch + Hiveフォールバック |
| `getSharedListsByGroup()` | なし    | try-catch + Hiveフォールバック |

### 2.3 sync_service.dart（2箇所のtimeout）

| メソッド                       | 行   | timeout | 用途                         |
| ------------------------------ | ---- | ------- | ---------------------------- |
| `syncAllGroupsFromFirestore()` | L43  | 30s     | アプリ起動時の全グループ同期 |
| `syncSpecificGroup()`          | L114 | 10s     | 通知受信時の個別グループ同期 |

### 2.4 network_monitor_service.dart — Source.server（2箇所、変更不要）

| 行   | 用途                                                       | 判断                            |
| ---- | ---------------------------------------------------------- | ------------------------------- |
| L93  | `checkFirestoreConnection()` Firestoreコレクション接続確認 | ✅ 変更不要（接続チェック目的） |
| L101 | 同上、別のコレクション確認                                 | ✅ 変更不要                     |

---

## 3. 修正方針

### 3.1 Write操作の方針

**原則: `.timeout()` を削除し、Firestore SDKのオフラインキューに委ねる**

Firestore SDKのwrite操作はオフライン時に以下の動作をする：

1. SDKローカルキャッシュに即座に書き込み（ms単位で完了）
2. `Future` が即座に resolve される
3. 接続復帰後に自動的にサーバーと同期

つまり、`.timeout()` が無くても write操作は即座に返る。TimeoutExceptionが発生する余地がない。

#### 修正パターン

```dart
// ❌ 現在: timeout → rethrow → UIフリーズ
await _firestoreRepo!.createGroup(groupId, groupName, ownerMember)
    .timeout(const Duration(seconds: 5));

// ✅ 修正後: timeoutなし、SDK任せ
await _firestoreRepo!.createGroup(groupId, groupName, ownerMember);
```

#### 書き込み後検証read（L448, L460）の対応

現在 `createGroup()` で書き込み後にFirestoreからreadして検証している。この検証readも不要。Firestore SDKが書き込みを受理した時点で、ローカルキャッシュには反映済み。

```dart
// ❌ 現在: 書き込み後にFirestoreから読み返して検証
final verifyDoc = await _firestore.collection('SharedGroups').doc(groupId).get()
    .timeout(const Duration(seconds: 5));

// ✅ 修正後: 検証read自体を削除（Hiveへの書き込みで十分）
```

### 3.2 Read操作の方針

**原則: Firestore SDKのキャッシュ優先動作を活用 + 安全タイムアウト + Hiveフォールバック**

Read操作はWrite操作と異なり、サーバーから最新データを取得しようとする可能性がある。安全策として：

1. **通常のread**: Firestore SDKに任せる（キャッシュがあればキャッシュ優先）
2. **バックグラウンド同期read**: 長めのtimeout（10-30s）を維持 → catch → Hiveフォールバック
3. **UIに直結するread**: 短めのtimeout（5s）→ catch → Hiveフォールバック → UIは表示可能

#### Read操作でtimeoutが無い箇所への対応

`getSharedListById()` と `getSharedListsByGroup()` にはtimeoutがない。Firestoreが応答しない場合に無限待機のリスクがある。安全タイムアウトを追加する。

```dart
// ✅ Read操作: 安全タイムアウト + Hiveフォールバック
try {
  final result = await _firestoreRepo!.getSharedListById(listId)
      .timeout(const Duration(seconds: 10));
  // Hiveにキャッシュ
  return result;
} catch (e) {
  AppLogger.warning('⚠️ Firestore読み取りタイムアウト、Hiveフォールバック');
  return await _hiveRepo.getSharedListById(listId);
}
```

### 3.3 Sync Queue（同期キュー）の方針

**原則: Firestore SDKが同期キューを内蔵しているため、アプリ側の同期キューは不要**

Firestore SDKのオフラインキューがwrite操作を自動管理するため、`_syncQueue` / `_addToSyncQueue` / `_processSyncQueue` / `_executeSyncOperation` は不要になる。

ただし、段階的に削除する：

1. **Phase 1**: `.timeout()` を削除してSDKに委ねる
2. **Phase 2**: sync queueコードの無効化・削除（動作確認後）

### 3.4 sync_service.dartの方針

sync_service.dartのtimeoutは **Read操作**（Firestore→Hiveの全同期）であるため、維持する。

| メソッド                       | timeout | 判断                          |
| ------------------------------ | ------- | ----------------------------- |
| `syncAllGroupsFromFirestore()` | 30s     | ✅ 維持（大量データ読み取り） |
| `syncSpecificGroup()`          | 10s     | ✅ 維持（個別データ読み取り） |

これらはバックグラウンド同期であり、UIスピナーに直結しないため問題ない。

---

## 4. 修正対象ファイル一覧

### Phase 1: Write操作の`.timeout()`削除（スピナー固まり解消）

#### hybrid_shared_group_repository.dart

| 行         | メソッド                                    | 変更内容                                    |
| ---------- | ------------------------------------------- | ------------------------------------------- |
| L439       | `createGroup()`                             | `.timeout(5s)` 削除                         |
| L448, L460 | `createGroup()` 検証read                    | 検証read自体を削除                          |
| L593       | `_executeSyncOperation()`                   | `.timeout(10s)` 削除                        |
| L642       | `_syncCreateGroupToFirestoreWithFallback()` | `.timeout(15s)` 削除                        |
| L713       | `updateGroup()`                             | `.timeout(5s)` 削除                         |
| L779       | `deleteGroup()`                             | `.timeout(5s)` 削除                         |
| L817       | `addMember()`                               | `.timeout(10s)` 削除（既にfire-and-forget） |
| L847       | `removeMember()`                            | `.timeout(10s)` 削除（既にfire-and-forget） |
| L914       | `setMemberId()`                             | `.timeout(10s)` 削除（既にfire-and-forget） |

#### hybrid_shared_list_repository.dart

| 行               | メソッド                             | 変更内容             |
| ---------------- | ------------------------------------ | -------------------- |
| L116             | `_syncListToFirestoreWithFallback()` | `.timeout(10s)` 削除 |
| L202, L210, L215 | `_syncItemToFirestoreWithFallback()` | `.timeout(10s)` 削除 |
| L399             | `createSharedList()`                 | `.timeout(5s)` 削除  |
| L527             | `updateSharedList()`                 | `.timeout(5s)` 削除  |
| L566             | `deleteSharedList()`                 | `.timeout(5s)` 削除  |
| L710             | `deleteSharedListsByGroupId()`       | `.timeout(5s)` 削除  |
| L792-829         | `_executeSyncOperation()` 全6箇所    | `.timeout(10s)` 削除 |

### Phase 1: Read操作の安全タイムアウト追加

#### hybrid_shared_list_repository.dart

| メソッド                  | 変更内容                                     |
| ------------------------- | -------------------------------------------- |
| `getSharedListById()`     | 安全タイムアウト10s + Hiveフォールバック追加 |
| `getSharedListsByGroup()` | 安全タイムアウト10s + Hiveフォールバック追加 |

### Phase 1で変更しないファイル

| ファイル                       | 理由                                            |
| ------------------------------ | ----------------------------------------------- |
| `sync_service.dart`            | Read操作（バックグラウンド同期）のtimeoutは維持 |
| `network_monitor_service.dart` | Source.serverは接続チェック目的で必要           |

### Phase 2: Sync Queue削除（Phase 1動作確認後）

| ファイル                              | 削除対象                                                                                                             |
| ------------------------------------- | -------------------------------------------------------------------------------------------------------------------- |
| `hybrid_shared_group_repository.dart` | `_SyncOperation`, `_executeSyncOperation()`, sync キュー関連コード                                                   |
| `hybrid_shared_list_repository.dart`  | `_SharedListSyncOperation`, `_addToSyncQueue()`, `_scheduleSync()`, `_processSyncQueue()`, `_executeSyncOperation()` |

---

## 5. 処理フロー図

### 5.1 Write操作（修正後）

```
ユーザー操作（グループ作成等）
    │
    ▼
┌─────────────────────┐
│ 1. Hiveに書き込み    │ ← 即座に完了（ローカル）
└─────────┬───────────┘
          │
          ▼
┌─────────────────────┐
│ 2. UIに成功を返す    │ ← スピナー即座に消える
└─────────┬───────────┘
          │
          ▼
┌─────────────────────────────────┐
│ 3. Firestoreに書き込み（await） │ ← SDKが内部処理
│    - オンライン: サーバー即反映  │
│    - オフライン: SDKキャッシュ   │
│      → 接続復帰後に自動同期     │
└─────────────────────────────────┘
```

### 5.2 Read操作（修正後）

```
データ読み取り要求
    │
    ▼
┌──────────────────────────────┐
│ Firestore SDKに読み取り要求  │
│ + 安全タイムアウト(10s)       │
└─────────┬──────────┬─────────┘
          │          │
       成功        タイムアウト/エラー
          │          │
          ▼          ▼
  ┌──────────┐  ┌───────────────┐
  │ データ返却│  │ Hiveから読み取り│ ← フォールバック
  │ + Hive   │  │ (キャッシュ)    │
  │ キャッシュ│  └───────────────┘
  └──────────┘
```

### 5.3 ネットワーク状態遷移

```
オンライン ──────────────────────────── オフライン
    │                                      │
    │  Write: Firestore即反映              │  Write: SDKキャッシュ保存
    │  Read: Firestore→Hiveキャッシュ       │  Read: Hiveフォールバック
    │                                      │
    └──── 接続復帰 ◄──────────────────────┘
              │
              ▼
    SDKキャッシュの未同期データを
    自動的にFirestoreへ同期
```

---

## 6. UI表示方針

### 6.1 ネットワーク状態表示（既存）

`NetworkMonitorService` による以下の表示は維持：

- **オンライン**: 緑アイコン
- **オフライン**: 赤アイコン + バナー表示
- **チェック中**: オレンジアイコン

### 6.2 書き込み操作のUI

修正後は `.timeout()` を削除するため、write操作は即座に完了する。特別なUI変更は不要。

### 6.3 スピナーの動作（修正後）

| 操作         | 現在                                | 修正後                    |
| ------------ | ----------------------------------- | ------------------------- |
| グループ作成 | 5秒後にタイムアウト→スピナー固まり  | 即座に完了→スピナー消える |
| リスト作成   | 5秒後にタイムアウト→スピナー固まり  | 即座に完了→スピナー消える |
| アイテム追加 | 10秒後にタイムアウト→sync queue追加 | 即座に完了                |
| メンバー追加 | fire-and-forget→問題なし            | 変更なし                  |

---

## 7. テスト方針

### 7.1 オフラインテスト

1. **機内モード ON** → グループ作成 → スピナーが即座に消えることを確認
2. **機内モード ON** → リスト作成 → スピナーが即座に消えることを確認
3. **機内モード ON** → アイテム追加 → スピナーが即座に消えることを確認
4. **機内モード OFF** → 上記で作成したデータがFirestoreに反映されることを確認

### 7.2 不安定ネットワークテスト

1. WiFi接続が不安定な環境で連続操作 → UIフリーズなしを確認
2. 操作中にWiFi切断 → データ損失なしを確認

### 7.3 回帰テスト

1. 通常のオンライン環境で全CRUD操作が正常動作
2. マルチデバイス同期が正常動作
3. 手動同期ボタンが正常動作

---

## 8. リスクと対策

### 8.1 Firestore SDKキャッシュの容量制限

**リスク**: 大量のオフライン書き込みがSDKキャッシュを圧迫する可能性

**対策**: GoShoppingアプリの書き込み頻度は低い（グループ/リスト/アイテムの作成・更新）ため、実用上問題なし。Firestore SDKのデフォルトキャッシュサイズ（100MB）で十分。

### 8.2 長期オフライン後のコンフリクト

**リスク**: 長時間オフライン後にサーバーと同期した際、他ユーザーのデータと衝突

**対策**: 現在のアプリではlast-write-wins方式が事実上の標準。Firestoreのマージ戦略により深刻なデータ損失は発生しない。

### 8.3 SDKキャッシュとHiveキャッシュの二重管理

**リスク**: Firestore SDKキャッシュとHiveキャッシュの両方が存在し、整合性の問題

**対策**: Hiveは「UIへの高速表示用キャッシュ」として維持。Firestoreからの読み取り成功時にHiveを更新するパターンは変更なし。

---

## 9. 実装スケジュール

### Phase 1（今回実施）

1. Write操作の `.timeout()` 削除（全29箇所のうちWrite操作分）
2. Read操作への安全タイムアウト追加（2箇所）
3. オフラインテスト実施

### Phase 2（Phase 1動作確認後）

1. Sync Queueコードの削除
2. 書き込み後検証readの削除
3. 回帰テスト実施

---

## 付録: Firestore SDK オフライン永続化の動作

### Write操作

```
app.set({ name: "グループA" })
    │
    ▼
┌─────────────────────────────────┐
│ Firestore SDK内部処理            │
│                                  │
│ 1. ローカルキャッシュに書き込み  │ ← Future resolve（即座）
│ 2. 同期キューに追加              │
│ 3. ネットワーク接続時にサーバー  │
│    に送信                        │
│ 4. サーバー確認後キューから削除  │
└─────────────────────────────────┘
```

### Read操作

```
app.get(docRef)
    │
    ▼
┌─────────────────────────────────┐
│ Firestore SDK内部処理            │
│                                  │
│ オンライン:                      │
│   → サーバーから取得             │
│   → ローカルキャッシュ更新       │
│                                  │
│ オフライン:                      │
│   → ローカルキャッシュから返却   │
│   → キャッシュなければエラー     │
└─────────────────────────────────┘
```

### `Source.server` の意味

```dart
// Source.server: キャッシュを無視して必ずサーバーに問い合わせる
// → network_monitor_service.dart の接続チェックに使用（変更不要）
await collection.get(GetOptions(source: Source.server));
```
