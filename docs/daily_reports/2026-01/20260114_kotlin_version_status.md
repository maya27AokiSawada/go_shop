# 日報 - Kotlin版開発 - 2026年1月14日（火）

## 📋 プロジェクト概要

**プロジェクト名**: goshopping-android (Kotlin版)
**目的**: Go ShopアプリのKotlin/Jetpack Compose版として再実装
**ロケーション**: `C:\KotlinProject\goshopping-android`
**ステータス**: データモデル設計フェーズ

---

## 📝 本日の作業内容

### 現状確認

**前回までの進捗**:
- プロジェクト構成検討中
- データモデルの作成途中で一時中断
- Flutter版でホワイトボード機能実装を優先

**本日の状況**:
- Flutter版のホワイトボード機能実装が完了
- Kotlin版の作業は未着手（Flutter版作業を優先）

---

## 🎯 Kotlin版で実装予定の機能

### 1. グループ階層機能
- 親子グループのリンク構造
- ツリー構造での表示
- 階層的な権限管理

### 2. 8ビット権限システム
- Permission class with bit flags:
  - NONE (0x00)
  - READ (0x01)
  - DONE (0x02)
  - COMMENT (0x04)
  - ITEM_CREATE (0x08)
  - ITEM_EDIT (0x10)
  - LIST_CREATE (0x20)
  - MEMBER_INVITE (0x40)
  - ADMIN (0x80)
- プリセット権限レベル:
  - VIEWER (READ)
  - CONTRIBUTOR (READ + DONE + COMMENT)
  - EDITOR (READ + DONE + COMMENT + ITEM_CREATE + ITEM_EDIT)
  - MANAGER (EDITOR + LIST_CREATE + MEMBER_INVITE)
  - FULL (ALL permissions)

### 3. SharedGroup拡張
```kotlin
data class SharedGroup(
    // 既存フィールド...

    // 🆕 階層構造
    val parentGroupId: String? = null,
    val childGroupIds: List<String> = emptyList(),

    // 🆕 権限管理
    val memberPermissions: Map<String, Int> = emptyMap(), // memberId -> permission bits
    val defaultPermission: Int = Permission.VIEWER,

    // 🆕 設定
    val inheritParentLists: Boolean = false,
)
```

### 4. データストレージ
- **Room Database**: ローカルキャッシュ
- **Firebase Firestore**: クラウド同期
- **SharedPreferences**: ユーザー設定

---

## 🔧 技術スタック（予定）

### 言語・フレームワーク
- **Kotlin**: 最新安定版
- **Jetpack Compose**: 宣言的UI
- **Coroutines + Flow**: 非同期処理

### アーキテクチャ
- **MVVM**: Model-View-ViewModel
- **Clean Architecture**: レイヤー分離
- **Repository Pattern**: データ抽象化

### ライブラリ（予定）
- **Firebase SDK**: Auth + Firestore
- **Room**: ローカルDB
- **Hilt**: 依存性注入
- **Coil**: 画像ローディング
- **Material3**: Material Design 3

---

## 📊 Flutter版との比較

| 機能 | Flutter版 | Kotlin版（予定） |
|------|-----------|-----------------|
| 階層構造 | ✅ モデル定義済み | ⏳ 未実装 |
| 権限システム | ✅ 8ビット実装済み | ⏳ 未実装 |
| ホワイトボード | ✅ 実装済み（future） | ❌ 予定なし |
| UI | Flutter Widgets | Jetpack Compose |
| ローカルDB | Hive | Room |
| 状態管理 | Riverpod | ViewModel + Flow |

---

## 🚧 現在の課題

### 技術的課題
1. **プロジェクト初期化**
   - Android Studioでのプロジェクトセットアップ
   - 依存関係の設定
   - Firebase統合

2. **データモデル移植**
   - Dart Freezed → Kotlin data class
   - Hive → Room Database
   - TypeAdapterの代替実装

3. **アーキテクチャ設計**
   - パッケージ構成の決定
   - レイヤー間のインターフェース定義
   - DIコンテナの設計

### 方針的課題
- Flutter版とKotlin版の機能差別化
- リソース配分（Flutter優先 vs 並行開発）
- Kotlin版の必要性再検討

---

## 📝 次回作業予定

### 優先度: HIGH
1. **プロジェクト方針の決定**
   - Kotlin版開発を継続するか？
   - Flutter版に注力するか？
   - 両方を並行開発するか？

### 優先度: MEDIUM（Kotlin版継続の場合）
2. **プロジェクト初期化**
   - Android Studioでプロジェクト作成
   - build.gradleの設定
   - Firebase統合

3. **データモデル実装**
   - SharedGroup entity (Room)
   - SharedList entity
   - SharedItem entity
   - Permission class

4. **Repository層実装**
   - RoomDAO定義
   - Firestore Repository
   - Hybrid Repository（Room + Firestore）

---

## 💭 検討事項

### Kotlin版開発の意義
**メリット**:
- Android専用の最適化が可能
- Jetpack Composeの最新機能活用
- Material Design 3のネイティブ実装
- パフォーマンス向上の可能性

**デメリット**:
- 開発リソースの分散
- 機能追加時の二重実装コスト
- テスト・メンテナンスの負担増
- Flutter版で既に十分な品質

**推奨**:
- 現時点ではFlutter版に注力すべき
- Kotlin版は学習目的または特定要件が発生した際に再開

---

## ⏰ 作業時間

**本日**: 0時間（Flutter版作業を優先）

**累積**: データモデル設計のみ（約1時間）

---

## 📦 成果物

**本日**: なし

**累積**:
- プロジェクト構想メモ
- データモデル設計ドラフト（未実装）

---

## 🎯 結論

**Kotlin版開発は一時中断を推奨**

理由:
1. Flutter版が順調に進行中
2. ホワイトボード機能などの差別化要素が実装済み
3. リソースをFlutter版に集中させるべき
4. Google Play Storeリリースが優先

**再開条件**:
- Flutter版が安定リリース完了後
- Android固有の要件が発生した場合
- 学習目的での時間確保ができた場合

---

## 📋 備考

- このドキュメントはFlutter版プロジェクト内に保管
- Kotlin版プロジェクトはワークスペース外のため直接アクセス不可
- 必要に応じて`C:\KotlinProject\goshopping-android`を別途開く
