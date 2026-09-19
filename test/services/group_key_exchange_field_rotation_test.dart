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
}
