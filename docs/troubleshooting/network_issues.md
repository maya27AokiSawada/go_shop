# ネットワーク関連トラブルシューティング

このドキュメントは、GoShoppingアプリで発生するネットワーク関連の問題と解決方法をまとめたものです。

---

## 目次

1. [コミュファ光 5GHz WiFi 接続問題](#1-コミュファ光-5ghz-wifi-接続問題)
2. [一般的なFirestore接続問題](#2-一般的なfirestore接続問題)
3. [デバッグ方法](#3-デバッグ方法)

---

## 1. コミュファ光 5GHz WiFi 接続問題

### 概要

**ISP**: コミュファ光（CTC - Chubu Telecommunications Company）  
**発生条件**: 5GHz WiFi帯を使用している場合  
**症状**: リスト作成・グループ操作が極端に遅い（1-3秒以上）  
**発見日**: 2026年2月26日  
**確認デバイス**: Pixel 9

### 症状の詳細

#### ユーザーが体感する症状

- リスト作成ボタンを押してから反映まで数秒かかる
- グループ作成・削除が遅い
- アイテム追加が遅延する
- アプリ全体の動作が遅く感じる

#### 技術的な症状

**Android logcatで確認できるエラー**:

```
W Firestore: Caused by: java.net.UnknownHostException: Unable to resolve host "firestore.googleapis.com": 
             No address associated with hostname

W Firestore: Caused by: android.system.GaiException: android_getaddrinfo failed: EAI_NODATA 
             (No address associated with hostname)
```

**エラーの意味**:
- デバイスはWiFiに接続されている
- しかし`firestore.googleapis.com`のDNS解決ができない
- Firebase/Firestoreへの通信がタイムアウトする

### 根本原因

**コミュファ光の5GHz WiFi帯に特有のDNS設定問題**

- 5GHz帯と2.4GHz帯で異なるルーター設定が使用される
- 5GHz帯のDNSサーバーまたはIPv6設定に問題がある可能性
- firebaseドメインの名前解決が失敗する
- 2.4GHz帯では正常に動作する

**なぜ5GHz帯だけ問題が起きるのか**:

多くのルーターでは、異なる周波数帯で以下が異なる場合があります：
- DNSサーバー設定
- IPv6の有効/無効
- プライベートDNS設定
- ルーティングテーブル

### 解決方法

#### 解決策1: 2.4GHz WiFi帯に切り替え ✅ 推奨

**手順**:

1. Androidの設定を開く
2. 「ネットワークとインターネット」→「インターネット」
3. 現在接続中のWiFi（SSID名に"ctc"を含む）をタップ
4. 「詳細設定」→「自動接続」をオフにする
5. WiFi一覧から同じ名前の2.4GHz帯SSIDを選択
   - 通常、5GHz帯: `YourSSID-5G` または `YourSSID_A`
   - 通常、2.4GHz帯: `YourSSID-2G` または `YourSSID_G`
6. 接続後、アプリでリスト作成をテスト

**確認方法**:

リスト作成が0.1-0.3秒で完了することを確認。
- 以前: 1-3秒以上
- 修正後: 0.1-0.3秒 ✅

**ユーザー確認済み**: "リスト作成自体は切り替えてOKだったんです" (2026-02-26)

#### 解決策2: モバイルデータを使用

**手順**:

1. WiFiをオフにする
2. モバイルデータ（4G/5G）で接続
3. アプリが正常動作することを確認

**注意**: データ通信量が発生するため、WiFiルーター設定を優先的に確認してください。

#### 解決策3: プライベートDNS設定を変更

**手順**:

1. Androidの設定を開く
2. 「ネットワークとインターネット」→「インターネット」
3. 接続中のWiFiをタップ→「詳細設定」
4. 「プライベートDNS」を探す
5. 「自動」から「オフ」に変更
6. WiFiを再接続
7. アプリでテスト

**注意**: これにより他のサービスの動作に影響が出る可能性があります。

#### 解決策4: ISPに問い合わせ

**連絡先**: コミュファ光カスタマーサポート

**問い合わせ内容のテンプレート**:

```
5GHz WiFi帯使用時に特定のドメイン（firestore.googleapis.com）への
DNS解決が失敗します。

エラー: android.system.GaiException: EAI_NODATA
環境: Android端末、5GHz WiFi帯
症状: 2.4GHz帯では正常動作

5GHz帯のDNS設定またはIPv6設定を確認していただけますか？
```

### パフォーマンス比較

| 環境                         | リスト作成時間 | 体感速度 |
| ---------------------------- | -------------- | -------- |
| 5GHz WiFi（問題あり）       | 1-3秒以上      | 非常に遅い |
| 5GHz WiFi + コード最適化後  | 依然として遅い | 遅い      |
| 2.4GHz WiFi（修正後）       | 0.1-0.3秒      | ✅ 高速   |
| モバイルデータ               | 0.2-0.5秒      | ✅ 高速   |

**改善率**: 10-30倍の高速化 ✅

### 関連情報

**コミット**: e3b8041 - リスト操作の通知送信を非同期化（2026-02-26）

この最適化により、通知送信がUIをブロックしなくなりましたが、
5GHz WiFiのDNS問題による遅延は依然として発生していました。

**両方の修正が必要**:
- ✅ コード最適化（通知の非同期化）
- ✅ ネットワーク修正（2.4GHz WiFiへの切り替え）

---

## 2. 一般的なFirestore接続問題

### 症状: 同期アイコンが赤色（×マーク）

**可能性のある原因**:

1. **インターネット接続がない**
   - WiFi/モバイルデータがオフ
   - 電波が弱い
   - 機内モードがオン

2. **Firebaseサービスの障害**
   - Firebase Status Pageで確認: https://status.firebase.google.com/

3. **デバイス固有のDNS問題**
   - TBA1011のような特定デバイスで発生
   - プライベートDNS設定の問題

### 一般的な解決手順

#### ステップ1: 基本的な接続確認

1. 他のアプリ（ブラウザ等）でインターネット接続を確認
2. WiFi接続をオフ/オンして再接続
3. デバイスを再起動

#### ステップ2: ネットワーク切り替え

1. WiFi → モバイルデータに切り替え
2. 問題が解決すれば、WiFiルーターの問題
3. 問題が継続すれば、デバイスまたはFirebaseの問題

#### ステップ3: DNSキャッシュクリア

**Android**:

1. 設定 → アプリ → GoShopping
2. ストレージ → キャッシュをクリア
3. アプリを再起動

#### ステップ4: プライベートDNS設定確認

1. 設定 → ネットワークとインターネット
2. プライベートDNS → 「自動」または「オフ」に設定
3. WiFiを再接続

---

## 3. デバッグ方法

### Android Debug Bridge (adb) によるログ確認

**前提条件**:
- PCにAndroid Studio（またはadbツール）がインストールされている
- USBデバッグが有効
- デバイスがPCに接続されている

#### Firestoreエラーログの確認

```bash
# デバイスIDを確認
adb devices

# Firestoreエラーを抽出
adb -s <device-id> logcat -d | grep -i firestore

# または、PowerShellの場合
adb -s <device-id> logcat -d | Select-String -Pattern "(firestore|permission|denied|error)"
```

#### 具体例: コミュファ光問題の発見

```bash
adb -s adb-51040DLAQ001K0-JamWam._adb-tls-connect._tcp logcat -d | 
Select-String -Pattern "(permission|denied|firestore|error)" | 
Select-Object -Last 30
```

**発見されたエラー**:

```
W Firestore: Caused by: java.net.UnknownHostException: Unable to resolve host "firestore.googleapis.com"
W Firestore: Caused by: android.system.GaiException: android_getaddrinfo failed: EAI_NODATA
```

### アプリ内のデバッグ情報

#### 同期状態の確認

1. GoShoppingアプリを開く
2. 画面上部のAppBarを確認
3. 同期アイコンの色で判断:
   - 🟢 **緑色のチェック**: 正常同期
   - 🟠 **オレンジの回転**: 同期中
   - 🔴 **赤色の×**: 同期エラー

#### エラー履歴の確認

1. 設定ページを開く
2. 「エラー履歴を見る」ボタンをタップ
3. 最近発生したエラーを確認

---

## トラブルシューティングフローチャート

```
リスト作成が遅い
    ↓
他のアプリは正常？
    ↓ YES
WiFi接続中？
    ↓ YES
コミュファ光ユーザー？
    ↓ YES
5GHz WiFi帯を使用中？
    ↓ YES
→ 2.4GHz WiFi帯に切り替え ✅
    ↓
問題解決？
    ↓ YES
→ このドキュメントの「コミュファ光 5GHz WiFi 接続問題」参照

    ↓ NO（他のケース）
→ 「一般的なFirestore接続問題」参照
```

---

## サポート情報

### 問題が解決しない場合

1. **GitHub Issue**: https://github.com/maya27AokiSawada/go_shop/issues
2. **開発者への報告**:
   - デバイス名
   - Android バージョン
   - ISP名（わかれば）
   - WiFi環境（5GHz/2.4GHz）
   - logcat出力（可能であれば）

### 既知の問題デバイス

| デバイス  | Android | 問題           | 解決方法           | ステータス |
| --------- | ------- | -------------- | ------------------ | ---------- |
| TBA1011   | 15      | DNS解決失敗    | モバイルデータ使用 | 未解決     |
| Pixel 9   | -       | コミュファ光5G | 2.4GHz WiFiに切替  | ✅ 解決済  |

---

## 更新履歴

- **2026-02-26**: コミュファ光 5GHz WiFi 接続問題を追加（Pixel 9で発見・解決確認済み）
- **2026-02-10**: TBA1011 Firestore接続問題を記録

---

## 関連ドキュメント

- [README.md - Known Issues](../../README.md#known-issues-as-of-2026-02-26)
- [copilot-instructions.md - Known Issues](.github/copilot-instructions.md#known-issues-as-of-2026-02-26)
- [Test Checklist](../daily_reports/2026-02/test_checklist_20260226.md)
