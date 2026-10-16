import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart' as auth_mocks;
import 'package:goshopping/services/group_key_exchange_service.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'invitation_key_exchange_test.mocks.dart';

const _groupId = 'group-fresh';
const _memberUid = 'member-fresh';

/// [groupKey] を現行鍵としてキャッシュしたサービスでアイテム名を暗号化する。
Future<String> _encryptWithKey(String groupKey, String plaintext) async {
  SharedPreferences.setMockInitialValues({'group_key_v1:$_groupId': groupKey});
  final service = GroupKeyExchangeService();
  await service.getPersistedGroupKey(groupId: _groupId);
  return service.encryptItemName(
    plaintextName: plaintext,
    memberUid: _memberUid,
    groupId: _groupId,
  );
}

void main() {
  group('tryDecryptItemName', () {
    test('現行鍵で復号でき、再暗号化は不要', () async {
      final encrypted = await _encryptWithKey('key-current', 'milk');
      final service = GroupKeyExchangeService();
      await service.getPersistedGroupKey(groupId: _groupId);

      final result = service.tryDecryptItemName(
        encryptedName: encrypted,
        memberUid: _memberUid,
        groupId: _groupId,
      );

      expect(result?.name, 'milk');
      expect(result?.needsReencrypt, isFalse);
    });

    test('旧鍵の暗号文は1世代前の鍵で復号し、再暗号化が必要と返す', () async {
      final encrypted = await _encryptWithKey('key-old', 'eggs');
      SharedPreferences.setMockInitialValues({
        'group_key_v1:$_groupId': 'key-new',
        'group_key_previous_v1:$_groupId': 'key-old',
      });
      final service = GroupKeyExchangeService();
      await service.getPersistedGroupKey(groupId: _groupId);

      final result = service.tryDecryptItemName(
        encryptedName: encrypted,
        memberUid: _memberUid,
        groupId: _groupId,
      );

      expect(result?.name, 'eggs');
      expect(result?.needsReencrypt, isTrue);
    });

    test('どの鍵でも復号できなければ null', () async {
      final encrypted = await _encryptWithKey('key-unknown', 'bread');
      SharedPreferences.setMockInitialValues({
        'group_key_v1:$_groupId': 'key-new',
      });
      final service = GroupKeyExchangeService();
      await service.getPersistedGroupKey(groupId: _groupId);

      final result = service.tryDecryptItemName(
        encryptedName: encrypted,
        memberUid: _memberUid,
        groupId: _groupId,
      );

      expect(result, isNull);
    });
  });

  group('ensureFreshGroupKey', () {
    test('ローカル鍵が現行世代なら Firestore を読まずに true', () async {
      SharedPreferences.setMockInitialValues({
        'group_key_v1:$_groupId': 'key-v3',
        'group_key_version_v1:$_groupId': 3,
      });
      final firestore = MockFirebaseFirestore();
      final service = GroupKeyExchangeService(firestore: firestore);

      final ready = await service.ensureFreshGroupKey(
        groupId: _groupId,
        activeKeyVersion: 3,
      );

      expect(ready, isTrue);
      verifyZeroInteractions(firestore);
    });

    test('旧世代なら keyExchangeEvents から解決し、失敗直後は再試行しない', () async {
      SharedPreferences.setMockInitialValues({
        'group_key_v1:$_groupId': 'key-v2',
        'group_key_version_v1:$_groupId': 2,
      });

      final firestore = MockFirebaseFirestore();
      final groupsCollection = MockCollectionReference<Map<String, dynamic>>();
      final groupDoc = MockDocumentReference<Map<String, dynamic>>();
      final exchangeCollection =
          MockCollectionReference<Map<String, dynamic>>();
      final exchangeDoc = MockDocumentReference<Map<String, dynamic>>();
      final exchangeSnapshot = MockDocumentSnapshot<Map<String, dynamic>>();

      when(firestore.collection('SharedGroups')).thenReturn(groupsCollection);
      when(groupsCollection.doc(_groupId)).thenReturn(groupDoc);
      when(groupDoc.collection('keyExchangeEvents'))
          .thenReturn(exchangeCollection);
      when(exchangeCollection.doc(_memberUid)).thenReturn(exchangeDoc);
      // 配布待ち（交換ドキュメントがまだ無い）
      when(exchangeDoc.get()).thenAnswer((_) async => exchangeSnapshot);
      when(exchangeSnapshot.exists).thenReturn(false);

      final service = GroupKeyExchangeService(
        firestore: firestore,
        auth: auth_mocks.MockFirebaseAuth(
          signedIn: true,
          mockUser: auth_mocks.MockUser(uid: _memberUid),
        ),
      );

      final first = await service.ensureFreshGroupKey(
        groupId: _groupId,
        activeKeyVersion: 3,
      );
      // 解決できなくても手元の鍵は残っている
      expect(first, isTrue);
      verify(exchangeDoc.get()).called(greaterThan(0));

      await service.ensureFreshGroupKey(
        groupId: _groupId,
        activeKeyVersion: 3,
      );
      verifyNever(exchangeDoc.get());
    });

    test('鍵未設定グループ（版数なし・ローカル鍵なし）は false', () async {
      SharedPreferences.setMockInitialValues({});
      final firestore = MockFirebaseFirestore();
      final groupsCollection = MockCollectionReference<Map<String, dynamic>>();
      final groupDoc = MockDocumentReference<Map<String, dynamic>>();
      final groupSnapshot = MockDocumentSnapshot<Map<String, dynamic>>();
      when(firestore.collection('SharedGroups')).thenReturn(groupsCollection);
      when(groupsCollection.doc(_groupId)).thenReturn(groupDoc);
      when(groupDoc.get()).thenAnswer((_) async => groupSnapshot);
      when(groupSnapshot.data()).thenReturn({'ownerUid': 'owner'});

      final service = GroupKeyExchangeService(firestore: firestore);

      final ready = await service.ensureFreshGroupKey(groupId: _groupId);

      expect(ready, isFalse);
    });
  });
}
