# 開発日報 - 2026年09月18日

## 📅 本日の目標

- [x] iOS ビルド36を内部テストに提出し、グループメンバー暗号化（[[Phase 2/3]] 実機復号バグ）の検証を行う
- [x] iPad mini 実機を USB 接続し `idevicesyslog` でトレースログを採取、原因を特定する
- [~] 修正の実装 → 未着手（引き継ぎ）
- [x] 本日の作業を日報にまとめて `sumomo-planning` へコミットする

---

## ✅ 完了した作業

### 1. iOS ビルド36 内部テストでグループ鍵ローテーション後の復号を確認 ⏸ 引き継ぎ

**Purpose**: `daily_report_20260909.md`（作業4）で未解決だった、グループメンバー
暗号化（Phase 3、書き込み暗号化 ON）実機での復号バグを、ビルド36の内部テストで再検証する。

**実施内容**: iOS 版ビルド36（`pubspec.yaml` を `1.1.0+34` → `1.1.0+36` に更新）を
内部テストに提出し、グループ鍵ローテーション後の挙動を確認した。

**結果**:

- ✅ **アイテム名の復号は成功**: 共有リストのアイテム（`SharedLists.items[].name`）は
  鍵ローテーション後も引き続き正しく復号され、UI に平文で表示される。
- ❌ **グループメンバーの復号は失敗**: `SharedGroups.members[].name` / `contact`
  （およびトップレベル `ownerName` / `ownerEmail`）は鍵ローテーション後、
  復号されずに暗号エンベロープ（Base64 文字列）のまま表示される。
  → `daily_report_20260909.md` に記録した「Phase 3 後の実機デバッグ（未解決・中断）」と
  同一症状。アイテム名側は正常なため、**グループ鍵の prime 経路・secret 導出周りに
  限定した問題**である可能性が高い（アイテム名と同じ暗号スキームの土台を共有しているため）。

**Status**: ✅ 症状再現を確認。原因特定は作業2で完了（下記）。

---

### 2. iPad mini 実機ログ採取によるグループメンバー復号バグの原因特定 ✅

**Purpose**: 作業1で再現した復号バグについて、`dd6c1218` で仕込んだ `🔎` トレースログ
（`GF_CFG` / `GF_PRIME` / `GF_DEC` / `GF_SECRET` / `GF_ENC`）を実機で採取し、
`daily_report_20260909.md` の仮説（read 経路で鍵が prime されていない）を検証する。

**手順**: テスト実施済みの iPad mini（金ヶ江真也のiPad (2)、iPad16,2、iOS 26.6.2）を
USB接続。Developer Mode が無効な状態だったため Xcode の実機コンソールは使えなかったが、
`idevicesyslog`（libimobiledevice、Developer Mode 不要）で OS 標準ログをストリーム採取し、
アプリを再起動してグループ詳細画面を開いた際のログ約 67 万行を回収、`🔎` マーカーで
3,126 件抽出した。

**判明した事実（グループ `a3f3e7c5_1788724125426` の例）**:

```
🔎 [GF_PRIME] groupId=a3f3e7c5_... keyLen=44        ← 現在の永続鍵は正しくロードできている
🔎 [GF_SECRET] keyLen=44 keyHead=JmJ5n5 ...          ← 新鍵での secret 導出（1回目）
🔎 [GF_SECRET] keyLen=0  keyHead= ...                ← 失敗 → 鍵なしへフォールバック（2回目）
🔎 [GF_DEC] FAIL groupId=a3f3e7c5_... err=FormatException: recipient secret does not match
```

→ `daily_report_20260909.md` の仮説（`GF_PRIME` が `keyLen=-1` で鍵が読めていない）は**誤り**。
鍵は正しく prime されているのに、その鍵で導出した secret では復号できていない。
つまり **暗号化時に使われた鍵と、現在復号に使っている鍵が一致していない**。

**Root Cause**: **グループ鍵ローテーション時、アイテム名は再暗号化されるがグループメンバー
情報は再暗号化されない非対称性**。

- [`hybrid_shared_list_repository.dart`](../../../lib/datastore/hybrid_shared_list_repository.dart)
  の `_reencryptAllItemsIfKeyChanged`（1248行目）が、`SharedPreferences` に保存した旧鍵の
  指紋（`group_key_fingerprint_v1:$groupId`）と現在の永続鍵を比較し、変化を検知すると
  全アイテムを「旧鍵で復号 → 新鍵で再暗号化」して Firestore に書き戻す。これが
  アイテム名がローテーション後も復号できる理由。
- [`group_key_exchange_service.dart`](../../../lib/services/group_key_exchange_service.dart)
  の `decryptGroupField`（950行目）には**この再暗号化・旧鍵フォールバックの仕組みが存在しない**。
  `rotateGroupKey` 実行後、Firestore 上の `members[].name/contact` は旧鍵の暗号文のまま残るが、
  復号は常に「現在の（新しい）永続鍵」でしか試みないため、鍵ローテーションが起きるたびに
  既存のメンバー情報が復号不能になる。フォールバック（`_deriveGroupFieldSecret(groupId: groupId)`、
  鍵なし＝旧々方式）も対象が違うため失敗し、暗号文がそのまま UI に表示される。

**Status**: ✅ 原因特定完了。修正（アイテム名と同様の「鍵変更検知→再暗号化」または
「旧鍵での復号フォールバック」をグループフィールド側にも実装）は次回。

---

## 🗓 次回の予定（引き継ぎ）

1. **修正実装**: グループフィールド（`members[].name/contact`, `ownerName/ownerEmail`）にも
   `_reencryptAllItemsIfKeyChanged` 相当の「鍵変更検知時の再暗号化」を実装する。
   アイテム側の `group_key_fingerprint_v1:$groupId`（`hybrid_shared_list_repository.dart`）
   と同じ仕組みを踏襲するか、`decryptGroupField` に「直前の永続鍵」でのフォールバック復号を
   追加する案のどちらかを検討する。後者は再暗号化タイミングの制御が不要な分シンプルだが、
   旧鍵をどこまで遡って保持するか（複数回ローテーションされた場合）の設計が要る。
2. 修正後、Phase 3（書き込み暗号化）の配布可否を判断する
   （解決するまで Phase 3 は配布しない方針を維持）。
3. 解決後、**Phase 4**（既存平文データの再暗号化パス。今回判明した鍵ローテーション対応と
   統合できる可能性がある）+ **Phase 5**（復号済み members でのバリデーション重複チェック）
   + 実機2端末 E2E に進む。
4. 採取した `🔎` トレースログ（`dd6c1218`）は原因特定に使用したため、修正実装後に撤去する。

---

## 📝 ドキュメント / 変更ファイル一覧

| ファイル | 更新内容 |
|---|---|
| `pubspec.yaml` | `version: 1.1.0+34` → `1.1.0+36`（iOS 内部テストビルド） |
| `docs/daily_reports/2026-09/daily_report_20260918.md` | **新規**: 本日の日報。ビルド36 内部テスト結果（アイテム復号は成功／メンバー復号は失敗）、iPad mini 実機ログ採取による根本原因の特定（鍵ローテーション時のメンバー情報再暗号化漏れ）を記録 |

### 未追跡・本コミット対象外

- `.vscode/settings.json`: エディタ側のフォーマット差分・Java LSP メモリ設定のローカル変更。本日の作業と無関係のため据え置き
- `.artifacts/`: 追跡対象外の作業ディレクトリ。本日の作業と無関係のため据え置き
