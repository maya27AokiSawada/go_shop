# 開発日報 - 2026年04月14日

## 📅 本日の目標

- [x] コードベース全体の既知アンチパターンスキャンを実施する
- [x] 検出した問題を個別コミットで修正する
- [x] ビルドエラーを修正して AAB ビルドを通す
- [x] ビルド 8 をクローズドテストリリースに登録する

---

## ✅ 完了した作業

### 1. Anti-3: Firestore write ops の `.timeout()` 削除（whiteboard_repository） ✅

**Purpose**: Firestore 書き込み操作に誤って設定されていた `.timeout()` を除去し、オフラインキューが正常動作するようにする

**Background**:

- `Anti-3` ルール: Firestore の **write** 操作に `.timeout()` をかけると、オフライン時にクライアント側キューに蓄積されるはずの書き込みが `TimeoutException` で捨てられる
- READ 操作の `.timeout()` は許容（応答のないクエリに対するフェールファスト）

**Problem / Root Cause**:

```dart
// ❌ 修正前 — clearStrokesSubcollection() 等
await docRef.update({...}).timeout(const Duration(seconds: 10));
await batch.commit().timeout(const Duration(seconds: 10));
```

**Solution**:

```dart
// ✅ 修正後
await docRef.update({...});
await batch.commit();
```

**Modified Files**:

- `lib/datastore/whiteboard_repository.dart` — `clearStrokesSubcollection()`, `_addStrokesWithoutTransaction()`, `clearWhiteboard()` の write ops から `.timeout()` 4箇所削除

**Commit**: `6c4dda9`
**Status**: ✅ 完了・検証済み

---

### 2. Anti-3: Firestore write ops の `.timeout()` 削除（hybrid_shared_group_repository） ✅

**Purpose**: hybrid_shared_group_repository の同期処理内の write `.timeout()` を除去する

**Problem / Root Cause**:

```dart
// ❌ 修正前 — pushLocalChangesToFirestore()
await docRef.set(...).timeout(const Duration(seconds: 10));
await docRef.update(...).timeout(const Duration(seconds: 10));
```

**Solution**:

```dart
// ✅ 修正後
await docRef.set(...);
await docRef.update(...);
```

**Modified Files**:

- `lib/datastore/hybrid_shared_group_repository.dart` — `pushLocalChangesToFirestore()` 内 write ops から `.timeout()` 2箇所削除（READ の `.timeout()` は保持）

**Commit**: `7241142`
**Status**: ✅ 完了・検証済み

---

### 3. listener ルール: `onError` + `cancelOnError: false` 追加 ✅

**Purpose**: `Stream.listen()` に `onError` ハンドラと `cancelOnError: false` を追加し、エラーで無音終了するストリームを排除する

**Background**:

- Firestore や Firebase Auth のストリームは永続リスナーとして動作するべきであり、エラー1件でキャンセルされてはならない
- `cancelOnError` のデフォルトは `false` だが、明示的に記載することでレビュー時に意図が明確になる

**Problem / Root Cause**:

```dart
// ❌ 修正前 — onError なし、エラー時に無音でストリーム終了
_authSubscription = _authService.authStateChanges().listen(
  (user) { ... },
);
```

**Solution**:

```dart
// ✅ 修正後
_authSubscription = _authService.authStateChanges().listen(
  (user) { ... },
  onError: (e, st) => debugPrint('[UserInitializationService] authStateChanges error: $e\n$st'),
  cancelOnError: false,
);
```

**Modified Files**:

- `lib/services/invitation_monitor_service.dart`
- `lib/pages/whiteboard_editor_page.dart`（メタデータ監視リスナー）
- `lib/widgets/app_initialize_widget.dart`
- `lib/services/user_initialization_service.dart`
- `lib/services/purchase_service.dart`（`cancelOnError: false` + `import 'dart:async'` 追加）

**Commit**: `1b55f40`
**Status**: ✅ 完了・検証済み

---

### 4. Anti-5: `getDataVersion()` の `containsKey` ガード追加 ✅

**Purpose**: SharedPreferences に `dataVersion` キーが未保存のユーザーを旧バージョンと誤判定するバグを修正する

**Background**:

- `Anti-5` ルール: `prefs.getInt(key) ?? fallback` は「キー未存在」と「明示的に保存された `fallback` 値」を区別できない
- 新規インストールユーザーは `dataVersion` キーを持たないが `?? 1` で v1 と扱われ、不要なマイグレーションが走る可能性があった

**Problem / Root Cause**:

```dart
// ❌ 修正前 — 未保存キーを v1 と誤判定
return prefs.getInt(_keyDataVersion) ?? 1;
```

**Solution**:

```dart
// ✅ 修正後 — 未保存なら -1 を返し、呼び出し側で「未初期化」として扱う
if (!prefs.containsKey(_keyDataVersion)) {
  return -1;
}
return prefs.getInt(_keyDataVersion)!;
```

**Modified Files**:

- `lib/services/user_preferences_service.dart` — `getDataVersion()` に `containsKey` ガード追加、未設定時 `-1` 返却

**Commit**: `4fa5f4e`
**Status**: ✅ 完了・検証済み

---

### 5. デッドコード `WhiteboardConflictResolver` 削除 ✅

**Purpose**: 未使用かつ `runTransaction` アンチパターンを含む `WhiteboardConflictResolver` クラスを削除する

**Background**:

- `whiteboard_conflict_resolution.dart`（406行）は `import` も `instantiation` もなく完全なデッドコード
- 内部に `runTransaction` を用いた Anti パターン実装が含まれており、将来的に誤用される危険もあった

**Modified Files**:

- `lib/datastore/whiteboard_conflict_resolution.dart` — **削除**（406行）

**Commit**: `78261b4`
**Status**: ✅ 完了・検証済み

---

### 6. `context.mounted` / `!mounted` ガード追加（12ファイル） ✅

**Purpose**: async 処理後に廃棄済み Widget の `context` / `ref` を使う安全でないコードにガードを追加する

**Background**:

- コミット `c272c9c` には前のセッションで作成されたが未コミットの変更が含まれていた
- `context.mounted` チェックなしの `Navigator.pop()` / `showDialog()` など12ファイルを一括修正

**Modified Files**: 12ファイル（UI ページ・ダイアログ・ウィジェット）

**Commit**: `c272c9c`
**Status**: ✅ 完了・検証済み

---

### 7. Firebase App Check `providerAndroid` 型エラー修正 ✅

**Purpose**: `firebase_app_check 0.4.2` の新 API に合わせて `main.dart` の App Check 初期化を修正する

**Background**:

- `firebase_app_check ^0.4.x` で `FirebaseAppCheck.instance.activate()` のパラメータ名と型が変更された
- 旧 `AndroidProvider` enum は deprecated となり、`providerAndroid` パラメータは `AndroidAppCheckProvider` サブクラスを要求するようになった

**Problem / Root Cause**:

```dart
// ❌ 修正前 — 型エラー: AndroidProvider は AndroidAppCheckProvider に代入不可
await FirebaseAppCheck.instance.activate(
  androidProvider: AndroidProvider.debug,   // deprecated enum
  appleProvider: AppleProvider.debug,
);
```

**Solution**:

```dart
// ✅ 修正後
await FirebaseAppCheck.instance.activate(
  providerAndroid: kDebugMode
      ? const AndroidDebugProvider()
      : const AndroidPlayIntegrityProvider(),
  providerApple: kDebugMode
      ? AppleDebugProvider()
      : AppleAppAttestProvider(),
);
```

また `purchase_service.dart` で `StreamSubscription` が未定義だったため `import 'dart:async'` を追加。

**Modified Files**:

- `lib/main.dart` — App Check 初期化 API を新形式に変更
- `lib/services/purchase_service.dart` — `import 'dart:async'` 追加

**Commit**: `bbca371`
**Status**: ✅ 完了・検証済み

---

### 8. ビルド 8 クローズドテスト登録 ✅

**Purpose**: 修正済みの AAB（ビルド 8 = 1.1.0+8）をクローズドテストトラックに登録する

**Background**:

- 前項の全修正を適用した上で `flutter build aab --release --flavor prod` が Exit 0 で完了
- ユーザーが Play Console でクローズドテストリリースに登録を実施

**検証結果**:

| 項目             | 状態                                                     |
| ---------------- | -------------------------------------------------------- |
| AAB ビルド       | ✅ Exit 0（`flutter build aab --release --flavor prod`） |
| Windows ビルド   | ✅ Exit 0（`flutter run --release -d windows`）          |
| Android 実機確認 | ✅ Exit 0（Pixel 9 flavor prod）                         |
| クローズドテスト | ✅ ビルド 8 登録済み                                     |

**Status**: ✅ 完了

---

## 🐛 発見された問題

### ビルドエラー: `AndroidProvider` 型非互換 ✅

- **症状**: `main.dart` 129行目 `The argument type 'AndroidProvider' can't be assigned to the parameter type 'AndroidAppCheckProvider'`
- **原因**: `firebase_app_check 0.4.x` の API 変更。旧 enum `AndroidProvider` は deprecated、新 API は `AndroidAppCheckProvider` サブクラスが必要
- **対処**: `AndroidDebugProvider()` / `AndroidPlayIntegrityProvider()` に変更、Apple 側も `AppleDebugProvider()` / `AppleAppAttestProvider()` に変更
- **状態**: 修正完了 ✅

### ビルドエラー: `StreamSubscription` 未定義 ✅

- **症状**: `purchase_service.dart` 29行目 `Undefined class 'StreamSubscription'`
- **原因**: `cancelOnError: false` 追加時に `dart:async` の import を漏らした
- **対処**: `import 'dart:async';` を追加
- **状態**: 修正完了 ✅

---

## 📊 バグ対応進捗

### 完了 ✅

1. ✅ Anti-3: Firestore write `.timeout()` 除去（完了日: 2026-04-14）
2. ✅ Anti-5: `getDataVersion()` containsKey ガード（完了日: 2026-04-14）
3. ✅ listener `onError` / `cancelOnError` 欠如（完了日: 2026-04-14）
4. ✅ デッドコード `WhiteboardConflictResolver` 除去（完了日: 2026-04-14）
5. ✅ `context.mounted` ガード 12ファイル（完了日: 2026-04-14）
6. ✅ App Check 新 API 対応（完了日: 2026-04-14）

### 翌日継続 ⏳

- ⏳ Pixel 9 での Play Store 版サインイン問題（前日より継続調査中）

---

## 💡 技術的学習事項

### `firebase_app_check 0.4.x` API 変更

**問題パターン**: `androidProvider:` パラメータ名が `providerAndroid:` に変更。型も `AndroidProvider` enum から `AndroidAppCheckProvider` サブクラスに変更。

**正しい使い方**:

```dart
await FirebaseAppCheck.instance.activate(
  providerAndroid: kDebugMode
      ? const AndroidDebugProvider()
      : const AndroidPlayIntegrityProvider(),
  providerApple: kDebugMode
      ? AppleDebugProvider()
      : AppleAppAttestProvider(),
);
```

### `cancelOnError: false` 追加時は `dart:async` import を確認

`StreamSubscription` 型を明示的に使う場合（変数型注釈、型キャストなど）は `import 'dart:async'` が必要。`cancelOnError: false` 追加に伴う修正時はセットで確認すること。

### `prefs.getInt(key) ?? fallback` の落とし穴

「未保存キー」と「明示的に保存された `fallback` 値」を区別できない。必ず `containsKey` で存在確認してから `!` でアクセスすること。

---

## 🔧 コミット一覧

| ハッシュ  | 内容                                                                                       |
| --------- | ------------------------------------------------------------------------------------------ |
| `6c4dda9` | fix(anti-3): remove .timeout() from Firestore write ops in whiteboard_repository           |
| `7241142` | fix(anti-3): remove .timeout() from Firestore write ops in hybrid_shared_group_repository  |
| `1b55f40` | fix(listener): add onError + cancelOnError:false to all Stream.listen() calls              |
| `4fa5f4e` | fix(anti-5): use containsKey guard in getDataVersion() to avoid treating missing key as v1 |
| `78261b4` | chore: delete unused WhiteboardConflictResolver (dead code, runTransaction anti-pattern)   |
| `c272c9c` | fix(mounted): add context.mounted / !mounted guards before async-post UI ops               |
| `bbca371` | fix: correct providerAndroid type and add missing dart:async import                        |

---

## 📝 明日のタスク

1. Pixel 9 での Play Store 版サインイン問題の調査継続
2. クローズドテスト（ビルド 8）の審査通過・テスター結果確認
