# 開発日報 - 2026年09月18日

## 📅 本日の目標

- [x] iOS ビルド36を内部テストに提出し、グループメンバー暗号化（[[Phase 2/3]] 実機復号バグ）の検証を行う
- [x] iPad mini 実機を USB 接続し `idevicesyslog` でトレースログを採取、原因を特定する
- [x] 修正の実装
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

### 3. グループ共有フィールド復号バグの修正実装 ✅

**Purpose**: 作業2で特定した根本原因（グループ鍵ローテーション時、アイテム名は
再暗号化されるがグループメンバー情報は再暗号化されない非対称性）を解消する。

**実装内容**:

- [`group_key_exchange_service.dart`](../../../lib/services/group_key_exchange_service.dart)
  の `_persistGroupKeyLocally` を変更し、端末のローカル永続鍵が切り替わる際、
  切り替わる**直前の鍵を1世代分だけ** `group_key_previous_v1:$groupId` に退避する
  ようにした（`getPreviousPersistedGroupKey` で取得可能）。オーナーの
  `rotateGroupKey` と、メンバー側の `resolveGroupKeyForMember` の両方がこの
  経路を通るため、鍵が変わるすべての端末で自動的に「1世代前の鍵」を保持する。
- `decryptGroupField` に、現在の鍵での復号失敗時、（呼び出し側が明示的に
  `groupKey` を指定していない場合に限り）直前の鍵でのフォールバック復号を追加。
  ローテーション直後、再暗号化が完了する前でも即座に復号できるようにした。
- 新規メソッド `reencryptGroupFieldsIfKeyChanged` を追加。直前鍵と現在鍵が
  異なる場合、`SharedGroups/{groupId}` を読み直し、`ownerName` / `ownerEmail` /
  `members[].name` / `members[].contact` のうち直前鍵で復号できたものを現在鍵で
  再暗号化して書き戻す（アイテム名の `_reencryptAllItemsIfKeyChanged` 相当）。
- [`group_field_cipher.dart`](../../../lib/datastore/group_field_cipher.dart) の
  `GroupKeyServiceFieldCipher.primeKey` から `reencryptGroupFieldsIfKeyChanged`
  を呼ぶようにした。`primeKey` は `SharedGroups` の読み書きサイト（
  `firestore_shared_group_repository.dart` ほか）が復号・暗号化の直前に必ず
  呼んでいるため、既存の呼び出し箇所を変更せずに全サイトへ適用される。
- 原因特定に使った `🔎` トレースログ（`dd6c1218`）を撤去。
- テスト追加: [`group_key_exchange_field_rotation_test.dart`](../../../test/services/group_key_exchange_field_rotation_test.dart)
  （フォールバック復号・再暗号化の書き戻し・鍵未変更時の no-op を検証）。
  既存の `group_key_exchange_field_test.dart` / `shared_group_firestore_codec_test.dart`
  （計30件）もパス継続を確認。

**既知の制約**: 直前1世代分の鍵のみ保持する設計のため、対象デバイスがオフライン等で
1度も再暗号化を経ずに2回以上ローテーションを跨ぐと、その世代の暗号文は復元できない。
また、本日の作業1・2で確認済みの実データ（グループ `a3f3e7c5_1788724125426`）は、
この修正が入る前に発生したローテーションであり、影響を受けた端末に旧鍵が
残っていない場合は本修正では復元できない（今後のローテーションでは再発しない）。

**Status**: ✅ 実装・テスト完了。次回、実機（iPad mini）で新規ローテーションを
発生させて動作確認を行う。

---

## 🗓 次回の予定（引き継ぎ）

1. ~~修正実装~~ → 作業3で完了（「直前の永続鍵」でのフォールバック復号 +
   鍵変更検知時の再暗号化書き戻しの両方を実装）。
2. **実機検証**: iPad mini で新規に鍵ローテーションを発生させ、グループメンバー
   情報が今度こそ正しく復号されることを確認する（今回発見済みの
   `a3f3e7c5_1788724125426` は修正前のローテーションによる影響のため、
   別グループ or 再招待による新規ローテーションで確認すること）。
3. 実機検証後、Phase 3（書き込み暗号化）の配布可否を判断する。
4. 解決後、**Phase 4**（既存平文データの再暗号化パス。今回判明した鍵ローテーション対応と
   統合できる可能性がある）+ **Phase 5**（復号済み members でのバリデーション重複チェック）
   + 実機2端末 E2E に進む。
5. ~~トレースログ撤去~~ → 作業3で完了。

---

## 📝 ドキュメント / 変更ファイル一覧

| ファイル | 更新内容 |
|---|---|
| `pubspec.yaml` | `version: 1.1.0+34` → `1.1.0+36`（iOS 内部テストビルド） |
| `lib/services/group_key_exchange_service.dart` | 鍵切り替え時に直前鍵を1世代分退避（`_persistGroupKeyLocally`）、`decryptGroupField` に直前鍵フォールバック追加、`reencryptGroupFieldsIfKeyChanged` 新規追加、原因調査用トレースログ撤去 |
| `lib/datastore/group_field_cipher.dart` | `primeKey` から `reencryptGroupFieldsIfKeyChanged` を呼ぶよう変更、トレースログ撤去 |
| `lib/datastore/shared_group_firestore_codec.dart` | `_dec` のトレースログ撤去 |
| `test/services/group_key_exchange_field_rotation_test.dart` | **新規**: フォールバック復号・再暗号化書き戻し・鍵未変更時 no-op を検証するテストを追加 |
| `docs/daily_reports/2026-09/daily_report_20260918.md` | **新規**: 本日の日報。ビルド36 内部テスト結果（アイテム復号は成功／メンバー復号は失敗）、iPad mini 実機ログ採取による根本原因の特定（鍵ローテーション時のメンバー情報再暗号化漏れ）、修正実装を記録 |

### 未追跡・本コミット対象外

- `.vscode/settings.json`: エディタ側のフォーマット差分・Java LSP メモリ設定のローカル変更。本日の作業と無関係のため据え置き
- `.artifacts/`: 追跡対象外の作業ディレクトリ。本日の作業と無関係のため据え置き
