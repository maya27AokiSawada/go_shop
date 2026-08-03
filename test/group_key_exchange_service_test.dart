import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:goshopping/services/group_key_exchange_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  group('GroupKeyExchangeService', () {
    test('returns false when no persisted group key exists', () async {
      final service = GroupKeyExchangeService();

      final hasUsableKey = await service.hasUsableGroupKey(groupId: 'group-1');

      expect(hasUsableKey, isFalse);
    });

    test('returns true when a persisted group key exists', () async {
      SharedPreferences.setMockInitialValues({
        'group_key_v1:group-1': 'sample-key',
      });
      final service = GroupKeyExchangeService();

      final hasUsableKey = await service.hasUsableGroupKey(groupId: 'group-1');

      expect(hasUsableKey, isTrue);
    });

    test('waits until a persisted group key becomes available', () async {
      SharedPreferences.setMockInitialValues({});
      final service = GroupKeyExchangeService();

      final future = service.waitForUsableGroupKey(
        groupId: 'group-1',
        checkInterval: const Duration(milliseconds: 20),
        maxAttempts: 5,
      );

      await Future.delayed(const Duration(milliseconds: 30));
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('group_key_v1:group-1', 'sample-key');

      final hasUsableKey = await future;

      expect(hasUsableKey, isTrue);
    });
  });
}
