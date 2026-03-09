# GoShopping セットアップガイド

このドキュメントは、GoShopping を新しい開発環境で動かすための最小セットアップ手順です。
現行仕様では `Flavor.dev` と `Flavor.prod` の **どちらも Firebase を使用** します。

## 1. 前提

必要なもの:

- Flutter SDK
- Dart SDK
- Firebase CLI
- Android Studio または Android SDK
- iOS を扱う場合は Xcode と CocoaPods

確認コマンド:

```bash
flutter doctor
firebase --version
```

## 2. Firebase プロジェクト

このアプリは Firebase プロジェクトを dev / prod で分けています。

### Production

- Project ID: `goshopping-48db9`
- Usage: `Flavor.prod`

### Development

- Project ID: `gotoshop-572b7`
- Usage: `Flavor.dev`

## 3. 機密ファイルの配置

このリポジトリには実運用の機密ファイルは含めません。
テンプレートや example を元に、各自のローカル環境で配置してください。

### 3.1 `lib/firebase_options.dart`

ベースに使えるファイル:

- `lib/firebase_options.dart.example`
- `lib/firebase_options.dart.template`

作成先:

- `lib/firebase_options.dart`

必要な値:

- `apiKey`
- `appId`
- `messagingSenderId`
- `projectId`
- `authDomain`
- `storageBucket`
- 必要に応じて `iosBundleId`

FlutterFire CLI を使う場合の例:

```bash
# Production
flutterfire configure --project=goshopping-48db9

# Development
flutterfire configure --project=gotoshop-572b7
```

このリポジトリでは `lib/firebase_options.dart` 側で flavor に応じた切り替えを行う前提です。

### 3.2 Android: `google-services.json`

テンプレート:

- `google-services.json.template`

配置先:

- `android/app/google-services.json`

取得元:

- Firebase Console > Project settings > Your apps > Android app

注意:

- Android で Firebase 初期化に失敗する場合、まずこのファイルの配置先を確認してください。
- `google-services.json.template` は参考用であり、そのままでは動作しません。

### 3.3 iOS: `GoogleService-Info.plist`

iOS は flavor ごとに別ファイルを使います。

配置先:

- `ios/GoogleService-Info-dev.plist`
- `ios/GoogleService-Info-prod.plist`

関連ファイル:

- `ios/GoogleService-Info-dev.plist.template`
- `ios/Runner/copy-googleservice-info.sh`

スクリプト `ios/Runner/copy-googleservice-info.sh` が、ビルド時に適切な plist をアプリバンドルへコピーします。

詳細手順は [docs/knowledge_base/ios_flavor_setup.md](docs/knowledge_base/ios_flavor_setup.md) を参照してください。

### 3.4 Firebase Extension 用 `.env`（任意）

メール送信機能を使う場合のみ設定します。

テンプレート:

- `extensions/firestore-send-email.env.template`

作成先:

- `extensions/firestore-send-email.env`

主な設定値:

- `DEFAULT_FROM`
- `SMTP_CONNECTION_URI`
- `DATABASE_REGION`

Gmail を使う場合はアプリパスワードを使用してください。

## 4. Firebase Console 側の設定

最低限必要な設定:

1. Authentication で `メール / パスワード` を有効化
2. Firestore Database を作成
3. 対応する Android / iOS アプリを各プロジェクトに登録

必要に応じて:

1. Extensions > Trigger Email を導入
2. API キー制限やセキュリティ設定を実施

## 5. Firestore ルールとインデックスの反映

このリポジトリのルールとインデックスを反映する場合:

```bash
firebase deploy --only firestore:rules
firebase deploy --only firestore:indexes
```

## 6. 依存関係のインストール

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

## 7. 実行

### Windows

```bash
flutter run -d windows
```

### Android

```bash
flutter run
```

### Android flavor 指定

```bash
flutter run --flavor dev
flutter run --flavor prod
```

### iOS flavor 指定

```bash
flutter run --flavor dev -d <ios-device-id>
flutter run --flavor prod -d <ios-device-id>
```

## 8. ビルド

```bash
flutter build windows
flutter build apk --debug --flavor prod
flutter build apk --release --flavor prod
flutter build web
```

## 9. セキュリティ上の注意

コミットしてはいけない代表例:

- `lib/firebase_options.dart`
- `android/app/google-services.json`
- `ios/GoogleService-Info-dev.plist`
- `ios/GoogleService-Info-prod.plist`
- `extensions/firestore-send-email.env`
- 各種 `.env`
- `*.jks`, `*.keystore`, `*.pem`, `*.key`

万一コミットした場合は、単に削除するだけでは不十分です。
認証情報の再発行と、必要なら Git 履歴からの除去を行ってください。

関連ドキュメント:

- [docs/SECURITY_ACTION_REQUIRED.md](docs/SECURITY_ACTION_REQUIRED.md)

## 10. よくある問題

### `No Firebase App '[DEFAULT]' has been created`

確認すること:

- `lib/firebase_options.dart` が存在するか
- 中身が空やテンプレート値のままではないか
- flavor 切り替えロジックが壊れていないか

### `google-services.json is missing`

確認すること:

- `android/app/google-services.json` に配置されているか
- ルート直下に置いただけになっていないか

### iOS で `GoogleService-Info.plist` が見つからない

確認すること:

- `ios/GoogleService-Info-dev.plist`
- `ios/GoogleService-Info-prod.plist`
- Xcode の Build Configuration / Scheme / Run Script 設定

詳細は [docs/knowledge_base/ios_flavor_setup.md](docs/knowledge_base/ios_flavor_setup.md) を参照してください。

### Hive adapter / typeId 関連のエラー

```bash
dart run build_runner clean
dart run build_runner build --delete-conflicting-outputs
```

### Firestore の挙動が古い / 反映されない

確認すること:

- `firestore.rules` と `firestore.indexes.json` をデプロイ済みか
- 参照している Firebase プロジェクトが dev / prod で一致しているか

## 11. 参照ドキュメント

- [README.md](README.md)
- [docs/README.md](docs/README.md)
- [docs/knowledge_base/ios_flavor_setup.md](docs/knowledge_base/ios_flavor_setup.md)
- [docs/specifications/network_failure_handling_flow.md](docs/specifications/network_failure_handling_flow.md)
