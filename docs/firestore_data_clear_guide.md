---
# Firestoreデータ全クリア手順

## 目的
Firebaseコンソールから全データを削除し、アプリを初期状態に戻す

## 🔥 Firebase Consoleでの操作手順

### 1. Firebase Consoleにアクセス
1. [Firebase Console](https://console.firebase.google.com/) にアクセス
2. `go_shop` プロジェクトを選択

### 2. Firestore Databaseで削除

#### コレクション削除順序（重要）
以下の順番で削除してください：

1. **`invitations`** コレクション
   - グループ招待データ
   - Path: `/invitations`

2. **`shoppingLists`** コレクション
   - 買い物リストデータ
   - Path: `/shoppingLists`

3. **`purchaseGroups`** コレクション
   - グループ情報（デフォルトグループ含む）
   - Path: `/purchaseGroups`

4. **`users`** コレクション
   - ユーザー情報
   - Path: `/users`

5. **その他** （存在する場合）
   - `accepted_invitations`
   - `user_settings`
   - `notifications`

### 3. コレクション削除手順

各コレクションごとに：

1. **コレクション名をクリック**
2. **右上の「⋮」（縦3点メニュー）をクリック**
3. **「コレクションを削除」を選択**
4. **確認ダイアログで「削除」をクリック**

⚠️ **注意事項**:
- サブコレクションがある場合は先にサブコレクションを削除
- ドキュメント数が多い場合、削除に時間がかかる場合があります
- 削除は不可逆的です - 必ずバックアップを確認

### 4. 削除完了確認

- Firestore Database画面でコレクション一覧が空になっていることを確認
- 「データがありません」と表示されればOK

## 📱 アプリでの確認手順

### 1. アプリを完全終了
```powershell
# Windows の場合、タスクマネージャーでプロセスを終了
```

### 2. アプリデータをクリア（オプション）
```powershell
# Hiveのローカルキャッシュもクリアする場合
flutter clean
flutter pub get
```

### 3. アプリを再起動
```powershell
flutter run
```

### 4. 初回起動時の動作確認

✅ **期待される動作**:
1. ログイン画面が表示される
2. ログイン後、デフォルトグループが自動作成される
   - グループ名: `{ユーザー名}さんのグループ` または `MyLists`
   - `groupId` = `currentUser.uid`
3. 空の買い物リストが表示される

## 🔧 トラブルシューティング

### ケース1: デフォルトグループが作成されない
**原因**: Firestore書き込みエラー
**対処**:
```dart
// lib/providers/purchase_group_provider.dart の
// _ensureDefaultGroupExists() メソッドを確認
```

### ケース2: 古いデータが残っている
**原因**: Hiveキャッシュが残存
**対処**:
```powershell
flutter clean
# アプリをアンインストール
flutter run
```

### ケース3: 認証エラー
**原因**: Firestore Rulesで書き込みが拒否
**対処**:
Firebase Console > Firestore Database > ルール で以下を確認:
```
allow create: if request.auth != null;
```

## 📝 削除後のチェックリスト

- [ ] `purchaseGroups` コレクションが空
- [ ] `shoppingLists` コレクションが空
- [ ] `invitations` コレクションが空
- [ ] `users` コレクションが空
- [ ] アプリを再起動済み
- [ ] ログイン成功
- [ ] デフォルトグループ自動作成確認
- [ ] デフォルトグループが削除不可能であることを確認

## 🎯 完了後の状態

```
Firestore Database
├── purchaseGroups/
│   └── {uid}/  # デフォルトグループ（自動作成）
├── shoppingLists/
│   └── （空）
├── invitations/
│   └── （空）
└── users/
    └── {uid}/  # ログインユーザー情報
```

---
**最終更新**: 2025-11-17
**作成者**: GitHub Copilot
