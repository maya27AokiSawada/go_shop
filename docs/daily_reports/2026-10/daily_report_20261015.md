# 開発日報 - 2026年10月15日

## 📅 本日の目標

- [x] iOS の `flutter build ipa` が署名エラーで失敗する原因を調べる
- [ ] iOS 版（prod）の IPA をビルドする
- [ ] Mac で iOS 版を確認し、App Store にリリースする

---

## ✅ 完了した作業

### 1. iOS IPA ビルドの署名エラー調査 ✅

**Purpose**: `flutter build ipa --release --flavor prod --dart-define=FLAVOR=PROD` が失敗する原因を特定する。

**Problem**:

- アーカイブ時に次のエラーが出て、`Failed to build iOS app` になった。
  - `No Accounts: Add a new account in Accounts settings.`
  - `No profiles for 'net.sumomo-planning.goshopping' were found`（iOS App Development のプロビジョニングプロファイルが無い）

**Investigation**:

- Xcode のアカウント一覧が空だった（`DVTDeveloperAccountManagerAppleIDLists` が空）。
- プロビジョニングプロファイルがローカルに無かった（`~/Library/MobileDevice/Provisioning Profiles` と `~/Library/Developer/Xcode/UserData/Provisioning Profiles` のどちらも空）。
- キーチェーンには `Apple Development` と `Apple Distribution`（Team `9A34XAPY8W`）の証明書がある。
- プロジェクト設定は正常だった（`DEVELOPMENT_TEAM = 9A34XAPY8W`、署名は Automatic、Bundle ID は `net.sumomo-planning.goshopping`）。
- 10/08 のビルド43は同じコマンドで成功しており、その後に Xcode からサインアウトされたか、プロファイルのキャッシュが消えたと考えられる。

**Cause**: 署名が Automatic のため、Xcode はアカウントでログインして Apple からプロファイルを取得する。アカウントが空でプロファイルも無いので、取得できずに失敗した。設定ファイルの問題ではなく、このマシンの署名環境の問題。

**Solution（対処手順・未実施）**:

1. Xcode → Settings → Accounts に、Team `9A34XAPY8W` のメンバーの Apple ID を追加する。
2. `open ios/Runner.xcworkspace` で開き、Runner ターゲットの Signing & Capabilities で Team を選んでエラーが消えることを確認する。
3. 次のコマンドで再ビルドする。
   `flutter build ipa --release --flavor prod --dart-define=FLAVOR=prod --export-method app-store`

**Status**: ✅ 原因の特定まで完了。Apple ID のサインインと再ビルドは未実施。

---

## 🔄 継続・確認事項

- **Xcode へのサインイン（要対応）**: アカウントを追加してから IPA を再ビルドする。サインイン後も同じエラーが出る場合は、新しいログで再調査する。
- **`--export-method app-store`**: アーカイブ時の署名は開発用のままで、Distribution プロファイルへの切り替えは export 時に行われる。ビルド43と同様に付ける。
- **2ステップ方式**: `instructions/90_testing_and_ci.md` の `xcodebuild -archive` → `-exportArchive` は Distribution 証明書が不足している場合の回避策。今回の原因（アカウントが空）には効かない。
- **SSH 経由のビルド**: キーチェーンの unlock が必要。
- **前日からの持ち越し**: ビルド44の Play ストアコンソールへのリリース、iOS 版の確認と App Store へのリリース、GCP の組織ポリシー（`goshopping-48db9`）を元に戻す作業、dev Functions の再デプロイ。

---

## 📝 メモ

- コードの変更はなし。`pubspec.yaml` のバージョンは 1.2.0+44 のまま。
- `pubspec.lock` の変更と、スクリーンショット画像の削除は今回の作業ではないため、コミットに含めていない。
