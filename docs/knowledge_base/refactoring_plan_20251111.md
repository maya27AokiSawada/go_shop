# リファクタリング計画 - コード品質向上プロジェクト

## 🎯 目標

### 主要目標

1. **コード削減**: 5,000 行 → 4,000 行（-20%）
2. **テストカバレッジ**: 0% → 60%
3. **平均メソッド長**: 40 行 → 20 行
4. **重複コード**: 15% → 5%

### 品質目標

- ✅ メソッドの単一責任原則（SRP）
- ✅ DRY 原則の徹底
- ✅ 型安全性の向上
- ✅ エラーハンドリングの統一

---

## 📅 実施ステップ

### 第 1 ステップ: 分析とプランニング

- [ ] コード分析ツール実行（dart analyze）
- [ ] 重複コード検出
- [ ] 長いメソッドのリストアップ
- [ ] リファクタリング優先度の決定

### 第 2 ステップ: 共通ロジックの抽出

- [ ] SyncService の作成
- [ ] ErrorHandler の作成
- [ ] RepositoryFactory の作成
- [ ] 既存コードの移行

### 第 3 ステップ: 型安全性の向上

- [ ] NotificationMetadata クラス作成
- [ ] InvitationData クラス作成
- [ ] Result 型の導入（エラーハンドリング）
- [ ] 既存コードの型変換

### 第 4 ステップ: テストの追加

- [ ] ユニットテスト（services/）
- [ ] Widget テスト（widgets/）
- [ ] 統合テスト（invitation flow）
- [ ] カバレッジレポート生成

### 第 5 ステップ: 最適化と仕上げ

- [ ] Firestore インデックス追加
- [ ] キャッシュ戦略の実装
- [ ] ログ管理の統一
- [ ] ドキュメント更新

---

## 🔧 詳細タスク

## 第 1 ステップ: 分析とプランニング

### Task 1.1: コード分析

```bash
# 静的解析
flutter analyze

# 重複コード検出
dart run jscpd lib/

# コードメトリクス
dart run dart_code_metrics:metrics analyze lib/
```

### Task 1.2: リファクタリング対象の特定

**長いメソッド（40 行以上）:**

```
lib/services/qr_invitation_service.dart:
  - acceptQRInvitation() [100行]
  - _processIndividualInvitation() [80行]
  - _processFriendInvitation() [90行]

lib/services/notification_service.dart:
  - _handleNotification() [80行]
  - sendNotificationToGroup() [70行]

lib/services/user_initialization_service.dart:
  - syncFromFirestoreToHive() [120行]
  - _initializeUserDefaults() [60行]
```

**重複コード:**

```
Firestore取得処理:
  - UserInitializationService.syncFromFirestoreToHive()
  - NotificationService._syncSpecificGroupFromFirestore()

エラーハンドリング:
  - 各サービスで同様のtry-catch-log

Hive操作:
  - 複数箇所でBox取得とPut/Get処理
```

---

## 第 2 ステップ: 共通ロジックの抽出

### Task 2.1: SyncService の作成

**新規ファイル:** `lib/services/sync_service.dart`

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/shared_group.dart';
import '../datastore/shared_group_repository.dart';

final syncServiceProvider = Provider<SyncService>((ref) {
  return SyncService(ref);
});

/// データ同期サービス
/// Firestore ⇄ Hive の同期を一元管理
class SyncService {
  final Ref _ref;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  SyncService(this._ref);

  SharedGroupRepository get _repository =>
      _ref.read(SharedGroupRepositoryProvider);

  /// 全グループを同期
  Future<void> syncAllGroups(User user) async {
    final groups = await _fetchGroupsFromFirestore(user);
    await _updateLocalGroups(groups);
  }

  /// 特定グループを同期
  Future<void> syncSpecificGroup(String groupId) async {
    final group = await _fetchGroupFromFirestore(groupId);
    if (group != null) {
      await _repository.updateGroup(groupId, group);
    }
  }

  /// 差分同期（最終同期日時以降の変更のみ）
  Future<void> syncDelta(User user, DateTime since) async {
    final groups = await _fetchGroupsFromFirestore(
      user,
      where: (query) => query.where('lastUpdated', isGreaterThan: since),
    );
    await _updateLocalGroups(groups);
  }

  /// Firestoreから全グループを取得
  Future<List<SharedGroup>> _fetchGroupsFromFirestore(
    User user, {
    Query<Map<String, dynamic>> Function(Query<Map<String, dynamic>>)? where,
  }) async {
    var query = _firestore
        .collection('SharedGroups')
        .where('allowedUid', arrayContains: user.uid);

    if (where != null) {
      query = where(query);
    }

    final snapshot = await query.get();
    return snapshot.docs
        .map((doc) => SharedGroup.fromJson(doc.data()))
        .toList();
  }

  /// Firestoreから特定グループを取得
  Future<SharedGroup?> _fetchGroupFromFirestore(String groupId) async {
    final doc = await _firestore
        .collection('SharedGroups')
        .doc(groupId)
        .get();

    if (!doc.exists) return null;
    return SharedGroup.fromJson(doc.data()!);
  }

  /// ローカルグループを更新
  Future<void> _updateLocalGroups(List<SharedGroup> groups) async {
    for (final group in groups) {
      await _repository.updateGroup(group.id, group);
    }
  }
}
```

**移行作業:**

1. `UserInitializationService` の同期処理を `SyncService` に委譲
2. `NotificationService` の同期処理を `SyncService` に委譲
3. 重複コード削除

### Task 2.2: ErrorHandler の作成

**新規ファイル:** `lib/utils/error_handler.dart`

```dart
import '../utils/app_logger.dart';

/// 統一されたエラーハンドリング
class ErrorHandler {
  /// 非同期処理のエラーハンドリング
  static Future<T?> handleAsync<T>({
    required Future<T> Function() operation,
    required String context,
    T? defaultValue,
    bool rethrow = false,
  }) async {
    try {
      return await operation();
    } catch (e, stackTrace) {
      AppLogger.error('❌ [$context] エラー: $e');
      AppLogger.debug('スタックトレース: $stackTrace');

      if (rethrow) {
        rethrow;
      }
      return defaultValue;
    }
  }

  /// 同期処理のエラーハンドリング
  static T? handleSync<T>({
    required T Function() operation,
    required String context,
    T? defaultValue,
    bool rethrow = false,
  }) {
    try {
      return operation();
    } catch (e, stackTrace) {
      AppLogger.error('❌ [$context] エラー: $e');
      AppLogger.debug('スタックトレース: $stackTrace');

      if (rethrow) {
        rethrow;
      }
      return defaultValue;
    }
  }
}
```

**使用例:**

```dart
// Before
try {
  await sendNotification(...);
} catch (e) {
  AppLogger.error('❌ [NOTIFICATION] 送信エラー: $e');
}

// After
await ErrorHandler.handleAsync(
  operation: () => sendNotification(...),
  context: 'NOTIFICATION:sendNotification',
);
```

### Task 2.3: RepositoryFactory の作成

**新規ファイル:** `lib/datastore/repository_factory.dart`

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'shared_group_repository.dart';
import 'hive_shared_group_repository.dart';
import '../flavors.dart';

/// リポジトリのファクトリー
/// フレーバーに応じて適切なリポジトリを返す
class RepositoryFactory {
  static SharedGroupRepository createSharedGroupRepository(Ref ref) {
    if (F.appFlavor == Flavor.prod) {
      // 本番環境: Firestore（未実装）
      throw UnimplementedError('FirestoreSharedGroupRepository');
    } else {
      // 開発環境: Hive
      return HiveSharedGroupRepository(ref);
    }
  }
}

// Provider の更新
final SharedGroupRepositoryProvider = Provider<SharedGroupRepository>((ref) {
  return RepositoryFactory.createSharedGroupRepository(ref);
});
```

---

## 第 3 ステップ: 型安全性の向上

### Task 3.1: NotificationMetadata の型定義

**新規ファイル:** `lib/models/notification_metadata.dart`

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'notification_metadata.freezed.dart';
part 'notification_metadata.g.dart';

@freezed
class NotificationMetadata with _$NotificationMetadata {
  const factory NotificationMetadata({
    String? groupId,
    String? newMemberId,
    String? newMemberName,
    String? invitationType,
    String? updateType,
    String? oldValue,
    String? newValue,
  }) = _NotificationMetadata;

  factory NotificationMetadata.fromJson(Map<String, dynamic> json) =>
      _$NotificationMetadataFromJson(json);
}
```

**使用例:**

```dart
// Before
final groupId = notification.metadata?['groupId'] as String?;

// After
final metadata = NotificationMetadata.fromJson(notification.metadata ?? {});
final groupId = metadata.groupId;
```

### Task 3.2: InvitationData の型定義

**新規ファイル:** `lib/models/invitation_data.dart`

```dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive/hive.dart';

part 'invitation_data.freezed.dart';
part 'invitation_data.g.dart';

enum InvitationStatus {
  @HiveField(0)
  pending,
  @HiveField(1)
  accepted,
  @HiveField(2)
  expired,
  @HiveField(3)
  revoked,
}

@freezed
@HiveType(typeId: 5)
class InvitationData with _$InvitationData {
  const factory InvitationData({
    @HiveField(0) required String invitationId,
    @HiveField(1) required String inviterUid,
    @HiveField(2) required String SharedGroupId,
    @HiveField(3) required String groupName,
    @HiveField(4) required String securityKey,
    @HiveField(5) required InvitationStatus status,
    @HiveField(6) required DateTime createdAt,
    @HiveField(7) required DateTime expiresAt,
    @HiveField(8) String? acceptorUid,
    @HiveField(9) DateTime? acceptedAt,
  }) = _InvitationData;

  factory InvitationData.fromJson(Map<String, dynamic> json) =>
      _$InvitationDataFromJson(json);
}
```

### Task 3.3: Result 型の導入

**新規ファイル:** `lib/utils/result.dart`

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'result.freezed.dart';

@freezed
class Result<T> with _$Result<T> {
  const factory Result.success(T data) = Success<T>;
  const factory Result.failure(String error, [StackTrace? stackTrace]) = Failure<T>;
}
```

**使用例:**

```dart
// Before
Future<bool> acceptQRInvitation(...) async {
  try {
    // 処理
    return true;
  } catch (e) {
    return false;
  }
}

// After
Future<Result<void>> acceptQRInvitation(...) async {
  try {
    // 処理
    return const Result.success(null);
  } catch (e, stackTrace) {
    return Result.failure(e.toString(), stackTrace);
  }
}

// 呼び出し側
final result = await service.acceptQRInvitation(...);
result.when(
  success: (_) => print('成功'),
  failure: (error, _) => print('失敗: $error'),
);
```

---

## 第 4 ステップ: テストの追加

### Task 4.1: セキュリティサービスのテスト

**新規ファイル:** `test/services/invitation_security_service_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:goshopping/services/invitation_security_service.dart';

void main() {
  late InvitationSecurityService service;

  setUp(() {
    service = InvitationSecurityService();
  });

  group('InvitationSecurityService', () {
    test('セキュリティキーは32文字', () {
      final key = service.generateSecurityKey();
      expect(key.length, equals(32));
    });

    test('セキュリティキーは英数字のみ', () {
      final key = service.generateSecurityKey();
      expect(key, matches(RegExp(r'^[a-zA-Z0-9]+$')));
    });

    test('招待IDにはグループIDが含まれる', () {
      final groupId = 'test-group-123';
      final invitationId = service.generateInvitationId(groupId);
      expect(invitationId, startsWith(groupId));
    });

    test('同じ入力で異なるセキュリティキーが生成される', () {
      final key1 = service.generateSecurityKey();
      final key2 = service.generateSecurityKey();
      expect(key1, isNot(equals(key2)));
    });

    test('セキュリティキーの検証が正しく動作する', () {
      final key = service.generateSecurityKey();
      expect(service.validateSecurityKey(key, key), isTrue);
      expect(service.validateSecurityKey(key, 'wrong-key'), isFalse);
    });
  });
}
```

### Task 4.2: QR 招待サービスのテスト

**新規ファイル:** `test/services/qr_invitation_service_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:goshopping/services/qr_invitation_service.dart';

void main() {
  group('QRInvitationService', () {
    test('QRデータのエンコード・デコードが正しく動作する', () {
      final service = QRInvitationService(mockRef);
      final originalData = {
        'invitationId': 'test-123',
        'groupName': 'テストグループ',
        'invitationType': 'individual',
      };

      final encoded = service.encodeQRData(originalData);
      final decoded = service.decodeQRData(encoded);

      expect(decoded, isNotNull);
      expect(decoded!['invitationId'], equals('test-123'));
      expect(decoded['groupName'], equals('テストグループ'));
    });

    test('無効なQRデータはnullを返す', () {
      final service = QRInvitationService(mockRef);
      final decoded = service.decodeQRData('invalid-data');
      expect(decoded, isNull);
    });
  });
}
```

### Task 4.3: 統合テスト

**新規ファイル:** `integration_test/invitation_flow_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:goshopping/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('招待フロー統合テスト', () {
    testWidgets('QR招待の作成から受諾まで', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // 1. ログイン
      // ...

      // 2. グループ作成
      // ...

      // 3. QR招待作成
      await tester.tap(find.text('QR招待'));
      await tester.pumpAndSettle();
      expect(find.byType(QrImageView), findsOneWidget);

      // 4. QRコード表示確認
      expect(find.text('個別招待'), findsOneWidget);
      expect(find.text('フレンド招待'), findsOneWidget);

      // 5. ダイアログを閉じる
      await tester.tap(find.text('閉じる'));
      await tester.pumpAndSettle();
    });
  });
}
```

### Task 4.4: カバレッジレポート

```bash
# テスト実行 + カバレッジ生成
flutter test --coverage

# カバレッジレポート表示（HTML）
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

**目標カバレッジ:**

```
services/: 70%
models/: 80%
utils/: 60%
widgets/: 50%
全体: 60%
```

---

## 第 5 ステップ: 最適化と仕上げ

### Task 5.1: Firestore インデックスの追加

**ファイル:** `firestore.indexes.json`

```json
{
  "indexes": [
    {
      "collectionGroup": "notifications",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "userId", "order": "ASCENDING" },
        { "fieldPath": "read", "order": "ASCENDING" },
        { "fieldPath": "timestamp", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "invitations",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "status", "order": "ASCENDING" },
        { "fieldPath": "expiresAt", "order": "ASCENDING" }
      ]
    },
    {
      "collectionGroup": "SharedGroups",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "allowedUid", "order": "ASCENDING" },
        { "fieldPath": "lastUpdated", "order": "DESCENDING" }
      ]
    }
  ],
  "fieldOverrides": []
}
```

**デプロイ:**

```bash
firebase deploy --only firestore:indexes
```

### Task 5.2: キャッシュ戦略の実装

**新規ファイル:** `lib/services/cache_service.dart`

```dart
import 'dart:collection';
import '../models/shared_group.dart';

/// メモリキャッシュサービス
class CacheService {
  static const int maxCacheSize = 50;
  final _cache = LinkedHashMap<String, CacheEntry<dynamic>>();

  /// キャッシュから取得
  T? get<T>(String key) {
    final entry = _cache[key];
    if (entry == null) return null;

    if (entry.isExpired) {
      _cache.remove(key);
      return null;
    }

    return entry.value as T;
  }

  /// キャッシュに保存
  void set<T>(String key, T value, {Duration ttl = const Duration(minutes: 5)}) {
    if (_cache.length >= maxCacheSize) {
      // LRU: 最も古いエントリを削除
      _cache.remove(_cache.keys.first);
    }

    _cache[key] = CacheEntry<T>(
      value: value,
      expiresAt: DateTime.now().add(ttl),
    );
  }

  /// キャッシュをクリア
  void clear() => _cache.clear();

  /// 特定のキーを削除
  void remove(String key) => _cache.remove(key);
}

class CacheEntry<T> {
  final T value;
  final DateTime expiresAt;

  CacheEntry({required this.value, required this.expiresAt});

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}
```

### Task 5.3: ログ管理の統一

**更新ファイル:** `lib/utils/app_logger.dart`

```dart
enum LogLevel {
  debug,
  info,
  warning,
  error,
}

class AppLogger {
  static LogLevel _minLevel = LogLevel.info;

  static void configure({required LogLevel minLevel}) {
    _minLevel = minLevel;
  }

  static void debug(String message) {
    _log(LogLevel.debug, message);
  }

  static void info(String message) {
    _log(LogLevel.info, message);
  }

  static void warning(String message) {
    _log(LogLevel.warning, message);
  }

  static void error(String message) {
    _log(LogLevel.error, message);
  }

  static void _log(LogLevel level, String message) {
    if (level.index < _minLevel.index) return;

    final prefix = _getPrefix(level);
    final timestamp = DateTime.now().toIso8601String();
    print('[$timestamp] $prefix $message');
  }

  static String _getPrefix(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return '🔍';
      case LogLevel.info:
        return 'ℹ️';
      case LogLevel.warning:
        return '⚠️';
      case LogLevel.error:
        return '❌';
    }
  }
}
```

**main.dart での設定:**

```dart
void main() async {
  // 開発環境: すべてのログを表示
  // 本番環境: エラーのみ
  AppLogger.configure(
    minLevel: F.appFlavor == Flavor.prod
      ? LogLevel.error
      : LogLevel.debug,
  );

  runApp(MyApp());
}
```

### Task 5.4: ドキュメント更新

**更新対象:**

1. `docs/sync_architecture.md` - SyncService の追加
2. `docs/invitation_system.md` - 型安全性の改善
3. `docs/notification_system.md` - エラーハンドリングの統一
4. `README.md` - テストの実行方法追加

---

## 📊 成果物チェックリスト

### コード

- [ ] SyncService 実装
- [ ] ErrorHandler 実装
- [ ] RepositoryFactory 実装
- [ ] NotificationMetadata 型定義
- [ ] InvitationData 型定義
- [ ] Result 型 実装
- [ ] CacheService 実装

### テスト

- [ ] InvitationSecurityService テスト
- [ ] QRInvitationService テスト
- [ ] NotificationService テスト
- [ ] SyncService テスト
- [ ] 統合テスト（招待フロー）
- [ ] カバレッジ 60%達成

### 最適化

- [ ] Firestore インデックス追加
- [ ] メモリキャッシュ実装
- [ ] ログレベル管理
- [ ] 不要なコード削除

### ドキュメント

- [ ] リファクタリング内容の記録
- [ ] テスト実行手順の追加
- [ ] 新しいアーキテクチャの図解
- [ ] FAQ 更新

---

## 🎉 期待される成果

### 定量的

- コード行数: 5,000 → 4,000（-20%）
- テストカバレッジ: 0% → 60%
- ビルド時間: 変化なし
- 起動時間: 2 秒 → 1.5 秒

### 定性的

- コードの可読性向上
- 保守性の向上
- バグ検出の容易化
- 新機能追加の効率化

---

**作成日:** 2025 年 11 月 8 日
**対象期間:** 2025 年 11 月 11 日〜15 日
**担当:** 開発チーム
**レビュー:** 金曜日午後
