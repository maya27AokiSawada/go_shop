# 開発日報 - 2026年10月1日

## 📅 本日の目標

- [x] Flutter stable SDKを最新版へ統一する
- [x] Android Firebase設定のパッケージ名をGoShoppingへ統一する
- [x] Gradle / AGPをFlutterが許容する安定版へ更新する
- [x] エミュレーター起動ログを確認する
- [x] 未解決のビルド・実行課題を整理する
- [x] Androidビルドエラー（compileSdk / 署名設定）を調査・修正する
- [x] ビルド40/41を内部テスト版へ反映し、SH-54Dの起動時クラッシュを調査・修正する
- [x] Windowsデスクトップ版をビルドできるように設定する

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

### 5. Androidビルドエラーの調査・修正 ✅

**Purpose**: `flutter build apk` / `flutter build appbundle` が失敗する問題を解消する。

**発見した原因と対応**:

1. **compileSdk不足によるビルド失敗**
   - `package_info_plus` が compileSdk 36+ を要求するが、`compileSdk = flutter.compileSdkVersion` では34相当にしかならず、`sentry_flutter` 側のAARメタデータとも競合してビルド失敗
   - `android/app/build.gradle.kts` で `compileSdk = 36` を明示指定
   - さらに `sentry_flutter` を `^8.9.0` → `^9.0.0`（解決後 9.30.1）へ更新。旧バージョンのネイティブAndroidモジュールが `compileSdkVersion 34` に固定されていたため
2. **署名設定(`key.properties`)の破損**
   - `storeFile` の値に `keytool -list -v -keystore ...` というコマンド断片が誤って貼り付けられており、release/appbundleビルドの署名ステップが失敗
   - 実際のキーストア（`C:\Users\fatim\upload-keystore.jks`）の存在を確認し、正しいパスへ修正（`android/key.properties` は `.gitignore` 対象のためコミット対象外）

**検証結果**:

- `flutter build apk --debug --flavor dev`: 成功
- `flutter build appbundle --release --flavor prod --dart-define=FLAVOR=prod`: 成功（`app-prod-release.aab` 77.2MB）

**Status**: ✅ 完了

---

### 6. 内部テスト版(SH-54D)起動時クラッシュの調査・修正 ✅

**Purpose**: ビルド40を内部テストでインストールしたSH-54D（Android 16 / API 36）実機が起動直後に終了する問題を解消する。

**調査方法**: adb経由でSH-54Dをこのマシンに接続し、`logcat`でクラッシュスタックトレースを直接取得。

**発見した原因**:

```
FATAL EXCEPTION: main
java.lang.RuntimeException: Unable to get provider androidx.startup.InitializationProvider
Caused by: java.lang.RuntimeException: Failed to create an instance of androidx.work.impl.WorkDatabase
```

`google_mobile_ads` が依存する `play-services-ads-api:25.3.0` が、古い `androidx.work:work-runtime:2.7.0` を固定で引き込んでいた。このバージョンはAndroid 15/16上でRoomの `WorkDatabase` 初期化に失敗し、起動直後にクラッシュしていた。他のライブラリは依存関係の衝突解決で自動的に新しいバージョンへ引き上げられていたが、work-runtimeだけはこれを要求する他の依存がなく2.7.0のまま残っていた。

**対応**:

- `android/app/build.gradle.kts` に `implementation("androidx.work:work-runtime:2.12.0")` を直接依存として追加し、Gradleの依存解決で古い2.7.0より優先されるように修正
- ビルド番号を41へ更新

**検証結果**:

- 依存ツリーで `androidx.work:work-runtime:2.7.0 -> 2.12.0` に解決されることを確認
- `flutter build apk --release --flavor prod` → SH-54Dへ再インストール → 起動後クラッシュせず継続動作を確認（logcatにFATAL EXCEPTIONなし）

**Status**: ✅ 完了

---

### 7. Windowsデスクトップビルド対応 ✅

**Purpose**: Windows版アプリをビルドできるようにする。

**実施内容**:

- `flutter create --platforms=windows .` でWindowsランナー一式（CMakeLists.txt, runner/*.cpp等）を追加。これまでこのプロジェクトにはWindows向けのネイティブプロジェクトファイルが存在していなかった
- `.gitignore` の `/windows/` 除外ルールを解除し、android/iosと同様にチームで共有・ビルドできるように変更
- 副次的に発見した `.gitignore` の `*.txt` ルールが新規 `CMakeLists.txt` を常にブロックしていた問題も修正（`!**/CMakeLists.txt` を追加）。このルールのせいで `windows/CMakeLists.txt` と `windows/runner/CMakeLists.txt` がコミット対象から漏れていた
- `flutter run -d windows`（デバッグビルド）で、`sentry_flutter` が組み込む `sentry-native` のCMakeビルドと `share_plus` プラグインの並列コンパイル時にPDB書き込みが衝突し `C1041` で失敗する問題を発見。`windows/CMakeLists.txt` に `/FS`（PDB書き込み同期化）フラグを追加して解消

**検証結果**:

- `flutter build windows --release`: 成功、生成した `goshopping.exe` を起動しFirebase/Hive初期化からホーム画面表示まで確認
- `flutter run -d windows --flavor dev`: 成功（修正前は `C1041` で失敗）

**Status**: ✅ 完了

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
5. ✅ compileSdk不足・署名設定破損によるAndroidビルド失敗を修正
6. ✅ SH-54D実機の起動時クラッシュ（WorkManager/WorkDatabase）を修正、ビルド41へ反映
7. ✅ Windowsデスクトップビルド対応（`flutter build windows` / `flutter run -d windows` とも成功）

### 対応中 🔄

1. 🔄 App Checkデバッグトークン登録後のFirestore動作確認（Priority: High）

### 備考

- Gradle daemonのJVMクラッシュ（`EXCEPTION_ACCESS_VIOLATION`）は、本日以降のセッションで `flutter build apk` / `appbundle` / `gradlew app:dependencies` を複数回実行しても再現せず。継続監視とし、再発時に改めて切り分ける。

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
3. ビルド41のPlay Console内部テスト反映結果（SH-54D以外の端末含む）を確認
4. Windows版の署名・配布方法（必要であれば）を検討

---

## 📝 ドキュメント更新

| ドキュメント | 更新内容 |
|---|---|
| `instructions/90_testing_and_ci.md` | Flutter 3.47.5、AGP 9.4.0、Gradle 9.6.0、Kotlin 2.4.0、JDK 21の現行値と検証方針を追記 |
| `docs/daily_reports/2026-10/daily_report_20261001.md` | 本日の作業・検証結果・未解決課題を記録 |
| Firebase設定ファイル | 更新したが、機密情報を含むためコミット対象外 |

## 📝 本日の変更ファイル（Androidビルド修正・Windows対応）

| ファイル | 内容 |
|---|---|
| `android/app/build.gradle.kts` | `compileSdk = 36` 明示指定、`androidx.work:work-runtime:2.12.0` を強制依存に追加 |
| `pubspec.yaml` / `pubspec.lock` | `sentry_flutter` を9系へ更新、ビルド番号を41へ |
| `android/key.properties` | 署名用`storeFile`パスの破損を修正（機密情報のためコミット対象外） |
| `.gitignore` | `/windows/` 除外解除、`*.txt` ルールが `CMakeLists.txt` を巻き込んでいた問題を修正 |
| `windows/` 一式 | `flutter create --platforms=windows .` で新規追加、トラッキング対象化 |
| `windows/CMakeLists.txt` | `/FS` フラグ追加（デバッグビルドのPDB競合C1041を解消） |
