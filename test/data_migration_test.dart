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
      expect(find.text('v1.0 → v2.0'), findsOneWidget);
      expect(find.text('データを更新する'), findsOneWidget);

      // 初期状態では開始ボタン表示（マイグレーションはまだ未開始）
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('Migration waits for button tap', (WidgetTester tester) async {
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

      // 現在仕様: ボタン押下まではマイグレーションを開始しない
      expect(find.text('データを更新する'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsNothing);
      expect(migrationCompleted, isFalse);
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
