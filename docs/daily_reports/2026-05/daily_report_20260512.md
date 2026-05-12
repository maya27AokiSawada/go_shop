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

## 📊 バグ対応進捗

### 完了 ✅

1. ✅ Firebase プロジェクト移行（goshopping-48db9 → go-shopping-61515）
2. ✅ Firestore 接続監視: `furestorenews` 空コレクション対応
3. ✅ サインアップ: パスワードポリシー（最低6文字に変更）
4. ✅ サインアップ後デフォルト AppUIMode をシングルに修正
5. ✅ Firestoreインデックスデプロイ（go-shopping-61515）
6. ✅ アカウント削除: レガシー `/invitations` クエリによるブロック解除

### 翌日継続 ⏳

- ⏳ 新プロジェクト `go-shopping-61515` での総合動作確認（グループ作成・招待・通知フロー）

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

1. 新プロジェクトでの総合動作確認（グループ作成・QR招待・通知フロー）
2. アカウント削除の実機動作確認
3. `future` ブランチの `oneness` へのマージ検討

---

## 📝 ドキュメント更新

| ドキュメント                           | 更新内容                                                              |
| -------------------------------------- | --------------------------------------------------------------------- |
| `instructions/50_user_and_settings.md` | §3 アカウント削除: レガシー `/invitations` クエリ削除の注記追加       |
| `instructions/50_user_and_settings.md` | §4a AppUIMode: 新規ユーザーのデフォルト `appUIMode: 0` 設定の記載追加 |
