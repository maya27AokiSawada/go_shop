// GroupKeyRotationService のテスト。
//
// - 抜けたメンバーを検出したら、現在のメンバーにだけ新しい鍵を配布してローテーションする
// - 旧鍵の暗号文を現行鍵へ揃えられなければローテーションしない
// - オーナー以外の端末では何もしない

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart' as auth_mocks;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goshopping/providers/firestore_provider.dart';
import 'package:goshopping/services/group_key_exchange_service.dart';
import 'package:goshopping/services/group_key_rotation_service.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'invitation_key_exchange_test.mocks.dart';

const _groupId = 'group-rotate';
const _ownerUid = 'owner-rotate';
const _stayingUid = 'member-staying';
const _departedUid = 'member-departed';

// ignore: subtype_of_sealed_class
class _FakeQueryDocumentSnapshot extends Fake
    implements QueryDocumentSnapshot<Map<String, dynamic>> {
  _FakeQueryDocumentSnapshot(this.id, this.reference, this._data);

  @override
  final String id;
  @override
  final DocumentReference<Map<String, dynamic>> reference;
  final Map<String, dynamic> _data;

  @override
  Map<String, dynamic> data() => _data;
}

class _FakeQuerySnapshot extends Fake
    implements QuerySnapshot<Map<String, dynamic>> {
  _FakeQuerySnapshot(this.docs);

  @override
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs;
}

class _Fixture {
  _Fixture({
    required String signedInUid,
    Map<String, Map<String, dynamic>> lists = const {},
    bool listUpdateFails = false,
  }) {
    when(firestore.collection('SharedGroups')).thenReturn(groupsCollection);
    when(groupsCollection.doc(_groupId)).thenReturn(groupDoc);
    when(groupDoc.get()).thenAnswer((_) async {
      final snapshot = MockDocumentSnapshot<Map<String, dynamic>>();
      when(snapshot.data()).thenReturn(Map<String, dynamic>.from(groupData));
      when(snapshot.exists).thenReturn(true);
      return snapshot;
    });
    when(groupDoc.set(any, any)).thenAnswer((invocation) async {
      final update = Map<String, dynamic>.from(
          invocation.positionalArguments.first as Map);
      groupWrites.add(update);
      if (update['activeKeyVersion'] != null) {
        groupData['activeKeyVersion'] = update['activeKeyVersion'];
      }
    });

    // 鍵配布データ
    when(groupDoc.collection('keyExchangeEvents'))
        .thenReturn(exchangeCollection);
    for (final uid in [_ownerUid, _stayingUid, _departedUid]) {
      final doc = MockDocumentReference<Map<String, dynamic>>();
      exchangeDocs[uid] = doc;
      when(exchangeCollection.doc(uid)).thenReturn(doc);
      when(doc.set(any, any)).thenAnswer((invocation) async {
        distributedTo.add(uid);
      });
      when(doc.delete()).thenAnswer((_) async {
        deleted.add(uid);
      });
    }
    when(exchangeCollection.get()).thenAnswer((_) async => _FakeQuerySnapshot([
          for (final uid in exchangeDocs.keys.where((u) => !deleted.contains(u)))
            _FakeQueryDocumentSnapshot(uid, exchangeDocs[uid]!, {'keyVersion': 2}),
        ]));

    // 回復エンベロープ
    when(groupDoc.collection('keyRecoveryEnvelopes'))
        .thenReturn(envelopeCollection);
    when(envelopeCollection.doc(any)).thenReturn(envelopeDoc);
    when(envelopeDoc.set(any)).thenAnswer((_) async {});

    // 共有リスト
    when(groupDoc.collection('sharedLists')).thenReturn(listsCollection);
    when(listsCollection.get()).thenAnswer((_) async => _FakeQuerySnapshot([
          for (final entry in lists.entries)
            _FakeQueryDocumentSnapshot(
                entry.key, MockDocumentReference(), entry.value),
        ]));
    for (final listId in lists.keys) {
      final doc = MockDocumentReference<Map<String, dynamic>>();
      when(listsCollection.doc(listId)).thenReturn(doc);
      when(doc.update(any)).thenAnswer((_) async {
        if (listUpdateFails) throw FirebaseException(plugin: 'test');
      });
    }

    final auth = auth_mocks.MockFirebaseAuth(
      signedIn: true,
      mockUser: auth_mocks.MockUser(uid: signedInUid),
    );
    keyService = GroupKeyExchangeService(firestore: firestore, auth: auth);
    final container = ProviderContainer(overrides: [
      firestoreProvider.overrideWithValue(firestore),
      groupKeyExchangeServiceProvider.overrideWithValue(keyService),
    ]);
    addTearDown(container.dispose);
    service = container.read(Provider(
      (ref) => GroupKeyRotationService(ref, auth: auth),
    ));
  }

  final firestore = MockFirebaseFirestore();
  final groupsCollection = MockCollectionReference<Map<String, dynamic>>();
  final groupDoc = MockDocumentReference<Map<String, dynamic>>();
  final exchangeCollection = MockCollectionReference<Map<String, dynamic>>();
  final envelopeCollection = MockCollectionReference<Map<String, dynamic>>();
  final envelopeDoc = MockDocumentReference<Map<String, dynamic>>();
  final listsCollection = MockCollectionReference<Map<String, dynamic>>();
  final exchangeDocs = <String, MockDocumentReference<Map<String, dynamic>>>{};

  final Map<String, dynamic> groupData = {
    'ownerUid': _ownerUid,
    // 抜けたメンバーは allowedUid から外れている
    'allowedUid': [_ownerUid, _stayingUid],
    'activeKeyVersion': 2,
    'keyReencryptionInProgress': false,
    'keyRotationStatus': 'idle',
  };
  final groupWrites = <Map<String, dynamic>>[];
  final distributedTo = <String>{};
  final deleted = <String>{};

  late final GroupKeyExchangeService keyService;
  late final GroupKeyRotationService service;

  bool get rotated => groupWrites.any((w) => w['activeKeyVersion'] == 3);
}

Map<String, dynamic> _listData(String itemName) => {
      'listId': 'list-1',
      'ownerUid': _ownerUid,
      'groupId': _groupId,
      'groupName': 'group',
      'listName': 'list',
      'description': '',
      'items': {
        'item-1': {
          'memberId': _stayingUid,
          'name': itemName,
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
    };

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({
      'group_key_v1:$_groupId': 'key-v2',
      'group_key_version_v1:$_groupId': 2,
    });
  });

  test('抜けたメンバーを検出したら、残ったメンバーにだけ新しい鍵を配布する', () async {
    final fixture = _Fixture(signedInUid: _ownerUid);

    await fixture.service.rotateIfMembersDeparted(groupId: _groupId);

    expect(fixture.rotated, isTrue);
    expect(fixture.distributedTo, containsAll([_ownerUid, _stayingUid]));
    expect(fixture.distributedTo, isNot(contains(_departedUid)));
    expect(fixture.deleted, {_departedUid});
    expect(
      await fixture.keyService.getPersistedGroupKeyVersion(groupId: _groupId),
      3,
    );
  });

  test('旧鍵の暗号文を現行鍵へ揃えられなければローテーションしない', () async {
    // 旧鍵で暗号化されたアイテムが残っている端末
    SharedPreferences.setMockInitialValues(
        {'group_key_v1:$_groupId': 'key-v1'});
    final oldService = GroupKeyExchangeService();
    await oldService.getPersistedGroupKey(groupId: _groupId);
    final oldCiphertext = oldService.encryptItemName(
      plaintextName: 'milk',
      memberUid: _stayingUid,
      groupId: _groupId,
    );
    SharedPreferences.setMockInitialValues({
      'group_key_v1:$_groupId': 'key-v2',
      'group_key_previous_v1:$_groupId': 'key-v1',
      'group_key_version_v1:$_groupId': 2,
    });

    final fixture = _Fixture(
      signedInUid: _ownerUid,
      lists: {'list-1': _listData(oldCiphertext)},
      listUpdateFails: true,
    );

    await expectLater(
      fixture.service.rotateSafely(groupId: _groupId),
      throwsA(isA<GroupKeyRotationBlockedException>()),
    );
    expect(fixture.rotated, isFalse);
    expect(fixture.deleted, isEmpty);
    expect(
      await fixture.keyService.getPersistedGroupKey(groupId: _groupId),
      'key-v2',
    );
  });

  test('オーナー以外の端末では何もしない', () async {
    final fixture = _Fixture(signedInUid: _stayingUid);

    await fixture.service.rotateIfMembersDeparted(groupId: _groupId);

    expect(fixture.rotated, isFalse);
    expect(fixture.deleted, isEmpty);
    verifyNever(fixture.exchangeCollection.get());
  });

  test('抜けたメンバーがいなければローテーションしない', () async {
    final fixture = _Fixture(signedInUid: _ownerUid);
    fixture.groupData['allowedUid'] = [_ownerUid, _stayingUid, _departedUid];

    await fixture.service.rotateIfMembersDeparted(groupId: _groupId);

    expect(fixture.rotated, isFalse);
  });
}
