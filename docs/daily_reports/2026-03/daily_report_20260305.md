# 開発日報 - 2026年03月05日

## 📅 本日の目標

- [ ] 総合実機テストチェックリスト セクション3〜12 実施（前日から継続）
- [x] write操作の `.timeout()` 削除 → Firestore SDKオフライン永続化活用
- [x] リポジトリ層（Hybrid）のユニットテスト作成
- [x] 機内モードでのグループ作成スピナーフリーズバグ修正
- [x] daily-summaryスキルのフォーマット調整

---

## ✅ 完了した作業

### 1. ネットワーク障害時処理フロー設計 + write `.timeout()` 全削除 ✅

**Purpose**: Firestore SDKのオフライン永続化機能を活かすため、write操作から `.timeout()` を全削除

**Background**:

- 機内モードでグループ作成するとスピナーが止まらない問題の根本原因調査として、TaskInterface同期キュー案を検討
- 調査の結果、Firestore SDKの内蔵オフライン永続化機能で十分対応可能と判明
- `.timeout()` がFirestoreのオフラインキュー機能を殺しており、`TimeoutException` がUI層まで伝播してスピナー停止の原因になっていた

**Solution**:

write操作の `.timeout()` を全削除（Firestore SDKがオフライン時もローカルキャッシュに即座書き込み → 接続復帰後に自動同期）:

```dart
// ❌ Before: .timeout() がオフラインキュー機能を殺す
await docRef.set(data).timeout(const Duration(seconds: 5));

// ✅ After: Firestore SDKのオフライン永続化に委任
await docRef.set(data);
```

**Modified Files**:

- `lib/datastore/hybrid_purchase_group_repository.dart` — write系 `.timeout()` 削除
- `lib/datastore/hybrid_shared_list_repository.dart` — write系 `.timeout()` 削除
- `docs/specifications/network_failure_handling_flow.md` — 設計書（新規作成）

**Status**: ✅ 完了・0エラー

---

### 2. リポジトリ層DI対応 + ユニットテスト作成（54テスト全パス） ✅

**Purpose**: HybridSharedGroupRepository / HybridSharedListRepository のテスタビリティ向上とユニットテスト実装

**Background**:

- Firebaseシングルトン直接参照により、テスト時にモック注入ができない構造だった
- firebase_auth_mocks + mockito を使用したDI対応リファクタリングを実施

**Solution**:

```dart
// ❌ Before: シングルトン直接参照（テスト不可能）
class HybridSharedGroupRepository {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
}

// ✅ After: コンストラクタ注入（後方互換維持）
class HybridSharedGroupRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  HybridSharedGroupRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;
}
```

**テスト結果**:

| テストファイル                               | テスト数 | 行数        | 結果          |
| -------------------------------------------- | -------- | ----------- | ------------- |
| `hybrid_purchase_group_repository_test.dart` | 27       | 830行       | ✅ 全パス     |
| `hybrid_shared_list_repository_test.dart`    | 27       | 1,206行     | ✅ 全パス     |
| **合計**                                     | **54**   | **2,036行** | ✅ **全パス** |

**テストカバレッジ**:

- 初期化・Firestore統合フロー
- CRUD操作（Firestoreモード / Hiveフォールバック）
- エラーハンドリング（Firestore障害時のHiveフォールバック）
- 差分同期（addSingleItem / updateSingleItem / removeSingleItem）
- isSyncingNotifier状態管理

**Modified Files**:

- `lib/datastore/hybrid_purchase_group_repository.dart` — DI対応リファクタリング
- `lib/datastore/hybrid_shared_list_repository.dart` — DI対応リファクタリング
- `test/datastore/hybrid_purchase_group_repository_test.dart` — 新規作成（830行）
- `test/datastore/hybrid_shared_list_repository_test.dart` — 新規作成（1,206行）

**Status**: ✅ 完了（54/54テスト成功）

---

### 3. 機内モードでのグループ作成スピナーフリーズ修正 ✅

**Purpose**: 機内モードでグループ作成するとダークオーバーレイとスピナーから復帰できない問題を修正

**Root Cause**:

3つの問題が重なっていた:

1. `FirestoreSharedGroupRepository.createGroup()` の `runTransaction()` フォールバック — オフライン時に無期限ハング
2. `HybridSharedGroupRepository.createGroup()` の Firestore `.set()` — タイムアウトなしで待ち続ける
3. `AllGroupsNotifier.createNewGroup()` の Firestore `.get()` — ユーザー名取得でオフライン時ハング

**Solution（3段階修正）**:

**Fix 1**: `runTransaction()` フォールバック削除

```dart
// ❌ Before: runTransaction() はオフラインで無期限ハング
try {
  await docRef.set(data);
} catch (e) {
  await _firestore.runTransaction((tx) async {
    await tx.set(docRef, data);  // ← ここでハング
  });
}

// ✅ After: set() のみ（SDKオフラインキューに委任）
await docRef.set(data);
```

**Fix 2**: Firestore書き込みに10秒タイムアウト + Hiveフォールバック

```dart
// ✅ Firestore書き込みに10sタイムアウト、失敗時はHiveのみで続行
try {
  await _firestoreRepo!.createGroup(groupId, groupName, ownerMember)
      .timeout(const Duration(seconds: 10));
} catch (e) {
  AppLogger.warning('⚠️ Firestore書き込みタイムアウト - Hiveのみで続行');
}
// Hiveは必ず実行
await _hiveRepo.createGroup(groupId, groupName, ownerMember);
```

**Fix 3**: ユーザー名取得 `.get()` に3秒タイムアウト

```dart
// ✅ Firestoreユーザー名取得に3sタイムアウト
final userDoc = await _firestore
    .collection('users').doc(user.uid).get()
    .timeout(const Duration(seconds: 3));
```

**Modified Files**:

- `lib/datastore/firestore_purchase_group_repository.dart` — `runTransaction()` フォールバック削除
- `lib/datastore/hybrid_purchase_group_repository.dart` — 10秒タイムアウト + Hiveフォールバック
- `lib/providers/purchase_group_provider.dart` — `.get()` 3秒タイムアウト

**Status**: ✅ 完了・0エラー・全54テスト成功継続

---

### 4. daily-summaryスキル v2.0 更新 ✅

**Purpose**: `.github/skills/daily-summary/SKILL.md` を実際の日報フォーマットに合わせて更新

**変更内容**:

| 項目         | v1.0（旧）                              | v2.0（新）                                                                         |
| ------------ | --------------------------------------- | ---------------------------------------------------------------------------------- |
| セクション数 | 5（Done/In-progress/Blockers/Next/FYI） | 7（本日の目標/完了した作業/発見された問題/バグ対応進捗/技術的学習事項/翌日の予定） |
| 言語         | 英語ベース                              | 日本語統一                                                                         |
| 詳細度       | 箇条書きのみ                            | Background/Root Cause/Solution/Modified Files/Status構造                           |
| コード例     | なし                                    | ❌ Before / ✅ After パターン                                                      |
| バグ追跡     | なし                                    | ✅/🔄/⏳ ステータス管理                                                            |

**Modified Files**:

- `.github/skills/daily-summary/SKILL.md` — v1.0 → v2.0 全面書き換え

**Status**: ✅ 完了

---

## 🐛 発見された問題

（なし — 本日の作業は全て計画通り完了）

---

## 📊 バグ対応進捗

### 完了 ✅

1. ✅ 機内モードスピナーフリーズ（2026-03-05）
2. ✅ NetworkMonitorService FIX 1-6（2026-03-04）
3. ✅ FIX 7: HybridRepo Firestore再初期化（2026-03-04）
4. ✅ QRスキャナー122pxオーバーフロー修正（2026-03-03）
5. ✅ ホワイトボードプレビュー継続監視バグ（2026-03-02）
6. ✅ 同一ユーザー他デバイス同期バグ（2026-03-02）

### 翌日継続 ⏳

- ⏳ 総合実機テストチェックリスト セクション3〜12（グループ管理〜）

---

## 💡 技術的学習事項

### 1. Firestore `runTransaction()` はオフラインで無期限ハングする

**問題パターン**:

```dart
// ❌ runTransaction() はサーバー応答を必須とするため機内モードでハング
await _firestore.runTransaction((transaction) async {
  await transaction.set(docRef, data);
});
```

**正しいパターン**:

```dart
// ✅ 通常の .set() はFirestore SDKのオフラインキューに入る
await docRef.set(data);
```

**教訓**: `runTransaction()` はサーバーとの通信が必須。書き込みのみの場合は `.set()` / `.update()` を使えばFirestore SDKが自動的にオフラインキューで処理する。

### 2. Write操作に `.timeout()` を付けるとFirestoreオフライン機能を殺す

**問題パターン**:

```dart
// ❌ .timeout() → TimeoutException → rethrow → UIスピナー停止
await docRef.set(data).timeout(const Duration(seconds: 5));
```

**正しいパターン**:

```dart
// ✅ Firestore SDKのオフライン永続化に委任（タイムアウト不要）
await docRef.set(data);
// SDKがオフラインキャッシュに即座書き込み → 接続復帰後に自動同期
```

**教訓**: Firestore SDKのwrite操作はオフライン時もローカルキャッシュに即座に書き込みが完了する。`.timeout()` を付けると、この内蔵機能が `TimeoutException` で中断されてしまう。

### 3. Hybridリポジトリのオフライン戦略 = Firestore試行 → Hiveフォールバック

```dart
// ✅ 書き込み: Firestoreにタイムアウト付き試行 → 失敗時Hiveのみで続行
try {
  await _firestoreRepo!.createGroup(...)
      .timeout(const Duration(seconds: 10));
} catch (e) {
  // Firestore失敗してもアプリは動作継続
}
await _hiveRepo.createGroup(...); // Hiveは必ず実行
```

**教訓**: Hybridリポジトリでは「Firestore失敗 = アプリ停止」にしない。Hiveフォールバックで必ずローカルデータを保持し、UI応答性を確保する。

---

## 🗓 翌日（2026-03-06）の予定

1. 総合実機テストチェックリスト セクション3〜12 実施
   - セクション3: グループ管理（22項目）
   - セクション4: 買い物リスト管理（20項目）
   - セクション5〜12: アイテム管理、QR招待、マルチデバイス、ホワイトボード等
2. テスト結果に応じたバグ修正対応
3. 本日の変更（4ファイル修正 + 2テストファイル新規 + スキル更新）をコミット
