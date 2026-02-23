# iOS Flavor Configuration Guide

このガイドでは、iOS版のGoShoppingアプリでdev/prodフレーバーを設定する手順を説明します。

## 概要

iOSでフレーバー対応を実現するため、以下の設定を行っています：

- **Dev環境**: `net.sumomo_planning.go_shop.dev` (アプリ名: GoShopping Dev)
- **Prod環境**: `net.sumomo_planning.goshopping` (アプリ名: GoShopping)

## 前提条件

1. Xcodeがインストールされていること
2. Firebase Console で両方のプロジェクト（dev/prod）にiOSアプリを登録済みであること
3. 各プロジェクトの `GoogleService-Info.plist` をダウンロード済みであること

## セットアップ手順

### 1. Firebase設定ファイルの配置

```bash
# Dev環境用のGoogleService-Info.plistを配置
cp path/to/dev/GoogleService-Info.plist ios/GoogleService-Info-dev.plist

# Prod環境用のGoogleService-Info.plistを配置
cp path/to/prod/GoogleService-Info.plist ios/GoogleService-Info-prod.plist
```

### 2. Xcodeプロジェクトの設定

#### 2.1 Xcodeでプロジェクトを開く

```bash
open ios/Runner.xcworkspace
```

#### 2.2 Build Configurationsの追加

1. Xcodeのプロジェクトナビゲーターで `Runner` プロジェクトを選択
2. `Info` タブを開く
3. `Configurations` セクションを展開
4. 以下のBuild Configurationsを追加（`+` ボタンで既存設定を複製）:
   - `Debug-dev` (Debugを複製)
   - `Debug-prod` (Debugを複製)
   - `Release-dev` (Releaseを複製)
   - `Release-prod` (Releaseを複製)
   - `Profile-dev` (Profileを複製)
   - `Profile-prod` (Profileを複製)

#### 2.3 各Build Configurationへのxcconfigファイルの割り当て

`Configurations` セクションで、各Build Configurationに対応するxcconfigファイルを割り当てます：

- **Debug-dev** → `Flutter/Debug-dev.xcconfig`
- **Debug-prod** → `Flutter/Debug-prod.xcconfig`
- **Release-dev** → `Flutter/Release-dev.xcconfig`
- **Release-prod** → `Flutter/Release-prod.xcconfig`
- **Profile-dev** → `Flutter/Profile-dev.xcconfig`
- **Profile-prod** → `Flutter/Profile-prod.xcconfig`

#### 2.4 Run Scriptの追加

1. `Runner` ターゲットを選択
2. `Build Phases` タブを開く
3. `+` ボタンをクリック → `New Run Script Phase` を選択
4. 新しいRun Scriptフェーズの名前を「Copy GoogleService-Info.plist」に変更
5. スクリプト欄に以下を入力：

```bash
"${PROJECT_DIR}/Runner/copy-googleservice-info.sh"
```

1. このフェーズを「Compile Sources」の**前**にドラッグ移動

#### 2.5 Schemesの作成

既存の「Runner」スキームを複製して、dev/prod用のスキームを作成します：

1. メニューバーから `Product` → `Scheme` → `Manage Schemes...` を選択
2. 「Runner」スキームを選択し、歯車アイコン → `Duplicate` をクリック
3. 新しいスキームの名前を「dev」に変更
4. `Edit Scheme...` で各アクションの Build Configuration を以下に変更：
   - Run: Debug-dev
   - Test: Debug-dev
   - Profile: Profile-dev
   - Analyze: Debug-dev
   - Archive: Release-dev
5. 同様に「prod」スキームを作成し、Build Configuration を以下に変更：
   - Run: Debug-prod
   - Test: Debug-prod
   - Profile: Profile-prod
   - Analyze: Debug-prod
   - Archive: Release-prod

### 3. ビルド確認

#### Flutter CLIからのビルド

```bash
# Dev環境でビルド
flutter build ios --flavor dev --debug

# Prod環境でビルド
flutter build ios --flavor prod --release
```

#### Xcodeからのビルド

1. Xcodeで適切なスキーム（dev または prod）を選択
2. ターゲットデバイスを選択
3. `Cmd + R` でビルド＆実行

## トラブルシューティング

### GoogleService-Info.plistが見つからないエラー

以下を確認してください：

1. `ios/GoogleService-Info-dev.plist` と `ios/GoogleService-Info-prod.plist` が存在するか
2. ファイル名が正確に一致しているか（大文字小文字を含む）
3. Run Scriptフェーズが正しく設定されているか

### Bundle Identifierの競合

各環境のBundle Identifierが異なることを確認してください：

- Dev: `net.sumomo_planning.go_shop.dev`
- Prod: `net.sumomo_planning.goshopping`

両方のBundle IdentifierをFirebase Consoleで登録する必要があります。

### CocoaPodsのエラー

Build Configurationsを追加した後、Podfile を更新する必要がある場合があります：

```bash
cd ios
pod install
```

## ファイル構成

```
ios/
├── GoogleService-Info-dev.plist          # Dev環境用Firebase設定（gitignore対象）
├── GoogleService-Info-prod.plist         # Prod環境用Firebase設定（gitignore対象）
├── GoogleService-Info-dev.plist.template # Dev環境用テンプレート
├── Flutter/
│   ├── Debug-dev.xcconfig                # Dev環境用Debug設定
│   ├── Debug-prod.xcconfig               # Prod環境用Debug設定
│   ├── Release-dev.xcconfig              # Dev環境用Release設定
│   ├── Release-prod.xcconfig             # Prod環境用Release設定
│   ├── Profile-dev.xcconfig              # Dev環境用Profile設定
│   └── Profile-prod.xcconfig             # Prod環境用Profile設定
└── Runner/
    └── copy-googleservice-info.sh        # Firebase設定ファイルコピースクリプト
```

## 参考情報

- [Flutter Flavors Documentation](https://flutter.dev/docs/deployment/flavors)
- [Xcode Build Configurations](https://developer.apple.com/documentation/xcode/adding-a-build-configuration-file-to-your-project)
- [Firebase iOS Setup](https://firebase.google.com/docs/ios/setup)
