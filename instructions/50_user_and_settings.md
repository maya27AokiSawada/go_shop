# ユーザー管理・設定指示書

> 共通ルールは `00_project_common.md` を先に読むこと。

---

## 1. 認証フロー詳細

認証フローの順序は `00_project_common.md` §2 を参照すること。
以下は補足ルール。

- **Firestore 同期完了前に「グループ0件」と UI 判定してはならない**
- `authStateChanges()` は Hive box 初期化より先に発火することがある
  → `forceSyncProvider` / `allGroupsProvider` を触る前に box の open を確認する
- サインイン後は `waitForSafeInitialization()` が `_firestoreRepo` の準備を保証するまで CRUD を呼ばない

---

## 2. ユーザー名の取得・保存

### 優先順位

```text
Firestore /users/{uid}.displayName
  → SharedPreferences
    → UserSettings (Hive)
      → Firebase Auth displayName
        → email prefix
          → UID（最終フォールバック）
```

### ユーザー名保存は Firebase Auth 登録の**前に SharedPreferences をクリア**してから行う

```dart
// サインアップ時の正しい順序
await UserPreferencesService.clearAllUserInfo();  // ← 先にクリア
await SharedGroupBox.clear();
await auth.signUp(email, password);
await UserPreferencesService.saveUserName(userName);  // ← Auth 後に保存
await user.updateDisplayName(userName);
```

---

## 3. アカウント削除

### 必須手順

1. **再認証**（`EmailAuthProvider.credential()` → `reauthenticateWithCredential()`）
   - `requires-recent-login` エラー対策
2. **2段階確認ダイアログ**（誤操作防止）
3. **Batch 分割削除**
   - Batch 1: サブコレクション（sharedLists, whiteboards）を削除 → commit
   - Batch 2: 親グループ削除 + メンバー離脱 + 通知 + 招待 + user プロファイル削除 → commit

### Batch を分割する理由

サブコレクションと親ドキュメントを同一 Batch で削除すると、
サブコレクション削除時の権限チェックで親ドキュメントへの `get()` が失敗して
`permission-denied` になる。

### オーナーグループと参加グループの扱い

```dart
// オーナーグループ → 完全削除
batch2.delete(group.reference);

// 参加グループ（メンバーとして参加） → allowedUid から自分を外すだけ
batch2.update(group.reference, {
  'allowedUid': FieldValue.arrayRemove([currentUser.uid]),
});
```

---

## 4. AppMode（買い物リスト ⇄ TODO 切替）

- `AppModeSettings.config.{property}` を使って用語を動的に切り替える
- UI にグループ名・リスト名・アイテム名をハードコードする **禁止**
- モード切替は `AppModeSettings.setMode()` + `appModeNotifierProvider` 更新
- 設定値は Hive の `UserSettings` に永続化

---

## 5. DeviceIdService

- プレフィックスは **SharedPreferences に永続化**する（再生成禁止）
- Android ID が 8 文字未満でも安全に処理する
- iOS の `identifierForVendor` は null になりうる → フォールバック UUID を使う

---

## 6. 禁止事項

- サインアウト前に Hive / SharedPreferences をクリアしないまま Auth を解除する
- Firestore 同期前に「グループ0件」と確定してページ遷移・UI 構築する
- アカウント削除を再認証なしで実行する
- Batch 分割なしにサブコレクションと親を同時削除する
