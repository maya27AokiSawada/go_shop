# 開発日報 - 2026年5月12日

## 📅 本日の目標

- [x] サインアップ後のデフォルトUIモードをシングルに修正
- [x] Firestoreインデックスのデプロイ（新プロジェクト go-shopping-61515）
- [x] アカウント削除機能のバグ修正

---

## ✅ 完了した作業

### 1. サインアップ時のデフォルト AppUIMode をシングルに変更 ✅

**Purpose**: サインアップ直後のユーザーがマルチモードで表示されてしまう問題を修正

**Background**:

Firebase プロジェクト移行（`goshopping-48db9` → `go-shopping-61515`）後に新規アカウントを作成すると、アプリがマルチモードで起動するという不具合が報告された。

**Problem / Root Cause**:

`firestore_user_name_service.dart` の `saveUserName()` が新規ユーザードキュメントを Firestore に作成する際、`appUIMode` フィールドを設定していなかった。

`user_initialization_service.dart` の `_syncUserProfile()` は以下の順序で動作する：

1. ローカル SharedPreferences から `localAppUIMode` を読む
2. Firestore に `appUIMode` がなければ `localAppUIMode` を書き込む
3. 前のユーザーのセッションから残った SharedPreferences の値（`1` = multi）がそのまま新規ユーザーの Firestore に書き込まれていた

```dart
// ❌ 新規ドキュメント作成時にappUIModeを設定しなかった
} else {
  dataToSave['email'] = currentEmail;
  dataToSave['createdAt'] = FieldValue.serverTimestamp();
}
```

**Solution**:

新規ユーザードキュメント作成時に `appUIMode: 0`（シングルモード）を明示的に設定。

```dart
// ✅ 新規ドキュメントにシングルモードをデフォルト設定
} else {
  dataToSave['email'] = currentEmail;
  dataToSave['createdAt'] = FieldValue.serverTimestamp();
  dataToSave['appUIMode'] = 0; // 新規ユーザーのデフォルトはシングルモード
}
```

`_syncUserProfile()` は Firestore の `appUIMode: 0` を検出して SharedPreferences / Hive にも反映するため、stale な値は上書きされる。

**Modified Files**:

- `lib/services/firestore_user_name_service.dart`（`saveUserName()` 新規ドキュメント作成ブロックに `appUIMode: 0` 追加）

**Commit**: `9f34907`
**Status**: ✅ 完了

---

### 2. Firestore 複合インデックスのデプロイ（go-shopping-61515） ✅

**Purpose**: 通知リスナーの `failed-precondition` エラーを解消

**Background**:

Firebase プロジェクト移行後、新プロジェクト `go-shopping-61515` に `firestore.indexes.json` で定義済みのインデックスがデプロイされていなかった。

**Problem / Root Cause**:

`NotificationService.startListening()` が以下のクエリを実行：

```dart
_firestore
  .collection('notifications')
  .where('userId', isEqualTo: currentUser.uid)
  .where('read', isEqualTo: false)
  .orderBy('timestamp', descending: true)
```

このクエリには `read` + `userId` + `timestamp` の複合インデックスが必要。既存プロジェクトには存在していたが、新プロジェクトには未作成だったため `cloud_firestore/failed-precondition` が発生。

```
❌ [NOTIFICATION] リスナーエラー: [cloud_firestore/failed-precondition]
The query requires an index.
```

**Solution**:

```bash
firebase deploy --only firestore:indexes --project go-shopping-61515
```

`firestore.indexes.json` に定義済みの全インデックスを新プロジェクトへデプロイ。

**Affected Indexes**:

| collectionGroup | fields                                          |
| --------------- | ----------------------------------------------- |
| `notifications` | `userId` ASC + `timestamp` DESC                 |
| `notifications` | `read` ASC + `userId` ASC + `timestamp` DESC    |
| `invitations`   | `groupId` ASC + `expiresAt` DESC                |
| `invitations`   | `groupId` ASC + `status` ASC + `createdAt` DESC |

**Status**: ✅ デプロイ完了（インデックスビルドは非同期・数分で有効化）

---

### 3. アカウント削除機能のバグ修正 ✅

**Purpose**: 設定ページからアカウント削除を実行してもログアウト・データ削除が行われない問題を修正

**Background**:

ユーザーからパスワードを入力して削除操作を行ってもログイン状態が維持され、サインアウト→再サインインが可能なままだと報告された。

**Problem / Root Cause**:

`account_deletion_section.dart` の削除処理 Batch 2 で、レガシーの `/invitations` コレクションに対してクエリを実行していた。

```dart
// ❌ レガシーコレクション（全拒否ルール）へのクエリ
final invitations = await firestore
    .collection('invitations')
    .where('invitedBy', isEqualTo: user.uid)
    .get();
```

`firestore.rules` では `/invitations` に `allow read, write: if false` が設定されており、このクエリで `permission-denied` 例外が発生。結果として後続の `user.delete()` が実行されず、Firebase Auth アカウントが残存していた。

```
// firestore.rules
match /invitations/{invitationId} {
  allow read, write: if false;  // ← レガシー、全拒否
}
```

**Solution**:

v3.x 以降は招待は `SharedGroups/{groupId}/invitations/` サブコレクションに移行済みであり、`/invitations` トップレベルコレクションにデータは存在しない。クエリ自体を削除。

```dart
// ✅ レガシークエリ削除（v3.x 以降データなし・全拒否ルールのためスキップ）
// ※ /invitations コレクション（レガシー）はセキュリティルールで全拒否のため
// クエリ不可。v3.x 以降は SharedGroups サブコレクションに移行済みのためスキップ。

final userDoc = firestore.collection('users').doc(user.uid);
```

**Modified Files**:

- `lib/widgets/settings/account_deletion_section.dart`（Batch 2 のレガシー `/invitations` クエリ削除）

**Status**: ✅ 完了

---

## 🐛 発見された問題

### 1. Firestoreインデックス未デプロイ（新プロジェクト移行時） ✅

- **症状**: `notifications` リスナーが `failed-precondition` エラーで起動直後から失敗
- **原因**: Firebase プロジェクト移行時にインデックスのデプロイが漏れていた
- **対処**: `firebase deploy --only firestore:indexes --project go-shopping-61515` 実行
- **状態**: 修正完了 ✅

### 2. アカウント削除: レガシーコレクションへの `permission-denied` ✅

- **症状**: パスワード入力→削除操作後もログイン状態が継続
- **原因**: 全拒否ルールの `/invitations` コレクションへのクエリが例外を投げて削除処理が中断
- **対処**: レガシークエリを削除
- **状態**: 修正完了 ✅

---

---

## 🌆 午後の作業

### 4. InitialSetupWidget リファクタリング + SharedGroupPage 連携 ⏳

**Purpose**: サインアップ後にシングルモードで InitialSetupWidget が正しく表示・遷移するよう修正

**Background**:

サインアップ直後、グループが 0 件の状態で `SharedGroupPage` を表示すると、`InitialSetupWidget` が自前 `Scaffold` を持っていたため外側の `Scaffold` と二重になっていた。またグループ作成後の画面遷移が `pageIndexProvider.setPageIndex(1)` に依存しており、Widget が削除されたタイミングと競合して不安定だった。

**Problem / Root Cause**:

```dart
// ❌ InitialSetupWidget が自前 Scaffold を持っていた
return Scaffold(
  body: SafeArea(...),
);
// → SharedGroupPage の Scaffold と二重になる

// ❌ グループ作成後に pageIndexProvider で強制遷移
ProviderScope.containerOf(context)
    .read(pageIndexProvider.notifier)
    .setPageIndex(1);
// → Widget 削除後の ref 参照で不安定
```

**Solution**:

- `InitialSetupWidget` を `ConsumerWidget` → `ConsumerStatefulWidget` に変換し、`Scaffold` ラッパーを除去（`SafeArea` のみ返す）
- グループ作成後の遷移を `allGroupsProvider` の更新（`AsyncData([newGroup])`）に委譲
- `SharedGroupPage` でシングルモード＋グループ 0 件時に `InitialSetupWidget`、1 件以上で `GroupListWidget` に自動切り替え

```dart
// ✅ SharedGroupPage: allGroupsProvider でボディを切り替え
if (isSingle) {
  final isEmpty = groupsAsync.when(
    data: (g) => g.isEmpty,
    loading: () => false,
    error: (_, __) => false,
  );
  body = isEmpty ? const InitialSetupWidget() : const GroupListWidget(...);
}
```

**Modified Files**:

- `lib/widgets/initial_setup_widget.dart`（ConsumerStatefulWidget 化・Scaffold 除去・ナビゲーション簡略化）
- `lib/pages/shared_group_page.dart`（シングルモード時のボディ切り替えロジック追加）

**Status**: ⏳ 実装済み・動作未確認（バグ残存の可能性あり）

---

### 5. サインアップ後 AppUIMode 即時設定（多重保険） ⏳

**Purpose**: `_syncUserProfile` の非同期完了を待たずにサインアップ直後からシングルモードを確実に設定

**Background**:

`_syncUserProfile()` は非同期で呼ばれるため、UI が先に描画される際に stale な `appUIMode`（前ユーザーのセッション値）が残っている場合があった。

**Solution**:

サインアップ成功直後に 3 箇所を即座に設定（`sign_up_form.dart` / `home_page.dart`）:

```dart
// ✅ サインアップ直後にシングルモードを即座に3箇所に設定
AppUIModeSettings.setMode(AppUIMode.single);
ref.read(appUIModeProvider.notifier).state = AppUIMode.single;
await UserPreferencesService.saveAppUIMode(0);
```

また `user_initialization_service.dart` の `_syncUserProfile()` も、Firestore にデータがなくローカルにある場合（新規ユーザー直後）は `localAppUIMode` を使わず `appUIMode: 0` を強制書き込みするよう修正。

**Modified Files**:

- `lib/forms/sign_up_form.dart`
- `lib/pages/home_page.dart`
- `lib/services/user_initialization_service.dart`

**Status**: ⏳ 実装済み・動作未確認（バグ残存の可能性あり）

---

### 6. SingleGroupCreationDialog に QR スキャン選択肢追加 ✅

**Purpose**: サインアップ後のグループ作成ダイアログで、新規作成だけでなく QR 参加もできるようにする

**Solution**:

ダイアログのフォーム下部に区切りと「QRコードでグループに参加」ボタンを追加。`QRScannerScreen` を `Navigator.push` で重ねて表示し、参加完了後にグループが存在すればダイアログを自動クローズ。

```dart
OutlinedButton.icon(
  onPressed: _scanQR,
  icon: const Icon(Icons.qr_code_scanner),
  label: const Text('QRコードでグループに参加'),
)
```

**Modified Files**:

- `lib/widgets/single_group_creation_dialog.dart`

**Status**: ✅ 実装完了

---

## 📊 バグ対応進捗

### 完了 ✅

1. ✅ Firebase プロジェクト移行（goshopping-48db9 → go-shopping-61515）
2. ✅ Firestore 接続監視: `furestorenews` 空コレクション対応
3. ✅ サインアップ: パスワードポリシー（最低6文字に変更）
4. ✅ サインアップ後デフォルト AppUIMode をシングルに修正（`firestore_user_name_service.dart`）
5. ✅ Firestoreインデックスデプロイ（go-shopping-61515）
6. ✅ アカウント削除: レガシー `/invitations` クエリによるブロック解除
7. ✅ SingleGroupCreationDialog に QR スキャン追加

### 作業中・未確認 ⏳

- ⏳ InitialSetupWidget リファクタ（SharedGroupPage 連携・Scaffold 二重化解消）
- ⏳ サインアップ直後の AppUIMode 即時設定（stale 値対策）

### 翌日継続

- 🔲 上記 ⏳ 項目の実機動作確認・最終バグ修正
- 🔲 新プロジェクト `go-shopping-61515` での総合動作確認（グループ作成・招待・通知フロー）

---

## 💡 技術的学習事項

### Firebase プロジェクト移行チェックリスト

Firebase プロジェクトを新規作成・移行する際には以下を漏れなく実施すること：

1. `android/app/src/prod/google-services.json` 更新
2. `ios/GoogleService-Info-prod.plist` 更新
3. `lib/firebase_options.dart` 全 prod セクション更新
4. `.firebaserc` の `prod` プロジェクトID更新
5. `firebase.json` のデフォルトプロジェクト更新
6. **`firebase deploy --only firestore:indexes --project <new-project>`** ← 忘れがち
7. **`firebase deploy --only firestore:rules --project <new-project>`** ← 忘れがち
8. Firebase Console で Email/Password 認証を有効化
9. パスワードポリシーを確認（デフォルト13文字以上に注意）
10. 必要な Android パッケージ名（`net.sumomo_planning.goshopping` 等）を全て登録

### レガシーコレクションのルール全拒否は削除処理のブロッカーになる

`allow read, write: if false` のコレクションにクエリすると `permission-denied` 例外が発生し、同一 try-catch 内の後続処理（`user.delete()` など）が実行されなくなる。
→ 削除フロー実装時は使用しないコレクションへのアクセスを排除すること。

---

## 🗓 翌日（2026-05-13）の予定

1. InitialSetupWidget / サインアップフローの実機動作確認・最終バグ修正
2. 新プロジェクトでの総合動作確認（グループ作成・QR招待・通知フロー）
3. アカウント削除の実機動作確認
4. `future` ブランチの `oneness` へのマージ検討

---

## 📝 ドキュメント更新

| ドキュメント                            | 更新内容                                                                |
| --------------------------------------- | ----------------------------------------------------------------------- |
| `instructions/50_user_and_settings.md`  | §3 アカウント削除: レガシー `/invitations` クエリ削除の注記追加         |
| `instructions/50_user_and_settings.md`  | §4a AppUIMode: 新規ユーザーのデフォルト `appUIMode: 0` 設定の記載追加   |
| `instructions/50_user_and_settings.md`  | §4a AppUIMode: サインアップ直後の即時3点設定パターン追加                |
| `instructions/20_groups_lists_items.md` | §9 InitialSetupWidget: シングルモード初期セットアップ画面のパターン追加 |
