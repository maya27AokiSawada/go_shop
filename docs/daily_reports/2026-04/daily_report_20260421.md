# 開発日報 - 2026年04月21日

## 📅 本日の目標

- [x] Tailscale SSH 経由でリモート Mac への接続を確立する
- [x] Mac (mac-mini) で Flutter iOS ビルドを成功させる
- [x] Xcode 26 で iOS ビルドターゲットが認識されない問題を修正する

---

## ✅ 完了した作業

### 1. Tailscale SSH によるリモート Mac 接続環境の構築 ✅

**Purpose**: Windows (maya-note) から Mac (mac-mini) へ SSH 接続し、iOS ビルドをリモート実行できる環境を確立する

**Background**:
iOS ビルドは macOS + Xcode 環境が必須のため、Tailscale VPN で接続した Mac (mac-mini) に SSH してビルドを実行する構成を採用した。

**Problem / Root Cause**:

Windows の OpenSSH Agent サービスが無効（`Disabled`）になっていたため、SSH 接続のたびにパスフレーズ入力が求められていた。

```powershell
# ❌ 修正前：サービスが無効
Status: Stopped, StartType: Disabled
```

**Solution**:

管理者 PowerShell でサービスを有効化・起動し、SSH キーを登録した。

```powershell
# ✅ 修正後
Set-Service ssh-agent -StartupType Automatic
Start-Service ssh-agent
ssh-add ~/.ssh/id_ed25519
```

**検証結果**:

| 確認項目                           | 結果                     |
| ---------------------------------- | ------------------------ |
| `ssh mayafatima@100.68.26.88` 接続 | 成功（パスフレーズ不要） |
| Mac 側プロジェクトパス確認         | `~/go_shop` を確認済み   |
| `future` ブランチ同期              | 成功                     |

**Status**: ✅ 完了

---

### 2. Xcode 26 で iOS ビルドターゲットが表示されない問題の修正 ✅

**Purpose**: `flutter build ios` 実行時に `Unable to find a destination matching { generic:1, platform:iOS }` エラーが発生する問題を解消する

**Background**:

commit `28516c4`（ユーザーが手動実行）で `project.pbxproj` から iOS 向けの設定を削除したことにより、プロジェクト全体の `SDKROOT` が未設定になった。Xcode 26 では `SDKROOT = iphoneos` が明示されていないと macOS ターゲットしか認識しないため、iOS デスティネーションが一覧に表示されなくなった。

```
# ❌ エラーメッセージ
Unable to find a destination matching { generic:1, platform:iOS }
  - macOS (platform:macOS)
```

**Root Cause**:

`ios/Runner.xcodeproj/project.pbxproj` のプロジェクトレベル build configuration 9 セクション（Debug / Debug-dev / Debug-prod / Release / Release-dev / Release-prod / Profile / Profile-dev / Profile-prod）すべてに `SDKROOT = iphoneos;` が欠落していた。

```
// ❌ 修正前（各セクションに SDKROOT が存在しない）
isa = XCBuildConfiguration;
buildSettings = {
    TARGETED_DEVICE_FAMILY = "1,2";
    ...
```

**Solution**:

9 つの build configuration セクションそれぞれに `SDKROOT = iphoneos;` を追加した。

```
// ✅ 修正後
isa = XCBuildConfiguration;
buildSettings = {
    SDKROOT = iphoneos;
    TARGETED_DEVICE_FAMILY = "1,2";
    ...
```

**Modified Files**:

- `ios/Runner.xcodeproj/project.pbxproj` — 9 セクションに `SDKROOT = iphoneos;` を追加

**Commit**: `4d38f67`
**Status**: ✅ 完了・iOS ビルド成功で確認済み

---

### 3. Mac 上の CocoaPods 未インストール問題の解消 ✅

**Purpose**: `pod install` が実行できず Flutter iOS ビルドが中断する問題を解消する

**Problem / Root Cause**:

Mac (mac-mini) に CocoaPods がインストールされていなかったため、`flutter build ios` 実行時に以下のエラーが発生した。

```
CocoaPods not installed. Skipping pod install.
CocoaPods not installed or not in valid state.
```

**Solution**:

SSH 経由で `brew install cocoapods` を実行し、CocoaPods 1.16.2 をインストールした。

```bash
ssh mayafatima@100.68.26.88 "/opt/homebrew/bin/brew install cocoapods"
```

**検証結果**:

| 確認項目                          | 結果                 |
| --------------------------------- | -------------------- |
| `/opt/homebrew/bin/pod --version` | `1.16.2`             |
| `brew list cocoapods`             | インストール済み確認 |

**Status**: ✅ 完了

---

### 4. SSH 経由 Flutter iOS ビルドの PATH 問題修正と成功 ✅

**Purpose**: SSH コマンド内で `flutter` と `pod` が見つからない問題を解消し、iOS ビルドを成功させる

**Background**:

SSH 非インタラクティブセッションでは Mac の `.zshrc` が読み込まれないため、Homebrew パスが `$PATH` に含まれない。さらに PowerShell から SSH コマンドを実行する際、`$PATH` が Windows 側の PATH に展開されるという問題も重なった。

**Problem / Root Cause**:

```powershell
# ❌ PowerShell が $PATH を Windows 側で展開してしまう
ssh ... "export PATH=/opt/homebrew/bin:$PATH && flutter build ios ..."
# → Mac側に届くとき $PATH はWindowsのPATHになっている
```

**Solution**:

PowerShell のバッククォートで `$PATH` をエスケープし、Mac のシェルで展開されるようにした。また `flutter` フルパスの代わりに PATH に追加する方式に統一した。

```powershell
# ✅ 修正後：バッククォートで $PATH をエスケープ
ssh ... "export PATH=/opt/homebrew/bin:/opt/homebrew/share/flutter/bin:`$PATH && export LANG=en_US.UTF-8 && cd ~/go_shop && flutter build ios --flavor prod --no-codesign"
```

**検証結果**:

```
Warning: Building for device with codesigning disabled.
Building com.oneness-as.goshopping for device (ios-release)...
Running pod install...                                             25.0s
Running Xcode build...
Xcode build done.                                           315.5s
✓ Built build/ios/iphoneos/Runner.app (66.1MB)
```

| ビルドフェーズ | 所要時間  |
| -------------- | --------- |
| pod install    | 25.0 秒   |
| Xcode build    | 315.5 秒  |
| 合計（概算）   | 約 5.7 分 |
| 出力サイズ     | 66.1 MB   |

**Status**: ✅ 完了・ビルド成功確認済み

---

## 🐛 発見された問題

### SDKROOT 欠落による Xcode 26 iOS デスティネーション消失 ✅

- **症状**: `flutter build ios --flavor prod` で `Unable to find a destination matching { generic:1, platform:iOS }` エラー
- **原因**: `project.pbxproj` の全プロジェクトレベル build configuration から `SDKROOT = iphoneos;` が欠落
- **対処**: 9 セクション全てに `SDKROOT = iphoneos;` を追加（commit `4d38f67`）
- **状態**: 修正完了 ✅

---

## 📊 バグ対応進捗

### 完了 ✅

1. ✅ Xcode 26 iOS デスティネーション消失（完了日: 2026-04-21）
2. ✅ iOS prod Bundle Identifier 不整合（完了日: 2026-04-20）

### 翌日継続 ⏳

- ⏳ iOS 実機デプロイ・コードサイニング設定（`--no-codesign` を外して実機インストール確認）

---

## 💡 技術的学習事項

### 1. Xcode 26 での `SDKROOT = iphoneos` 必須化

**問題パターン**:

Xcode 26 では、プロジェクトレベルの build configuration に `SDKROOT` が明示されていないと iOS ターゲットが認識されず、macOS ターゲットのみ表示される。

**正しいパターン**:

```
// project.pbxproj の各 XCBuildConfiguration セクション
buildSettings = {
    SDKROOT = iphoneos;    // ← 必須
    TARGETED_DEVICE_FAMILY = "1,2";
    ...
```

**教訓**: Xcode 大型バージョンアップ後に iOS ビルドが通らない場合は、`project.pbxproj` 全セクションの `SDKROOT` を確認する。

---

### 2. PowerShell から SSH コマンド内の変数エスケープ

**問題パターン**:

```powershell
# PowerShell が $PATH をWindows側のPATHに展開してしまう
ssh user@host "export PATH=/opt/homebrew/bin:$PATH && ..."
```

**正しいパターン**:

```powershell
# バッククォートでエスケープ → Mac側のシェルで展開される
ssh user@host "export PATH=/opt/homebrew/bin:`$PATH && ..."
```

**教訓**: PowerShell の SSH コマンド文字列内でシェル変数を使う場合は、必ず `` ` `` でエスケープする。

---

### 3. SSH 非インタラクティブセッションの PATH 問題

**教訓**: SSH でコマンドを実行する場合、`.zshrc` / `.bashrc` は読み込まれない。Homebrew ツール（`flutter`, `pod` 等）はフルパス指定か、コマンド内で `export PATH=...` を先頭に追加する必要がある。

---

## 🗓 翌日（2026-04-22）の予定

1. iOS 実機コードサイニング設定（証明書・プロビジョニングプロファイル確認）
2. `flutter build ipa --flavor prod` によるアーカイブビルド確認
3. 必要に応じて TestFlight 配信フローの確認

---

## 📝 ドキュメント更新

| ドキュメント | 更新内容                                                                                                                                            |
| ------------ | --------------------------------------------------------------------------------------------------------------------------------------------------- |
| （更新なし） | 理由: 今日の作業は iOS ビルド環境整備（Xcode 設定修正・CocoaPods 導入・SSH 設定）であり、アプリアーキテクチャ・機能仕様・テスト戦略に変更はないため |
