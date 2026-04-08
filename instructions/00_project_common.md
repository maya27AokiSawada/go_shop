# プロジェクト共通指示書（必読）

> **このファイルはすべての実装・修正前に必ず参照すること。**
> ここを破ることが赤画面・再発バグ・データ整合性崩壊の大半の原因となっている。

---

## 1. 基本アーキテクチャ

- **Firestore ファースト・ハイブリッド構成**
  - Firestore = source of truth（唯一の真実）
  - Hive = キャッシュ（read 高速化のみ）
- **認証必須アプリ**（未認証前提の設計・分岐は禁止）
- **Repository パターン**（UI → Provider → Repository / Service の層分離を厳守）
- Riverpod は **Generator 不使用**（従来構文のみ）

### Firebase プロジェクト

| Flavor        | Project ID         | 用途         |
| ------------- | ------------------ | ------------ |
| `Flavor.prod` | `goshopping-48db9` | 本番リリース |
| `Flavor.dev`  | `gotoshop-572b7`   | 開発・テスト |

### Hive TypeID 一覧（新規追加時は必ず確認）

| typeId | クラス             |
| ------ | ------------------ |
| 0      | SharedGroupRole    |
| 1      | SharedGroupMember  |
| 2      | SharedGroup        |
| 3      | SharedItem         |
| 4      | SharedList         |
| 6      | UserSettings       |
| 7      | AcceptedInvitation |
| 8      | InvitationStatus   |
| 9      | InvitationType     |
| 10     | SyncStatus         |
| 11     | GroupType          |
| 12     | ListType           |
| 15     | DrawingStroke      |
| 16     | DrawingPoint       |
| 17     | Whiteboard         |

空き番号: 5、13、14、18 以降

---

## 2. 認証フロー（順序厳守）

```text
サインアップ:
  ① SharedPreferences + Hive を全クリア  ← Firebase Auth 登録より先に実行
  ② Firebase Auth.signUp()
  ③ UserPreferencesService.saveUserName()
  ④ user.updateDisplayName()
  ⑤ ref.invalidate(allGroupsProvider) 等
  ⑥ forceSyncProvider で Firestore → Hive 同期

サインイン:
  ① Firebase Auth.signIn()
  ② Firestore からユーザー名取得 → SharedPreferences 保存
  ③ forceSyncProvider（invalidate してから await）
  ④ ref.invalidate(allGroupsProvider)

サインアウト:
  ① SharedPreferences + Hive を全クリア
  ② ref.invalidate() 各 Provider
  ③ Firebase Auth.signOut()  ← 最後
```

---

## 3. Riverpod ルール（CRITICAL）

### 3-1. `AsyncNotifier.build()` 内では `ref.watch()` のみ

```dart
// ✅ 正しい
@override
Future<Data> build() async {
  final auth = ref.watch(authStateProvider).value;
  return fetchData(auth);
}

// ❌ 禁止 — assertion error の原因
@override
Future<Data> build() async {
  final auth = ref.read(authStateProvider).value;
  return fetchData(auth);
}
```

### 3-2. `late final Ref _ref` は使ってはならない

```dart
// ✅ 正しい
Ref? _ref;

@override
Future<Data> build() async {
  _ref ??= ref;  // 初回のみ代入
  return fetchData();
}

// ❌ 禁止 — 2回目の build() で LateInitializationError
late final Ref _ref;

@override
Future<Data> build() async {
  _ref = ref;  // クラッシュ
  return fetchData();
}
```

### 3-3. 命令的な再同期は「invalidate → await future」

```dart
// ✅ 正しい
ref.invalidate(forceSyncProvider);
await ref.read(forceSyncProvider.future);

// ❌ 禁止 — 前回の Future 結果を再利用する可能性がある
await ref.read(forceSyncProvider.future);
```

### 3-4. async / callback 内では `ref.watch()` を使わない

```dart
// ✅ 正しい
Future<void> doSomething() async {
  final auth = ref.read(authStateProvider);
}

// ❌ 禁止 — 依存関係が破壊される
Future<void> doSomething() async {
  final auth = ref.watch(authStateProvider);
}
```

### 3-5. `showDialog()` 内 Consumer では必ず `ref.watch()`

```dart
// ✅ 正しい
showDialog(
  context: context,
  builder: (_) => Consumer(
    builder: (_, ref, __) {
      final auth = ref.watch(authStateProvider).value;
      return AlertDialog(...);
    },
  ),
);

// ❌ 禁止 — ダイアログは特殊なライフサイクル。2回目表示で赤画面になる
showDialog(
  context: context,
  builder: (_) => Consumer(
    builder: (_, ref, __) {
      final auth = ref.read(authStateProvider).value;
      return AlertDialog(...);
    },
  ),
);
```

---

## 4. 頻出アンチパターン（実被害を出したもの）

### ❌ Anti-1: Hive を即時の真実として扱う

ユーザー切替直後の空 Hive をそのまま「0件」と確定してはならない。

```dart
// ❌ 間違い
await hiveService.initializeForUser(newUid);
final groups = await ref.read(allGroupsProvider.future); // 空の Hive を正とする

// ✅ 正しい
await hiveService.initializeForUser(newUid);
ref.invalidate(forceSyncProvider);
await ref.read(forceSyncProvider.future);           // Firestore で復元
await ref.read(allGroupsProvider.notifier).cleanupInvalidHiveGroups();
await ref.read(allGroupsProvider.notifier).refresh();
```

### ❌ Anti-2: 破棄される Widget から async 後に `ref` / `context` を使う

```dart
// ❌ 間違い — Widget が消えた後も ref.invalidate() / Navigator.pop() を呼ぶ
await ref.read(allGroupsProvider.notifier).createNewGroup(groupName);
await ref.read(allGroupsProvider.future);
if (context.mounted) {
  ref.invalidate(allGroupsProvider); // Widget 廃棄後は二次障害を引き起こす
  Navigator.pop(context);
}

// ✅ 正しい — UI は provider watch で自動更新させ、async 後に余計な操作をしない
await ref.read(allGroupsProvider.notifier).createNewGroup(groupName);
await ref.read(allGroupsProvider.future);
// 以降は何もしない
```

### ❌ Anti-3: Firestore write に `.timeout()` を付ける

```dart
// ❌ 間違い — オフラインキュー機能を殺す
await docRef.set(data).timeout(const Duration(seconds: 5));

// ✅ 正しい — SDK のオフラインキューに委任
await docRef.set(data);
```

Hybrid リポジトリでは Firestore 失敗後も **Hive 書き込みは必ず続行**する。

```dart
try {
  await _firestoreRepo!.createGroup(...);
} catch (_) {}
await _hiveRepo.createGroup(...);  // 必ず実行
```

### ❌ Anti-4: `runTransaction()` をオフラインで使う

`runTransaction()` はサーバー応答必須のため、オフライン時に無期限ハングする。
Windows 版では SDK レベルのクラッシュ（abort()）も発生する。
**write-only な処理に transaction は使わない**。

### ❌ Anti-5: 未保存キーを旧バージョンと誤解する

```dart
// ❌ 間違い — 未保存 = 旧版ではない
final version = prefs.getInt(_dataVersionKey) ?? 1;

// ✅ 正しい — 未保存 = 初回起動
if (!prefs.containsKey(_dataVersionKey)) {
  await prefs.setInt(_dataVersionKey, _currentDataVersion);
  return _currentDataVersion;
}
```

### ❌ Anti-6: catch ブロックで二次例外を起こす

```dart
// ❌ 間違い — stackTrace を第2引数に渡してしまう
catch (e, stackTrace) {
  Log.error('failed', stackTrace);  // Log.error の引数順が違う

// ✅ 正しい
catch (e, stackTrace) {
  Log.error('failed: $e', e, stackTrace);
}
```

### ❌ Anti-7: 接続監視で単発失敗を即 offline 判定する

DNS / 名前解決の一時的失敗を即 `offline` にしない。
`offlineFailureThreshold = 2`、`transientRetryDelay` を挟み連続失敗でのみ判定する。

### ❌ Anti-8: `Switch` の更新で現在値を反転する

`Switch` の `onChanged` callback はユーザーの **目標値** を直接渡す。現在値の反転は stale state との race を引き起こす。

```dart
// ✅ 正しい
Switch(
  value: _currentValue,
  onChanged: (newValue) => _setValue(newValue),  // 目標値をそのまま保存
);
```

### ❌ Anti-9: サインイン復元を Hive box 未準備のまま走らせる

`authStateChanges()` は Hive 初期化完了より先に飛ぶことがある。
`forceSyncProvider` / `allGroupsProvider` を触る前に box の open を確認すること。

### ❌ Anti-10: `waitForSafeInitialization()` を省略する

`HybridRepository` の CRUD を呼ぶ前に `waitForSafeInitialization()` を呼ぶ。
Firebase Auth の起動遅延で `_firestoreRepo == null` のまま処理が進むことを防ぐ。

---

## 5. プラットフォーム固有ルール

| 項目                        | Windows                          | Android / iOS |
| --------------------------- | -------------------------------- | ------------- |
| Firestore transaction       | **禁止**（abort クラッシュ）     | 使用可        |
| runTransaction              | **禁止**                         | 使用可        |
| write timeout               | **禁止**                         | **禁止**      |
| Hive ユーザー切替後の即読み | **禁止**（Firestore 復元を待つ） | 要注意        |

---

## 6. Git / Push ルール

- デフォルトは `oneness` ブランチにのみ push
- `main` への push は明示的に指示された場合のみ

## 7. メソッドシグネチャ変更ルール

AI が独断でシグネチャを変更することは **禁止**。
変更が必要な場合は影響箇所を列挙し、ユーザーの承認を得てから実施する。
