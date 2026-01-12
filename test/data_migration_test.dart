import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:goshopping/widgets/data_migration_widget.dart';
import 'package:goshopping/services/data_version_service.dart';

void main() {
  group('Data Migration Widget Tests', () {
    testWidgets('DataMigrationWidget displays correctly',
        (WidgetTester tester) async {
      // マイグレーション画面を表示
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: DataMigrationWidget(
              oldVersion: '1.0',
              newVersion: '2.0',
              onMigrationComplete: () {
                // Migration completed callback
              },
            ),
          ),
        ),
      );

      // UI要素が表示されているかチェック
      expect(find.text('データアップデート'), findsOneWidget);
      expect(find.text('バージョン 1.0 → 2.0'), findsOneWidget);

      // プログレスインジケーターが表示されているかチェック
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('Migration starts automatically', (WidgetTester tester) async {
      bool migrationCompleted = false;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: DataMigrationWidget(
              oldVersion: '1.0',
              newVersion: '2.0',
              onMigrationComplete: () {
                migrationCompleted = true;
              },
            ),
          ),
        ),
      );

      // 初期状態でマイグレーション中
      expect(find.text('準備中...'), findsOneWidget);

      // ちょっと待つ
      await tester.pump(const Duration(milliseconds: 500));

      // 何らかの進捗があるはず
      await tester.pumpAndSettle();

      // マイグレーションが完了しているかチェック
      expect(migrationCompleted, isTrue);
    });
  });

  group('Data Version Service Tests', () {
    test('Current version string returns correct value', () {
      final versionString = DataVersionService.currentVersionString;
      expect(versionString, isNotEmpty);
      expect(int.tryParse(versionString), isNotNull);
    });

    test('Current data version is positive integer', () {
      final version = DataVersionService.currentDataVersion;
      expect(version, greaterThan(0));
    });
  });
}
