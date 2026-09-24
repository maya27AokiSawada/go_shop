import 'package:flutter_test/flutter_test.dart';
import 'package:goshopping/services/group_key_exchange_service.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'invitation_key_exchange_test.mocks.dart';

/// 鍵ローテーション後のグループ共有フィールド
/// （members[].name/contact, ownerName/ownerEmail）復号バグの修正を検証する。
///
/// 背景（docs/daily_reports/2026-09/daily_report_20260918.md）:
/// グループ鍵ローテーション後、アイテム名は再暗号化されるが、グループ共有
/// フィールドは再暗号化されないため、`decryptGroupField` が常に「現在の
/// 永続鍵」でしか復号を試みず、旧鍵の暗号文が復号不能になっていた。
void main() {
  const groupId = 'group-rot';

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('decryptGroupField falls back to the previous persisted key '
      'after rotation', () async {
    final service = GroupKeyExchangeService();

    // ローテーション前の鍵で暗号化された既存データを用意する。
    final encrypted = service.encryptGroupField(
      plaintext: 'Alice',
      groupId: groupId,
      groupKey: 'old-key',
    );

    // 端末の永続鍵が old-key -> new-key へ切り替わったことを模す
    // （resolveGroupKeyForMember / rotateGroupKey が内部で行う
    // _persistGroupKeyLocally と同じ経路）。
    SharedPreferences.setMockInitialValues({
      'group_key_v1:$groupId': 'old-key',
    });
    await service.getPersistedGroupKey(groupId: groupId); // old-key を prime
    SharedPreferences.setMockInitialValues({
      'group_key_v1:$groupId': 'new-key',
    });
    // rotate 相当: 旧鍵を previous スロットへ退避しつつ新鍵を保存する経路を
    // 直接叩けないため、prefs を新鍵へ差し替えた上で previous を明示的に用意する。
    SharedPreferences.setMockInitialValues({
      'group_key_v1:$groupId': 'new-key',
      'group_key_previous_v1:$groupId': 'old-key',
    });
    await service.getPersistedGroupKey(groupId: groupId); // new-key + previous を prime

    // 旧鍵の暗号文は、鍵指定なし（= 現在のキャッシュ経由）でも復号できる。
    final decrypted = service.decryptGroupField(
      ciphertext: encrypted,
      groupId: groupId,
    );
    expect(decrypted, 'Alice');
  });

  test('reencryptGroupFieldsIfKeyChanged migrates ownerName/ownerEmail and '
      'members[].name/contact from the previous key to the current key',
      () async {
    final mockFirestore = MockFirebaseFirestore();
    final mockCollection = MockCollectionReference<Map<String, dynamic>>();
    final mockGroupDoc = MockDocumentReference<Map<String, dynamic>>();
    final mockGroupSnapshot = MockDocumentSnapshot<Map<String, dynamic>>();

    final service = GroupKeyExchangeService(firestore: mockFirestore);

    // ローテーション前の鍵で暗号化された既存の Firestore ドキュメントを用意する。
    final oldOwnerName = service.encryptGroupField(
      plaintext: 'Owner',
      groupId: groupId,
      groupKey: 'old-key',
    );
    final oldOwnerEmail = service.encryptGroupField(
      plaintext: 'owner@example.com',
      groupId: groupId,
      groupKey: 'old-key',
    );
    final oldMemberName = service.encryptGroupField(
      plaintext: 'Alice',
      groupId: groupId,
      groupKey: 'old-key',
    );
    final oldMemberContact = service.encryptGroupField(
      plaintext: 'alice@example.com',
      groupId: groupId,
      groupKey: 'old-key',
    );

    when(mockFirestore.collection('SharedGroups')).thenReturn(mockCollection);
    when(mockCollection.doc(groupId)).thenReturn(mockGroupDoc);
    when(mockGroupDoc.get()).thenAnswer((_) async => mockGroupSnapshot);
    when(mockGroupSnapshot.data()).thenReturn({
      'ownerName': oldOwnerName,
      'ownerEmail': oldOwnerEmail,
      'members': [
        {
          'memberId': 'm1',
          'name': oldMemberName,
          'contact': oldMemberContact,
          'role': 'member',
        },
      ],
    });

    Map<String, dynamic>? capturedUpdate;
    when(mockGroupDoc.set(any, any)).thenAnswer((invocation) async {
      capturedUpdate = invocation.positionalArguments[0] as Map<String, dynamic>;
    });

    // 端末の鍵が old-key -> new-key へローテーションした状態を prefs で模す。
    SharedPreferences.setMockInitialValues({
      'group_key_v1:$groupId': 'new-key',
      'group_key_previous_v1:$groupId': 'old-key',
    });
    await service.getPersistedGroupKey(groupId: groupId);

    await service.reencryptGroupFieldsIfKeyChanged(groupId: groupId);

    expect(capturedUpdate, isNotNull);
    expect(
      service.decryptGroupField(
        ciphertext: capturedUpdate!['ownerName'] as String,
        groupId: groupId,
        groupKey: 'new-key',
      ),
      'Owner',
    );
    expect(
      service.decryptGroupField(
        ciphertext: capturedUpdate!['ownerEmail'] as String,
        groupId: groupId,
        groupKey: 'new-key',
      ),
      'owner@example.com',
    );
    final members = capturedUpdate!['members'] as List<dynamic>;
    final member = Map<String, dynamic>.from(members.single as Map);
    expect(
      service.decryptGroupField(
        ciphertext: member['name'] as String,
        groupId: groupId,
        groupKey: 'new-key',
      ),
      'Alice',
    );
    expect(
      service.decryptGroupField(
        ciphertext: member['contact'] as String,
        groupId: groupId,
        groupKey: 'new-key',
      ),
      'alice@example.com',
    );
  });

  test('reencryptGroupFieldsIfKeyChanged does not rewrite fields that were '
      'already migrated to the current key (regression: repeated calls used '
      'to keep retrying already-migrated fields with the previous key, '
      'causing a Firestore write -> realtime listener -> re-check feedback '
      'loop)', () async {
    final mockFirestore = MockFirebaseFirestore();
    final mockCollection = MockCollectionReference<Map<String, dynamic>>();
    final mockGroupDoc = MockDocumentReference<Map<String, dynamic>>();
    final mockGroupSnapshot = MockDocumentSnapshot<Map<String, dynamic>>();

    final service = GroupKeyExchangeService(firestore: mockFirestore);

    // 前回の呼び出しで既に new-key へ再暗号化済みのフィールド。
    final currentOwnerName = service.encryptGroupField(
      plaintext: 'Owner',
      groupId: groupId,
      groupKey: 'new-key',
    );
    final currentMemberName = service.encryptGroupField(
      plaintext: 'Alice',
      groupId: groupId,
      groupKey: 'new-key',
    );

    when(mockFirestore.collection('SharedGroups')).thenReturn(mockCollection);
    when(mockCollection.doc(groupId)).thenReturn(mockGroupDoc);
    when(mockGroupDoc.get()).thenAnswer((_) async => mockGroupSnapshot);
    when(mockGroupSnapshot.data()).thenReturn({
      'ownerName': currentOwnerName,
      'members': [
        {
          'memberId': 'm1',
          'name': currentMemberName,
          'role': 'member',
        },
      ],
    });

    // 端末は old-key -> new-key へローテーション済みのまま
    // （previous key はまだ残っている）。
    SharedPreferences.setMockInitialValues({
      'group_key_v1:$groupId': 'new-key',
      'group_key_previous_v1:$groupId': 'old-key',
    });
    await service.getPersistedGroupKey(groupId: groupId);

    await service.reencryptGroupFieldsIfKeyChanged(groupId: groupId);

    // 既に current key で復号できるフィールドしかないので、
    // Firestore への書き戻しは発生しない
    // （書き戻しが起きるとリアルタイムリスナーが再発火し、
    // 同じチェックが延々と繰り返される）。
    verifyNever(mockGroupDoc.set(any, any));
  });

  test('rotateGroupKey does not corrupt the previously persisted key when a '
      'retry follows a Firestore write failure', () async {
    final mockFirestore = MockFirebaseFirestore();
    final mockAuth = MockFirebaseAuth();
    final mockUser = MockUser();
    final mockGroupCollection = MockCollectionReference<Map<String, dynamic>>();
    final mockGroupDoc = MockDocumentReference<Map<String, dynamic>>();
    final mockGroupSnapshot = MockDocumentSnapshot<Map<String, dynamic>>();
    final mockExchangeCollection =
        MockCollectionReference<Map<String, dynamic>>();
    final mockExchangeDoc = MockDocumentReference<Map<String, dynamic>>();

    const ownerUid = 'owner-uid';
    const memberUid = 'member-uid';

    when(mockAuth.currentUser).thenReturn(mockUser);
    when(mockUser.uid).thenReturn(ownerUid);

    when(mockFirestore.collection('SharedGroups'))
        .thenReturn(mockGroupCollection);
    when(mockGroupCollection.doc(groupId)).thenReturn(mockGroupDoc);
    when(mockGroupDoc.get()).thenAnswer((_) async => mockGroupSnapshot);
    // Firestore 上の activeKeyVersion は、書き込みが一度も成功していない
    // 想定なので常に 1 のまま返す。
    when(mockGroupSnapshot.data()).thenReturn({'activeKeyVersion': 1});
    when(mockGroupDoc.collection('keyExchangeEvents'))
        .thenReturn(mockExchangeCollection);
    when(mockExchangeCollection.doc(memberUid)).thenReturn(mockExchangeDoc);
    when(mockGroupDoc.set(any, any)).thenAnswer((_) async {});

    var exchangeWriteAttempts = 0;
    when(mockExchangeDoc.set(any, any)).thenAnswer((_) async {
      exchangeWriteAttempts++;
      if (exchangeWriteAttempts == 1) {
        // 1 回目は権限エラー等で失敗する（今回の実機で再現した状況）。
        throw Exception('permission-denied');
      }
    });

    final service =
        GroupKeyExchangeService(firestore: mockFirestore, auth: mockAuth);

    // ローテーション前から端末に保存されていた「本物の旧鍵」。
    SharedPreferences.setMockInitialValues({
      'group_key_v1:$groupId': 'true-old-key',
    });
    await service.getPersistedGroupKey(groupId: groupId);

    // 1 回目のローテーションは Firestore への配布中に失敗する。
    await expectLater(
      service.rotateGroupKey(
        groupId: groupId,
        ownerUid: ownerUid,
        memberUids: [memberUid],
      ),
      throwsA(anything),
    );

    // 失敗した 1 回目の後も、ローカルの鍵は書き換えられていないこと。
    expect(await service.getPersistedGroupKey(groupId: groupId), 'true-old-key');

    // 2 回目のローテーションは成功する（App Check 登録などで解消された想定）。
    await service.rotateGroupKey(
      groupId: groupId,
      ownerUid: ownerUid,
      memberUids: [memberUid],
    );

    // 新しい鍵に切り替わっていること。
    final newKey = await service.getPersistedGroupKey(groupId: groupId);
    expect(newKey, isNot('true-old-key'));
    expect(await service.getPersistedGroupKeyVersion(groupId: groupId), 2);

    // previous スロットには、1 回目の失敗で生成された使われなかった鍵ではなく
    // 「本物の旧鍵」が残っていること。
    expect(
      await service.getPreviousPersistedGroupKey(groupId: groupId),
      'true-old-key',
    );
  });

  test('reencryptGroupFieldsIfKeyChanged is a no-op when the key has not '
      'changed', () async {
    final mockFirestore = MockFirebaseFirestore();
    final service = GroupKeyExchangeService(firestore: mockFirestore);

    SharedPreferences.setMockInitialValues({
      'group_key_v1:$groupId': 'same-key',
      'group_key_previous_v1:$groupId': 'same-key',
    });
    await service.getPersistedGroupKey(groupId: groupId);

    await service.reencryptGroupFieldsIfKeyChanged(groupId: groupId);

    verifyNever(mockFirestore.collection(any));
  });

  test('ensureGroupKeyForOwner does not poison the previous-key slot when '
      'creating the very first key for a brand new group (regression: a '
      'throwaway key generated before rotateGroupKey used to end up as the '
      'previous key forever, causing reencryptGroupFieldsIfKeyChanged to '
      'fail and warn on every read of any newly created group)', () async {
    final mockFirestore = MockFirebaseFirestore();
    final mockAuth = MockFirebaseAuth();
    final mockUser = MockUser();
    final mockGroupCollection = MockCollectionReference<Map<String, dynamic>>();
    final mockGroupDoc = MockDocumentReference<Map<String, dynamic>>();
    final mockGroupSnapshot = MockDocumentSnapshot<Map<String, dynamic>>();
    final mockExchangeCollection =
        MockCollectionReference<Map<String, dynamic>>();
    final mockExchangeDoc = MockDocumentReference<Map<String, dynamic>>();

    const ownerUid = 'owner-uid';

    when(mockAuth.currentUser).thenReturn(mockUser);
    when(mockUser.uid).thenReturn(ownerUid);

    when(mockFirestore.collection('SharedGroups'))
        .thenReturn(mockGroupCollection);
    when(mockGroupCollection.doc(groupId)).thenReturn(mockGroupDoc);
    when(mockGroupDoc.get()).thenAnswer((_) async => mockGroupSnapshot);
    // ブランドニューなグループなのでドキュメントはまだ存在しない。
    when(mockGroupSnapshot.data()).thenReturn(null);
    when(mockGroupDoc.collection('keyExchangeEvents'))
        .thenReturn(mockExchangeCollection);
    when(mockExchangeCollection.doc(ownerUid)).thenReturn(mockExchangeDoc);
    when(mockExchangeDoc.set(any, any)).thenAnswer((_) async {});
    when(mockGroupDoc.set(any, any)).thenAnswer((_) async {});

    final service =
        GroupKeyExchangeService(firestore: mockFirestore, auth: mockAuth);

    final created = await service.ensureGroupKeyForOwner(
      groupId: groupId,
      ownerUid: ownerUid,
      memberUids: const [],
    );

    expect(created, isTrue);
    expect(await service.getPersistedGroupKey(groupId: groupId), isNotNull);
    // 使い捨ての鍵が previous スロットへ紛れ込んでいないこと。
    expect(await service.getPreviousPersistedGroupKey(groupId: groupId), isNull);

    // previous key が無いので、以後このグループを読み込んでも
    // reencryptGroupFieldsIfKeyChanged は即座に no-op で返るはず
    // （Firestoreへのアクセスなし = 警告の連発が起きない）。
    clearInteractions(mockFirestore);
    await service.reencryptGroupFieldsIfKeyChanged(groupId: groupId);
    verifyNever(mockFirestore.collection(any));
  });
}
