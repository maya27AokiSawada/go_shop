# QR招待 Deep Link 実装計画

**作成日**: 2026-04-28
**状態**: 📋 計画中
**目的**: QRコード招待をDeep Link URL化し、未インストール時のアプリインストール→自動グループ参加を実現する

---

## 📋 現状分析

### 課題

| 項目                     | 現状                                                | 問題                          |
| ------------------------ | --------------------------------------------------- | ----------------------------- |
| QRコード内容             | JSON埋め込み（`encodeQRData()`がJSONを返す）        | 一般QRリーダーで開けない      |
| `deep_link_service.dart` | MethodChannelベース・ネイティブ実装なし・未呼び出し | 事実上未使用                  |
| `AndroidManifest.xml`    | App Links用 `intent-filter` なし                    | 深リンクが機能しない          |
| Firebase Hosting         | `firebase.json` に `hosting` 節なし                 | assetlinks.jsonを配信できない |
| iOS                      | `Runner.entitlements` ファイルなし                  | Universal Linksが機能しない   |

### 関連ファイル（既存）

- `lib/services/qr_invitation_service.dart` — `encodeQRData()` / `decodeQRData()` / `createQRInvitationData()`
- `lib/services/invite_code_service.dart` — `generateInviteText()` 招待テキスト生成
- `lib/services/deep_link_service.dart` — 既存DeepLinkサービス（MethodChannel、未使用）
- `lib/widgets/accept_invitation_widget.dart` — QRスキャン→`decodeQRData()`→`acceptQRInvitation()` のUI
- `android/app/src/main/AndroidManifest.xml`
- `lib/main.dart` — `MaterialApp`（`navigatorKey` なし）

### 既存QRフロー（現状）

```
[招待者] createQRInvitationData() → Firestoreに保存
         ↓ encodeQRData() → JSON文字列
         ↓ QrImage ウィジェットで表示
[受諾者] アプリ内スキャナーでQRをスキャン
         ↓ accept_invitation_widget.dart
         ↓ decodeQRData(jsonString) → Firestoreから詳細取得
         ↓ acceptQRInvitation()
```

---

## 🎯 実装目標

**ターゲット**: Android + iOS
**Deep Linkドメイン**: `goshopping-48db9.web.app`（Firebase Hosting）
**URL形式**: `https://goshopping-48db9.web.app/invite?invitationId=XXX&key=YYY&groupId=ZZZ`
**Deferred Deep Link**: Android = Play Install Referrer API、iOS = クリップボード検出
**除外**: Firebase Dynamic Links（2025年8月シャットダウン済みのため不使用）

---

## 🚀 実装計画

### Phase 1: QRコード URL 生成対応

**目的**: QRコードにHTTPS URLを埋め込み、一般QRリーダーで開けるようにする

**変更ファイル**: `lib/services/qr_invitation_service.dart`

1. `encodeQRData()` の出力をHTTPS URLに変更
   - 変更前: `jsonEncode({invitationId, sharedGroupId, securityKey, type, version})`
   - 変更後: `https://goshopping-48db9.web.app/invite?invitationId=XXX&key=YYY&groupId=ZZZ`

2. `decodeQRData()` に**URL形式の解析を追加**（後方互換：JSON形式も引き続き受け付け）
   - 入力が `https://` で始まる場合 → URLクエリパラメータを解析
   - それ以外 → 既存のJSON解析ロジック（`version 3.0 / 3.1`）を継続

3. `lib/services/invite_code_service.dart` の `generateInviteText()` にURL情報を追記

---

### Phase 2: Firebase Hosting ランディングページ（Phase 3と並行可）

**目的**: assetlinks.json / apple-app-site-association を配信し、招待ランディングページを提供する

**新規ファイル**:

| ファイル                                     | 内容                                               |
| -------------------------------------------- | -------------------------------------------------- |
| `web/.well-known/assetlinks.json`            | Android App Links 検証用（パッケージ名 + SHA-256） |
| `web/.well-known/apple-app-site-association` | iOS Universal Links 検証用（Team ID + Bundle ID）  |
| `web/invite.html`                            | 招待ランディングページ                             |

**`firebase.json` 変更点**:

- `hosting` セクション追加（`public: "web"`, `/invite` へのrewrite）
- `.well-known/` ファイルのContent-Type設定（`application/json`）

**`web/invite.html` 仕様**:

- URLパラメータ（`invitationId`, `key`, `groupId`）から招待情報を表示
- **インストール済み**: App Links / Universal Linksで自動処理。フォールバックとしてカスタムスキームボタン
- **未インストール (Android)**: `?referrer=invitationId%3D...` 付きPlay StoreへリダイレクトURL
- **未インストール (iOS)**: App StoreへのリンクDL + クリップボードに招待URLをコピー

⚠️ **事前作業（手動）**: 実装前にユーザーが以下を取得すること:

- Android: debug / release キーストアの SHA-256 フィンガープリント
- iOS: Apple Team ID（Apple Developer Consoleから取得）
- Google Play App Signing有効の場合: Play Consoleから「App Signing certificate」のSHA-256も追加

---

### Phase 3: Android App Links設定（Phase 2と並行可）

**変更ファイル**: `pubspec.yaml`, `android/app/src/main/AndroidManifest.xml`

1. `pubspec.yaml` に `app_links: ^6.4.0` を追加

2. `AndroidManifest.xml` の `<activity>` に以下のintent-filterを追加:

```xml
<intent-filter android:autoVerify="true">
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data android:scheme="https"
          android:host="goshopping-48db9.web.app"
          android:pathPrefix="/invite" />
</intent-filter>
```

---

### Phase 4: iOS Universal Links設定（Phase 2と並行可）

**新規・変更ファイル**: `ios/Runner/Runner.entitlements`, `ios/Runner/Info.plist`

1. `ios/Runner/Runner.entitlements` 新規作成:
   - `com.apple.developer.associated-domains`: `applinks:goshopping-48db9.web.app`

2. `ios/Runner/Info.plist` にカスタムスキームフォールバック追加（`CFBundleURLSchemes`）

3. Xcodeでentitlementsファイルをプロジェクトに関連付け（手動作業）

---

### Phase 5: Deep Link ハンドリング（Phase 3・4完了後）

**目的**: アプリ起動時・フォアグラウンド時にDeep Linkを受信して招待処理に繋ぐ

**変更ファイル**: `lib/services/deep_link_service.dart`, `lib/main.dart`

1. `deep_link_service.dart` を `app_links` パッケージベースに書き換え
   - `AppLinks().uriLinkStream` でフォアグラウンド時のリンクを受信
   - `AppLinks().getInitialAppLink()` でアプリ起動リンクを取得
   - URL解析: `invitationId` / `key` / `groupId` を抽出し、`accept_invitation_widget.dart` の既存フローに渡す
   - **既存の `acceptQRInvitation()` を直接再利用**（重複実装しない）

2. `lib/main.dart` の `AppInitializeWidget` 内で `DeepLinkService.initialize(context, ref)` を呼び出し

---

### Phase 6: Deferred Deep Link（Phase 5完了後）

**目的**: アプリ未インストール時に「インストール後に招待を自動処理」する

**新規ファイル**: `lib/services/deferred_deep_link_service.dart`

#### Android — Play Install Referrer

1. `pubspec.yaml` に `play_install_referrer: ^2.0.0` を追加

2. `deferred_deep_link_service.dart` の `checkDeferredDeepLink()`:
   - `InstallReferrer.referrerDetails` でinstall referrerを取得
   - referrerに `invitationId` が含まれていれば認証完了後に招待処理
   - `SharedPreferences` に `deferred_deeplink_checked: true` を保存（1回のみ実行）

#### iOS — Clipboard Fallback

1. 同ファイルにiOS分岐を追加:
   - `Clipboard.getData(Clipboard.kTextPlain)` でクリップボードを確認
   - `goshopping-48db9.web.app/invite?` を含む場合は確認ダイアログを表示

2. `lib/main.dart` で認証完了後（`authStateProvider` が `User` を返した直後）に `DeferredDeepLinkService.check(context, ref)` を呼び出し

---

## 📁 変更ファイル一覧

| ファイル                                       | 変更内容                                                         |
| ---------------------------------------------- | ---------------------------------------------------------------- |
| `lib/services/qr_invitation_service.dart`      | `encodeQRData()` をURL出力に変更、`decodeQRData()` にURL解析追加 |
| `lib/services/invite_code_service.dart`        | `generateInviteText()` にURL情報を追加                           |
| `lib/services/deep_link_service.dart`          | `app_links` パッケージベースに書き換え                           |
| `lib/services/deferred_deep_link_service.dart` | ✨ 新規作成（Play Install Referrer + iOS Clipboard）             |
| `android/app/src/main/AndroidManifest.xml`     | intent-filter追加                                                |
| `ios/Runner/Runner.entitlements`               | ✨ 新規作成（Associated Domains）                                |
| `ios/Runner/Info.plist`                        | `CFBundleURLSchemes` 追加                                        |
| `web/.well-known/assetlinks.json`              | ✨ 新規作成                                                      |
| `web/.well-known/apple-app-site-association`   | ✨ 新規作成                                                      |
| `web/invite.html`                              | ✨ 新規作成                                                      |
| `firebase.json`                                | `hosting` セクション追加                                         |
| `pubspec.yaml`                                 | `app_links`, `play_install_referrer` 追加                        |
| `lib/main.dart`                                | `DeepLinkService` / `DeferredDeepLinkService` 初期化追加         |

---

## ✅ 検証手順

1. `firebase deploy --only hosting` 後、`https://goshopping-48db9.web.app/.well-known/assetlinks.json` に直接アクセスして内容確認

2. Google Digital Asset Links API で検証:

   ```
   https://digitalassetlinks.googleapis.com/v1/statements:list?source.web.site=https://goshopping-48db9.web.app&relation=delegate_permission/common.handle_all_urls
   ```

3. App Links動作確認（Android実機・インストール済み）:

   ```bash
   adb shell am start -a android.intent.action.VIEW -d "https://goshopping-48db9.web.app/invite?invitationId=TEST&key=TEST&groupId=TEST"
   ```

4. Play Install Referrer テスト:

   ```bash
   adb shell am broadcast -a com.android.vending.INSTALL_REFERRER \
     --es referrer "invitationId%3DTEST%26key%3DTEST%26groupId%3DTEST" \
     net.sumomo_planning.goshopping
   ```

5. iOS実機でSafariから招待URLを開いてUniversal Links動作確認

---

## ⚠️ 実装前の手動作業

| 作業                     | コマンド / 手順                                                                                                               |
| ------------------------ | ----------------------------------------------------------------------------------------------------------------------------- |
| debug SHA-256取得        | `keytool -list -v -keystore %USERPROFILE%\.android\debug.keystore -alias androiddebugkey -storepass android -keypass android` |
| release SHA-256取得      | `keytool -list -v -keystore android/app/upload-keystore.jks -alias <alias>`                                                   |
| Play App Signing SHA-256 | Play Console > アプリの完全性 > App Signing certificate                                                                       |
| Apple Team ID取得        | Apple Developer Console > Membership または Xcode > Signing & Capabilities                                                    |
| 作業                     | コマンド / 手順                                                                                                               |
| ---                      | ---                                                                                                                           |
| debug SHA-256取得        | `keytool -list -v -keystore %USERPROFILE%\.android\debug.keystore -alias androiddebugkey -storepass android -keypass android` |
| release SHA-256取得      | `keytool -list -v -keystore android/app/upload-keystore.jks -alias <alias>`                                                   |
| Play App Signing SHA-256 | Play Console > アプリの完全性 > App Signing certificate                                                                       |
| Apple Team ID取得        | Apple Developer Console > Membership または Xcode > Signing & Capabilities                                                    |
