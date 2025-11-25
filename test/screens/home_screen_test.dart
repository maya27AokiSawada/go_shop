// test/screens/home_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_shop/screens/home_screen.dart';
import 'package:go_shop/providers/page_index_provider.dart';
import 'package:go_shop/providers/auth_provider.dart';
import 'package:go_shop/providers/app_mode_notifier_provider.dart';
import 'package:go_shop/config/app_mode_config.dart';
import 'package:go_shop/pages/home_page.dart';
import 'package:go_shop/pages/purchase_group_page.dart';
import 'package:go_shop/pages/shopping_list_page_v2.dart';
import 'package:go_shop/pages/settings_page.dart';

void main() {
  group('HomeScreen Widget Tests', () {
    testWidgets('HomeScreenが正常にレンダリングされる', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith((ref) => Stream.value(null)),
            appModeNotifierProvider.overrideWith((ref) => AppMode.shopping),
          ],
          child: const MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );

      // Act
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(BottomNavigationBar), findsOneWidget);
    });

    testWidgets('初期状態でHomePageが表示される', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith((ref) => Stream.value(null)),
            appModeNotifierProvider.overrideWith((ref) => AppMode.shopping),
          ],
          child: const MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );

      // Act
      await tester.pumpAndSettle();

      // Assert: 初期状態(pageIndex=0)でHomePageが表示される
      expect(find.byType(HomePage), findsOneWidget);
      expect(find.byType(SharedGroupPage), findsNothing);
      expect(find.byType(ShoppingListPageV2), findsNothing);
      expect(find.byType(SettingsPage), findsNothing);
    });

    testWidgets('BottomNavigationBarに4つのタブが存在する', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith((ref) => Stream.value(null)),
            appModeNotifierProvider.overrideWith((ref) => AppMode.shopping),
          ],
          child: const MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );

      // Act
      await tester.pumpAndSettle();

      // Assert: 4つのBottomNavigationBarItemが存在する
      final bottomNavBar = tester.widget<BottomNavigationBar>(
        find.byType(BottomNavigationBar),
      );
      expect(bottomNavBar.items.length, 4);

      // ラベルの確認
      expect(bottomNavBar.items[0].label, 'ホーム');
      expect(bottomNavBar.items[3].label, '設定');
    });

    testWidgets('タブタップでページが切り替わる（ホーム→設定）', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith((ref) => Stream.value(null)),
            appModeNotifierProvider.overrideWith((ref) => AppMode.shopping),
          ],
          child: const MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 初期状態でHomePageが表示されていることを確認
      expect(find.byType(HomePage), findsOneWidget);
      expect(find.byType(SettingsPage), findsNothing);

      // Act: 設定タブ（インデックス3）をタップ
      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();

      // Assert: SettingsPageが表示される
      expect(find.byType(HomePage), findsNothing);
      expect(find.byType(SettingsPage), findsOneWidget);
    });

    testWidgets('タブタップでページが切り替わる（ホーム→リスト）', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith((ref) => Stream.value(null)),
            appModeNotifierProvider.overrideWith((ref) => AppMode.shopping),
          ],
          child: const MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Act: リストタブ（インデックス2）をタップ
      await tester.tap(find.byIcon(Icons.list));
      await tester.pumpAndSettle();

      // Assert: ShoppingListPageV2が表示される
      expect(find.byType(HomePage), findsNothing);
      expect(find.byType(ShoppingListPageV2), findsOneWidget);
    });

    testWidgets('currentIndexが正しく反映される', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith((ref) => Stream.value(null)),
            appModeNotifierProvider.overrideWith((ref) => AppMode.shopping),
          ],
          child: const MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 初期状態: currentIndex = 0
      var bottomNavBar = tester.widget<BottomNavigationBar>(
        find.byType(BottomNavigationBar),
      );
      expect(bottomNavBar.currentIndex, 0);

      // Act: 設定タブをタップ
      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();

      // Assert: currentIndex = 3
      bottomNavBar = tester.widget<BottomNavigationBar>(
        find.byType(BottomNavigationBar),
      );
      expect(bottomNavBar.currentIndex, 3);
    });

    testWidgets('pageIndexProviderの状態が正しく更新される', (WidgetTester tester) async {
      // Arrange
      int? capturedIndex;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith((ref) => Stream.value(null)),
            appModeNotifierProvider.overrideWith((ref) => AppMode.shopping),
            pageIndexProvider.overrideWith((ref) {
              final notifier = PageIndexNotifier();
              ref.onDispose(() {
                capturedIndex = notifier.state;
              });
              return notifier;
            }),
          ],
          child: MaterialApp(
            home: Consumer(
              builder: (context, ref, child) {
                // 現在のpageIndexを追跡
                capturedIndex = ref.watch(pageIndexProvider);
                return const HomeScreen();
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 初期値の確認
      expect(capturedIndex, 0);

      // Act: リストタブをタップ
      await tester.tap(find.byIcon(Icons.list));
      await tester.pumpAndSettle();

      // Assert: pageIndexが2に更新される
      expect(capturedIndex, 2);
    });

    testWidgets('複数回のタブ切り替えが正常に動作する', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith((ref) => Stream.value(null)),
            appModeNotifierProvider.overrideWith((ref) => AppMode.shopping),
          ],
          child: const MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Act & Assert: ホーム → リスト → 設定 → ホーム
      expect(find.byType(HomePage), findsOneWidget);

      await tester.tap(find.byIcon(Icons.list));
      await tester.pumpAndSettle();
      expect(find.byType(ShoppingListPageV2), findsOneWidget);

      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();
      expect(find.byType(SettingsPage), findsOneWidget);

      await tester.tap(find.byIcon(Icons.home));
      await tester.pumpAndSettle();
      expect(find.byType(HomePage), findsOneWidget);
    });

    testWidgets('開発環境ではグループタブが認証なしでアクセス可能（このテストはスキップ）',
        (WidgetTester tester) async {
      // Note: F.appFlavorのモックが必要なためスキップ
      // 実際のインテグレーションテストで確認を推奨
    }, skip: true);

    testWidgets('本番環境で未認証時にグループタブをタップすると警告が表示される（このテストはスキップ）',
        (WidgetTester tester) async {
      // Note: F.appFlavorのモックが必要なためスキップ
      // 実際のインテグレーションテストで確認を推奨
    }, skip: true);
  });
}
