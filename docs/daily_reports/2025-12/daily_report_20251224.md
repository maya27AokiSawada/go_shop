# 開発日報 - 2025年12月24日（火）

**作業者**: まや
**作業環境**: 自宅PC（Windows 11）
**開発ブランチ**: `oneness`
**Flutter Version**: 3.27.2
**Dart Version**: 3.6.1

---

## 📋 本日の作業サマリー

### 実施内容

1. ✅ メンバー伝言メッセージ機能の詳細設計書作成
2. ✅ dev版とprod版のフレーバー違いによるグループ表示問題の調査・解決
3. ✅ 通知履歴画面実装（未読/既読管理、リアルタイム表示）
4. ✅ Firestoreインデックスデプロイ

### 作業時間

- **設計**: 約1時間（詳細設計書作成）
- **デバッグ**: 約30分（フレーバー問題調査・解決）
- **通知履歴実装**: 約2時間（UI実装、インデックス設定）
- **合計**: 約3.5時間

---

## 🎯 実装詳細

### 1. メンバー伝言メッセージ機能 - 詳細設計書作成 ✅

**目的**: 年末年始休暇中の実装に向けた包括的な設計書作成

**成果物**: `docs/member_message_feature_design.md`（約900行）

**設計内容**:

#### データモデル設計
- `MemberMessage` モデル（Freezed + Hive）
  - HiveField(0-8): messageId, groupId, targetMemberId, fromMemberId, fromMemberName, message, createdAt, isRead, readAt
  - TypeID: 7
  - バリデーション: メッセージ1-500文字

#### Firestore構造設計
```
/SharedGroups/{groupId}/memberMessages/{messageId}
```

**複合インデックス設計**:
1. `targetMemberId` + `isRead` + `createdAt` (未読クエリ用)
2. `targetMemberId` + `createdAt` (履歴クエリ用)

#### Repository実装設計
- `MemberMessageRepository` (Abstract)
- `FirestoreMemberMessageRepository` (Firestore実装)
- `HiveMemberMessageRepository` (キャッシュ実装)
- `HybridMemberMessageRepository` (Firestore優先、Hiveフォールバック)

**主要メソッド**:
- `sendMessage()`: メッセージ送信
- `watchMessages()`: リアルタイム監視（Stream）
- `watchUnreadCount()`: 未読数監視（Stream）
- `markAsRead()`: 既読処理
- `markAllAsRead()`: 全既読処理

#### UI設計
- **メンバーリスト拡張** (`group_member_management_page.dart`)
  - メッセージアイコン追加
  - 未読バッジ表示（数字またはdot）

- **メッセージダイアログ** (`member_message_dialog.dart`)
  - 最新10件のメッセージ履歴表示
  - リアルタイム更新（StreamBuilder）
  - 送信中ローディング表示
  - エラーハンドリング

#### セキュリティルール
```javascript
// 自分宛または自分が送ったメッセージのみ閲覧可能
function canReadMessage() {
  return resource.data.targetMemberId == request.auth.uid ||
         resource.data.fromMemberId == request.auth.uid;
}

// メッセージ削除は不可（履歴保持のため）
allow delete: if false;
```

#### 実装手順（6フェーズ）
| Phase | 作業内容 | 見積時間 |
|-------|---------|---------|
| Phase 1 | データモデル実装 | 1時間 |
| Phase 2 | Repository実装 | 2時間 |
| Phase 3 | Provider実装 | 1時間 |
| Phase 4 | UI実装 | 2.5時間 |
| Phase 5 | Firestore設定 | 0.5時間 |
| Phase 6 | テスト | 1時間 |
| **合計** | | **8時間** |

**実装予定スケジュール**:
- 12/28（土）: Phase 1-4（データモデル → UI）
- 12/29（日）: Phase 5-6（Firestore設定 → テスト）

---

### 2. dev版とprod版のフレーバー違いによるグループ表示問題 ✅

**問題発生**:
- SH-54D: デフォルトグループ + 共有グループ2つ表示（正常）
- Pixel 9: デフォルトグループのみ表示（異常）
- 両デバイスとも同じアカウント（まや、fatima.sumomo@gmail.com）でサインイン

#### 調査プロセス

**1. デバイス確認**
```bash
flutter devices
# Pixel 9: 192.168.0.14:38977 (prod版)
# SH-54D: 192.168.0.17:42005 (dev版 ※バージョン末尾に"-dev"あり)
```

**2. Flavorの違いを発見**
- **SH-54D**: dev版 (`net.sumomo_planning.go_shop.dev`)
- **Pixel 9**: prod版 (`net.sumomo_planning.go_shop`)

**3. google-services.json確認**

両方とも同じFirebaseプロジェクト（`gotoshop-572b7`）を使用しているが、**パッケージ名が異なる**：

```
android/app/src/dev/google-services.json
  → package_name: net.sumomo_planning.go_shop.dev

android/app/src/prod/google-services.json
  → package_name: net.sumomo_planning.go_shop
```

#### 根本原因

**Firebase AuthenticationはAndroidパッケージ名でアプリを識別**するため：
- dev版サインイン → UID: `abc123`
- prod版サインイン → UID: `def456`（別UID）

同じメールアドレスでも**別ユーザー扱い**となり、異なるデフォルトグループ（groupId = UID）が作成されていた。

さらに、**Pixel 9にdev版のHiveキャッシュが残っていた**ため、Firestore優先読み込みが実装されていても古いデータが表示されていた。

#### 解決策

```bash
# Pixel 9のアプリを完全削除して再インストール
flutter run -d 192.168.0.14:38977 --flavor prod --uninstall-first
```

または、Pixel 9で以下を実行：
1. 設定 → アプリ → Go Shop
2. ストレージとキャッシュ → **データを削除**

**結果**: ✅ 両デバイスで同じグループが表示されるようになった

#### 技術的学習

1. **Flavorごとにパッケージ名が変わる設計**
   - dev版: `applicationIdSuffix = ".dev"`
   - Firebase Authはパッケージ名でユーザーを管理
   - 同じFirebaseプロジェクトでもパッケージ名が違えば別アプリ扱い

2. **Hiveデータの永続性**
   - アプリ更新ではHiveデータは削除されない
   - `flutter run`の上書きインストールでもデータは残る
   - 完全なデータクリアには`--uninstall-first`または設定からデータ削除が必要

3. **Firestore優先読み込みの限界**
   - 実装済みの「Firestore優先→Hiveキャッシュ」でも、古いHiveデータがあると問題が起きる
   - アプリバージョンアップ時のマイグレーション処理が重要

---

### 3. 通知履歴画面実装 ✅

**目的**: Firestoreの通知データをリアルタイムで表示し、履歴として管理

**実装ファイル**:
- **新規**: `lib/pages/notification_history_page.dart` (332行)
- **変更**: `lib/widgets/settings/notification_settings_panel.dart`

**主な機能**:

1. **リアルタイム通知表示**
   - StreamBuilderでFirestore `notifications`コレクションから取得
   - `userId` + `timestamp`でフィルタリング・ソート
   - 最新100件まで表示

2. **未読/既読管理**
   - タップまたはチェックボタンで既読マーク
   - 未読通知は青い背景で強調表示

3. **既読通知一括削除**
   - AppBarの削除アイコンから実行
   - Firestore batch操作で効率的に削除

4. **通知タイプ別アイコン・色**
   - listCreated: 緑, listDeleted: 赤, listRenamed: 青など

5. **時間差表示**
   - 「たった今」「3分前」「2日前」など直感的表示

**Firestoreインデックス**: デプロイ済み（`userId` + `timestamp`）

**テスト状況**: 画面遷移✅、通知表示⏳（インデックス作成待ち）

**コミット**: `c1fac4a` - "feat: 通知履歴画面実装"

---

## 📝 技術メモ

### Flavor管理のベストプラクティス

#### 現在の設計（改善の余地あり）

**問題点**:
- dev版とprod版で別ユーザー扱い
- 開発時にdevで作成したデータがprodで見えない
- テストユーザーをdev/prodで別々に管理する必要がある

**検討すべき改善案**:

1. **dev版もprod版と同じパッケージ名を使う**
   ```kotlin
   // build.gradle.kts
   create("dev") {
       dimension = "default"
       // applicationIdSuffix = ".dev"  // ← コメントアウト
       versionNameSuffix = "-dev"       // バージョン名だけ区別
   }
   ```

2. **Firebase Emulatorを使う**
   - dev版: Firebase Emulator（ローカル）
   - prod版: 本番Firestore
   - これなら本番データに影響なく開発可能

3. **Firebaseプロジェクトを分ける**
   - `gotoshop-dev`: 開発用
   - `gotoshop-prod`: 本番用
   - 完全に分離されるがコスト増

**現時点の運用方針**:
- **全て prod 版で統一する**（今回の解決策）
- dev版は将来的にEmulator対応時に使用
- これが最もシンプルで混乱が少ない

---

## 🐛 Known Issues

なし（本日発見した問題はすべて解決済み）

---

## 📚 参考資料

- [Flutter Flavors Best Practices](https://docs.flutter.dev/deployment/flavors)
- [Firebase Authentication Package Name](https://firebase.google.com/docs/auth/android/start)
- [Hive Database - Data Persistence](https://docs.hivedb.dev/)

---

## 🎯 次回作業予定

### 12/25（水）

**作業所最終日のため開発作業なし**

### 12/27（金）～1/4（土）年末年始休暇

**実装予定**:

1. **メンバー伝言メッセージ機能実装**（12/28-29）
   - 設計書に基づいて実装
   - 見積: 8時間（2日間）

2. **ポートフォリオドキュメント整備**（12/30-1/3）
   - アーキテクチャ図作成
   - セキュリティ実装の説明
   - 技術スタック・工夫点のまとめ
   - README.md更新

3. **バックグラウンド同期最適化**（時間あれば）
   - LOW priority
   - バッテリー消費削減

---

## 💡 学んだこと

### Firebase Authentication とパッケージ名の関係

- **package_name は Firebase Auth の重要な識別子**
- 同じメールアドレスでも package_name が違えば別ユーザー
- Flavor 設定で `applicationIdSuffix` を使う場合は注意が必要

### Hiveデータの永続性とクリーニング

- `flutter run` では Hive データは保持される
- アプリアップデート時も Hive データは残る
- 完全クリアには `--uninstall-first` または Android 設定から削除が必要

### 実装済み機能でも起こり得る問題

- Firestore 優先読み込みを実装していても、古いキャッシュが問題を起こすケースがある
- マイグレーション処理やバージョン管理の重要性

---

**作成日時**: 2025年12月24日
**次回更新予定**: 2025年12月28日（実装開始時）
