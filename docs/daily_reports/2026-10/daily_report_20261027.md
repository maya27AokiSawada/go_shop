# 開発日報 - 2026年10月27日

## 📅 本日の目標

- [x] ビルド `1.2.0+47` 向けの開発に入る
- [x] iOS（TestFlight）でもプレオープン特典の案内を表示する

---

## ✅ 完了した作業

### 1. バージョンを `1.2.0+47` に更新 ✅

**Purpose**: ビルド46は内部テストにリリース済みのため、+47 向けの開発に入る。

**Solution**:

- `pubspec.yaml` の `version` を `1.2.0+47` に、`AGENTS.md` の「現在のビルド目標バージョン」も `1.2.0+47` に更新した。
- 各プラットフォームの生成ファイル（`android/local.properties`、`ios/Flutter/Generated.xcconfig`、`windows/flutter/ephemeral/generated_config.cmake`）は次回ビルド時に pubspec から再生成される（gitignore 対象）。

**Note**: 三点メニューのバージョン情報が +45 と表示されていた件を調査した。表示は `PackageInfo.fromPlatform()` で取得しており、ハードコードはない。10/26 にアップロードした AAB の versionCode は 46 で正しかったため、端末側が旧版（+45）のままだったと考えられる。

---

### 2. iOS でもプレオープン特典の案内を表示 ✅

**Purpose**: iOS は課金開始前のため `PurchasePlanPanel` を非表示にしており、その中にある「プレオープン特典を利用中」の案内も出ていなかった。TestFlight 版でも Android と同じく案内を出す。課金関連の UI はまだ出さない。

**Solution**:

- 特典の案内を `PreOpenBenefitNotice`（`lib/widgets/settings/pre_open_benefit_notice.dart`）に共通化した。Android の `PurchasePlanPanel` はこれを使い、見た目と動きは変わらない。
- `PreOpenBenefitPanel` を追加した。`PurchasePlanPanel.isAvailable` が `false` の環境（iOS の課金開始前。TestFlight を含む）で、設定画面に特典の案内だけを表示する。特典の対象外なら何も表示しない（余白も残さない）。購入ボタンなど課金関連の UI は含めない。
- `instructions/50_user_and_settings.md` に表示ルールを追記した。

**Modified Files**:

- `lib/widgets/settings/pre_open_benefit_notice.dart`（新規）
- `lib/widgets/settings/purchase_plan_panel.dart`、`lib/pages/settings_page.dart`
- `instructions/50_user_and_settings.md`

**Status**: ✅ 実装済み（`flutter analyze` で新たな指摘なし。実機確認は未実施）

---

### 3. 既存ユーザーへのプレオープン特典の付与を確認 ✅

- 特典の判定はサインアップ時だけでなく、起動時とサインイン状態の変化時に毎回行っている（`preOpenBenefitProvider`）。
- 判定はアカウント作成日（Firebase Auth の `metadata.creationTime`）で行うため、+45 以前にアカウントを作成したユーザーも対象になる。Functions で Firestore にフラグを付ける必要はない。
- ただし特典の処理は +46 以降に入っているため、旧版のままのユーザーには効かない。アップデートした時点で自動的に Premium 相当になる。

---

## 🔄 継続・確認事項

- TestFlight 版（+47）で、特典対象のアカウントの設定画面に案内だけが出て、購入ボタンなどが出ないことを確認する。
- 内部テスト版で、三点メニューのバージョン情報が実際にインストールしたビルド番号と一致することを確認する。
