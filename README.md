# Go Shop - 家族向け買い物リスト共有アプリ

**開発者**: 金ヶ江 真也 ファーティマ (Maya Fatima Kanagae)
👉 [開発者についてはこちら](PROFILE.md)

## 🎯 プロジェクト概要

Go Shop は家族やグループで買い物リストをリアルタイム共有できるFlutterクロスプラットフォームアプリケーションです。Android・Windows に対応（iOS実装済み・未テスト）し、Firebase とのハイブリッド同期システムにより、オフライン時も快適に利用でき、オンライン復帰時に自動同期されます。
👉 [開発のいきさつはこちら](HISTORY.md)

## 🛠️ 技術スタック

### **フロントエンド**

- **Flutter 3.35.5** - クロスプラットフォーム（Android/Windows、iOS実装済み・未テスト）
- **Riverpod 2.6.1** - 状態管理
- **Hive** - ローカルデータベース（キャッシュ）
- **flutter_dotenv** - 環境変数管理

### **バックエンド・インフラ**

- **Firebase** - クラウドデータベース・認証
- **Firestore** - NoSQLドキュメントデータベース
- **Firebase Auth** - ユーザー認証システム

### **アーキテクチャパターン**

- **Repository Pattern** - データアクセス層の抽象化
- **Hybrid Sync System** - オフライン・オンライン対応
- **Provider Pattern** - 依存性注入・状態管理

## 🚀 主要機能

### 📋 **グループ管理**

- グループ作成・削除
- メンバー招待・役割管理（オーナー・管理者・メンバー）
- 権限ベースのアクセス制御

### 🛒 **買い物リスト管理**

- アイテム追加・編集・削除
- 購入状態の切り替え
- 定期購入アイテム設定と自動リセット
- リストの一括クリア
- アプリモード切り替え（買い物リスト ⇄ TODOタスク管理）

### 🔄 **リアルタイム同期**

- Firebase Firestore によるリアルタイム同期
- オフライン時は Hive によるローカル保存
- オンライン復帰時の自動データ同期
- 競合解決機能

### 📖 **ヘルプシステム**

- 内蔵ヘルプ（6つの主要セクション）
- 外部マークダウンファイル対応
- 検索機能付きヘルプ
- 操作ガイド・FAQ

### 📲 **QRコード招待システム**

- QRコードによるグループ招待
- セキュリティキー認証
- 招待使用回数制限（最大5回）
- 招待有効期限管理（24時間）

### 📱 **モバイル広告統合**

- AdMob バナー広告
- 地域広告対応（位置情報ベース）
- プラットフォーム別広告表示制御

### 🔒 **プライバシー機能**

- シークレットモード（デフォルトグループのみ表示）
- サインアップ前のグループ作成制限
- ユーザー別データ分離

## 🏗️ システム アーキテクチャ

### **ハイブリッド同期システム**

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   UI Layer      │    │   Repository     │    │   Data Layer    │
│   (Flutter)     │◄──►│   Pattern        │◄──►│   (Hive +       │
│                 │    │                  │    │    Firestore)   │
├─────────────────┤    ├──────────────────┤    ├─────────────────┤
│ • Pages         │    │ • Abstract Repo  │    │ • Hive Cache    │
│ • Widgets       │    │ • Hybrid Repo    │    │ • Firebase Sync │
│ • Providers     │    │ • Cache Strategy │    │ • Data Models   │
└─────────────────┘    └──────────────────┘    └─────────────────┘
```

### **データフロー**

1. **オフライン時**: UI ↔ Repository ↔ Hive (ローカル)
2. **オンライン時**: UI ↔ Repository ↔ Hive + Firestore (同期)
3. **競合解決**: タイムスタンプベースのマージ処理

## 💻 開発環境構築

### **前提条件**

- Flutter SDK 3.35.5+
- 開発環境: Windows 10/11、macOS、Linux
- ターゲットプラットフォーム: Android、Windows（iOS実装済み・未テスト）
- Firebase プロジェクト
- AdMob アカウント（広告機能を使用する場合）

### **セットアップ手順**

1. **リポジトリクローン**

   ```bash
   git clone https://github.com/maya27AokiSawada/go_shop.git
   cd go_shop
   ```

2. **依存関係インストール**

   ```bash
   flutter pub get
   ```

3. **環境変数設定**

   ```bash
   # .env.example をコピーして .env ファイルを作成
   cp .env.example .env

   # .env ファイルに以下の情報を記入
   # - Firebase API Key、Project ID、App ID 等
   # - AdMob App ID、Ad Unit ID
   ```

4. **Firebase プロジェクト設定**

   - Firebase Console でプロジェクトを作成
   - Android、iOS、Windows アプリを登録
   - 設定値を `.env` ファイルに記入

5. **AdMob 設定**（広告機能を使用する場合）

   - AdMob でアプリを作成し、App ID と Ad Unit ID を取得
   - `.env` ファイルに AdMob の設定を記入
   - `android/app/src/main/AndroidManifest.xml` に AdMob App ID を設定
   - `ios/Runner/Info.plist` に AdMob App ID を設定

6. **アプリ実行**

   ```bash
   # Windows版
   flutter run -d windows

   # Android版（実機またはエミュレータ）
   flutter run -d android

   # iOS版（macOSのみ）
   flutter run -d ios
   ```

### **環境変数について**

セキュリティのため、機密情報は `.env` ファイルで管理しています。

**必要な環境変数**:

```env
# Firebase Configuration
FIREBASE_API_KEY_WEB=
FIREBASE_APP_ID_WEB=
FIREBASE_MESSAGING_SENDER_ID=
FIREBASE_PROJECT_ID=
FIREBASE_AUTH_DOMAIN=
FIREBASE_STORAGE_BUCKET=
FIREBASE_MEASUREMENT_ID_WEB=
FIREBASE_APP_ID_ANDROID=
FIREBASE_APP_ID_IOS=
FIREBASE_IOS_BUNDLE_ID=
FIREBASE_APP_ID_WINDOWS=

# AdMob Configuration
ADMOB_APP_ID=ca-app-pub-XXXXXXXXXXXXXXXX~XXXXXXXXXX
ADMOB_BANNER_AD_UNIT_ID=ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX
ADMOB_TEST_BANNER_AD_UNIT_ID=ca-app-pub-3940256099942544/6300978111
```

`.env.example` をテンプレートとして使用してください。

## 🤔 技術的チャレンジと解決策

### **チャレンジ1: オフライン・オンライン対応**

**課題**: ネットワーク状況に関係なく快適な操作を実現
**解決策**: Hive によるローカルキャッシュと Firebase の組み合わせによるハイブリッド同期システム

### **チャレンジ2: データ競合の解決**

**課題**: 複数ユーザーが同時編集した際のデータ整合性
**解決策**: タイムスタンプベースの競合解決とマージ処理

### **チャレンジ3: 状態管理の複雑性**

**課題**: 複数のデータソース（Hive + Firestore）の状態管理
**解決策**: Riverpod の AsyncNotifierProvider を活用した統一的な状態管理

## 📚 学習成果

### **技術スキル**

- Flutter によるクロスプラットフォームアプリ開発（Android/iOS/Windows）
- Firebase 統合とリアルタイム同期
- 複雑な状態管理（Riverpod）
- Repository パターンによる設計
- AdMob 広告統合と収益化
- QRコード認証システムの実装
- 環境変数管理とセキュリティ対策

### **設計スキル**

- ユーザー中心設計（UCD）
- アクセシビリティ考慮
- エラーハンドリング戦略
- データモデリング

## 🚀 今後の展開

### **短期的改善**

- [x] Android版の開発・テスト（完了）
- [x] Windows版の開発・テスト（完了）
- [ ] iOS版の実機テスト
- [x] QRコード招待システム（完了）
- [x] AdMob広告統合（完了）
- [ ] プッシュ通知機能
- [ ] 商品画像添付機能
- [ ] 予算管理機能
- [ ] 定期購入アイテムのUI強化

### **長期的展開**

- [ ] 機械学習による商品推薦
- [ ] 在庫管理システム連携
- [ ] 小売店舗との API 連携
- [ ] 多言語対応

## 👤 開発者情報

### 金ヶ江 真也 ファーティマ (Maya Fatima Kanagae)

- GitHub: [@maya27AokiSawada](https://github.com/maya27AokiSawada)
- Email: <fatima.sumomo@gmail.com>
- LinkedIn: [金ヶ江真也ファーティマ](https://www.linkedin.com/in/maya27aokisawada)

---

### 🎯 プロジェクトハイライト

このプロジェクトは、実用的なアプリケーション開発を通じて以下のスキルを実証しています：

- **フルスタック開発**: フロントエンド（Flutter）+ バックエンド（Firebase）
- **クラウドネイティブ**: Firebase を活用したサーバーレス アーキテクチャ
- **UX/UI デザイン**: ユーザー中心の直感的なインターフェース設計
- **データ設計**: 効率的なNoSQLデータモデリング
- **品質管理**: テスト戦略とドキュメント作成

*このプロジェクトが私の技術力と問題解決能力を示す代表作となることを願っています。*

