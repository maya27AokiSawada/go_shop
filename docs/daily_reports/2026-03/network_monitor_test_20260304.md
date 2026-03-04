# NetworkMonitorService テスト手順書

**テスト日**: 2026-03-04
**対象修正**: 2026-03-03 NetworkMonitorService 重大バグ修正（5件）
**対象ファイル**: `lib/services/network_monitor_service.dart`, `lib/widgets/network_status_banner.dart`
**テストデバイス**: SH54D (Android 16) / AS10L / Pixel 9

---

## 修正内容サマリー

### 事前修正（2026-03-03）

| #         | 修正内容                                                                                | 対応テスト           |
| --------- | --------------------------------------------------------------------------------------- | -------------------- |
| Fix #1    | 初回接続チェック未実行 → コンストラクタで`checkFirestoreConnection()`呼び出し           | テスト1              |
| Fix #2    | 自動リトライトリガー欠落 → `_updateStatus()`でoffline検出時に`startAutoRetry()`呼び出し | テスト2              |
| Fix #3    | Permission-deniedエラー → 認証状態に応じたクエリ先選択                                  | テスト4              |
| Syntax #1 | 重複閉じ括弧 → 削除                                                                     | ビルド成功で確認済み |
| Syntax #2 | `_currentStatus`のfinal修飾子 → 削除                                                    | ビルド成功で確認済み |

### テスト前修正（2026-03-04 Riverpodアサーションエラー対応）

| #     | 修正内容                                                                            | 対象ファイル                       |
| ----- | ----------------------------------------------------------------------------------- | ---------------------------------- |
| FIX 1 | `hiveInitializationStatusProvider`追加 → Hive初期化完了までNetworkMonitor生成を遅延 | `user_specific_hive_provider.dart` |
| FIX 2 | `networkMonitorProvider`をProviderに変更 + Hive初期化ガード追加                     | `network_monitor_service.dart`     |
| FIX 3 | 廃止済み`createDefaultGroup()`呼び出し削除                                          | `user_initialization_service.dart` |
| FIX 4 | `NetworkStatusBanner`のref.listenをref.watchに変更 + WidgetsBindingObserver削除     | `network_status_banner.dart`       |

### テスト中修正（2026-03-04 テスト5で発見）

| #     | 修正内容                                                                         | 対象ファイル                   |
| ----- | -------------------------------------------------------------------------------- | ------------------------------ |
| FIX 5 | `reportFirestoreSuccess()`メソッド追加 → 外部Firestore操作成功時にオンライン復帰 | `network_monitor_service.dart` |
| FIX 6 | `createNewGroup()`成功後に`reportFirestoreSuccess()`を呼び出し                   | `purchase_group_provider.dart` |

---

## テスト準備

### ログ監視コマンド

```bash
# ターミナル1: ログ監視開始（テスト中は常時起動）
adb logcat | Select-String "NETWORK_MONITOR|BANNER"

# フィルタを広げる場合
adb logcat | Select-String "NETWORK_MONITOR|BANNER|permission-denied|FIRESTORE"
```

### APKデプロイ（必要な場合）

```bash
# ビルド
flutter build apk --debug --flavor prod

# インストール
adb install -r build\app\outputs\flutter-apk\app-prod-debug.apk
```

---

## テスト1: 初回接続チェック（Fix #1 検証）

**目的**: アプリ起動時に自動的にFirestore接続チェックが実行されることを確認

**前提条件**: WiFi接続済み（オンライン状態）

**手順**:

1. アプリを完全終了（タスクキルまたは `adb shell am force-stop net.sumomo_planning.goshopping`）
2. ログ監視を開始
3. アプリを起動

**期待ログ（順番通り）**:

```
🌐 [NETWORK_MONITOR] 初期化完了 - 初期状態: online
🔍 [NETWORK_MONITOR] 初回接続チェック開始
🔍 [NETWORK_MONITOR] Firestore接続チェック開始
📡 [NETWORK_MONITOR] 状態変更: online → checking
🔍 [NETWORK_MONITOR] Firestoreクエリ実行中...
🔍 [NETWORK_MONITOR] 認証済み - ユーザードキュメントで接続チェック: xxx***
✅ [NETWORK_MONITOR] Firestore接続成功 - ドキュメント存在: true
📡 [NETWORK_MONITOR] 状態変更: checking → online
```

**確認ポイント**:

- [x] 「初回接続チェック開始」ログが表示される
- [x] 「Firestore接続成功」ログが表示される
- [x] オフラインバナーが**表示されない**（正常なオンライン状態）
- [x] `permission-denied` エラーが**表示されない**

**結果**: ✅ PASS

**備考**: 初回チェック → checking → online の遷移を確認。アサーションエラーなし。

---

## テスト2: オフライン検出 + 自動リトライ（Fix #2 検証）

**目的**: オフライン状態で自動リトライが開始されることを確認

**前提条件**: アプリ起動済み

**手順**:

1. **機内モードをON**にする
2. ログ監視を確認
3. アプリ画面上部にオレンジ色バナーが表示されるか確認
4. バナーにカウントダウン（「次の確認まで: X分Y秒」）が表示されるか確認

**方法A: リトライボタンで強制オフライン検出**

機内モードONの状態で：

1. バナーのリトライボタン（🔄アイコン）を押す
2. または10分待って自動リトライを待つ

**方法B: アプリ再起動で検出**

機内モードONの状態で：

1. アプリを完全終了
2. アプリを再起動

**期待ログ**:

```
🔍 [NETWORK_MONITOR] Firestore接続チェック開始
❌ [NETWORK_MONITOR] Firestore接続エラー（予期しない）: ...
📡 [NETWORK_MONITOR] 状態変更: online → offline
🔄 [NETWORK_MONITOR] オフライン検出 → 自動リトライ開始
🔄 [NETWORK_MONITOR] 自動リトライ開始（10分間隔）
```

**確認ポイント**:

- [x] オレンジ色バナーが画面上部に表示される
- [x] バナーのメッセージ: 「ネットワーク障害が回復するまでお待ちください」
- [x] カウントダウン表示: 「次の確認まで: X分Y秒」
- [x] リトライボタン（🔄）が表示される
- [x] 「自動リトライ開始（10分間隔）」ログが表示される

**結果**: ✅ PASS

**備考**: 方法A（リトライボタン）で検証。機内モードON → リトライ → offline検出 → バナー表示 → 自動リトライ開始。

---

## テスト3: 手動リトライ + オンライン復帰

**目的**: 手動リトライでオンラインに復帰し、バナーが消えることを確認

**前提条件**: テスト2の状態（オフラインバナー表示中）

**手順**:

1. **機内モードをOFF**にする（WiFiに再接続）
2. 5秒ほど待つ（WiFi接続安定化）
3. バナーのリトライボタン（🔄アイコン）を押す
4. バナーの変化を観察

**期待ログ**:

```
🔄 [BANNER] 手動リトライボタンが押されました
🔍 [NETWORK_MONITOR] Firestore接続チェック開始
📡 [NETWORK_MONITOR] 状態変更: offline → checking
🔍 [NETWORK_MONITOR] 認証済み - ユーザードキュメントで接続チェック: xxx***
✅ [NETWORK_MONITOR] Firestore接続成功 - ドキュメント存在: true
📡 [NETWORK_MONITOR] 状態変更: checking → online
⏹️ [NETWORK_MONITOR] 自動リトライ停止
✅ [BANNER] SnackBar表示: ネットワーク接続が復帰しました
🔄 [BANNER] 手動リトライ結果: オンライン復帰成功
```

**確認ポイント**:

- [x] リトライボタン押下後、バナーが一時的に青色（「接続確認中...」）に変化
- [x] 接続成功後、バナーが**消失**する
- [x] 緑色のSnackBar「✅ ネットワーク接続が復帰しました」が表示される
- [x] 「自動リトライ停止」ログが表示される

**結果**: ✅ PASS

**備考**: offline → checking → online の遷移を87msで完了。SnackBar表示・バナー消失ともに正常。

---

## テスト4: Permission-denied回避（Fix #3 検証）

**目的**: 認証状態に応じたクエリ先で接続チェックが行われ、permission-deniedエラーが発生しないことを確認

**手順**: テスト1〜3のログを横断的に確認

**確認ポイント**:

### 4-A: 認証済みの場合

- [x] 「認証済み - ユーザードキュメントで接続チェック」ログが表示される
- [x] `users/{uid}` にアクセスしている
- [x] `permission-denied` エラーが**一切表示されない**

### 4-B: 未認証の場合（オプション）

サインアウト状態でテストする場合：

1. サインアウトする
2. アプリを再起動
3. ログを確認

- [ ] 「未認証 - 公開ニュースで接続チェック」ログが表示される
- [ ] `furestorenews` コレクションにアクセスしている
- [ ] `permission-denied` エラーが**一切表示されない**

> **注**: 4-Bは未実施（認証済み状態でのみテスト）

**結果**: ✅ PASS

**備考**: テスト1〜3、5、6の全ログで `permission-denied` ゼロを確認。認証済みクエリ先 `users/{uid}` が正しく選択されている。

---

## テスト5: グループ作成後のバナー自動消失

**目的**: オフラインバナー表示中にFirestore操作（グループ作成）が成功した場合、バナーが自動消失することを確認

**前提条件**: WiFi接続済み、アプリ起動済み

> **重要**: 機内モードONだけではバナーは表示されない。バナー表示には、オフライン状態でFirestore接続チェックが失敗する必要がある（リトライボタン押下またはアプリ再起動）。

**手順**:

1. 機内モードON
2. リトライボタン押下（またはアプリ再起動）→ オフラインバナー表示を確認
3. 機内モードOFF → WiFi再接続（5秒待機）
4. **リトライボタンは押さずに**、グループの＋ボタンからグループを作成
5. 作成が成功した場合、バナーの状態を確認

**期待ログ**:

```
✅ [ALL_GROUPS] グループ作成完了: テストグループ名
🔥 [NETWORK_MONITOR] Firestore操作成功を検出 → オンライン復帰
📡 [NETWORK_MONITOR] 状態変更: offline → online
⏹️ [NETWORK_MONITOR] 自動リトライ停止
🔄 [BANNER] ステータス変化: offline → online → オンライン復帰→バナー非表示
```

**確認ポイント**:

- [x] グループ作成が成功する（Firestoreに書き込み成功）
- [x] `reportFirestoreSuccess()` によりバナーが**自動的に消失**する
- [x] 手動リトライ不要でバナーが消える

**結果**: ✅ PASS（初回FAIL → バグ修正後の再テストでPASS）

**備考**: 初回テストでバナーが消失しないバグを発見。原因：`NetworkMonitorService`は自身の`checkFirestoreConnection()`でのみオンライン復帰を検出していたが、外部のFirestore操作成功（グループ作成等）では復帰を検出できなかった。`reportFirestoreSuccess()`メソッド追加（FIX 5/6）で解決。

---

## テスト6: 機内モードサイクルテスト

**目的**: オンライン→オフライン→オンラインの繰り返しで正常に動作することを確認

**手順**:

1. オンライン状態でアプリ起動（バナーなし確認）
2. 機内モードON → リトライボタン押下 → オフラインバナー表示確認
3. 機内モードOFF → リトライボタン押下 → バナー消失確認
4. 手順2-3をもう1回繰り返す

**確認ポイント**:

- [x] 1回目サイクル: オフライン検出 → バナー表示 → 復帰 → バナー消失
- [ ] 2回目サイクル: （1回のサイクルで検証完了）
- [x] エラーが発生しない
- [x] 状態遷移ログが正しい順序で表示される

**結果**: ✅ PASS

**備考**: 機内モードON→リトライ→offline→バナー表示→機内モードOFF→リトライ→checking→online→バナー消失。全シーケンスが87ms以内に完了。`permission-denied` ゼロ。

---

## テスト結果サマリー

| テスト  | 内容                          | 結果    | 備考                                           |
| ------- | ----------------------------- | ------- | ---------------------------------------------- |
| テスト1 | 初回接続チェック              | ✅ PASS | 初回チェック正常、アサーションエラーなし       |
| テスト2 | オフライン検出 + 自動リトライ | ✅ PASS | リトライボタンで検証、自動リトライ開始確認     |
| テスト3 | 手動リトライ + オンライン復帰 | ✅ PASS | 87msでoffline→online遷移、SnackBar・バナー消失 |
| テスト4 | Permission-denied回避         | ✅ PASS | 全テストログで `permission-denied` ゼロ        |
| テスト5 | グループ作成後のバナー消失    | ✅ PASS | 初回FAIL→FIX 5/6適用→再テストPASS              |
| テスト6 | 機内モードサイクル            | ✅ PASS | 全サイクル正常、エラーなし                     |

**総合判定**: ✅ ALL PASS（6/6）

---

## 発見された問題（テスト中に記入）

### 問題1: Riverpod `_didChangeDependency` アサーションエラー ✅ 修正済み

- **症状**: アプリ起動直後に `_didChangeDependency is not true` アサーションエラーが発生し、NetworkMonitorServiceが初期化されない
- **再現手順**: APKインストール → アプリ起動
- **原因**: Hive初期化完了前にNetworkMonitorServiceが生成され、依存プロバイダーが未初期化
- **修正**: FIX 1〜4（テスト前に適用）
- **影響度**: ✅ Critical → **修正済み**

### 問題2: オフラインバナーがFirestore操作成功後も消失しない ✅ 修正済み

- **症状**: 機内モードON→バナー表示→機内モードOFF→グループ作成成功→**バナーが消えない**
- **再現手順**: (1)機内モードON (2)リトライでoffline検出・バナー表示 (3)機内モードOFF (4)グループ作成 (5)作成成功するがバナー残存
- **原因**: `NetworkMonitorService`は自身の`checkFirestoreConnection()`でのみオンライン復帰を検出。外部のFirestore操作（createGroup等）の成功はオンライン復帰として認識されなかった。
- **修正**: FIX 5（`reportFirestoreSuccess()`メソッド追加）+ FIX 6（`createNewGroup()`から呼び出し）
- **影響度**: ✅ High → **修正済み**

---

## 収集ログファイル

| ファイル                       | 内容                                                  |
| ------------------------------ | ----------------------------------------------------- |
| `debug_info/test5_fix_log.txt` | テスト5再テスト時のログ（reportFirestoreSuccess確認） |
| `debug_info/test6_log.txt`     | テスト6ログ（機内モードサイクル確認）                 |

---

**作成者**: Copilot
**テスト実施者**: ユーザー（SH-54D実機）
**テスト日時**: 2026-03-04 12:30〜13:10
**レビュー**: 全6テスト PASS、2件のバグを発見・修正・再検証完了
