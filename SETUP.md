# GoShopping セットアップガイド

このドキュメントは、GoShopping を **このリポジトリに含まれていない別の Firebase / AdMob プロジェクト** でビルド・運用するための手順です。

実際の Firebase 設定値、AdMob ID、秘密情報はこのドキュメントには記載しません。すべて **プレースホルダー** または **取得先** のみを記載します。

## 1. 想定する構成

- `Flavor.dev`: 開発・検証用
- `Flavor.prod`: 本番運用用

推奨:

- Firebase プロジェクトは `dev` / `prod` で分離する
- AdMob も `dev` / `prod` で用途を分ける
- 開発中は AdMob テストIDを使う

単一の Firebase プロジェクトで運用したい場合は、`dev` / `prod` の両方に同じ設定を入れても動作します。ただし、本番運用では環境分離を推奨します。

## 2. 前提ツール

必要なもの:

- Flutter SDK
- Dart SDK
- Firebase CLI
- FlutterFire CLI
- Android Studio または Android SDK
- iOS を扱う場合は Xcode と CocoaPods

確認コマンド:

```bash
flutter doctor
firebase --version
dart pub global activate flutterfire_cli
```

## 3. 先に理解しておくこと

このアプリでは Firebase 関連設定が複数ファイルに分かれています。

| 用途                             | 必要ファイル                                                            | 備考                         |
| -------------------------------- | ----------------------------------------------------------------------- | ---------------------------- |
| Flutter 実行時の Firebase 初期化 | `lib/firebase_options.dart`                                             | 生成ファイル。コミットしない |
| Android ネイティブ Firebase 設定 | `android/app/google-services.json`                                      | Firebase Console から取得    |
| iOS ネイティブ Firebase 設定     | `ios/GoogleService-Info-dev.plist`, `ios/GoogleService-Info-prod.plist` | Firebase Console から取得    |
| アプリ内の環境変数               | `.env`                                                                  | `.env.example` を元に作成    |
| Firebase Extension 用設定        | `extensions/firestore-send-email.env`                                   | メール送信機能を使う場合のみ |

## 4. 作成・配置が必要なファイル

### 4.1 `.env`

テンプレート:

- `.env.example`

作成先:

- `.env`

このファイルはアプリ実行時に読み込まれます。`pubspec.yaml` の assets に含まれているため、**存在しないとビルド後の動作が不安定になる可能性があります**。

最低限確認すべきキー:

```env
# Firebase Web
FIREBASE_API_KEY_WEB=your_firebase_api_key_web
FIREBASE_APP_ID_WEB=your_firebase_app_id_web
FIREBASE_MESSAGING_SENDER_ID=your_messaging_sender_id
FIREBASE_PROJECT_ID=your_project_id
FIREBASE_AUTH_DOMAIN=your_project_id.firebaseapp.com
FIREBASE_STORAGE_BUCKET=your_project_id.firebasestorage.app
FIREBASE_MEASUREMENT_ID_WEB=your_measurement_id_web

# Firebase Android / iOS / Windows
FIREBASE_APP_ID_ANDROID=your_firebase_app_id_android
FIREBASE_APP_ID_IOS=your_firebase_app_id_ios
FIREBASE_IOS_BUNDLE_ID=com.example.goShop
FIREBASE_APP_ID_WINDOWS=your_firebase_app_id_windows

# AdMob
ADMOB_APP_ID=your_admob_app_id
ADMOB_BANNER_AD_UNIT_ID=your_admob_banner_ad_unit_id
ADMOB_INTERSTITIAL_AD_UNIT_ID=your_admob_interstitial_ad_unit_id

# Sentry (desktop only)
SENTRY_DSN=your_sentry_dsn
SENTRY_ENVIRONMENT=development

# Optional test-only credentials
TEST_EMAIL_RECIPIENT=tester@example.com
TEST_SCENARIO_EMAIL=tester@example.com
TEST_SCENARIO_PASSWORD=change_me

# 開発用テストID
ADMOB_TEST_APP_ID=ca-app-pub-3940256099942544~3347511713
ADMOB_TEST_BANNER_AD_UNIT_ID=ca-app-pub-3940256099942544/6300978111
```

運用ルール:

- 実IDは `.env` のみに入れる
- `.env.example` はプレースホルダーのまま維持する
- `.env` はコミットしない

### 4.2 `lib/firebase_options.dart`

テンプレート:

- `lib/firebase_options.dart.example`
- `lib/firebase_options.dart.template`

作成先:

- `lib/firebase_options.dart`

このファイルは FlutterFire CLI で生成する前提です。

例:

```bash
# 開発用プロジェクト
flutterfire configure --project=<your-dev-project-id>

# 本番用プロジェクト
flutterfire configure --project=<your-prod-project-id>
```

注意:

- このリポジトリでは flavor に応じて Firebase 設定を切り替える前提です
- 実運用値を含む `lib/firebase_options.dart` はコミットしないでください
- 既存テンプレートを手で埋めるより、FlutterFire CLI での再生成を推奨します

### 4.3 Android: `google-services.json`

配置先:

- `android/app/google-services.json`

取得元:

- Firebase Console → Project settings → Your apps → Android app

補足:

- Android アプリの `applicationId` と Firebase に登録した Android app が一致している必要があります
- `dev` / `prod` を分ける場合は、実際の flavor 構成に合わせて JSON の差し替え運用を検討してください
- まずは 1 つの Android Firebase app で動作確認し、その後 flavor 分離しても構いません

### 4.4 iOS: `GoogleService-Info.plist`

テンプレート:

- `ios/GoogleService-Info.plist.template`
- `ios/GoogleService-Info-dev.plist.template`

配置先:

- `ios/GoogleService-Info-dev.plist`
- `ios/GoogleService-Info-prod.plist`

取得元:

- Firebase Console → Project settings → Your apps → iOS app

補足:

- `dev` / `prod` を分ける場合は、それぞれ対応する plist を用意してください
- 単一 Firebase プロジェクトで運用する場合は、同一内容を `dev` / `prod` の両ファイル名で配置しても構いません
- iOS の Firebase 設定ファイルは Git で共有しない前提にしてください

### 4.5 Firebase Extension 用 `.env`

テンプレート:

- `extensions/firestore-send-email.env.template`

作成先:

- `extensions/firestore-send-email.env`

このファイルはメール送信機能を使う場合のみ必要です。

主な設定例:

```env
DEFAULT_FROM=example@example.com
SMTP_CONNECTION_URI=smtps://username:app-password@smtp.example.com:465
DATABASE_REGION=asia-northeast1
```

### 4.6 Sentry 設定

このアプリは Windows / Linux / macOS で `sentry_flutter` を使用できます。
実際の DSN は追跡対象ファイルに書かず、`.env` にのみ設定してください。

使用するキー:

```env
SENTRY_DSN=your_sentry_dsn
SENTRY_ENVIRONMENT=development
```

ルール:

- `SENTRY_DSN` は `.env` のみに記載する
- `.env.example` にはプレースホルダーのみ残す
- Sentry を使わない場合は `SENTRY_DSN` を空欄のままにしてよい
- 本番運用では `SENTRY_ENVIRONMENT=production` など、環境名を明示する

### 4.7 テスト用資格情報

テスト用ウィジェットを使う場合のみ、以下を `.env` に設定してください。

```env
TEST_EMAIL_RECIPIENT=tester@example.com
TEST_SCENARIO_EMAIL=tester@example.com
TEST_SCENARIO_PASSWORD=change_me
```

ルール:

- テスト用メールアドレスやパスワードをソースコードに直書きしない
- 実運用アカウントを使う場合も `.env` またはローカル専用の仕組みだけで保持する
- 不要なら未設定のままでよい

## 5. Firebase Console 側で必要な設定

最低限必要な設定:

1. Firebase プロジェクトを作成する
2. Authentication で `メール / パスワード` を有効化する
3. Firestore Database を作成する
4. Android アプリを登録する
5. iOS アプリを登録する
6. 必要に応じて Web / Windows 向け設定値を取得する

任意だが推奨:

1. Crashlytics を有効化する
2. App Check の導入方針を決める
3. 本番用と開発用でプロジェクトを分離する
4. メール送信を使う場合は Firebase Extensions の Trigger Email を導入する
5. デスクトップで障害監視したい場合は Sentry プロジェクトを作成する

## 6. AdMob 設定

このアプリは `google_mobile_ads` を使用しています。
実際の AdMob ID は **`.env` のみ** に設定してください。

必要な値:

- `ADMOB_APP_ID`
- `ADMOB_BANNER_AD_UNIT_ID`
- `ADMOB_INTERSTITIAL_AD_UNIT_ID`

推奨運用:

- 開発中は `.env.example` に記載済みの Google 提供テストIDを使う
- 本番配布時のみ本番 AdMob ID に切り替える
- 実IDをドキュメントやソースコードに直接書かない

## 7. Sentry 設定

Sentry はデスクトップ版（Windows / Linux / macOS）で任意利用です。

必要な値:

- `SENTRY_DSN`
- `SENTRY_ENVIRONMENT`

推奨運用:

- 実 DSN は `.env` にのみ保持する
- `README.md` や `main.dart` などの追跡対象ファイルに DSN を書かない
- CI では `DOT_ENV` Secret に Sentry 設定を含める
- Sentry を未使用にしたい環境では `SENTRY_DSN` を未設定にして起動する

## 8. セキュリティ・非公開情報の扱い

コミットしてはいけない代表例:

- `.env`
- `lib/firebase_options.dart`
- `android/app/google-services.json`
- `ios/GoogleService-Info-dev.plist`
- `ios/GoogleService-Info-prod.plist`
- `extensions/firestore-send-email.env`
- `SENTRY_DSN` を含む各種ローカル設定ファイル
- `key.properties`
- `*.jks`, `*.keystore`, `*.pem`, `*.key`

ルール:

- ドキュメントには実際の Firebase Project ID、API Key、AdMob ID を書かない
- サンプルはすべて `your_project_id` のようなプレースホルダーで表現する
- 認証情報を誤ってコミットした場合は、削除だけでなく再発行を前提に対応する

## 9. Firestore ルールとインデックスの反映

対象プロジェクトを選んでから反映します。

```bash
firebase use <your-project-id>
firebase deploy --only firestore:rules
firebase deploy --only firestore:indexes
```

`dev` と `prod` を分けている場合は、両プロジェクトに対して個別に実行してください。

## 10. 依存関係の取得

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

## 11. 実行方法

### Windows

```bash
flutter run -d windows
```

### Android / 開発用

```bash
flutter run --flavor dev --dart-define=FLAVOR=dev
```

### Android / 本番用

```bash
flutter run --flavor prod --dart-define=FLAVOR=prod
```

### iOS / 開発用

```bash
flutter run --flavor dev --dart-define=FLAVOR=dev -d <ios-device-id>
```

### iOS / 本番用

```bash
flutter run --flavor prod --dart-define=FLAVOR=prod -d <ios-device-id>
```

## 12. ビルド

```bash
flutter build windows
flutter build apk --debug --flavor dev --dart-define=FLAVOR=dev
flutter build apk --release --flavor prod --dart-define=FLAVOR=prod
flutter build web
```

## 13. 運用時のチェックリスト

本番投入前に確認すること:

1. `prod` が本番 Firebase プロジェクトを向いている
2. `dev` が開発 Firebase プロジェクトを向いている
3. `.env` に本番 AdMob ID が入っている
4. Firestore Rules / Indexes が対象プロジェクトへデプロイ済み
5. iOS / Android の Firebase ネイティブ設定ファイルが最新
6. 機密ファイルが Git に含まれていない
7. Sentry を使う場合は `.env` の `SENTRY_DSN` / `SENTRY_ENVIRONMENT` が正しい

## 14. よくある問題

### `No Firebase App '[DEFAULT]' has been created`

確認すること:

- `lib/firebase_options.dart` が存在するか
- `lib/firebase_options.dart` がテンプレートのままではないか
- flavor 切り替え時に期待した Firebase 設定が選ばれているか

### `google-services.json is missing`

確認すること:

- `android/app/google-services.json` に配置されているか
- ルート直下など誤った場所に置いていないか

### iOS で `GoogleService-Info.plist` が見つからない

確認すること:

- `ios/GoogleService-Info-dev.plist`
- `ios/GoogleService-Info-prod.plist`
- Xcode 側の Build Configuration / Scheme / Run Script 設定

### AdMob が表示されない

確認すること:

- `.env` の AdMob 設定が空ではないか
- 開発環境で本番IDではなくテストIDを使っているか
- Firebase 設定は正しくても、AdMob 側の審査・反映待ちでは配信されないことがある

### `.env` を作ったのに値が反映されない

確認すること:

- `.env` がリポジトリルートにあるか
- キー名が `.env.example` と一致しているか
- 変更後にアプリを再起動したか

### Sentry が動かない

確認すること:

- `.env` に `SENTRY_DSN` が入っているか
- デスクトップ版（Windows / Linux / macOS）で起動しているか
- `SENTRY_ENVIRONMENT` が空欄になっていないか
- `DOT_ENV` Secret を使う CI では `.env` に Sentry 設定が含まれているか

## 15. 関連ドキュメント

- `docs/knowledge_base/ios_flavor_setup.md`
- `docs/SECURITY_ACTION_REQUIRED.md`
