// FirestoreSharedListRepository のアイテム名暗号化境界のテスト。
//
// Firestore 上は暗号文、リポジトリより上は平文で扱うこと、
// 平文・旧鍵のアイテムを現行鍵で書き戻すことを確認する。

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goshopping/datastore/firestore_shared_list_repository.dart';
import 'package:goshopping/models/shared_list.dart';
import 'package:goshopping/providers/firestore_provider.dart';
import 'package:goshopping/services/group_key_exchange_service.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/invitation_key_exchange_test.mocks.dart';

const _groupId = 'group-crypto';
const _listId = 'list-crypto';
const _memberUid = 'member-crypto';

class _Fixture {
  _Fixture() {
    when(firestore.collection('SharedGroups')).thenReturn(groupsCollection);
    when(groupsCollection.doc(_groupId)).thenReturn(groupDoc);
    when(groupDoc.collection('sharedLists')).thenReturn(listsCollection);
    when(listsCollection.doc(_listId)).thenReturn(listDoc);
    when(listDoc.update(any)).thenAnswer((invocation) async {
      updates.add(Map<String, dynamic>.from(
          invocation.positionalArguments.first as Map));
    });
    when(listDoc.set(any)).thenAnswer((invocation) async {
      writes.add(Map<String, dynamic>.from(
          invocation.positionalArguments.first as Map));
    });
  }

  final firestore = MockFirebaseFirestore();
  final groupsCollection = MockCollectionReference<Map<String, dynamic>>();
  final groupDoc = MockDocumentReference<Map<String, dynamic>>();
  final listsCollection = MockCollectionReference<Map<String, dynamic>>();
  final listDoc = MockDocumentReference<Map<String, dynamic>>();
  final updates = <Map<String, dynamic>>[];
  final writes = <Map<String, dynamic>>[];

  /// 鍵サービスは Firestore を持たない（版数確認はオフライン扱い＝手元の鍵を使う）。
  final keyService = GroupKeyExchangeService();

  FirestoreSharedListRepository createRepository() {
    final container = ProviderContainer(overrides: [
      firestoreProvider.overrideWithValue(firestore),
      groupKeyExchangeServiceProvider.overrideWithValue(keyService),
    ]);
    addTearDown(container.dispose);
    return container.read(
      Provider((ref) => FirestoreSharedListRepository(ref)),
    );
  }

  MockDocumentSnapshot<Map<String, dynamic>> listSnapshot(
      Map<String, String> itemNames) {
    final snapshot = MockDocumentSnapshot<Map<String, dynamic>>();
    when(snapshot.exists).thenReturn(true);
    when(snapshot.data()).thenReturn({
      'listId': _listId,
      'ownerUid': _memberUid,
      'groupId': _groupId,
      'groupName': 'group',
      'listName': 'list',
      'description': '',
      'items': {
        for (final entry in itemNames.entries)
          entry.key: {
            'memberId': _memberUid,
            'name': entry.value,
            'quantity': 1,
            'registeredDate': Timestamp.fromDate(DateTime(2026, 1, 1)),
            'isPurchased': false,
            'shoppingInterval': 0,
            'itemId': entry.key,
            'isDeleted': false,
          },
      },
      'createdAt': Timestamp.fromDate(DateTime(2026, 1, 1)),
      'updatedAt': Timestamp.fromDate(DateTime(2026, 1, 2)),
    });
    return snapshot;
  }
}

Future<String> _encrypt(GroupKeyExchangeService service, String plaintext) {
  return Future.value(service.encryptItemName(
    plaintextName: plaintext,
    memberUid: _memberUid,
    groupId: _groupId,
  ));
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({
      'group_key_v1:$_groupId': 'key-current',
      'group_key_version_v1:$_groupId': 1,
    });
  });

  test('読み込み時にアイテム名を復号して平文で返す', () async {
    final fixture = _Fixture();
    await fixture.keyService.getPersistedGroupKey(groupId: _groupId);
    final encrypted = await _encrypt(fixture.keyService, 'milk');
    when(fixture.listDoc.snapshots()).thenAnswer(
      (_) => Stream.value(fixture.listSnapshot({'item-1': encrypted})),
    );

    final repository = fixture.createRepository();
    final list =
        await repository.watchSharedList(_groupId, _listId).first;

    expect(list?.items['item-1']?.name, 'milk');
    await pumpEventQueue();
    expect(fixture.updates, isEmpty, reason: '現行鍵の暗号文は書き戻さない');
  });

  test('鍵設定済みグループの平文アイテムは現行鍵で暗号化して書き戻す', () async {
    final fixture = _Fixture();
    when(fixture.listDoc.snapshots()).thenAnswer(
      (_) => Stream.value(fixture.listSnapshot({'item-1': 'eggs'})),
    );

    final repository = fixture.createRepository();
    final list =
        await repository.watchSharedList(_groupId, _listId).first;
    await pumpEventQueue();

    expect(list?.items['item-1']?.name, 'eggs');
    expect(fixture.updates, hasLength(1));
    final written = fixture.updates.single['items.item-1.name'] as String;
    expect(written, isNot('eggs'));
    expect(fixture.keyService.isEncryptedItemName(written), isTrue);
    expect(
      fixture.keyService
          .tryDecryptItemName(
            encryptedName: written,
            memberUid: _memberUid,
            groupId: _groupId,
          )
          ?.name,
      'eggs',
    );
  });

  test('旧鍵の暗号文は復号して返し、現行鍵で書き戻す', () async {
    // 旧鍵で暗号化
    SharedPreferences.setMockInitialValues(
        {'group_key_v1:$_groupId': 'key-old'});
    final oldService = GroupKeyExchangeService();
    await oldService.getPersistedGroupKey(groupId: _groupId);
    final oldCiphertext = await _encrypt(oldService, 'bread');

    // 現行鍵へローテーション済みの端末
    SharedPreferences.setMockInitialValues({
      'group_key_v1:$_groupId': 'key-new',
      'group_key_previous_v1:$_groupId': 'key-old',
      'group_key_version_v1:$_groupId': 2,
    });
    final fixture = _Fixture();
    when(fixture.listDoc.snapshots()).thenAnswer(
      (_) => Stream.value(fixture.listSnapshot({'item-1': oldCiphertext})),
    );

    final repository = fixture.createRepository();
    final list =
        await repository.watchSharedList(_groupId, _listId).first;
    await pumpEventQueue();

    expect(list?.items['item-1']?.name, 'bread');
    expect(fixture.updates, hasLength(1));
    final written = fixture.updates.single['items.item-1.name'] as String;
    final result = fixture.keyService.tryDecryptItemName(
      encryptedName: written,
      memberUid: _memberUid,
      groupId: _groupId,
    );
    expect(result?.name, 'bread');
    expect(result?.needsReencrypt, isFalse, reason: '現行鍵で暗号化されている');
  });

  test('リスト保存時は平文のアイテム名を暗号化して書き込む', () async {
    final fixture = _Fixture();
    final existing = MockDocumentSnapshot<Map<String, dynamic>>();
    when(existing.exists).thenReturn(false);
    when(fixture.listDoc.get()).thenAnswer((_) async => existing);

    final repository = fixture.createRepository();
    await repository.updateSharedList(SharedList(
      ownerUid: _memberUid,
      groupId: _groupId,
      groupName: 'group',
      listId: _listId,
      listName: 'list',
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 2),
      items: {
        'item-1': SharedItem(
          memberId: _memberUid,
          name: 'tofu',
          registeredDate: DateTime(2026, 1, 1),
          itemId: 'item-1',
        ),
      },
    ));

    final items = fixture.writes.single['items'] as Map<String, dynamic>;
    final written = (items['item-1'] as Map<String, dynamic>)['name'] as String;
    expect(written, isNot('tofu'));
    expect(
      fixture.keyService
          .tryDecryptItemName(
            encryptedName: written,
            memberUid: _memberUid,
            groupId: _groupId,
          )
          ?.name,
      'tofu',
    );
  });
}
