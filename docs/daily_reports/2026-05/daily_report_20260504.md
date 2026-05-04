# 開発日報 - 2026年5月4日

## 📅 本日の目標

- [x] macOS デスクトップサポートの有効化
- [x] macOS ビルドエラーの修正
- [ ] Firebase Auth サインイン成功（keychain-error 未解決）

---

## ✅ 完了した作業

### 1. macOS ビルドエラー修正 ✅

**Purpose**: Flutter アプリを macOS デスクトップで動作させる

**Background**: `flutter run --debug --flavor prod -d macos` 実行時にビルドエラーが複数発生。

**問題1: `keychain-access-groups` Entitlement エラー**

```
Code Sign error: The signature for the bundle contains a disqualified entitlement
```

**Solution**: `macos/Runner/DebugProfile.entitlements` から `com.apple.security.keychain-access-groups` entitlement を削除。

---

**問題2: `useUserAccessGroup` API が存在しない**

```
error: The method 'useUserAccessGroup' isn't defined for the type 'FirebaseAuth'
```

firebase_auth 6.4.0 では `useUserAccessGroup` は廃止されており、代わりに `setSettings(userAccessGroup: '')` を使用する必要がある。

**Solution**:

```dart
// lib/main.dart / lib/main_prod.dart
if (defaultTargetPlatform == TargetPlatform.macOS) {
  try {
    await FirebaseAuth.instance.setSettings(userAccessGroup: '');
    AppLogger.info('✅ macOS: setSettings 設定完了');
  } catch (e) {
    AppLogger.warning('⚠️ macOS: setSettings エラー（無視）: $e');
  }
}
```

**Modified Files**:
- `lib/main.dart`
- `lib/main_prod.dart`
- `macos/Runner/DebugProfile.entitlements`

**Status**: ✅ ビルド成功

---

### 2. Firestore LevelDB LOCK 競合問題の回避策確立 ✅

**Problem**: macOS アプリ起動時に Firestore がロックファイルを取得できずクラッシュ。

```
Failed to create leveldb cache: IO error: lock /Users/mayafatima/Library/Application Support/
firestore/__FIRAPP_DEFAULT/goshopping-48db9/main/LOCK: already held by process
```

**Root Cause**: 前回起動したアプリプロセスが終了せずにロックファイルを保持し続けている。

**Workaround** (起動前に毎回実行):

```bash
pkill -9 -f "goshopping" 2>/dev/null
rm -f "/Users/mayafatima/Library/Application Support/firestore/__FIRAPP_DEFAULT/goshopping-48db9/main/LOCK" 2>/dev/null
rm -f /Users/mayafatima/Documents/hive_db/*.lock 2>/dev/null
cd /Users/mayafatima/go_shop && flutter run --debug --flavor prod -d macos
```

**Status**: ✅ 回避策確立（Firestore接続成功確認）

---

## 🔴 未解決の問題

### Firebase Auth keychain-error

**症状**: ログイン画面でメールアドレス＋パスワードを入力してサインインボタンを押すと以下エラーが発生。

```
[firebase_auth/keychain-error] An error occurred when accessing the keychain.
The NSLocalizedFailureReasonErrorKey field in the NSError.userInfo dictionary
will contain more information about the error encountered
```

**原因分析**: macOS の keychain-error (-34018 = `errSecMissingEntitlement`) はアプリが適切な keychain アクセス権を持っていないことを示す。`setSettings(userAccessGroup: '')` 自体もこのエラーを返すが try/catch で無視している。`signInWithEmailAndPassword` 呼び出し時も同エラーが発生しサインイン失敗。

**試した対策**:
1. ❌ `keychain-access-groups` entitlement 追加 → ビルドエラーになったため削除
2. ❌ `setSettings(userAccessGroup: '')` → setSettings自体もkeychain-errorを返す（エラー無視で回避）

**次回試す対策**:
1. Xcodeでアプリを直接開いて「Keychain Sharing」機能を有効化
2. `com.apple.security.application-groups` entitlement 追加
3. `flutter build macos --debug --flavor prod` でXcodeビルドログを詳細確認
4. macOS コンソール.app で `NSLocalizedFailureReasonErrorKey` の詳細を確認
5. firebase_auth macOS の GitHub Issues を確認

---

## 📊 本日の進捗サマリー

| 項目 | 状態 |
|------|------|
| macOS ビルド成功 | ✅ |
| Firestore 接続成功 | ✅ |
| Firebase Auth サインイン | ❌ keychain-error |
| .gitignore に secrets/ 追加 | ✅ |

---

## 🔧 環境情報

- Flutter: macOS desktop flavor=prod
- Firebase Auth: 6.4.0
- macOS Signing: `CODE_SIGN_IDENTITY = "-"` (ad-hoc)
- App Sandbox: false
- Branch: `future`
