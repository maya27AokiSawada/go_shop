# 開発日報 - 2026年5月5日

## 📅 本日の目標

- [x] Bundle ID の確認
- [x] iOS 実機（iPhone 17e）へのインストール成功
- [ ] macOS Firebase Auth keychain-error 解決（次回継続）

---

## ✅ 完了した作業

### 1. Bundle ID 確認 ✅

**Purpose**: 各プラットフォームの Bundle ID を整理し、不整合を把握する

**調査結果**:

| プラットフォーム | Flavor        | Bundle ID                         |
| ---------------- | ------------- | --------------------------------- |
| Android          | prod          | `net.sumomo_planning.goshopping`  |
| Android          | dev           | `net.sumomo_planning.go_shop.dev` |
| iOS              | prod          | `com.oneness-as.goshopping`       |
| iOS              | dev           | `net.sumomo_planning.go_shop.dev` |
| macOS            | prod/dev 共通 | `com.oneness-as.goshopping`       |

**判明した不整合**:

- Android prod と iOS/macOS prod で Bundle ID が異なる
  - Android: `net.sumomo_planning.goshopping`
  - iOS/macOS: `com.oneness-as.goshopping`
- macOS に dev/prod の flavor 切り替えがない（`AppInfo.xcconfig` にハードコード）
- `GoogleService-Info.plist` の `BUNDLE_ID` は `com.oneness-as.goshopping` で macOS 設定と一致 ✅

**Status**: ✅ 確認完了（不整合は把握済み・即時対応不要）

---

### 2. iOS 実機（iPhone 17e）インストール成功 ✅

**Purpose**: iPhone 17e 実機でアプリの動作確認を行う

**Background**: 今まで Android 実機と iOS シミュレータのみで検証していた。iPhone 17e（iOS 26.4.2）を新たに実機テスト環境として追加。

**問題と解決の流れ**:

#### 問題1: No valid code signing certificates

```
Error: No development certificates available to code sign app for device deployment
```

**Solution**: Xcode → Settings → Accounts で Apple ID（fatima.yatomi@outlook.com）をサインインし、Development Certificate を生成。`ios/Runner.xcworkspace` を開いて Runner ターゲットの Signing & Capabilities で Team を設定。

---

#### 問題2: キーチェーンアクセスダイアログが繰り返し表示される

`codesign がキーチェーンに含まれるキー"Apple Development: SHINYA KANAGAE"へアクセスしようとしています`

**Solution**: ダイアログで「**常に許可**」を選択。証明書ファイルが複数あるため数回表示されるが、すべて「常に許可」にすることで以後表示されなくなる。

---

#### 問題3: Dart VM Service が発見されず起動タイムアウト

```
The Dart VM Service was not discovered after 60 seconds.
Error launching application on 金ヶ江真也のiPhone 17e.
```

**Solution**:

1. iPhone の `設定 → プライバシーとセキュリティ → デベロッパモード` をオン
2. iPhone を再起動
3. `設定 → 一般 → VPNとデバイス管理` で証明書を「信頼」
4. `flutter run --flavor prod -d 00008150-000114CC3E33401C` を再実行

**検証結果**: アプリ起動成功・基本動作 OK

**実行コマンド**:

```bash
flutter run --flavor prod -d 00008150-000114CC3E33401C
```

**Modified Files**:

- `ios/Runner.xcodeproj/project.pbxproj` （Development Team・Signing 設定追加）
- `ios/Runner.xcodeproj/xcshareddata/xcschemes/dev.xcscheme` （スキーム更新）
- `ios/Runner.xcodeproj/xcshareddata/xcschemes/prod.xcscheme` （スキーム更新）
- `ios/Podfile.lock` （Pod 依存関係更新）

**Status**: ✅ 完了・実機動作確認済み

---

## 🐛 発見された問題

### macOS Firebase Auth keychain-error ⚠️（昨日から継続）

- **症状**: `signInWithEmailAndPassword` 実行時に `[firebase_auth/keychain-error]` が発生しサインイン失敗
- **原因**: macOS が ad-hoc 署名（`CODE_SIGN_IDENTITY = "-"`）のため Team ID が存在せず、keychain アクセス権が付与されない（`-34018 errSecMissingEntitlement`）
- **対処**: 未着手
- **状態**: 調査中

**次回試す対策**:

1. Apple Developer Team ID を `AppInfo.xcconfig` に設定
2. Xcode で Keychain Sharing を有効化
3. `com.apple.security.application-groups` entitlement 追加

---

## 📊 バグ対応進捗

### 完了 ✅

1. ✅ iOS 実機インストール（完了日: 2026-05-05）
2. ✅ macOS ビルドエラー修正（完了日: 2026-05-04）
3. ✅ Firestore LevelDB LOCK 競合回避策確立（完了日: 2026-05-04）

### 対応中 🔄

1. 🔄 macOS Firebase Auth keychain-error（Priority: High）

### 翌日継続 ⏳

- ⏳ macOS Firebase Auth keychain-error 根本解決
- ⏳ macOS dev/prod flavor 切り替え追加

---

## 💡 技術的学習事項

### iOS 実機デプロイに必要な手順（まとめ）

1. Xcode に Apple ID をサインイン（無料アカウントでも可）
2. `ios/Runner.xcworkspace` で Team を設定・証明書自動生成
3. iPhone の「デベロッパモード」をオン（iOS 16以降必須）
4. キーチェーンダイアログは「**常に許可**」を選択
5. iPhone の `VPNとデバイス管理` で証明書を「信頼」
6. `flutter run --flavor prod -d <デバイスID>`

**注意**: 無料 Apple ID の場合、証明書有効期限は 7日間。

---

## 指示書更新

なし（iOS デプロイ手順は運用知識であり、アーキテクチャ・仕様変更なし）
