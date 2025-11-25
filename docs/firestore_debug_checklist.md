# Firestore データ確認チェックリスト

## 問題の状況

招待受諾後、`allowedUid` が招待元のUIDのみになり、招待を受けた側のUIDが含まれていない。

## Firebase Consoleでの確認手順

### 1. Firestoreコレクション確認

1. Firebase Console > Firestore Database
2. `SharedGroups` コレクションを開く
3. 以下のグループIDを検索：

#### グループ `1113-1431` (1763011892363)
- **期待される状態**:
  ```json
  {
    "groupId": "1763011892363",
    "groupName": "1113-1431",
    "allowedUid": [
      "K35DAuQUktfhSr4XWFoAtBNL32E3",  // すもも (招待元/Android)
      "VqNEozvTyXXw55Q46mNiGNMNngw2"   // maya (招待された側/Windows)
    ],
    "members": [ ... ],
    "ownerUid": "K35DAuQUktfhSr4XWFoAtBNL32E3"
  }
  ```

- **実際の状態を確認**:
  - `allowedUid` フィールドの値
  - `members` 配列の内容
  - `updatedAt` タイムスタンプ

#### グループ `1113-1436` (1763012177920)
- **期待される状態**:
  ```json
  {
    "allowedUid": [
      "K35DAuQUktfhSr4XWFoAtBNL32E3",  // すもも (招待元)
      "VqNEozvTyXXw55Q46mNiGNMNngw2"   // maya (招待された側)
    ]
  }
  ```

- **実際の状態を確認**:
  - `allowedUid` フィールドに両方のUIDがあるか

### 2. 確認すべきポイント

#### ケース1: `allowedUid` が空配列 `[]`
→ **招待受諾時の初期作成で設定されなかった**
→ `qr_invitation_service.dart` の `acceptInvitation()` を確認

#### ケース2: `allowedUid` が招待元のみ `[K35DAuQUktfhSr4XWFoAtBNL32E3]`
→ **招待された側のUID追加が失敗した**
→ `HybridRepository.updateGroup()` の実行タイミング問題

#### ケース3: `allowedUid` フィールド自体が存在しない
→ **フィールド名のタイポまたはマージ設定の問題**
→ `SetOptions(merge: true)` の動作確認

### 3. Firestoreルールの確認

```
service cloud.firestore {
  match /databases/{database}/documents {
    match /SharedGroups/{groupId} {
      // 読み取り: allowedUid配列に自分のUIDが含まれている
      allow read: if request.auth != null &&
                     resource.data.allowedUid.hasAny([request.auth.uid]);

      // 書き込み: allowedUid配列に自分のUIDが含まれている
      allow write: if request.auth != null &&
                      resource.data.allowedUid.hasAny([request.auth.uid]);
    }
  }
}
```

**確認**:
- 招待された側が`allowedUid`に含まれていないと、**読み取り・書き込みができない**
- これが原因でFirestoreクエリが0件になっている可能性

### 4. ログから読み取れる問題

```
📊 [SYNC] Firestoreクエリ完了: 2個のグループ
  - 1763010465455  ← 1113-1407（正常動作）
  - 1763012177920  ← 1113-1436（最新のテスト）

❌ 1763011892363 (1113-1431) が取得されない
```

**推測される原因**:
1. Firestoreの `allowedUid` が空または招待元のみ
2. Firestoreルールにより、mayaからのクエリで取得できない
3. 結果: 同期時に「Firestoreにない」と判断されて削除

## 修正の方向性

### 即座の対応（データ修正）

Firebase Consoleで手動修正:
1. グループ `1763011892363` のドキュメントを開く
2. `allowedUid` フィールドを編集:
   ```
   ["K35DAuQUktfhSr4XWFoAtBNL32E3", "VqNEozvTyXXw55Q46mNiGNMNngw2"]
   ```
3. 保存

### コード修正（根本対策）

招待受諾時の処理を確認:
1. `qr_invitation_service.dart` の `acceptInvitation()`
2. `allowedUid` への招待された側のUID追加ロジック
3. Firestoreへの書き込みタイミング

## 確認結果の記録

### グループ 1113-1431 (1763011892363)

**Firestoreの実際の状態**:
```json
{
  "allowedUid": [ /* ここに実際の値を記入 */ ]
}
```

**問題の特定**:
- [ ] `allowedUid` が空配列
- [ ] `allowedUid` が招待元のみ
- [ ] `allowedUid` フィールドが存在しない
- [ ] その他: _______________

### グループ 1113-1436 (1763012177920)

**Firestoreの実際の状態**:
```json
{
  "allowedUid": [ /* ここに実際の値を記入 */ ]
}
```

**状態**:
- [ ] 正常（両方のUIDあり）
- [ ] 異常（招待元のみ）
- [ ] 異常（空配列）

## 次のアクション

確認結果に基づき：

1. **データ修正が必要** → Firebase Consoleで手動修正
2. **コード修正が必要** → `qr_invitation_service.dart` を修正
3. **Firestoreルール修正が必要** → セキュリティルールを見直し
