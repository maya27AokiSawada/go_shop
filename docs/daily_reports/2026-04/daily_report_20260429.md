# 開発日報 - 2026年04月29日

## 📅 本日の目標

- [x] SH-54D ネットワーク障害の調査
- [x] Windows ビルドエラーの修正
- [x] 設定ページのシークレットモードUI除去

---

## ✅ 完了した作業

### 1. SH-54D ネットワーク障害調査 ✅

**Purpose**: SH-54DでFirestoreへの接続が失敗する問題の原因調査

**Problem / Root Cause**:

```
W Firestore: Stream closed with status: Status{code=UNAVAILABLE,
  description=Unable to resolve host firestore.googleapis.com,
  cause=java.net.UnknownHostException: No address associated with hostname
```

- Firestoreの gRPC クライアント（`DnsNameResolver` → `Inet6AddressImpl`）が IPv6 DNS 解決を先に試みるが失敗（`EAI_NODATA`）
- ルーター（IODATA-4b9024-2G, 192.168.0.1）が IPv6 アドレスを割り当てているものの IPv6 DNS サーバーを提供していない
- `ping` はIPv4フォールバックで成功するが、gRPCは IPv6 解決に失敗

**Solution**:

- アプリ再起動で一時回復を確認
- 根本対策: ルーターの IPv6 DNS 設定追加 or IPv6 無効化を推奨

**検証結果**: 調査時点で `ping firestore.googleapis.com` が成功（自己回復）、アプリ再起動で解消

**Status**: ✅ 完了（一時的に回復。ルーター設定は利用者対応）

---

### 2. Windows ビルドエラー修正（Firebase C++ SDK バージョン不一致） ✅

**Purpose**: `flutter run --debug -d windows` が失敗する問題の修正

**Problem / Root Cause**:

```
firebase_app_check_plugin.cpp(234,45): error C2039:
  'GetLimitedUseAppCheckToken': 'firebase::app_check::AppCheck' のメンバーではありません
```

- `build/windows/x64/extracted/` に古い Firebase C++ SDK **v12.x** がキャッシュされていた
- `firebase_app_check` プラグイン (v0.4.3) は Firebase C++ SDK **v13.5.0** の `GetLimitedUseAppCheckToken` を呼び出すため不一致

**Solution**:

```powershell
Remove-Item -Recurse -Force "build\windows\x64\extracted"
```

キャッシュ削除後に v13.5.0 が再ダウンロードされ、コンパイル成功。

**検証結果**: `✓ Built build\windows\x64\runner\Debug\go_shop.exe`

**Modified Files**:

- なし（ビルドキャッシュのクリアのみ）

**Status**: ✅ 完了・検証済み

---

### 3. 設定ページのシークレットモードUI除去 ✅

**Purpose**: 廃止済みのシークレットモード機能のUIを設定ページから削除

**Background**: シークレットモード（サインイン強制）機能は廃止済みだったが、UIが残存していた

**Solution**:

`lib/widgets/settings/privacy_settings_panel.dart` から以下を削除:

```dart
// ❌ 削除したコード
bool _isSecretMode = false;
_loadSecretMode()  // initStateで呼び出し
ElevatedButton.icon(...)  // シークレットモードトグルボタン
Text('シークレットモードをオンにすると...')  // 説明テキスト
const Divider(height: 24)
```

```dart
// ✅ 変更後: StatelessWidget に簡略化
class PrivacySettingsPanel extends StatelessWidget {
  // プライバシーポリシー・利用規約リンクのみ保持
}
```

**検証結果**: コンパイルエラーなし (`get_errors` で確認)

**Modified Files**:

- `lib/widgets/settings/privacy_settings_panel.dart` — シークレットモードUI削除、`ConsumerStatefulWidget` → `StatelessWidget`
- `instructions/50_user_and_settings.md` — ウィジェット構成表を更新

**Commit**: `cf2526d`
**Status**: ✅ 完了・検証済み

---

## 🐛 発見された問題

### IPv6 DNS 未提供によるFirestore 接続断（断続的）⚠️

- **症状**: Firestoreの gRPC 接続が `EAI_NODATA` で失敗（SH-54D）
- **原因**: WiFiルーターが IPv6 DNS サーバーを提供していない
- **対処**: アプリ再起動で一時回復。ルーターの IPv6 DNS 設定が根本対策
- **状態**: 暫定回復済み / ルーター設定は未対応

---

## 📊 バグ対応進捗

### 完了 ✅

1. ✅ Windows ビルドエラー（Firebase C++ SDK v12/v13 キャッシュ不一致）（完了日: 2026-04-29）
2. ✅ 設定ページ シークレットモードUI残存（完了日: 2026-04-29）

### 対応中 🔄

（なし）

### 翌日継続 ⏳

1. ⏳ ルーター IPv6 DNS 設定（利用者対応、開発者側では対応不可）

---

## 🔧 技術メモ

### Firebase C++ SDK キャッシュ問題

Windows ビルドで Firebase C++ SDK のバージョン不一致が起きた場合は以下で解消:

```powershell
Remove-Item -Recurse -Force "build\windows\x64\extracted"
flutter build windows --debug
```

### SH-54D IPv6 DNS 問題

- `ping` (ICMP) はIPv4フォールバックするが gRPC/DNS は IPv6 を優先
- Android の `Inet6AddressImpl` がIPv6 DNS 解決を先に試みる仕様
- プライベートDNS設定は `off` のため問題なし（ルーターDNSが原因）

---

## 📝 指示書更新

- `instructions/50_user_and_settings.md`: `privacy_settings_panel.dart` のウィジェット種別を `ConsumerStatefulWidget` → `StatelessWidget` に更新、役割説明からシークレットモード記述を削除

---

## コミット履歴

| ハッシュ  | メッセージ                                       |
| --------- | ------------------------------------------------ |
| `cf2526d` | refactor: 設定ページのシークレットモードUIを削除 |
