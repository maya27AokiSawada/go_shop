import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:goshopping/services/group_key_exchange_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'invitation_key_exchange_test.mocks.dart';

@GenerateMocks([
  FirebaseFirestore,
  CollectionReference,
  DocumentReference,
  DocumentSnapshot,
  FirebaseAuth,
  User,
])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockFirebaseFirestore mockFirestore;
  late MockCollectionReference<Map<String, dynamic>> mockSharedGroupsCollection;
  late MockCollectionReference<Map<String, dynamic>> mockKeyExchangeCollection;
  late MockDocumentReference<Map<String, dynamic>> mockGroupDoc;
  late MockDocumentReference<Map<String, dynamic>> mockKeyExchangeDoc;
  late MockDocumentSnapshot<Map<String, dynamic>> mockGroupSnapshot;
  late MockDocumentSnapshot<Map<String, dynamic>> mockKeyExchangeSnapshot;
  late MockFirebaseAuth mockAuth;
  late MockUser mockUser;

  const groupId = 'test-group-id';
  const ownerUid = 'owner-uid';
  const member1Uid = 'member1-uid';
  const member2Uid = 'member2-uid';

  setUp(() {
    // Mock Firebase Auth
    mockAuth = MockFirebaseAuth();
    mockUser = MockUser();
    when(mockAuth.currentUser).thenReturn(mockUser);
    when(mockUser.uid).thenReturn(ownerUid);

    // Mock Firestore
    mockFirestore = MockFirebaseFirestore();
    mockSharedGroupsCollection = MockCollectionReference();
    mockKeyExchangeCollection = MockCollectionReference();
    mockGroupDoc = MockDocumentReference();
    mockGroupSnapshot = MockDocumentSnapshot();
    mockKeyExchangeDoc = MockDocumentReference();
    mockKeyExchangeSnapshot = MockDocumentSnapshot();

    when(mockFirestore.collection('SharedGroups'))
        .thenReturn(mockSharedGroupsCollection);
    when(mockSharedGroupsCollection.doc(groupId)).thenReturn(mockGroupDoc);
    when(mockGroupDoc.collection('keyExchangeEvents'))
        .thenReturn(mockKeyExchangeCollection);
    when(mockGroupDoc.get()).thenAnswer((_) async => mockGroupSnapshot);
    when(mockGroupSnapshot.data()).thenReturn({'activeKeyVersion': 1});

    // Default mock for key exchange document
    when(mockKeyExchangeCollection.doc(any)).thenReturn(mockKeyExchangeDoc);
    when(mockKeyExchangeDoc.get())
        .thenAnswer((_) async => mockKeyExchangeSnapshot);
    when(mockKeyExchangeDoc.set(any, any)).thenAnswer((_) async => {});
    when(mockKeyExchangeDoc.update(any)).thenAnswer((_) async => {});
    when(mockKeyExchangeSnapshot.exists).thenReturn(true);
    when(mockKeyExchangeSnapshot.data()).thenReturn({
      'encryptedGroupKey': 'encrypted-key',
      'keyVersion': 1,
      'status': 'ready',
    });
    when(mockKeyExchangeSnapshot.reference).thenReturn(mockKeyExchangeDoc);

    // Mock SharedPreferences
    SharedPreferences.setMockInitialValues({});
  });

  test(
      'handleAcceptedInvitation creates a key for the first member, and resolveGroupKeyForMember gets it',
      () async {
    // ARRANGE
    final ownerService =
        GroupKeyExchangeService(firestore: mockFirestore, auth: mockAuth);

    // Set up mock for the key exchange document for member1
    final capturedSetData = <Map<String, dynamic>>[];
    when(mockKeyExchangeCollection.doc(member1Uid))
        .thenReturn(mockKeyExchangeDoc);
    when(mockKeyExchangeDoc.set(any, any)).thenAnswer((invocation) async {
      capturedSetData.add(invocation.positionalArguments[0]);
    });
    when(mockKeyExchangeSnapshot.exists).thenAnswer((_) => true);
    when(mockKeyExchangeSnapshot.data())
        .thenAnswer((_) => capturedSetData.last);

    // ACT
    // 1. Owner handles the invitation for the first member
    await ownerService.handleAcceptedInvitation(
      groupId: groupId,
      memberUid: member1Uid,
      ownerUid: ownerUid,
    );

    // 2. Member tries to resolve the key
    final memberService = GroupKeyExchangeService(firestore: mockFirestore);
    final resolvedKey = await memberService.resolveGroupKeyForMember(
      groupId: groupId,
      memberUid: member1Uid,
    );

    // ASSERT
    // Assert that the owner created and persisted a key
    final ownerKey = await ownerService.getPersistedGroupKey(groupId: groupId);
    expect(ownerKey, isNotNull);
    expect(ownerKey, isNotEmpty);

    // Assert that the member resolved the same key
    expect(resolvedKey, isNotNull);
    expect(resolvedKey, ownerKey);
  });

  test('owner resolves and confirms its own key after creation', () async {
    final ownerService =
        GroupKeyExchangeService(firestore: mockFirestore, auth: mockAuth);
    final capturedOwnerUpdates = <Map<String, dynamic>>[];

    when(mockKeyExchangeCollection.doc(ownerUid))
        .thenReturn(mockKeyExchangeDoc);
    when(mockKeyExchangeDoc.set(any, any)).thenAnswer((invocation) async {
      final payload = invocation.positionalArguments[0];
      if (payload is Map) {
        final data = Map<String, dynamic>.from(payload);
        when(mockKeyExchangeSnapshot.data()).thenReturn(data);
      }
    });
    when(mockKeyExchangeDoc.update(any)).thenAnswer((invocation) async {
      final payload = invocation.positionalArguments[0];
      if (payload is Map) {
        capturedOwnerUpdates.add(Map<String, dynamic>.from(payload));
      }
    });
    when(mockKeyExchangeSnapshot.exists).thenReturn(true);

    await ownerService.handleAcceptedInvitation(
      groupId: groupId,
      memberUid: ownerUid,
      ownerUid: ownerUid,
    );

    final resolvedKey = await ownerService.resolveGroupKeyForMember(
      groupId: groupId,
      memberUid: ownerUid,
    );

    expect(resolvedKey, isNotNull);
    expect(capturedOwnerUpdates, isNotEmpty);
    expect(capturedOwnerUpdates.last['status'], 'confirmed');
  });

  test(
      'hasUsableGroupKey returns false when the cached local key is older than activeKeyVersion',
      () async {
    final groupService = GroupKeyExchangeService(firestore: mockFirestore);
    final groupSnapshot = MockDocumentSnapshot<Map<String, dynamic>>();

    when(mockGroupDoc.get()).thenAnswer((_) async => groupSnapshot);
    when(groupSnapshot.data()).thenReturn({'activeKeyVersion': 2});
    await SharedPreferences.getInstance().then((prefs) async {
      await prefs.setString('group_key_v1:test-group-id', 'legacy-key');
      await prefs.setInt('group_key_version_v1:test-group-id', 1);
    });

    final hasUsableKey = await groupService.hasUsableGroupKey(groupId: groupId);

    expect(hasUsableKey, isFalse);
  });

  test(
      'hasUsableGroupKey returns false when the exchange doc is still ready even with the current local version',
      () async {
    final groupService = GroupKeyExchangeService(
      firestore: mockFirestore,
      auth: mockAuth,
    );
    final groupSnapshot = MockDocumentSnapshot<Map<String, dynamic>>();

    when(mockAuth.currentUser).thenReturn(mockUser);
    when(mockUser.uid).thenReturn(member1Uid);
    when(mockGroupDoc.get()).thenAnswer((_) async => groupSnapshot);
    when(groupSnapshot.data()).thenReturn({'activeKeyVersion': 2});
    when(mockKeyExchangeCollection.doc(member1Uid))
        .thenReturn(mockKeyExchangeDoc);
    when(mockKeyExchangeDoc.get())
        .thenAnswer((_) async => mockKeyExchangeSnapshot);
    when(mockKeyExchangeSnapshot.exists).thenReturn(true);
    when(mockKeyExchangeSnapshot.data()).thenReturn({
      'encryptedGroupKey': 'encrypted-key',
      'keyVersion': 2,
      'status': 'ready',
    });

    await SharedPreferences.getInstance().then((prefs) async {
      await prefs.setString('group_key_v1:test-group-id', 'legacy-key');
      await prefs.setInt('group_key_version_v1:test-group-id', 2);
    });

    final hasUsableKey = await groupService.hasUsableGroupKey(groupId: groupId);

    expect(hasUsableKey, isFalse);
  });

  test(
      'hasUsableGroupKey returns false when a confirmed doc is older than activeKeyVersion',
      () async {
    final groupService = GroupKeyExchangeService(
      firestore: mockFirestore,
      auth: mockAuth,
    );
    final groupSnapshot = MockDocumentSnapshot<Map<String, dynamic>>();

    when(mockAuth.currentUser).thenReturn(mockUser);
    when(mockUser.uid).thenReturn(member1Uid);
    when(mockGroupDoc.get()).thenAnswer((_) async => groupSnapshot);
    when(groupSnapshot.data()).thenReturn({'activeKeyVersion': 2});
    when(mockKeyExchangeCollection.doc(member1Uid))
        .thenReturn(mockKeyExchangeDoc);
    when(mockKeyExchangeDoc.get())
        .thenAnswer((_) async => mockKeyExchangeSnapshot);
    when(mockKeyExchangeSnapshot.exists).thenReturn(true);
    when(mockKeyExchangeSnapshot.data()).thenReturn({
      'encryptedGroupKey': 'encrypted-key',
      'keyVersion': 1,
      'status': 'confirmed',
    });

    await SharedPreferences.getInstance().then((prefs) async {
      await prefs.setString('group_key_v1:test-group-id', 'legacy-key');
      await prefs.setInt('group_key_version_v1:test-group-id', 2);
    });

    final hasUsableKey = await groupService.hasUsableGroupKey(groupId: groupId);

    expect(hasUsableKey, isFalse);
  });

  test(
      'shouldRefreshGroupKey returns true when the cached local version is behind activeKeyVersion',
      () async {
    final groupService = GroupKeyExchangeService(firestore: mockFirestore);
    final groupSnapshot = MockDocumentSnapshot<Map<String, dynamic>>();

    when(mockGroupDoc.get()).thenAnswer((_) async => groupSnapshot);
    when(groupSnapshot.data()).thenReturn({'activeKeyVersion': 2});
    await SharedPreferences.getInstance().then((prefs) async {
      await prefs.setString('group_key_v1:test-group-id', 'legacy-key');
      await prefs.setInt('group_key_version_v1:test-group-id', 1);
    });

    final shouldRefresh = await groupService.shouldRefreshGroupKey(
      groupId: groupId,
      memberUid: member1Uid,
    );

    expect(shouldRefresh, isTrue);
  });

  test(
      'resolveGroupKeyForMember ignores stale key exchange docs older than activeKeyVersion',
      () async {
    final groupService = GroupKeyExchangeService(firestore: mockFirestore);
    final staleExchangeDoc = MockDocumentReference<Map<String, dynamic>>();
    final staleSnapshot = MockDocumentSnapshot<Map<String, dynamic>>();

    when(mockKeyExchangeCollection.doc(member1Uid))
        .thenReturn(staleExchangeDoc);
    when(staleExchangeDoc.get()).thenAnswer((_) async => staleSnapshot);
    when(staleSnapshot.exists).thenReturn(true);
    when(staleSnapshot.data()).thenReturn({
      'encryptedGroupKey': 'stale-encrypted-key',
      'keyVersion': 1,
      'status': 'confirmed',
    });
    when(staleSnapshot.reference).thenReturn(staleExchangeDoc);
    when(staleExchangeDoc.update(any)).thenAnswer((_) async {});

    final groupSnapshot = MockDocumentSnapshot<Map<String, dynamic>>();
    when(mockGroupDoc.get()).thenAnswer((_) async => groupSnapshot);
    when(groupSnapshot.data()).thenReturn({'activeKeyVersion': 2});

    final resolvedKey = await groupService.resolveGroupKeyForMember(
      groupId: groupId,
      memberUid: member1Uid,
    );

    expect(resolvedKey, isNull);
  });

  test('a second invited member gets the same group key', () async {
    // ARRANGE
    final ownerService =
        GroupKeyExchangeService(firestore: mockFirestore, auth: mockAuth);
    final member1Service = GroupKeyExchangeService(firestore: mockFirestore);
    final member2Service = GroupKeyExchangeService(firestore: mockFirestore);

    // --- Mocking for Member 1 ---
    final member1KeyDoc = MockDocumentReference<Map<String, dynamic>>();
    final member1Snapshot = MockDocumentSnapshot<Map<String, dynamic>>();
    final capturedData1 = <Map<String, dynamic>>[];
    when(mockKeyExchangeCollection.doc(member1Uid)).thenReturn(member1KeyDoc);
    when(member1KeyDoc.set(any, any)).thenAnswer((inv) async {
      capturedData1.add(inv.positionalArguments[0]);
    });
    when(member1KeyDoc.get()).thenAnswer((_) async => member1Snapshot);
    when(member1Snapshot.exists).thenReturn(true);
    when(member1Snapshot.data()).thenAnswer((_) => capturedData1.last);
    when(member1Snapshot.reference).thenReturn(member1KeyDoc);
    when(member1KeyDoc.update(any)).thenAnswer((_) async {});

    // --- Mocking for Member 2 ---
    final member2KeyDoc = MockDocumentReference<Map<String, dynamic>>();
    final member2Snapshot = MockDocumentSnapshot<Map<String, dynamic>>();
    final capturedData2 = <Map<String, dynamic>>[];
    when(mockKeyExchangeCollection.doc(member2Uid)).thenReturn(member2KeyDoc);
    when(member2KeyDoc.set(any, any)).thenAnswer((inv) async {
      capturedData2.add(inv.positionalArguments[0]);
    });
    when(member2KeyDoc.get()).thenAnswer((_) async => member2Snapshot);
    when(member2Snapshot.exists).thenReturn(true);
    when(member2Snapshot.data()).thenAnswer((_) => capturedData2.last);
    when(member2Snapshot.reference).thenReturn(member2KeyDoc);
    when(member2KeyDoc.update(any)).thenAnswer((_) async {});

    // ACT
    // 1. Invite first member
    await ownerService.handleAcceptedInvitation(
      groupId: groupId,
      memberUid: member1Uid,
      ownerUid: ownerUid,
    );
    final key1 = await member1Service.resolveGroupKeyForMember(
      groupId: groupId,
      memberUid: member1Uid,
    );

    // 2. Invite second member
    await ownerService.handleAcceptedInvitation(
      groupId: groupId,
      memberUid: member2Uid,
      ownerUid: ownerUid,
    );
    final key2 = await member2Service.resolveGroupKeyForMember(
      groupId: groupId,
      memberUid: member2Uid,
    );

    // ASSERT
    final ownerKey = await ownerService.getPersistedGroupKey(groupId: groupId);
    expect(ownerKey, isNotNull);
    expect(key1, ownerKey);
    expect(key2, ownerKey);
    expect(key1, key2);
  });
}
