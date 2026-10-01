# 開発日報 - 2026年10月1日

## 📅 本日の目標

- [x] Flutter stable SDKを最新版へ統一する
- [x] Android Firebase設定のパッケージ名をGoShoppingへ統一する
- [x] Gradle / AGPをFlutterが許容する安定版へ更新する
- [x] エミュレーター起動ログを確認する
- [x] 未解決のビルド・実行課題を整理する

---

## ✅ 完了した作業

### 1. Flutter stable SDKの統一 ✅

**Purpose**: ローカル、FVM、GitHub ActionsでFlutter SDKのバージョンを揃える。

**実施内容**:

- Flutter stable `3.35.6` / `3.47.2` から `3.47.5` へ更新
- Dart `3.13.4` を確認
- CIのFlutterバージョンをstableチャンネル任せから `3.47.5` 固定へ変更

**Modified Files**:

- `.fvm/fvm_config.json`
- `.github/workflows/flutter-ci.yml`
- `.github/workflows/main-release.yml`

**検証結果**:

- `flutter pub get`: 成功
- 旧バージョン `3.47.2` の残存なし

**Status**: ✅ 完了

---

### 2. Firebase Androidパッケージ名の整理 ✅

**Purpose**: Kotlin移植版の旧アプリ名 `taskringk` をGoShoppingのapplicationIdへ統一する。

**Before**:

```json
"package_name": "net.sumomo_planning.taskringk"
```

**After**:

```json
"package_name": "net.sumomo_planning.goshopping"
```

dev flavorは次の値へ統一した。

```text
net.sumomo_planning.goshopping.dev
```

**Modified Files**:

- `android/app/google-services.json`（ローカル設定）
- `android/app/src/debug/google-services.json`（ローカル設定）
- `android/app/src/prod/google-services.json`（ローカル設定）

**検証結果**:

- JSONとして読み込み成功
- `taskringk` の残存なし
- `prod` / `dev` のapplicationIdと一致することを確認

**Status**: ✅ 完了。Firebase設定ファイルは機密設定のためコミット対象外。

---

### 3. Androidビルド基盤の更新 ⚠️

**Purpose**: Flutter 3.47.5が推奨する範囲でGradleとAGPを安定版へ近づける。

**更新内容**:

- Android Gradle Plugin: `8.11.1` → `9.4.0`
- Gradle Wrapper: `8.14` → `9.6.0`
- Kotlin: `2.4.0`
- JVM: JDK `21` LTSを使用

**Modified Files**:

- `android/settings.gradle.kts`
- `android/build.gradle.kts`
- `android/gradle/wrapper/gradle-wrapper.properties`
- `instructions/90_testing_and_ci.md`

**検証結果**:

- `android/gradlew.bat --version`: Gradle `9.6.0` 起動成功
- prod Debug APKビルドはJavaコンパイルまで進行
- 最終的にGradle daemonが`EXCEPTION_ACCESS_VIOLATION`で終了
- 問題フレームはGradleの`AbstractListChildMap.invalidate`

**Status**: ⚠️ 設定更新は完了。Windows/JDK 21環境でのGradle daemonクラッシュは継続調査。

---

### 4. エミュレーター起動ログ確認 ✅

**検証環境**:

- Android Emulator `emulator-5554`
- Android 17 / API 37
- 前面プロセス: `net.sumomo_planning.goshopping.dev`

**確認結果**:

- アプリ起動中、クラッシュなし
- `FATAL EXCEPTION`: なし
- `ANR`: なし
- バナー広告: 読み込み成功
- App Checkデバッグトークン交換: `403`
- Firestoreの`users/{uid}`読み取り: `PERMISSION_DENIED`
- gRPC名前解決失敗が複数回発生

**原因整理**:

- App Check `403` はデバッグトークン未登録の可能性が高い
- Firestoreルールは`request.auth`を確認しているが、`request.app`は使用していない
- App Check登録後もFirestore権限エラーが続く場合は、認証UID、Firebaseプロジェクト、ルールデプロイ状態を確認する

**Status**: ✅ ログ確認完了。App CheckとFirestore権限は要対応。

---

## 🐛 発見された問題

### Gradle daemonのJVMクラッシュ ⚠️

- **症状**: prod Debug APKビルド中にGradle daemonが異常終了
- **原因**: Gradle 9.6.0のファイルスナップショット処理中にJVM `EXCEPTION_ACCESS_VIOLATION`
- **対処**: `hs_err_pid*.log` で問題フレームを確認済み。Gradleキャッシュ・ファイル監視・JDK互換性の切り分けが必要
- **状態**: 調査中

### App Checkデバッグトークン未登録 ⚠️

- **症状**: Debug Providerのトークン交換が403
- **対処**: Firebase Consoleのdevアプリへエミュレーターのデバッグトークンを登録する
- **状態**: ユーザー側のFirebase Console作業待ち

### Firestore権限エラー ⚠️

- **症状**: `users/{uid}` の読み取りが`PERMISSION_DENIED`
- **対処**: App Check登録後も再現する場合、認証UID・接続先プロジェクト・Firestore Rulesのデプロイを確認する
- **状態**: 継続確認

---

## 📊 バグ対応進捗

### 完了 ✅

1. ✅ Flutter stable SDKを3.47.5へ統一
2. ✅ Firebase Android package_nameをGoShoppingへ統一
3. ✅ Gradle Wrapper / AGPを更新
4. ✅ エミュレーター起動ログの初回確認

### 対応中 🔄

1. 🔄 Gradle daemonのJVMクラッシュ（Priority: High）
2. 🔄 App Checkデバッグトークン登録後のFirestore動作確認（Priority: High）

---

## 💡 技術的学習事項

### Flutter flavorとFirebase設定ファイルの組み合わせ

```text
prod applicationId: net.sumomo_planning.goshopping
 dev applicationId: net.sumomo_planning.goshopping.dev
```

Firebaseの`google-services.json`は、flavorごとのapplicationIdと一致する`package_name`を含める必要がある。`src/debug`と`src/prod`を組み合わせるビルドでは、source setの優先順位にも注意する。

### App CheckとFirestore Rules

```text
App Checkの403 = デバッグトークン検証の問題
Firestore PERMISSION_DENIED = 認証UID / Rules / App Check enforcementを個別に確認
```

App Checkの警告とFirestore Rulesの認証条件は別の層で評価されるため、同じログに出ても一つの原因と決めつけない。

---

## 🗓 翌日（2026年10月2日）の予定

1. Firebase ConsoleへdevエミュレーターのApp Checkデバッグトークンを登録
2. 再起動してFirestore `PERMISSION_DENIED` の再現有無を確認
3. Gradle daemonクラッシュのキャッシュ・ファイル監視・JDK条件を切り分ける
4. prod flavorが実際に`net.sumomo_planning.goshopping`で起動することを確認

---

## 📝 ドキュメント更新

| ドキュメント | 更新内容 |
|---|---|
| `instructions/90_testing_and_ci.md` | Flutter 3.47.5、AGP 9.4.0、Gradle 9.6.0、Kotlin 2.4.0、JDK 21の現行値と検証方針を追記 |
| `docs/daily_reports/2026-10/daily_report_20261001.md` | 本日の作業・検証結果・未解決課題を記録 |
| Firebase設定ファイル | 更新したが、機密情報を含むためコミット対象外 |
