# 開発日報 - 2026年06月24日

## 📅 本日の目標

- [x] Windows Firebase Auth サインイン失敗の原因を特定・修正する
- [x] QR 招待の Firestore 書き込みサイレント失敗を修正する
- [x] Android ビルドエラー（Kotlin バージョン）を修正する
- [ ] Windows QR 招待エンドツーエンドテスト（サインイン修正後に着手予定）

---

## ✅ 完了した作業

### 1. Windows Firebase Auth `unknown-error` の原因特定・修正 ✅

**Purpose**: Windows アプリでのサインインが `[firebase_auth/unknown-error]` で失敗する問題を解決する

**Background**:

- Windows Firebase は Web Firebase 設定（app_id: `1:37061888509:web:...`）を使用
- API キーは `.env` の `FIREBASE_API_KEY_WEB` に格納、`firebase_options.dart` が `flutter_dotenv` 経由で読み込む

**Problem / Root Cause**:
Google Cloud Console で `Browser key (auto created by Firebase)` に有効期限が設定されており、その期限が切れていた。
Firebase Auth REST API が 400 エラーを返し、Firebase C++ SDK が `unknown-error` にマッピングしていた。

**Solution**:

1. GCC → APIs & Services → 認証情報 で新しい Browser key（`26-06-24Browser key`）を確認
2. `.env` の `FIREBASE_API_KEY_WEB` を新しいキーの値に更新
3. アプリをホットリスタートしてサインイン成功を確認

**検証結果**: Windows アプリでのサインイン成功を確認

**Modified Files**:

- `.env` （gitignore 対象 — `FIREBASE_API_KEY_WEB` を新キーに更新）

**Status**: ✅ 完了・検証済み

---

### 2. Firebase Admin SDK と Web API キーの混同を解消 ✅

**Purpose**: ユーザーが Firebase Admin SDK のサービスアカウントキーを Flutter アプリに使おうとしていたリスクを解消する

**Problem**:
Firebase Console の「プロジェクトの設定 → Firebase Admin SDK」でサービスアカウント JSON をダウンロードし、これを Flutter アプリに設定しようとしていた。

**Solution**:

- **Admin SDK キー**: サーバーサイド専用（管理者権限あり）→ Flutter アプリには絶対使わない
- **Flutter 用 API キー**: Firebase Console → プロジェクトの設定 → 全般 → Web アプリ → `apiKey`（`AIzaSy...` 形式）
- `.env` に保存して `flutter_dotenv` で読み込む設計を確認・説明した

**Status**: ✅ 完了（ユーザー理解確認済み）

---

### 3. QR 招待 Firestore 書き込みサイレント失敗の修正 ✅

**Purpose**: Windows から QR 招待コードを生成した際、Firestore への書き込みが失敗しても QR が表示されてしまう問題を修正

**Problem / Root Cause**:
`qr_invitation_service.dart` の `createInvitation` が書き込みエラーをキャッチせず、失敗しても `invitationData` を返していた。
→ QR 表示後に Android 端末でスキャンしても「招待が見つかりません」エラーになる。

**Solution**:

```dart
// ❌ 修正前: エラーをキャッチしても継続
} catch (e) {
  Log.error('書き込みエラー: $e');
  // 何も throw しない → QR が生成されてしまう
}

// ✅ 修正後: タイムアウト・FirebaseException で明示的に throw
await _firestore
    .collection('SharedGroups').doc(sharedGroupId)
    .collection('invitations').doc(invitationId)
    .set(invitationDocData)
    .timeout(const Duration(seconds: 30));
// on TimeoutException → throw
// on FirebaseException → throw
```

また書き込み前に認証トークンリフレッシュ（`getIdToken(true)`）と Firestore ネットワーク再接続（`enableNetwork()`）を追加。

**Modified Files**:

- `lib/services/qr_invitation_service.dart`

**Commit**: `2a2c296`
**Status**: ✅ 完了（Android 実機検証は API キー修正後に着手予定）

---

### 4. Windows QR スキャナー `file_picker` 12.x API 修正 ✅

**Purpose**: `file_picker` を v8 → v12 に更新した際の破壊的変更に対応

**Problem / Root Cause**:

```dart
// ❌ v8 までの API（v12 で廃止）
final result = await FilePicker.platform.pickFiles(...);
```

**Solution**:

```dart
// ✅ v12 の API
final result = await FilePickerPlatform.instance.pickFiles(...);
```

**Modified Files**:

- `lib/widgets/windows_qr_scanner_simple.dart`

**Commit**: `2a2c296`
**Status**: ✅ 完了

---

### 5. Android Kotlin 2.4.0 アップグレード + `compilerOptions` DSL 移行 ✅

**Purpose**: Flutter の Kotlin Gradle プラグインバージョン警告を解消し、Android ビルドを通す

**Problem / Root Cause**:

1. Kotlin 2.1.0 → Flutter が警告（`AGP 8.11.1` との非互換）
2. Kotlin 2.4.0 にアップグレード後、`kotlinOptions { jvmTarget: String }` が削除されコンパイルエラー

```
e: Using 'jvmTarget: String' is an error.
Please migrate to the compilerOptions DSL.
```

**Solution**:

```kotlin
// ❌ Kotlin 2.4.0 で廃止
android {
    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()  // or "11"
    }
}

// ✅ compilerOptions DSL に移行
kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_11
    }
}
```

**Modified Files**:

- `android/settings.gradle.kts` （`2.1.0` → `2.4.0`）
- `android/app/build.gradle.kts` （`kotlinOptions` → `kotlin { compilerOptions }`）

**Commit**: `36debf2`
**Status**: 🔄 fix 適用済み・次回ビルドで検証要

---

### 6. パッケージバージョン更新 ✅

**Modified Files**:

- `pubspec.yaml`

**Commit**: `9f9661d`

| パッケージ          | 旧バージョン | 新バージョン     |
| ------------------- | ------------ | ---------------- |
| `file_picker`       | `^8.1.6`     | `^12.0.0-beta.7` |
| `google_mobile_ads` | `^5.1.0`     | `^9.0.0`         |
| `share_plus`        | `^7.2.2`     | `^13.1.0`        |
| `flutter_dotenv`    | `^5.1.0`     | `^6.0.1`         |
| `package_info_plus` | `^8.0.0`     | `^10.1.0`        |
| `geocoding`         | `^3.0.0`     | `^4.0.0`         |
| `device_info_plus`  | `^10.1.2`    | `^13.1.0`        |
| `signature`         | `^5.5.0`     | `^6.3.0`         |

**Status**: ✅ 完了

---

## 🐛 発見された問題

### Firebase API キー有効期限設定 ⚠️（運用上の注意）

- **症状**: Windows サインインが `unknown-error` で失敗（300ms で即時拒否）
- **原因**: GCC で Browser key に有効期限が設定されており期限切れになっていた
- **対処**: 新しい Browser key を作成・`.env` 更新で解決
- **状態**: 修正完了。今後は GCC でキーの有効期限を「期限なし」に設定することを推奨

### Android Kotlin 2.4.0 ビルド未検証 ⚠️

- **症状**: `compilerOptions` DSL 修正後の Android ビルドが未検証
- **原因**: 修正適用後のビルド実行未完了
- **状態**: 次回セッション開始時に確認要

---

## 📊 バグ対応進捗

### 完了 ✅

1. ✅ Windows Firebase Auth `unknown-error`（原因: API キー期限切れ）
2. ✅ QR 招待 Firestore 書き込みサイレント失敗
3. ✅ `file_picker` 12.x 破壊的変更対応
4. ✅ Kotlin Gradle プラグイン バージョン警告
5. ✅ `kotlinOptions` → `compilerOptions` DSL 移行

### 翌日継続 ⏳

1. 🔄 Android ビルド（Kotlin 2.4.0）検証
2. ⏳ Windows QR 招待 → Android スキャン エンドツーエンドテスト
3. ⏳ Firestore 書き込み（Windows gRPC AuthError 1）検証

---

## 💡 技術的学習事項

### Firebase API キー有効期限と `unknown-error` の関係

**問題パターン**: Windows Flutter アプリで Firebase Auth サインインが `[firebase_auth/unknown-error]` で失敗する

**根本原因の見分け方**:

- エラーが 300ms 以内に即時発生 → サーバー側 400/403 拒否（API キー問題 or App Check enforcement）
- エラーが 10-30 秒後に発生 → ネットワーク・タイムアウト問題

**確認手順**:

1. GCC → APIとサービス → 認証情報 → API キーの有効期限を確認
2. Firebase Console → App Check → Authentication の Enforcement 設定を確認

**重要**: `.env` の `FIREBASE_API_KEY_WEB` は `firebase_options.dart` が `flutter_dotenv` 経由で読み込む。更新後はホットリスタート（フルリビルド不要）で反映される。

### Kotlin 2.4.0 の破壊的変更

**問題パターン**: Kotlin 2.4.0 で `kotlinOptions { jvmTarget = "11" }` がコンパイルエラーになる

**対処**:

```kotlin
// android { ... } の外に以下を追加
kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_11
    }
}
```

### Firebase Admin SDK vs Flutter クライアント API キー

- Admin SDK JSON = **サーバーサイド専用**（管理者権限）→ Flutter アプリに絶対使わない
- Flutter 用 Web API キー = Firebase Console → プロジェクトの設定 → 全般 → Web アプリ → `apiKey`（`AIzaSy...`）

---

## 📝 翌日のタスク

1. **優先度高**: Android ビルドが通るか確認（Kotlin 2.4.0 `compilerOptions` 修正）
2. Android 実機で QR 招待の Firestore 書き込みが成功するか確認
3. Windows QR 生成 → Android スキャン のエンドツーエンドテスト
