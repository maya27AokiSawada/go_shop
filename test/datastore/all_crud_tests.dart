import 'package:flutter_test/flutter_test.dart';

import 'shared_group_repository_test.dart' as shared_group_tests;
import 'shared_list_repository_test.dart' as shared_list_tests;
import 'integration_crud_test.dart' as integration_tests;

void main() {
  group('全CRUDテスト実行', () {
    print('\n========================================');
    print('GoShopping - CRUD Unit Tests');
    print('========================================\n');

    shared_group_tests.main();
    shared_list_tests.main();
    integration_tests.main();

    print('\n========================================');
    print('全テスト完了');
    print('========================================\n');
  });
}
