# 認証フロー分析（2026-02-12 更新）

> ⚠️ **注意**: デフォルトグループ機能は 2026-02-12 に廃止済み。
> 未サインイン状態での自動グループ作成は行わない。認証必須アーキテクチャに移行済み。

## 現在の実装状況

### ✅ 実装済み

1. **アプリ起動時**
   - サインイン状態: Firestoreからバックグラウンド同期 ✅
   - 未サインイン: ログイン画面を表示（グループ作成は行わない）✅

2. **基本的なデータ管理**
   - HybridSharedGroupRepository で Hive + Firestore ✅
   - AllGroupsNotifier でグループ管理 ✅

### ❌ 未実装・要改善

1. **サインイン時の完全同期**
   - マージロジックが部分的
   - 競合解決の仕組みが不足

## 廃止済み機能

- ~~未サインイン: Hiveのみでデフォルトグループ作成~~ → **廃止**
- ~~デフォルトグループ(default_group) への自動移行~~ → **廃止**
- ~~未サインイン時のデフォルトグループ制限~~ → **廃止**（認証必須に変更）

## 現在の認証フロー

```dart
// サインアップ時
1. SharedPreferences + Hive を全クリア（Firebase Auth登録より先）
2. Firebase Auth.signUp()
3. UserPreferencesService.saveUserName()
4. user.updateDisplayName()
5. ref.invalidate(allGroupsProvider) 等
6. forceSyncProvider で Firestore → Hive 同期

// サインイン時
1. Firebase Auth.signIn()
2. Firestore からユーザー名取得 → SharedPreferences 保存
3. forceSyncProvider（invalidate してから await）
4. ref.invalidate(allGroupsProvider)
```

## 修正すべきファイル

### データ移行

- `lib/services/user_initialization_service.dart`
- `lib/datastore/hybrid_shared_group_repository.dart`
