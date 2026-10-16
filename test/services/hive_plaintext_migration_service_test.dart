import 'package:flutter_test/flutter_test.dart';
import 'package:goshopping/datastore/hive_shared_group_repository.dart';
import 'package:goshopping/datastore/hive_shared_list_repository.dart';
import 'package:goshopping/datastore/shared_group_firestore_codec.dart';
import 'package:goshopping/models/shared_list.dart';
import 'package:goshopping/services/group_key_exchange_service.dart';
import 'package:goshopping/services/hive_plaintext_migration_service.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _groupId = 'group-migrate';
const _memberUid = 'member-migrate';

class _FakeHiveListRepository extends Mock implements HiveSharedListRepository {
  _FakeHiveListRepository(this.lists);

  final List<SharedList> lists;
  final List<SharedList> saved = [];

  @override
  List<SharedList> getAllLists() => lists;

  @override
  Future<void> updateSharedList(SharedList list) async => saved.add(list);
}

class _FakeHiveGroupRepository extends Mock
    implements HiveSharedGroupRepository {}

SharedList _list(Map<String, String> names) {
  return SharedList(
    ownerUid: _memberUid,
    groupId: _groupId,
    groupName: 'group',
    listId: 'list-migrate',
    listName: 'list',
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 2),
    items: {
      for (final entry in names.entries)
        entry.key: SharedItem(
          memberId: _memberUid,
          name: entry.value,
          registeredDate: DateTime(2026, 1, 1),
          itemId: entry.key,
        ),
    },
  );
}

void main() {
  late GroupKeyExchangeService keyService;

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'group_key_v1:$_groupId': 'key-current',
      // 旧実装が残した平文アイテム名と鍵変更マーカー
      'group_key_v1:${_groupId}_items': <String>['{"name":"milk"}'],
      'group_key_fingerprint_v1:$_groupId': 'key-current',
    });
    keyService = GroupKeyExchangeService();
    await keyService.getPersistedGroupKey(groupId: _groupId);
  });

  test('Hive の暗号文を平文にし、updatedAt は変えない', () async {
    final encrypted = keyService.encryptItemName(
      plaintextName: 'milk',
      memberUid: _memberUid,
      groupId: _groupId,
    );
    final listRepository = _FakeHiveListRepository([
      _list({'item-1': encrypted, 'item-2': 'eggs'}),
    ]);

    await HivePlaintextMigrationService.runIfNeeded(
      hiveListRepository: listRepository,
      hiveGroupRepository: _FakeHiveGroupRepository(),
      keyService: keyService,
      codec: const SharedGroupFirestoreCodec(),
    );

    final saved = listRepository.saved.single;
    expect(saved.items['item-1']?.name, 'milk');
    expect(saved.items['item-2']?.name, 'eggs');
    expect(saved.updatedAt, DateTime(2026, 1, 2));
  });

  test('旧実装の平文保存キーを削除し、2回目は何もしない', () async {
    final listRepository = _FakeHiveListRepository([
      _list({'item-1': 'eggs'}),
    ]);

    await HivePlaintextMigrationService.runIfNeeded(
      hiveListRepository: listRepository,
      hiveGroupRepository: _FakeHiveGroupRepository(),
      keyService: keyService,
      codec: const SharedGroupFirestoreCodec(),
    );

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getStringList('group_key_v1:${_groupId}_items'), isNull);
    expect(prefs.getString('group_key_fingerprint_v1:$_groupId'), isNull);
    expect(prefs.getString('group_key_v1:$_groupId'), 'key-current',
        reason: 'グループ鍵そのものは消さない');
    expect(listRepository.saved, isEmpty, reason: '平文のみのリストは保存し直さない');

    final secondRun = _FakeHiveListRepository([
      _list({'item-1': 'eggs'}),
    ]);
    await HivePlaintextMigrationService.runIfNeeded(
      hiveListRepository: secondRun,
      hiveGroupRepository: _FakeHiveGroupRepository(),
      keyService: keyService,
      codec: const SharedGroupFirestoreCodec(),
    );
    expect(secondRun.saved, isEmpty);
  });
}
