# Go Shop セットアップガイド

## 1. 必要な機密ファイルの設定

このリポジトリには機密情報が含まれるファイルは含まれていません。
以下のファイルをテンプレートからコピーして、各自の環境に合わせて設定してください。

### 1.1 Firebase設定ファイル

#### `lib/firebase_options.dart`

```bash
# テンプレートをコピー
cp lib/firebase_options.dart.template lib/firebase_options.dart

# エディタで開いて値を設定
# Firebase Console > プロジェクト設定 > 全般 > マイアプリ から値を取得
```

**設定する値**:

- `apiKey`: Firebase API キー
- `appId`: アプリケーションID
- `messagingSenderId`: メッセージング送信者ID
- `projectId`: Firebaseプロジェクト ID
- `authDomain`: 認証ドメイン
- `storageBucket`: ストレージバケット

#### `google-services.json` (Android用)

```bash
# Firebase Console からダウンロード
# プロジェクト設定 > 全般 > マイアプリ (Android)
# 「google-services.json」をダウンロードして、以下に配置：
# android/app/google-services.json
```

#### `GoogleService-Info.plist` (iOS用)

⚠️ **iOS フレーバー対応**: Dev環境とProd環境で異なるFirebaseプロジェクトを使用します。

```bash
# Firebase Console から両環境の設定ファイルをダウンロード
# プロジェクト設定 > 全般 > マイアプリ (iOS)

# Dev環境用 (プロジェクトID: gotoshop-572b7)
# Bundle ID: net.sumomo_planning.go_shop.dev
# ダウンロードした GoogleService-Info.plist を以下に配置：
cp path/to/dev/GoogleService-Info.plist ios/GoogleService-Info-dev.plist

# Prod環境用 (プロジェクトID: goshopping-48db9)
# Bundle ID: net.sumomo_planning.goshopping
# ダウンロードした GoogleService-Info.plist を以下に配置：
cp path/to/prod/GoogleService-Info.plist ios/GoogleService-Info-prod.plist

# ビルド時に自動的に適切な設定ファイルがコピーされます
```

**⚠️ Xcodeの手動設定は不要**:

- 自動生成スクリプト `ios/Runner/copy-googleservice-info.sh` が環境に応じて適切な設定ファイルをコピーします
- Xcodeプロジェクトには `ios/GoogleService-Info.plist`（元のファイル）のみ追加してください

**詳細な設定手順**: `docs/knowledge_base/ios_flavor_setup.md` を参照

**⚠️ セキュリティ注意**:

- これらのファイルは`.gitignore`で除外されています
- 公開リポジトリには**絶対にコミットしないでください**
- テンプレートファイル(`*.template`)のみがリポジトリに含まれます

### 1.2 Firebase Extension設定 (メール送信機能)

#### `extensions/firestore-send-email.env`

```bash
# テンプレートをコピー
cp extensions/firestore-send-email.env.template extensions/firestore-send-email.env

# エディタで開いて値を設定
```

**設定する値**:

- `DEFAULT_FROM`: 送信元メールアドレス
- `SMTP_CONNECTION_URI`: SMTP接続URI
  - Gmail例: `smtps://your.email@gmail.com:app_password@smtp.gmail.com:465`
  - Gmailアプリパスワード取得: https://myaccount.google.com/apppasswords
- `DATABASE_REGION`: Firestoreリージョン (例: `asia-northeast2`)

## 2. Firebase Consoleでの設定

### 2.1 Firebaseプロジェクト作成

1. https://console.firebase.google.com/ にアクセス
2. 新しいプロジェクトを作成
3. Authentication > Sign-in method で「メール/パスワード」を有効化
4. Firestore Database を作成 (本番モード)

### 2.2 Security Rules設定

```bash
# firestore.rules をデプロイ
firebase deploy --only firestore:rules
```

### 2.3 Firebase Extension インストール (オプション)

メール送信機能を使う場合:

1. Firebase Console > Extensions
2. "Trigger Email" をインストール
3. `extensions/firestore-send-email.env` の設定を使用

## 3. 依存関係のインストール

```bash
# Flutter依存関係
flutter pub get

# Hive code generation
dart run build_runner build --delete-conflicting-outputs
```

## 4. 実行

```bash
# Windows
flutter run -d windows

# Android
flutter run -d android

# 開発モード (Hiveのみ)
# lib/flavors.dart で F.appFlavor = Flavor.dev; に変更
```

## 5. セキュリティ注意事項

⚠️ **絶対にコミットしてはいけないファイル**:

- `lib/firebase_options.dart` (Firebase API keys)
- `google-services.json` (Android設定)
- `extensions/firestore-send-email.env` (SMTP credentials)
- `*.env` (環境変数ファイル)
- `*.key`, `*.pem`, `*.jks` (秘密鍵)
- `*.log` (ログファイル)

これらは `.gitignore` で除外されていますが、
万が一誤ってコミットした場合は、直ちに以下の対応を行ってください:

1. Git履歴から削除 (`git filter-branch`)
2. Firebase API Keyを再生成
3. SMTPパスワードを変更

## 6. トラブルシューティング

### Firebase初期化エラー

```
[core/no-app] No Firebase App '[DEFAULT]' has been created
```

→ `lib/firebase_options.dart` が正しく設定されているか確認

### Hive typeId conflict

```
TypeId XXX has already been registered
```

→ `dart run build_runner clean` → `dart run build_runner build` を実行

### Android build error

```
google-services.json is missing
```

→ Firebase Consoleから `google-services.json` をダウンロードして配置

## 7. サポート

問題が解決しない場合は、以下を確認してください:

- Flutter SDK: `flutter doctor`
- Firebase設定: Firebase Console > プロジェクト設定
- ログファイル: `flutter run --verbose`
