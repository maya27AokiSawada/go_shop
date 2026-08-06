# AGP 9 アップグレード計画

## 1. 背景

Android Gradle Plugin (AGP) のバージョン9へのアップグレードを行い、最新のAndroidビルドシステムに対応する。

## 2. 現状分析

- **AGPバージョン管理**: `dev.flutter.flutter-gradle-plugin` により、Flutter SDKバージョンと連動して自動管理されている。
- **Gradleバージョン**: `8.14` (AGP 9 の要件 `8.8+` を満たしている)
- **Javaバージョン**:
    - JDK: ビルド実行には `JDK 17` 以上が必要。
    - ソース互換性: `Java 11`
- **依存プラグイン**:
    - `com.google.gms.google-services`: `4.4.4` (公式ドキュメントにないバージョン。最新版への更新を推奨)

## 3. アップグレード計画

### ステップ1: Flutterバージョンの特定

プロジェクトが使用している正確なFlutter SDKバージョンを特定する。`.fvmrc` が存在するため、FVM (Flutter Version Management) を通じてバージョンを確認する。

```sh
fvm flutter --version
```

### ステップ2: 互換性の調査

ステップ1で特定したFlutterバージョンと、AGP 9との互換性を調査する。AGP 9をサポートするFlutterのバージョンが公式にリリースされているか（stable, beta, masterチャンネルを含め）を確認する。

### ステップ3: Flutter SDKのアップグレード

AGP 9と互換性のあるFlutterバージョンが見つかった場合、FVMを利用してプロジェクトのSDKをアップグレードする。

### ステップ4: 関連ライブラリの更新

AGP 9および新しいFlutter SDKとの互換性を確保するため、以下のライブラリを更新する。

- **`android/build.gradle.kts`**:
  - `com.google.gms.google-services` プラグインを最新の互換バージョン (例: `4.4.2`) に更新する。
- **`android/app/build.gradle.kts`**:
  - `com.google.firebase:firebase-bom` を最新版に更新する。
- その他、ビルドエラーが発生した場合は、関連する依存関係を適宜更新する。

### ステップ5: ビルドと検証

すべての変更を適用した後、以下のコマンドでクリーンビルドを実行し、アプリの動作を検証する。

```sh
flutter clean
flutter pub get
flutter run android
```
