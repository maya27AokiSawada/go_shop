# 認証フロー分析と改善提案

## 現在の実装状況

### ✅ 実装済み
1. **アプリ起動時**
   - サインイン状態: Firestoreからバックグラウンド同期 ✅
   - 未サインイン: Hiveのみでデフォルトグループ作成 ✅

2. **基本的なデータ管理**
   - HybridPurchaseGroupRepository で Hive + Firestore ✅
   - AllGroupsNotifier でグループ管理 ✅

### ❌ 未実装・要改善
1. **サインアップ時のデータ移行**
   - Hiveローカルデータ → Firestore への移行が不完全
   - 現在はFirestore側で新規デフォルトグループ作成のみ

2. **サインイン時の完全同期**
   - マージロジックが部分的
   - 競合解決の仕組みが不足

3. **アクセス制御**
   - 未サインイン時のデフォルトグループ制限が未実装
   - 全ての機能がアクセス可能になっている

## 推奨改善方針

### 1. サインアップ時のデータ移行強化
```dart
// 未サインイン → サインアップ時
1. ローカルの default_group を検出
2. Firestore に同じ内容でアップロード
3. ローカルグループID を Firebase形式に変更
4. 既存の買い物リストも移行
```

### 2. アクセス制御の実装
```dart
// 未サインイン時の制限
- デフォルトグループ(default_group)のみアクセス
- 新規グループ作成を制限
- 招待機能を無効化
- クラウド同期機能を無効化
```

### 3. 完全同期ロジック
```dart
// サインイン時の処理
1. Firestore データ取得
2. ローカル データ取得  
3. タイムスタンプベースの競合解決
4. 双方向マージ実行
5. 重複グループの統合
```

### 4. 実装優先度
1. **高**: アクセス制御 (ユーザー体験の統一)
2. **中**: サインアップ時データ移行 (データ損失防止)
3. **低**: 完全同期ロジック (現状で基本動作は可能)

## 修正すべきファイル

### アクセス制御
- `lib/widgets/group_selector_widget.dart`
- `lib/widgets/group_creation_with_copy_dialog.dart`
- `lib/pages/purchase_group_page.dart`

### データ移行
- `lib/services/user_initialization_service.dart`
- `lib/datastore/hybrid_purchase_group_repository.dart`

### UI制限
- `lib/providers/purchase_group_provider.dart` (createNewGroup制限)
- `lib/widgets/invitation_dialog.dart` (招待機能制限)