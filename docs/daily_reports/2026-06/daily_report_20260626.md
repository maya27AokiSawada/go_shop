# 開発日報 - 2026年06月26日

## 📅 本日の目標

- [x] Mac 開発環境への切り替えと iOS pod 更新
- [ ] Windows QR 招待エンドツーエンドテスト（継続 → 翌日へ）
- [ ] iOS ビルド確認（Kotlin 変更の影響がないことを確認）

---

## ✅ 完了した作業

### 1. iOS Podfile.lock 更新（Mac 環境での pod install） ✅

**Purpose**: 2026-06-24 のパッケージバージョン bump に対応する iOS 側の依存関係を Mac 環境で最新化する

**Background**:

2026-06-24 に `pubspec.yaml` で以下のパッケージをアップグレードしたが、iOS 側の `Podfile.lock` は Windows 環境での古いバージョンのままだった。Mac 環境に切り替え後、`pod install` を実行することで iOS 側の依存関係が更新された。

**変更内容**:

| Pod                                                                       | 変更前                              | 変更後                                 |
| ------------------------------------------------------------------------- | ----------------------------------- | -------------------------------------- |
| `file_picker` path                                                        | `.symlinks/plugins/file_picker/ios` | `.symlinks/plugins/file_picker/darwin` |
| `google_mobile_ads`                                                       | 5.3.1                               | 9.0.0                                  |
| `Google-Mobile-Ads-SDK`                                                   | 11.13.0                             | 13.3.0                                 |
| `DKImagePickerController` / `DKPhotoGallery` / `SDWebImage` / `SwiftyGif` | 存在                                | 削除（file_picker v12 が依存不要に）   |

**Solution**:

`file_picker` v12 では iOS/macOS 統合 (`darwin`) パスに移行しており、画像選択の内部実装が変更されたため DKImagePickerController 関連の依存が完全に除去された。`google_mobile_ads` v9 では Google-Mobile-Ads-SDK が 11.x → 13.x へメジャーアップデートされた。

**Modified Files**:

- `ios/Podfile.lock` — file_picker darwin パス移行、google_mobile_ads 9.0.0、不要 pod 削除

**Status**: ✅ Podfile.lock 更新完了

---

### 2. 開発環境を Windows → Mac へ切り替え

**Purpose**: Mac 環境（M1 Mac）で Flutter 開発を継続するための環境セットアップ

**Background**:

Android IDE 設定ファイル (`android/.settings/org.eclipse.buildship.core.prefs`) が Windows の Gradle init script パスと Java home から Mac のパスに自動更新された。このファイルはマシン固有のため**コミット対象外**。

**変更内容**:

| 設定項目           | Windows                           | Mac                                           |
| ------------------ | --------------------------------- | --------------------------------------------- |
| Gradle init script | `C:\Users\fatim\AppData\...`      | `/var/folders/...` (Mac temp)                 |
| Java home          | `C:/Program Files/OpenJDK/jdk-21` | `/opt/homebrew/Cellar/openjdk@17/17.0.18/...` |

**Modified Files**:

- `android/.settings/org.eclipse.buildlib.core.prefs` — IDE 自動更新（未コミット・コミット不要）

**Status**: ✅ 環境切り替え完了

---

## 🐛 発見された問題

### java.home の JDK バージョン差異（Windows: 21 / Mac: 17）

- **症状**: Mac 環境で Gradle が OpenJDK 17 を使用（Windows では 21）
- **原因**: Mac に OpenJDK 21 が未インストール
- **対処**: Homebrew で `openjdk@17` を利用中。Flutter ビルドに支障がなければ現状維持
- **状態**: 調査中（影響があればアップグレード検討）

---

## 📊 バグ対応進捗

### 完了 ✅

1. ✅ Windows Firebase Auth `unknown-error` 修正（2026-06-24）
2. ✅ QR 招待 Firestore サイレント書き込み失敗修正（2026-06-24）
3. ✅ Kotlin 2.1.0→2.4.0 アップグレード + DSL 移行（2026-06-24）
4. ✅ Kotlin language version 1.6 未サポートエラー修正（2026-06-25）
5. ✅ iOS Podfile.lock 更新（file_picker v12、google_mobile_ads v9 対応）（2026-06-26）

### 翌日継続 ⏳

- ⏳ Windows QR 招待エンドツーエンドテスト
- ⏳ iOS ビルド確認（Kotlin 変更の影響チェック）
- ⏳ Mac 環境で Android ビルド確認（Java 17 で問題がないか検証）

---

## 💡 技術的学習事項

### file_picker v12 の iOS パス変更（`ios` → `darwin`）

file_picker v12 で iOS と macOS が統合 `darwin` プラグインに移行した。それに伴い DKImagePickerController / DKPhotoGallery / SDWebImage / SwiftyGif への依存がすべて除去された。

**変更前 (v8.x)**:

```ruby
# .symlinks/plugins/file_picker/ios を参照
# DKImagePickerController / DKPhotoGallery / SDWebImage / SwiftyGif が必要
file_picker (0.0.1):
  - DKImagePickerController/PhotoGallery
  - Flutter
```

**変更後 (v12.x)**:

```ruby
# .symlinks/plugins/file_picker/darwin を参照
# 不要な依存が除去された
file_picker (0.0.1):
  - Flutter
  - FlutterMacOS
```

**教訓**: file_picker の iOS パスが `ios` から `darwin` に変わったため、`pod install` 前に Podfile を確認する必要がある。Podfile の `file_picker` の参照先が古い場合は手動修正が必要になることがある。

---

## 🗓 翌日（2026-06-27）の予定

1. Mac 環境での Android ビルド確認（`flutter build apk --debug --flavor prod`）
2. iOS ビルド確認（`flutter build ios --debug --flavor prod`、シミュレーター or 実機）
3. Windows QR 招待エンドツーエンドテスト（Windows 機で実施）
4. Mac の Java バージョン確認（必要であれば OpenJDK 21 にアップグレード）

---

## 📝 ドキュメント更新

| ドキュメント | 更新内容                                                                   |
| ------------ | -------------------------------------------------------------------------- |
| （更新なし） | 理由: 今日の作業は環境セットアップ・pod 更新のみ。コード変更・設計変更なし |
