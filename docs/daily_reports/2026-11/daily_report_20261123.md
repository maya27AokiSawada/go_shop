# 開発日報 - 2026年11月23日

## 📅 本日の目標

- [x] iOS の `1.2.0+49` をリリースビルドする
- [x] Android の `1.2.0+49` を AAB でビルドする
- [x] App Store / Google Play のクローズドテストに申請する

---

## ✅ 完了した作業

### 1. iOS リリースビルド `1.2.0+49` ✅

- `pubspec.yaml` の `version`（`1.2.0+49`）が、AGENTS.md のビルド目標と一致していることを確認した。
- 次のコマンドで IPA を作成した（`build/ios/ipa/`、36.7MB）。自動署名で通り、2 ステップ方式は不要だった。

```bash
flutter build ipa --release --flavor prod --dart-define=FLAVOR=prod
```

- 提出ビルドに `IAP_SALES_OPEN` は付けていない。

### 2. Android AAB `1.2.0+49` ✅

- 次のコマンドで AAB を作成した（`build/app/outputs/bundle/prodRelease/app-prod-release.aab`、81.7MB）。

```bash
flutter build appbundle --release --flavor prod --dart-define=FLAVOR=prod
```

- AAB 内の versionCode が 49 であることは、`bundletool` では確認していない。

### 3. クローズドテストへ申請 ✅

- `1.2.0+49` を App Store（TestFlight）と Google Play の、いずれもクローズドテストに申請した。

---

## 📝 残った課題・メモ

- ビルド時に Kotlin 関連の警告が出ている（ビルドは成功）。
  - Kotlin 2.4.10 のサポートが近く終了する。
  - `cloud_functions`、`firebase_app_check`、`firebase_auth`、`firebase_core`、`firebase_crashlytics`、`sentry_flutter` が Kotlin Gradle Plugin を使っており、将来の Flutter ではビルドが失敗する。Built-in Kotlin への対応を検討する。
- iOS で、全プラグインが Swift Package 対応なのに CocoaPods 連携が残っている、という警告が出ている。Swift Package Manager 移行の扱いは、11/21 からの課題のまま。
- 審査やテストで再ビルドが必要になったら、`pubspec.yaml` と AGENTS.md のビルド目標を `+50` に上げる。
- 11/21 の課題（解約→失効の確認、年額プランの購入確認、App Check デバッグトークンの削除）は、引き続き残っている。
