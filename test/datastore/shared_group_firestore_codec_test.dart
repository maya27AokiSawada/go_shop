import 'package:flutter_test/flutter_test.dart';
import 'package:goshopping/datastore/shared_group_firestore_codec.dart';
import 'package:goshopping/models/shared_group.dart';

/// 決定的なフェイク暗号器。`enc:` プレフィックスで「暗号化済み」を表現する。
class _FakeCipher implements GroupFieldCipher {
  final Set<String> seenGroupIds = {};

  @override
  String encrypt({required String plaintext, required String groupId}) {
    seenGroupIds.add(groupId);
    return 'enc:$groupId:$plaintext';
  }

  @override
  String decrypt({required String ciphertext, required String groupId}) {
    if (!ciphertext.startsWith('enc:$groupId:')) {
      throw const FormatException('wrong group');
    }
    return ciphertext.substring('enc:$groupId:'.length);
  }

  @override
  bool isEncrypted(String value) => value.startsWith('enc:');
}

SharedGroupMember _member({
  String id = 'm1',
  String name = 'Alice',
  String contact = 'alice@example.com',
  SharedGroupRole role = SharedGroupRole.member,
}) {
  return SharedGroupMember(
    memberId: id,
    name: name,
    contact: contact,
    role: role,
  );
}

void main() {
  group('SharedGroupFirestoreCodec without cipher (legacy behavior)', () {
    const codec = SharedGroupFirestoreCodec();

    test('member map keeps name/contact as plaintext', () {
      final map = codec.memberToMap(_member(), groupId: 'g1');
      expect(map['name'], 'Alice');
      expect(map['contact'], 'alice@example.com');
      expect(map['role'], 'member');
      expect(map['memberId'], 'm1');
    });

    test('round-trips a member', () {
      final map = codec.memberToMap(_member(), groupId: 'g1');
      final back = codec.memberFromMap(map, groupId: 'g1');
      expect(back.name, 'Alice');
      expect(back.contact, 'alice@example.com');
      expect(back.role, SharedGroupRole.member);
    });

    test('reads legacy alias fields (uid / displayName)', () {
      final back = codec.memberFromMap(
        {'uid': 'u9', 'displayName': 'Legacy', 'contact': 'x@y.z', 'role': 'owner'},
        groupId: 'g1',
      );
      expect(back.memberId, 'u9');
      expect(back.name, 'Legacy');
      expect(back.role, SharedGroupRole.owner);
    });
  });

  group('SharedGroupFirestoreCodec with cipher', () {
    late _FakeCipher cipher;
    late SharedGroupFirestoreCodec codec;

    setUp(() {
      cipher = _FakeCipher();
      codec = SharedGroupFirestoreCodec(cipher: cipher);
    });

    test('encrypts name/contact on write, decrypts on read', () {
      final map = codec.memberToMap(_member(), groupId: 'g1');
      expect(map['name'], 'enc:g1:Alice');
      expect(map['contact'], 'enc:g1:alice@example.com');

      final back = codec.memberFromMap(map, groupId: 'g1');
      expect(back.name, 'Alice');
      expect(back.contact, 'alice@example.com');
    });

    test('does not double-encrypt already-encrypted values', () {
      final once = codec.memberToMap(_member(), groupId: 'g1');
      final twice = codec.memberToMap(
        codec.memberFromMap(once, groupId: 'g1').copyWithExtra(
              name: once['name'] as String,
              contact: once['contact'] as String,
            ),
        groupId: 'g1',
      );
      expect(twice['name'], 'enc:g1:Alice');
      expect(twice['contact'], 'enc:g1:alice@example.com');
    });

    test('plaintext legacy values pass through on read (migration window)', () {
      final back = codec.memberFromMap(
        {'memberId': 'm1', 'name': 'PlainAlice', 'contact': 'p@e.com', 'role': 'member'},
        groupId: 'g1',
      );
      expect(back.name, 'PlainAlice');
      expect(back.contact, 'p@e.com');
    });

    test('undecryptable ciphertext falls back to raw value', () {
      final back = codec.memberFromMap(
        {'memberId': 'm1', 'name': 'enc:OTHER:Alice', 'contact': '', 'role': 'member'},
        groupId: 'g1',
      );
      expect(back.name, 'enc:OTHER:Alice');
    });

    test('groupToFirestore encrypts ownerName/ownerEmail and members', () {
      final group = SharedGroup(
        groupName: 'Family',
        groupId: 'g1',
        ownerUid: 'owner',
        ownerName: 'Owner Name',
        ownerEmail: 'owner@example.com',
        allowedUid: const ['owner', 'm1'],
        members: [
          _member(id: 'owner', name: 'Owner Name', contact: 'owner@example.com',
              role: SharedGroupRole.owner),
          _member(),
        ],
      );

      final map = codec.groupToFirestore(group);
      expect(map['ownerName'], 'enc:g1:Owner Name');
      expect(map['ownerEmail'], 'enc:g1:owner@example.com');
      expect(map['allowedUid'], ['owner', 'm1']); // アクセス制御は平文のまま
      expect((map['members'] as List).first['name'], 'enc:g1:Owner Name');

      final back = codec.groupFromMap(map);
      expect(back.ownerName, 'Owner Name');
      expect(back.ownerEmail, 'owner@example.com');
      expect(back.members!.first.name, 'Owner Name');
      expect(back.members!.last.contact, 'alice@example.com');
      expect(back.allowedUid, ['owner', 'm1']);
    });

    test('decryptGroup post-hook decrypts an already-built group', () {
      final encryptedGroup = SharedGroup(
        groupName: 'Family',
        groupId: 'g1',
        ownerUid: 'owner',
        ownerName: 'enc:g1:Owner Name',
        ownerEmail: 'enc:g1:owner@example.com',
        allowedUid: const ['owner'],
        members: [
          _member(name: 'enc:g1:Alice', contact: 'enc:g1:alice@example.com'),
        ],
      );

      final decrypted = codec.decryptGroup(encryptedGroup);
      expect(decrypted.ownerName, 'Owner Name');
      expect(decrypted.members!.single.name, 'Alice');
      expect(decrypted.members!.single.contact, 'alice@example.com');
    });

    test('empty strings are left untouched', () {
      final map = codec.memberToMap(
        _member(name: '', contact: ''),
        groupId: 'g1',
      );
      expect(map['name'], '');
      expect(map['contact'], '');
    });
  });
}
