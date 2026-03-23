# テスト・CI/CD指示書

> 共通ルールは `00_project_common.md` を先に読むこと。

---

## 1. テスト戦略

| カテゴリ         | カバレッジ目安 | 対象                                                                    |
| ---------------- | -------------- | ----------------------------------------------------------------------- |
| Unit テスト      | 30–40%         | シンプルなメソッド（encodeQRData、enum パース等）、モデルコンストラクタ |
| E2E / 統合テスト | 60–70%         | Firestore CRUD、通知フロー、招待受諾、認証全体                          |

**方針**: Firestore を多用する複雑なフローはモックコストが高いため E2E に任せる。

---

## 2. モック方針

### `firebase_auth_mocks` パッケージを使う

```dart
final mockAuth = MockFirebaseAuth(
  signedIn: true,
  mockUser: MockUser(uid: 'test-uid', email: 'test@example.com'),
);
final service = MyService(ref, auth: mockAuth);  // DI で注入
```

### `DocumentSnapshot<Map<String, dynamic>>` の手動モックは禁止

`type 'Null' is not a subtype of type 'String'` のような型エラーが多発する。
→ `fromFirestore()` のテストは E2E に回し、コンストラクタを直接テストする。

### Firebase 依存サービスは DI 対応（後方互換維持）

```dart
class MyService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  MyService(this._ref, {FirebaseAuth? auth, FirebaseFirestore? firestore})
      : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;
}
```

---

## 3. Group-level setUp パターン（必須）

mockito はスタブ設定をグローバルに追跡する。
グローバル `setUp()` でモックを共有すると状態汚染が起きる。
**各 `group()` の中でローカルに `setUp()` を定義すること。**

```dart
// ❌ 禁止 — グローバル setUp はテスト間で状態汚染する
late MockFirebaseAuth mockAuth;
setUp(() {
  mockAuth = MockFirebaseAuth(signedIn: true);
  when(mockAuth.currentUser).thenReturn(...);
});

// ✅ 正しい — グループごとにローカル setUp
group('createGroup', () {
  late MockFirebaseAuth mockAuth;

  setUp(() {
    mockAuth = MockFirebaseAuth(signedIn: true);
  });

  test('...', () { ... });
});
```

---

## 4. CI/CD（GitHub Actions）

- **トリガー**: `main` ブランチへの push のみ自動ビルド
- **ビルド環境**: `ubuntu-latest`
- **APK パス**: `app-dev-release.apk`
- シークレットは GitHub Repository Secrets で管理
  - `GOOGLE_SERVICES_JSON`: `android/app/google-services.json` の内容
- ワークフローファイル: `.github/workflows/flutter-ci.yml`

### 機密ファイルの生成（bash Here-Document 構文）

```yaml
- name: Create google-services.json
  run: |
    cat << 'EOF' > android/app/google-services.json
    ${{ secrets.GOOGLE_SERVICES_JSON }}
    EOF
```

---

## 5. ビルドコマンド

```bash
# デバッグ APK（実機テスト）
flutter build apk --debug --flavor prod

# リリース APK
flutter build apk --release --flavor prod

# Android App Bundle（Play Store 配布）
flutter build appbundle --release --flavor prod

# コード生成（Freezed / Hive アダプター）
dart run build_runner build --delete-conflicting-outputs
```

---

## 6. 禁止事項

- グローバル `setUp()` でのモック共有
- `DocumentSnapshot<Map<String, dynamic>>` の手動モック作成
- CI で `windows-latest` を使う（`ubuntu-latest` を使うこと）
- `flutter pub upgrade` 後にビルド確認なしで push
