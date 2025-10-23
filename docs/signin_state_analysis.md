# サインイン状態チェック処理の分析

## 現在の流れ (Windows アプリ起動時)

### 1. main.dart
```dart
// Firebase初期化
await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

// AppInitializeWidget でラップされた HomeScreen を表示
home: const AppInitializeWidget(child: HomeScreen())
```

### 2. AppInitializeWidget
```dart
// 初期化処理の実行順序:
1. _checkAndHandleMigration()         // データマイグレーション
2. _initializeUserServices()          // ユーザー初期化サービス開始
   → userInitService.startAuthStateListener()
   → ref.read(allGroupsProvider.future)
```

### 3. UserInitializationService.startAuthStateListener()
```dart
// アプリ起動時に一度実行
WidgetsBinding.instance.addPostFrameCallback((_) {
  _initializeBasedOnUserState();
});

// Firebase Auth状態変化を監視 (サインイン/サインアウト時)
_auth.authStateChanges().listen((User? user) {
  if (user != null) {
    _initializeUserDefaults(user);
  }
});
```

### 4. _initializeBasedOnUserState()
```dart
// STEP1: AllGroupsProvider でグループ一覧取得（デフォルトグループ自動作成）
await _ref.read(allGroupsProvider.future);

// STEP2: Firebase認証状態チェック
final currentUser = _auth.currentUser;
if (currentUser != null && _isFirebaseUserId(currentUser.uid)) {
  // サインイン済み → Firestoreと同期
  await _syncWithFirestore(currentUser);
} else {
  // 未サインイン → ローカルのみ
}
```

### 5. AllGroupsNotifier.build()
```dart
// グループ一覧取得
final groups = await repository.getAllGroups();

// デフォルトグループが存在しない場合は作成
if (groups.isEmpty || !groups.any((g) => g.groupId == 'default_group')) {
  await _ensureDefaultGroupExists();
  // 作成後に再度取得
  return await repository.getAllGroups();
}
```

## 問題点の分析

### サインイン状態でアプリ起動時の課題
1. **Firebase Auth currentUser が即座に取得できない可能性**
   - Firebase初期化直後は `currentUser` が `null` かもしれない
   - `authStateChanges()` ストリームの最初のイベントを待つ必要

2. **グループ表示のタイミング問題**
   - `AllGroupsNotifier.build()` がFirebase認証確認前に実行される
   - サインイン状態での Firestore データ取得が遅れる

3. **初期化順序の課題**
   - Auth状態確認 → グループデータ取得 の順序が保証されていない

## 推奨改善案

### Option 1: Auth状態を待ってからグループ初期化
```dart
// AppInitializeWidget で Auth状態を先に確認
final authState = await ref.read(authStateProvider.future);
// その後でグループ初期化
await ref.read(allGroupsProvider.future);
```

### Option 2: AllGroupsNotifier で Auth状態を監視
```dart
@override
Future<List<PurchaseGroup>> build() async {
  // Auth状態を先に確認
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (user) async {
      // ユーザー状態に応じてグループ取得
      return await _getGroupsForUser(user);
    },
    loading: () => [],
    error: (_, __) => await _getLocalGroupsOnly(),
  );
}
```

### Option 3: Firebase Auth初期化完了を待つ
```dart
// main.dart でFirebase Auth完全初期化を待つ
await FirebaseAuth.instance.authStateChanges().first;
```