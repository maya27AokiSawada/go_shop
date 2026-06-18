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

## 3. Flavor のテスト用上書き（`F.appFlavor` セッター）

`F.appFlavor` は `--dart-define=FLAVOR` から取得するが、テスト内では `setUp()` でセッターを使って上書きできる。

```dart
// ✅ テスト内でのFlavor上書き
setUp(() {
  F.appFlavor = Flavor.dev; // または Flavor.prod
});
```

`lib/flavors.dart` に `static Flavor? _override` + `static set appFlavor` が定義されている。
本番ビルドでは `_override` は常に `null` のため動作に影響なし。

```dart
// ❌ 禁止 — セッターを追加せずゲッターのみにすると CI でコンパイルエラー
// test: F.appFlavor = Flavor.dev; → Error: Setter not found: 'appFlavor'
```

---

## 4. Group-level setUp パターン（必須）

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

## 5. CI/CD（GitHub Actions）

- **トリガー（CI）**: `future` ブランチへの push で単体テスト
- **トリガー（Release）**: `main` ブランチへの push で Pages + ストア配布（environment 承認後）
- **ビルド環境**: `ubuntu-latest`
- **APK パス**: `app-dev-release.apk`
- シークレットは GitHub Repository Secrets で管理
  - `GOOGLE_SERVICES_JSON`: `android/app/google-services.json` の内容
- ワークフローファイル:
  - `.github/workflows/flutter-ci.yml`（future CI）
  - `.github/workflows/main-release.yml`（main 配布）
  - `.github/workflows/jekyll-gh-pages.yml`（Pages）

### `main-release.yml` の現在運用（2026-05-21時点）

- `Upload to Google Play` と `Upload to TestFlight` は `if: ${{ false }}` で一時停止中
- Android 配布を再開する場合は、`PLAY_SERVICE_ACCOUNT_JSON` を `/tmp/play-service-account.json` に書き出し、`jq empty` で JSON 妥当性を確認してから有効化する
- iOS 配布を再開する場合は、App Store Connect API キー系シークレット（`APPSTORE_ISSUER_ID` / `APPSTORE_KEY_ID` / `APPSTORE_PRIVATE_KEY`）が environment に設定済みであることを確認する

### Build Number 自動採番

- `main-release.yml` で `BUILD_NUMBER=$((10000 + GITHUB_RUN_NUMBER))` を採用
- Android/iOS の両方で同じ `--build-number` を適用
- `pubspec.yaml` の `+N` は固定値のままで運用可能（CI が上書き）

### 機密ファイルの生成（bash Here-Document 構文）

```yaml
- name: Create google-services.json
  run: |
    cat << 'EOF' > android/app/google-services.json
    ${{ secrets.GOOGLE_SERVICES_JSON }}
    EOF
```

---

## 6. ビルドコマンド

```bash
# デバッグ APK（実機テスト）
flutter build apk --debug --flavor prod --dart-define=FLAVOR=prod

# リリース APK
flutter build apk --release --flavor prod --dart-define=FLAVOR=prod

# Android App Bundle（Play Store 配布）
flutter build appbundle --release --flavor prod --dart-define=FLAVOR=prod

# コード生成（Freezed / Hive アダプター）
dart run build_runner build --delete-conflicting-outputs
```

### Android Release と Crashlytics Mapping Upload（2026-06-18）

- `android/app/build.gradle.kts` では `uploadCrashlyticsMappingFile*` タスクを無効化している
- 理由: 公開リポジトリ運用でローカル設定が未完了の場合、`uploadCrashlyticsMappingFileDevRelease` が `HTTP 400` で失敗し、APK 生成まで到達できないため
- 前提: リリース APK 生成の再現性を優先し、マッピングアップロードは別工程（本番 CI / 正式リリース時）で実施する

```kotlin
tasks.configureEach {
  if (name.startsWith("uploadCrashlyticsMappingFile")) {
    enabled = false
  }
}
```

### iOS IPA ビルド（TestFlight 配布）

Distribution 証明書が keychain に登録されていない場合は `flutter build ipa` が失敗する。
その場合は以下の 2 ステップ方式を使う（Mac mini SSH 経由でも可）。

```bash
# 1. keychain アンロック（SSH 時は毎回必要）
security unlock-keychain -p "PASSWORD" ~/Library/Keychains/login.keychain-db
security set-keychain-settings -t 3600 ~/Library/Keychains/login.keychain-db

# 2. Flutter iOS ビルド（コード署名なし）
flutter build ios --release --flavor prod --dart-define=FLAVOR=prod --no-codesign

# 3. xcarchive 生成
xcodebuild \
  -workspace ios/Runner.xcworkspace \
  -scheme prod \
  -configuration Release-prod \
  -archivePath build/ios/archive/Runner.xcarchive \
  archive

# 4. ExportOptions.plist を用意（method: app-store, signingStyle: automatic, teamID: 9A34XAPY8W）

# 5. IPA export
xcodebuild -exportArchive \
  -archivePath build/ios/archive/Runner.xcarchive \
  -exportOptionsPlist /tmp/ExportOptions.plist \
  -exportPath build/ios/ipa/
```

**ポイント**:

- `--dart-define=FLAVOR=prod` は必須（省略すると Dart 側が prod にならない）
- ビルド番号は `pubspec.yaml` の `version: x.y.z+N` の `N` を毎回インクリメント
- **TestFlight 手順**: 新ビルドをグループに追加してから古いビルドを期限切れにする（逆順にするとテスター側で更新が表示されない）

---

## 7. 禁止事項

- グローバル `setUp()` でのモック共有
- `DocumentSnapshot<Map<String, dynamic>>` の手動モック作成
- CI で `windows-latest` を使う（`ubuntu-latest` を使うこと）
- `flutter pub upgrade` 後にビルド確認なしで push
