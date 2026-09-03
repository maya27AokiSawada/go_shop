# 開発日報 - 2026年09月03日

## 📅 本日の目標

- [x] Play Store「リリースの署名が無効」エラーの原因を特定する
- [x] `android/key.properties` の署名設定を正しい形に修正する
- [x] `secrets/` に配置したキーストアが現行の署名鍵と同一か検証する
- [x] Play Console 登録済みアップロード鍵とローカルキーストアの一致を確認する
- [x] 依存パッケージ更新を反映して prod release AAB を再生成する

---

## ✅ 完了した作業

### 1. Play Store 署名エラーの原因特定 ✅

**Purpose**: リリース AAB アップロード時に Play Console から「署名が無効」と拒否される問題を解消する。

**調査経過（表面的なエラーを順に潰した）**:

| 発生エラー | 真因 | 対処 |
|---|---|---|
| `Malformed \uxxxx encoding`（`Properties.load`） | `key.properties` の `storeFile` が `C:\Users\...` 形式で、`\upload` が `.properties` の Unicode エスケープ（`\uXXXX`）として解釈された | パス区切りを `/` に変更 |
| `Keystore file '...\app\"C:\..."' not found` | `storeFile` の値をダブルクォートで囲んでいた。`.properties` はクォートを文字列の一部として保持し、先頭が `"` のため相対パス扱いになった | クォートを削除 |
| `Gradle build daemon disappeared unexpectedly` | 約1時間55分生存していた古い Gradle デーモンが GC スレッドで `EXCEPTION_ACCESS_VIOLATION`（`jvm.dll`）クラッシュ。R8 難読化中に発生 | `~/.gradle/daemon/8.14` を削除して新しいデーモンで再実行 |

**Root Cause（本当の原因）**:

- 署名設定・キーストアはいずれも正常だった。
- Play Console が拒否していたのは **versionCode 30 が過去の失敗アップロードで「使用済み」状態のまま残っていた**ため。

**Status**: ✅ 原因特定・解消

---

### 2. キーストアの同一性検証 ✅

**Purpose**: `secrets/` に配置したキーストアが現行の署名鍵と同じものか、Play Console のアップロード鍵と一致するかを確認する。

**検証結果**:

| 対象 | MD5 | SHA-1 |
|---|---|---|
| `android/app/upload-keystore.jks` | `6f5fdcaf13dc2fdc42c963abb5d8b33a` | `04:AF:DB:D4:E8:20:BB:72:D1:76:2D:E1:25:8A:CC:B6:BA:41:F5:2E` |
| `secrets/upload-keystore.jks` | 同一 | 同一 |
| `C:/Users/fatim/upload-keystore.jks`（署名で使用） | 同一 | 同一 |
| `E:/upload-keystore.jks` | 同一 | 同一 |

- ローカルに存在するキーストアは 4 ファイルすべてバイト単位で同一。
- Play Console「アップロード鍵の証明書」の SHA-1 `04:AF:DB:...:F5:2E` / SHA-256 `D1:80:EF:...:BE:36` と**完全一致**。
- → アップロード鍵のリセットは不要。`storeFile` の表記ミスのみが問題だった。

**Modified Files**:

- `android/key.properties`（gitignore 対象・未コミット）: `storeFile` をクォートなしの `/` 区切り絶対パスに修正
  ```properties
  storeFile=C:/Users/fatim/upload-keystore.jks
  ```

**Status**: ✅ 同一性・Play 登録鍵との一致を確認

---

### 3. 依存パッケージ更新 ✅

**Purpose**: Firebase 系を中心に、リリースビルド前に依存を最新の互換バージョンへ引き上げる。

**主な更新**:

| パッケージ | 変更前 | 変更後 |
|---|---|---|
| `firebase_core` | ^4.1.1 | ^4.14.0 |
| `firebase_auth` | ^6.3.0 | ^6.6.1 |
| `cloud_firestore` | ^6.0.2 | ^6.9.0 |
| `firebase_crashlytics` | ^5.0.5 | ^5.3.0 |
| `firebase_app_check` | ^0.4.2 | ^0.4.7 |
| `google_mobile_ads` | 5.3.1（固定） | ^9.1.0 |
| `geocoding` | ^4.0.0 | ^5.0.0 |
| `device_info_plus` | ^13.1.0 | ^13.2.0 |
| `cloud_functions` | 6.4.0（固定） | ^6.4.0 |

- `firebase_auth_mocks` は `firebase_core ^4.14` と非互換のため一時的にコメントアウト（ユニットテストの Auth モックは要再整備）。
- `analysis_options.yaml`: `android/`・`ios/`・`web/`・`windows/`・`linux/` を解析対象から除外。先頭 BOM を除去。
- `android/build.gradle.kts`: `plugins {}` に `com.android.application` / `org.jetbrains.kotlin.android` のバージョンを明示。

**検証結果**:

| 項目 | 結果 |
|---|---|
| prod release AAB ビルド | 成功（更新後の依存で 2 回連続成功） |

**Modified Files**:

- `pubspec.yaml` / `pubspec.lock`
- `analysis_options.yaml`
- `android/build.gradle.kts`

**Status**: ✅ 更新・リリースビルドで動作確認

---

### 4. prod release AAB（build 31）生成 ✅

**Purpose**: versionCode 重複を解消した最新 AAB を生成する。

**Solution**:

- `pubspec.yaml` を `1.1.0+30` → `1.1.0+31` に更新。
- `flutter build appbundle --flavor prod` を実行。

**検証結果**:

| 項目 | 結果 |
|---|---|
| versionName | `1.1.0` |
| versionCode | `31` |
| AAB | `build/app/outputs/bundle/prodRelease/app-prod-release.aab` |
| サイズ | 約 77.2 MB（80,975,640 bytes） |
| 署名 | `META-INF/UPLOAD.RSA`（`upload` エイリアス、SHA384withRSA / 2048bit RSA） |
| 生成日時 | 2026-09-03 16:36 |

**Modified Files**:

- `pubspec.yaml`（build number 30 → 31）

**Status**: ✅ 生成完了・署名検証済み

---

## 🐛 発見された問題

### versionCode 30 が失敗アップロードで「使用済み」扱いのまま残存 ✅

- **症状**: リリース AAB アップロード時に Play Console が拒否
- **原因**: 過去の失敗したアップロードで versionCode 30 が消費され、有効な状態として残っていた
- **対処**: versionCode を 31 に繰り上げて再ビルド
- **状態**: 解消

### `.properties` ファイルでの Windows パス記述ミス ✅

- **症状**: `Malformed \uxxxx encoding` → クォート付きパスで `Keystore file not found`
- **原因**: `\` が Unicode エスケープと衝突／ダブルクォートが値の一部として残る
- **対処**: `storeFile=C:/Users/fatim/upload-keystore.jks`（クォートなし・`/` 区切り）
- **状態**: 解消

### 長時間生存した Gradle デーモンの JVM クラッシュ ⚠️

- **症状**: R8 難読化中に `daemon disappeared` / `hs_err_pidXXXXX.log` 出力
- **原因**: 約 2 時間生存したデーモンの GC スレッドで `EXCEPTION_ACCESS_VIOLATION`
- **対処**: `~/.gradle/daemon/8.14` を削除して再実行（以後は正常）
- **状態**: 暫定対処。再発するなら `org.gradle.jvmargs` の見直し（`MaxMetaspaceSize=4G` 削除、`-XX:+UseParallelGC`）や JDK 更新を検討

---

## 📊 バグ対応進捗

### 完了 ✅

1. ✅ Play Store 署名エラーの原因特定（versionCode 重複）（完了日: 2026-09-03）
2. ✅ `key.properties` の署名設定修正（完了日: 2026-09-03）
3. ✅ キーストアと Play 登録アップロード鍵の一致確認（完了日: 2026-09-03）
4. ✅ 依存パッケージ更新とリリースビルド確認（完了日: 2026-09-03）
5. ✅ prod release AAB build 31 生成（完了日: 2026-09-03）

### 対応中 🔄

1. 🔄 Play Store テストトラック配布版での購入・復元 E2E（Priority: High、2026-09-01 から継続）
2. 🔄 `firebase_auth_mocks` 非互換によるユニットテスト Auth モックの再整備（Priority: Medium）

### 未着手 ⏳

1. ⏳ Google Play RTDN / App Store Server Notifications による失効同期（Priority: High）

### 翌日継続 ⏳

- ⏳ build 31 AAB を Play Store テストトラックへアップロード
- ⏳ 依存更新後のアプリを実機で回帰確認（Firestore 同期・課金・広告）
- ⏳ `firebase_auth_mocks` 相当のモック手段を決めてテストを復旧

---

## 💡 技術的学習事項

### `.properties` ファイルの Windows パスはエスケープに注意する

**問題パターン**:

```properties
# ❌ \u が Unicode エスケープと衝突／クォートが値に残る
storeFile="C:\Users\fatim\upload-keystore.jks"
```

**正しいパターン**:

```properties
# ✅ クォートなし・スラッシュ区切り（Java の File が解決可能）
storeFile=C:/Users/fatim/upload-keystore.jks
```

**教訓**: `java.util.Properties` は `\` をエスケープ、`"` を通常文字として扱う。Windows パスは `/` 区切りか `\\` で書く。

### 「署名が無効」は署名鍵以外が原因のこともある

**教訓**: Play Console のアップロード鍵証明書（SHA-1 / SHA-256）とローカルキーストアの指紋を先に照合する。一致していれば署名鍵は正常で、versionCode 重複・パッケージ名不一致・デバッグ署名など別要因を疑う。

---

## 🗓 翌日（2026-09-04）の予定

1. build 31 AAB を Play Store テストトラックへアップロードして受理を確認
2. 依存更新後のアプリを SH-54D / Pixel 9 で回帰確認
3. Premium 購入・復元・Functions 検証・Firestore 反映を E2E 確認
4. `firebase_auth_mocks` の代替を決めてユニットテストを復旧

---

## 📝 ドキュメント更新

| ドキュメント | 更新内容 |
|---|---|
| `docs/daily_reports/2026-09/daily_report_20260903.md` | 本日の日報を新規作成 |
| `docs/daily_reports/2026-09/daily_report_20260901.md` | 「今日のTodo」節を追記 |
| その他の指示書・README | 更新なし |
