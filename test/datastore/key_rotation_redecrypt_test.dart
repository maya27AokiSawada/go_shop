// 鍵ローテーション直後に、画面遷移なしで新しい鍵へ切り替えて復号できることのテスト。
//
// 再現する状況: 端末の鍵は旧鍵のまま、データは新しい鍵で再暗号化済み、
// 鍵の確認結果は使い回し中（最初の確認では新しい鍵を取りに行かない）。

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goshopping/datastore/firestore_shared_list_repository.dart';
import 'package:goshopping/datastore/group_field_cipher.dart';
import 'package:goshopping/datastore/shared_group_firestore_codec.dart';
import 'package:goshopping/models/shared_group.dart';
import 'package:goshopping/providers/firestore_provider.dart';
import 'package:goshopping/services/group_key_exchange_service.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/invitation_key_exchange_test.mocks.dart';

const _groupId = 'group-redecrypt';
const _listId = 'list-redecrypt';
const _memberUid = 'member-redecrypt';

/// 確認結果を使い回している間は何もせず、[markGroupKeyStale] の後の確認で
/// 新しい鍵を受け取る（ローテーション直後の鍵解決を模擬）。
class _StaleThenFreshKeyService extends GroupKeyExchangeService {
  bool _stale = false;
  int resolveCount = 0;

  @override
  void markGroupKeyStale({required String groupId}) {
    _stale = true;
    super.markGroupKeyStale(groupId: groupId);
  }

  @override
  Future<bool> ensureFreshGroupKey({
    required String groupId,
    int? activeKeyVersion,
  }) async {
    if (_stale) {
      _stale = false;
      resolveCount++;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('group_key_previous_v1:$groupId', 'key-old');
      await prefs.setString('group_key_v1:$groupId', 'key-new');
    }
    final key = await getPersistedGroupKey(groupId: groupId);
    return key != null && key.isNotEmpty;
  }
}

/// [groupKey] を現行鍵として持つ端末のサービス。
Future<GroupKeyExchangeService> _serviceWithKey(String groupKey) async {
  SharedPreferences.setMockInitialValues({'group_key_v1:$_groupId': groupKey});
  final service = GroupKeyExchangeService();
  await service.getPersistedGroupKey(groupId: _groupId);
  return service;
}

void main() {
  test('リスト: 新しい鍵の暗号文を受け取ったら、鍵を取り直して同じ読み込みで復号する', () async {
    final newKeyService = await _serviceWithKey('key-new');
    final encrypted = newKeyService.encryptItemName(
      plaintextName: 'milk',
      memberUid: _memberUid,
      groupId: _groupId,
    );

    SharedPreferences.setMockInitialValues({'group_key_v1:$_groupId': 'key-old'});
    final keyService = _StaleThenFreshKeyService();

    final firestore = MockFirebaseFirestore();
    final groupsCollection = MockCollectionReference<Map<String, dynamic>>();
    final groupDoc = MockDocumentReference<Map<String, dynamic>>();
    final listsCollection = MockCollectionReference<Map<String, dynamic>>();
    final listDoc = MockDocumentReference<Map<String, dynamic>>();
    final snapshot = MockDocumentSnapshot<Map<String, dynamic>>();
    when(firestore.collection('SharedGroups')).thenReturn(groupsCollection);
    when(groupsCollection.doc(_groupId)).thenReturn(groupDoc);
    when(groupDoc.collection('sharedLists')).thenReturn(listsCollection);
    when(listsCollection.doc(_listId)).thenReturn(listDoc);
    when(listDoc.update(any)).thenAnswer((_) async {});
    when(snapshot.exists).thenReturn(true);
    when(snapshot.data()).thenReturn({
      'listId': _listId,
      'ownerUid': _memberUid,
      'groupId': _groupId,
      'groupName': 'group',
      'listName': 'list',
      'description': '',
      'items': {
        'item-1': {
          'memberId': _memberUid,
          'name': encrypted,
          'quantity': 1,
          'registeredDate': Timestamp.fromDate(DateTime(2026, 1, 1)),
          'isPurchased': false,
          'shoppingInterval': 0,
          'itemId': 'item-1',
          'isDeleted': false,
        },
      },
      'createdAt': Timestamp.fromDate(DateTime(2026, 1, 1)),
      'updatedAt': Timestamp.fromDate(DateTime(2026, 1, 2)),
    });
    when(listDoc.snapshots()).thenAnswer((_) => Stream.value(snapshot));

    final container = ProviderContainer(overrides: [
      firestoreProvider.overrideWithValue(firestore),
      groupKeyExchangeServiceProvider.overrideWithValue(keyService),
    ]);
    addTearDown(container.dispose);
    final repository = container
        .read(Provider((ref) => FirestoreSharedListRepository(ref)));

    final list = await repository.watchSharedList(_groupId, _listId).first;

    expect(list?.items['item-1']?.name, 'milk');
    expect(keyService.resolveCount, 1);
  });

  test('グループ: 新しい鍵の暗号文が残っていたら、鍵を取り直して復号し直す', () async {
    final newKeyService = await _serviceWithKey('key-new');
    final encryptedOwnerName = newKeyService.encryptGroupField(
      plaintext: 'Owner Name',
      groupId: _groupId,
    );

    SharedPreferences.setMockInitialValues({'group_key_v1:$_groupId': 'key-old'});
    final keyService = _StaleThenFreshKeyService();
    final codec = SharedGroupFirestoreCodec(
      cipher: GroupKeyServiceFieldCipher(keyService),
    );
    await codec.primeKey(_groupId);

    final firstPass = codec.decryptGroup(SharedGroup(
      groupName: 'group',
      groupId: _groupId,
      ownerName: encryptedOwnerName,
    ));
    expect(firstPass.ownerName, encryptedOwnerName, reason: '旧鍵では復号できない');

    final retried = await codec.retryDecryptWithFreshKey(firstPass);

    expect(retried.ownerName, 'Owner Name');
    expect(keyService.resolveCount, 1);
  });
}
