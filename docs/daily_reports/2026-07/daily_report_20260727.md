# 開発日報 - 2026年07月27日

## 📅 本日の目標

- [x] Play Store Billing Library バージョンアップ対応
- [x] ビルド番号カウントアップ + IPA / AAB ビルド
- [x] iOS 実機（iPhone 17e）デプロイ
- [x] QR 招待エラーの調査・修正
- [x] Firestore rules デプロイ（prod プロジェクト）

---

## ✅ 完了した作業

### 1. Play Store Billing Library 8.0 対応 ✅

**Purpose**: Google Play の警告に対応し、Billing Library を最新版に更新する

**Background**: Google が Billing Library 7.1.1 → 8.0.0 へのアップグレードを要求

**Solution**:

```yaml
# ❌ Before
in_app_purchase: ^3.2.0   # → in_app_purchase_android 0.4.0+10 (BL 7.1.1)

# ✅ After
in_app_purchase: ^3.3.0   # → in_app_purchase_android 0.5.2 (BL 8.0.0)
```

**副作用確認**: `queryPurchaseHistory`、`ProrationMode`、`enablePendingPurchases` の破壊的変更は本プロジェクトでは使用しておらず影響なし。

**Modified Files**:

- `pubspec.yaml`（in_app_purchase: ^3.3.0、version: 1.1.0+19）

**Commit**: `7b61ae7`
**Status**: ✅ 完了

---

### 2. IPA / AAB ビルド ✅

**Purpose**: ビルド番号 18 → 19 でストア提出用バイナリを作成

**検証結果**:
| 成果物 | サイズ | ビルド番号 | Bundle ID |
|---|---|---|---|
| `*.ipa` | 51.5 MB | 19 | com.oneness-as.goshopping |
| `app-prod-release.aab` | 78.4 MB | 19 | com.oneness-as.goshopping |

**Status**: ✅ 完了・コミット済み

---

### 3. iOS 実機デプロイ（iPhone 17e / iOS 26.5.2）✅

**Purpose**: USB 接続した実機でアプリを動作確認する

**Background**: 初回接続のため DDI（Developer Disk Image）が未インストールの状態だった

**Problem / Root Cause**:

```
Error: The developer disk image could not be mounted on this device.
→ ddiServicesAvailable: false
→ ~/Library/Developer/Xcode/iOS DeviceSupport/ に 26.5.2 (23F84) が存在しなかった
```

**Solution**:

1. Xcode を起動し、Devices & Simulators ウィンドウで接続 → DDI 自動ダウンロード開始
2. ダウンロード完了後、`iPhone18,5 26.5.2 (23F84)` が DeviceSupport に追加
3. debug モードは Dart VM Service が接続できないため（iOS 26 + USB の相性問題）、**release モードで** `xcrun devicectl device install` + `xcrun devicectl device process launch` を使用してインストール・起動

**Modified Files**:

- なし（シンボリックリンク `build/ios/iphoneos → Release-prod-iphoneos` は一時的。`.gitignore` 対象）

**Status**: ✅ リリースモードで起動確認済み

---

### 4. QR 招待バグ修正 ✅

**Purpose**: QR スキャン後の招待受諾が常に「グループへの参加に失敗しました」で失敗していた問題を調査・修正する

**Background**: `acceptQRInvitation` が内部例外を握りつぶして `false` を返すため、実際のエラー原因が見えなかった

**Problem / Root Cause**:

```dart
// ❌ 問題のあったコード（2箇所）

// (1) inviterUid の unsafe cast — null なら TypeError でクラッシュ
final inviterUid = invitationData['inviterUid'] as String;

// (2) 内部例外を握りつぶして false を返す
} catch (e) {
  Log.error('QR招待受諾エラー: $e');
  await ErrorLogService.logOperationError('QR招待受諾', '$e');
  return false;  // 実際のエラーが呼び出し元に伝わらない
}
```

**Solution**:

```dart
// ✅ 修正後のコード

// (1) null-safe cast + 明示的チェック
final inviterUid = invitationData['inviterUid'] as String?;
if (inviterUid == null || inviterUid.isEmpty) {
  Log.error('❌ [ACCEPT] inviterUid が null または空 - invitationData: ${invitationData.keys.toList()}');
  throw Exception('招待者の情報が取得できません（inviterUid不足）');
}

// (2) rethrow で実際のエラーを呼び出し元に伝播
} catch (e, stackTrace) {
  Log.error('QR招待受諾エラー: $e');
  await ErrorLogService.logOperationError('QR招待受諾', '$e', stackTrace);
  rethrow;  // ← 呼び出し元の ErrorHandler.handleAsync がキャッチしてSnackBarに表示
}
```

**影響範囲**: `acceptQRInvitation` の呼び出し元は全て `ErrorHandler.handleAsync` でラップ済みのため問題なし。

**Modified Files**:

- `lib/services/qr_invitation_service.dart`

**Status**: ✅ 完了

---

### 5. Firestore rules デプロイ（prod）✅

**Purpose**: `notifications` コレクションへの書き込みが permission-denied になる問題を修正する

**Background**: prod Firebase プロジェクトの Firestore rules が古いバージョンのままで、`notifications.create` のルールが restrictive だった

**Root Cause**:

- prod プロジェクト ID が `.firebaserc` で `go-shopping-61515`（削除済み / 旧）になっていた
- 実際の prod プロジェクトは `goshopping-48db9`（`google-services.json` / `GoogleService-Info-prod.plist` が指す）
- Firebase CLI が旧プロジェクトにデプロイしようとして失敗していた
- iOS アプリは `GoogleService-Info-prod.plist` を優先読み込みし、Flutter の `firebase_options.dart`（`go-shopping-61515`）は `duplicate-app` 例外で素通りされる

**Solution**:

1. `.firebaserc` の prod エイリアスを `go-shopping-61515` → `goshopping-48db9` に修正
2. `firebase use prod && firebase deploy --only firestore:rules` でデプロイ完了

**Modified Files**:

- `.firebaserc`（prod プロジェクト ID 修正）

**Status**: ✅ デプロイ完了

---

## 🐛 発見された問題

### `firebase_options.dart` のプロジェクト ID が古い ⚠️

- **症状**: `firebase_options.dart` の prod セクションが `go-shopping-61515`（旧）を参照
- **原因**: プロジェクト移行時に `firebase_options.dart` が更新されなかった
- **影響**: iOS では `GoogleService-Info-prod.plist` が優先されるため実害なし。ただし将来的に混乱の恐れあり
- **状態**: 未修正（次回 `flutterfire configure` で更新推奨）

### iOS 実機での debug モード不可 ⚠️

- **症状**: `flutter run`（debug モード）で Dart VM Service が 60 秒後にタイムアウト
- **原因**: iPhone 17e (iOS 26.5.2) + USB での Dart VM 接続が不安定（新 CoreDevice 経由の debug プロトコル問題の可能性）
- **対処**: release モードで実機インストール・起動（`xcrun devicectl` を直接使用）
- **状態**: ログ確認不可だが機能テストは可能

---

## 📊 バグ対応進捗

### 完了 ✅

1. ✅ QR 招待受諾エラーが汎用メッセージで隠蔽される（完了: 2026-07-27）
2. ✅ inviterUid の unsafe null cast（完了: 2026-07-27）
3. ✅ Firestore rules 未デプロイによる notifications permission-denied（完了: 2026-07-27）

### 翌日継続 ⏳

- ⏳ `firebase_options.dart` の prod プロジェクト ID を `goshopping-48db9` に更新

---

## 💡 技術的学習事項

### iOS 26 + Xcode 26: DDI の自動ダウンロード

**問題パターン**: 初回接続の iOS デバイスに DDI が未インストール → `ddiServicesAvailable: false`

**確認方法**:

```bash
xcrun devicectl device info details --device <UDID> | grep ddiServices
# → ddiServicesAvailable: false なら未インストール
ls ~/Library/Developer/Xcode/iOS\ DeviceSupport/
# → 対象 iOS バージョンのフォルダがあればインストール済み
```

**教訓**: DDI のダウンロードは Xcode の Devices & Simulators ウィンドウを開いてデバイスを接続することでトリガーされる。コマンドラインからは `devicectl` に DDI インストールサブコマンドが存在しない。

---

### `acceptQRInvitation` の例外ハンドリングパターン

**問題パターン**: サービス層でキャッチして `false` を返すと、UI 層が実際のエラー原因を知れない

```dart
// ❌ NG — エラーを握りつぶす
} catch (e) {
  return false;
}
```

**正しいパターン**: 呼び出し元が `ErrorHandler.handleAsync` でラップ済みの場合は `rethrow` する

```dart
// ✅ 推奨 — 呼び出し元に伝播させる
} catch (e, stackTrace) {
  Log.error('エラー: $e');
  await ErrorLogService.logOperationError(..., '$e', stackTrace);
  rethrow;
}
```

**教訓**: サービス層の例外ハンドリングは「ログ → rethrow」が基本。`false` を返す形式は呼び出し元でのデバッグを困難にする。

---

### Firebase prod プロジェクト確認手順

iOS では `GoogleService-Info-prod.plist` が `firebase_options.dart` より先に読まれ、Flutter 側の初期化は `duplicate-app` で素通りされる。プロジェクト ID の確認は以下で行う：

```bash
# 実際に使われているプロジェクト
grep PROJECT_ID ios/GoogleService-Info-prod.plist  # iOS prod
grep project_id android/app/google-services.json   # Android prod

# .firebaserc と一致しているか確認
cat .firebaserc
```

**教訓**: `firebase_options.dart` のプロジェクト ID が古くても iOS の動作に影響しない場合がある。しかし混乱を避けるため定期的に `flutterfire configure` で同期すること。

---

## 🗓 翌日（2026-07-28）の予定

1. `firebase_options.dart` を `goshopping-48db9` に更新（`flutterfire configure --project goshopping-48db9`）
2. QR 招待フローの end-to-end テスト（iPhone 17e で招待受諾が成功するか確認）
3. debug モード接続問題の調査継続（必要であれば Wi-Fi デバッグを試す）

---

## 📝 ドキュメント更新

| ドキュメント                              | 更新内容                                                                           |
| ----------------------------------------- | ---------------------------------------------------------------------------------- |
| `instructions/40_qr_and_notifications.md` | `acceptQRInvitation` の rethrow パターン、Firebase prod プロジェクト確認手順を追記 |
