import 'package:flutter_test/flutter_test.dart';
import 'package:goshopping/services/group_key_exchange_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late GroupKeyExchangeService service;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    service = GroupKeyExchangeService();
  });

  test('persisted group key returns null before any exchange', () async {
    final key = await service.getPersistedGroupKey(groupId: 'group-a');
    expect(key, isNull);
  });

  test('groups without a configured key use plaintext fallback', () async {
    final mode = await service.getGroupKeyMode(groupId: 'group-a');
    expect(mode, GroupKeyMode.plaintext);
  });

  test('owner can create and persist a new group key', () async {
    final created = await service.ensureGroupKeyForOwner(
      groupId: 'group-a',
      ownerUid: 'owner-a',
      memberUids: ['member-a'],
      forceRefresh: true,
    );

    expect(created, isTrue);
    final persisted = await service.getPersistedGroupKey(groupId: 'group-a');
    expect(persisted, isNotNull);
    expect(persisted, isNotEmpty);
  });

  test('reencrypts shared item payloads when a group key exists', () async {
    await service.ensureGroupKeyForOwner(
      groupId: 'group-b',
      ownerUid: 'owner-b',
      memberUids: ['member-b'],
      forceRefresh: true,
    );

    await service.reencryptSharedItemsForGroup(
      groupId: 'group-b',
      items: [
        {'memberId': 'member-b', 'name': 'milk'},
      ],
    );

    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList('group_key_v1:group-b_items');
    expect(stored, isNotNull);
    expect(stored, isNotEmpty);
  });

  test('decrypts item names with the recipient secret', () async {
    const encryptedName = 'encrypted-name';
    const memberUid = 'member-c';
    const groupId = 'group-c';

    final encrypted = service.encryptItemName(
      plaintextName: 'milk',
      memberUid: memberUid,
      groupId: groupId,
    );
    final decrypted = service.decryptItemName(
      encryptedName: encrypted,
      groupKey: '',
      memberUid: memberUid,
      groupId: groupId,
    );

    expect(decrypted, 'milk');
    expect(encrypted, isNotNull);
    expect(encrypted, isNotEmpty);
  });
}
