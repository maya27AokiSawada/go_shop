import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart' as auth_mocks;
import 'package:goshopping/services/group_key_exchange_service.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'invitation_key_exchange_test.mocks.dart';

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
    final mockFirestore = MockFirebaseFirestore();
    final mockSharedGroupsCollection =
        MockCollectionReference<Map<String, dynamic>>();
    final mockGroupDoc = MockDocumentReference<Map<String, dynamic>>();
    final mockGroupSnapshot = MockDocumentSnapshot<Map<String, dynamic>>();
    final mockKeyExchangeCollection =
        MockCollectionReference<Map<String, dynamic>>();
    final mockKeyExchangeDoc = MockDocumentReference<Map<String, dynamic>>();

    when(mockFirestore.collection('SharedGroups'))
        .thenReturn(mockSharedGroupsCollection);
    when(mockSharedGroupsCollection.doc(any)).thenReturn(mockGroupDoc);
    when(mockGroupDoc.get()).thenAnswer((_) async => mockGroupSnapshot);
    when(mockGroupSnapshot.data()).thenReturn({
      'keyReencryptionInProgress': false,
      'keyRotationStatus': 'idle',
      'ownerUid': 'owner-a',
      'allowedUid': ['owner-a', 'member-a'],
    });
    when(mockGroupDoc.collection('keyExchangeEvents'))
        .thenReturn(mockKeyExchangeCollection);
    when(mockKeyExchangeCollection.doc(any)).thenReturn(mockKeyExchangeDoc);
    when(mockKeyExchangeDoc.set(any, any)).thenAnswer((_) async => {});
    when(mockGroupDoc.set(any, any)).thenAnswer((_) async => {});

    final ownerService = GroupKeyExchangeService(
      auth: auth_mocks.MockFirebaseAuth(
        signedIn: true,
        mockUser: auth_mocks.MockUser(uid: 'owner-a'),
      ),
      firestore: mockFirestore,
    );

    final created = await ownerService.ensureGroupKeyForOwner(
      groupId: 'group-a',
      ownerUid: 'owner-a',
      memberUids: ['member-a'],
      forceRefresh: true,
    );

    expect(created, isTrue);
    final persisted =
        await ownerService.getPersistedGroupKey(groupId: 'group-a');
    expect(persisted, isNotNull);
    expect(persisted, isNotEmpty);
  });

  test('rotation writes a recovery envelope for the current key version',
      () async {
    final mockFirestore = MockFirebaseFirestore();
    final mockSharedGroupsCollection =
        MockCollectionReference<Map<String, dynamic>>();
    final mockGroupDoc = MockDocumentReference<Map<String, dynamic>>();
    final mockGroupSnapshot = MockDocumentSnapshot<Map<String, dynamic>>();
    final mockKeyExchangeCollection =
        MockCollectionReference<Map<String, dynamic>>();
    final mockKeyExchangeDoc = MockDocumentReference<Map<String, dynamic>>();
    final mockRecoveryCollection =
        MockCollectionReference<Map<String, dynamic>>();
    final mockRecoveryDoc = MockDocumentReference<Map<String, dynamic>>();
    final recoveryWrites = <Map<String, dynamic>>[];

    when(mockFirestore.collection('SharedGroups'))
        .thenReturn(mockSharedGroupsCollection);
    when(mockSharedGroupsCollection.doc('group-a')).thenReturn(mockGroupDoc);
    when(mockGroupDoc.get()).thenAnswer((_) async => mockGroupSnapshot);
    when(mockGroupSnapshot.data()).thenReturn({
      'activeKeyVersion': 4,
      'keyReencryptionInProgress': false,
      'keyRotationStatus': 'idle',
    });
    when(mockGroupDoc.collection('keyExchangeEvents'))
        .thenReturn(mockKeyExchangeCollection);
    when(mockKeyExchangeCollection.doc(any)).thenReturn(mockKeyExchangeDoc);
    when(mockKeyExchangeDoc.set(any, any)).thenAnswer((_) async {});
    when(mockGroupDoc.collection('keyRecoveryEnvelopes'))
        .thenReturn(mockRecoveryCollection);
    when(mockRecoveryCollection.doc('4-to-5')).thenReturn(mockRecoveryDoc);
    when(mockRecoveryDoc.set(any)).thenAnswer((invocation) async {
      recoveryWrites.add(
        Map<String, dynamic>.from(invocation.positionalArguments[0]),
      );
    });
    when(mockGroupDoc.set(any, any)).thenAnswer((_) async {});

    final ownerService = GroupKeyExchangeService(
      auth: auth_mocks.MockFirebaseAuth(
        signedIn: true,
        mockUser: auth_mocks.MockUser(uid: 'owner-a'),
      ),
      firestore: mockFirestore,
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'group_key_v1:group-a', 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=');
    await prefs.setInt('group_key_version_v1:group-a', 4);

    await ownerService.rotateGroupKey(
      groupId: 'group-a',
      ownerUid: 'owner-a',
      memberUids: ['owner-a', 'member-a'],
    );

    expect(recoveryWrites, hasLength(1));
    expect(recoveryWrites.single['fromVersion'], 4);
    expect(recoveryWrites.single['toVersion'], 5);
    expect(recoveryWrites.single['encryptedGroupKey'], isNotEmpty);
  });

  test('reencrypts shared item payloads when a group key exists', () async {
    final mockFirestore = MockFirebaseFirestore();
    final mockSharedGroupsCollection =
        MockCollectionReference<Map<String, dynamic>>();
    final mockGroupDoc = MockDocumentReference<Map<String, dynamic>>();
    final mockGroupSnapshot = MockDocumentSnapshot<Map<String, dynamic>>();
    final mockKeyExchangeCollection =
        MockCollectionReference<Map<String, dynamic>>();
    final mockKeyExchangeDoc = MockDocumentReference<Map<String, dynamic>>();

    when(mockFirestore.collection('SharedGroups'))
        .thenReturn(mockSharedGroupsCollection);
    when(mockSharedGroupsCollection.doc(any)).thenReturn(mockGroupDoc);
    when(mockGroupDoc.get()).thenAnswer((_) async => mockGroupSnapshot);
    when(mockGroupSnapshot.data()).thenReturn({
      'keyReencryptionInProgress': false,
      'keyRotationStatus': 'idle',
      'ownerUid': 'owner-b',
      'allowedUid': ['owner-b', 'member-b'],
    });
    when(mockGroupDoc.collection('keyExchangeEvents'))
        .thenReturn(mockKeyExchangeCollection);
    when(mockKeyExchangeCollection.doc(any)).thenReturn(mockKeyExchangeDoc);
    when(mockKeyExchangeDoc.set(any, any)).thenAnswer((_) async => {});
    when(mockGroupDoc.set(any, any)).thenAnswer((_) async => {});

    final ownerService = GroupKeyExchangeService(
      auth: auth_mocks.MockFirebaseAuth(
        signedIn: true,
        mockUser: auth_mocks.MockUser(uid: 'owner-b'),
      ),
      firestore: mockFirestore,
    );

    await ownerService.ensureGroupKeyForOwner(
      groupId: 'group-b',
      ownerUid: 'owner-b',
      memberUids: ['member-b'],
      forceRefresh: true,
    );

    await ownerService.reencryptSharedItemsForGroup(
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
