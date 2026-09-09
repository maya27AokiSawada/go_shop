import 'package:flutter_test/flutter_test.dart';
import 'package:goshopping/datastore/shared_group_firestore_codec.dart';
import 'package:goshopping/models/shared_group.dart';

/// 決定的なフェイク暗号器。`enc:` プレフィックスで「暗号化済み」を表現する。
class _FakeCipher implements GroupFieldCipher {
  final Set<String> seenGroupIds = {};
  final List<String> primedGroupIds = [];

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

  @override
  Future<void> primeKey(String groupId) async {
    primedGroupIds.add(groupId);
  }
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
  group('sharedGroupFirestoreCodec() module-level switch', () {
    tearDown(resetSharedGroupCodec);

    test('defaults to a cipher-less codec', () {
      expect(sharedGroupFirestoreCodec().encryptionEnabled, isFalse);
    });

    test('configureSharedGroupCodec swaps the active codec for all callers', () {
      configureSharedGroupCodec(SharedGroupFirestoreCodec(cipher: _FakeCipher()));
      expect(sharedGroupFirestoreCodec().encryptionEnabled, isTrue);

      final map = sharedGroupFirestoreCodec()
          .memberToMap(_member(), groupId: 'g1');
      expect(map['name'], 'enc:g1:Alice');

      resetSharedGroupCodec();
      expect(sharedGroupFirestoreCodec().encryptionEnabled, isFalse);
    });
  });

  group('SharedGroupFirestoreCodec decrypt-only (Phase 2)', () {
    late _FakeCipher cipher;
    late SharedGroupFirestoreCodec codec;

    setUp(() {
      cipher = _FakeCipher();
      codec = SharedGroupFirestoreCodec(cipher: cipher, encryptOnWrite: false);
    });

    test('writes stay plaintext', () {
      final map = codec.memberToMap(_member(), groupId: 'g1');
      expect(map['name'], 'Alice');
      expect(map['contact'], 'alice@example.com');
      expect(cipher.seenGroupIds, isEmpty);
    });

    test('encryptGroup is a no-op (returns same instance)', () {
      final group = SharedGroup(
        groupName: 'G',
        groupId: 'g1',
        ownerUid: 'o',
        ownerName: 'Owner',
        allowedUid: const ['o'],
        members: [_member()],
      );
      expect(identical(codec.encryptGroup(group), group), isTrue);
    });

    test('encryptGroupPrimed / encryptMembersPrimed are no-ops', () async {
      final group = SharedGroup(
        groupName: 'G',
        groupId: 'g1',
        ownerUid: 'o',
        ownerName: 'Owner',
        allowedUid: const ['o'],
        members: [_member()],
      );
      expect(identical(await codec.encryptGroupPrimed(group), group), isTrue);
      final m = [_member()];
      final out = await codec.encryptMembersPrimed(m, groupId: 'g1');
      expect(out.single.name, m.single.name); // 平文のまま
      expect(cipher.primedGroupIds, isEmpty); // prime も呼ばれない
    });

    test('reads still decrypt', () {
      final back = codec.memberFromMap(
        {'memberId': 'm1', 'name': 'enc:g1:Alice', 'contact': 'enc:g1:a@e.com', 'role': 'member'},
        groupId: 'g1',
      );
      expect(back.name, 'Alice');
      expect(back.contact, 'a@e.com');
    });

    test('encryptsOnWrite is false, encryptionEnabled is true', () {
      expect(codec.encryptsOnWrite, isFalse);
      expect(codec.encryptionEnabled, isTrue);
    });
  });

  group('SharedGroupFirestoreCodec without cipher (legacy behavior)', () {
    const codec = SharedGroupFirestoreCodec();

    test('encryptGroup / decryptGroup are no-ops when cipher is null', () {
      final group = SharedGroup(
        groupName: 'G',
        groupId: 'g1',
        ownerUid: 'o',
        ownerName: 'Owner',
        ownerEmail: 'o@e.com',
        allowedUid: const ['o'],
        members: [_member()],
      );
      expect(identical(codec.encryptGroup(group), group), isTrue);
      expect(identical(codec.decryptGroup(group), group), isTrue);
    });

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

    test('encryptGroup / decryptGroup round-trip preserves other fields', () {
      final group = SharedGroup(
        groupName: 'Family',
        groupId: 'g1',
        ownerUid: 'owner',
        ownerName: 'Owner Name',
        ownerEmail: 'owner@example.com',
        allowedUid: const ['owner', 'm1'],
        members: [
          _member(id: 'm1', name: 'Alice', contact: 'alice@example.com'),
        ],
      );

      final encrypted = codec.encryptGroup(group);
      expect(encrypted.ownerName, 'enc:g1:Owner Name');
      expect(encrypted.members!.single.name, 'enc:g1:Alice');
      // 非対象フィールドは不変
      expect(encrypted.allowedUid, ['owner', 'm1']);
      expect(encrypted.members!.single.memberId, 'm1');
      expect(encrypted.members!.single.role, SharedGroupRole.member);

      final back = codec.decryptGroup(encrypted);
      expect(back.ownerName, 'Owner Name');
      expect(back.members!.single.name, 'Alice');
      expect(back.members!.single.contact, 'alice@example.com');
    });

    test('decryptGroupPrimed primes the key before decrypting', () async {
      final encryptedGroup = SharedGroup(
        groupName: 'G',
        groupId: 'g1',
        ownerUid: 'o',
        ownerName: 'enc:g1:Owner',
        allowedUid: const ['o'],
        members: [_member(name: 'enc:g1:Alice', contact: 'enc:g1:a@e.com')],
      );

      final out = await codec.decryptGroupPrimed(encryptedGroup);
      expect(cipher.primedGroupIds, ['g1']);
      expect(out.ownerName, 'Owner');
      expect(out.members!.single.name, 'Alice');
    });

    test('encryptGroupPrimed primes the key before encrypting', () async {
      final group = SharedGroup(
        groupName: 'G',
        groupId: 'g1',
        ownerUid: 'o',
        ownerName: 'Owner Name',
        ownerEmail: 'owner@example.com',
        allowedUid: const ['o'],
        members: [_member(id: 'm1', name: 'Alice', contact: 'alice@example.com')],
      );

      final out = await codec.encryptGroupPrimed(group);
      expect(cipher.primedGroupIds, ['g1']);
      expect(out.ownerName, 'enc:g1:Owner Name');
      expect(out.members!.single.name, 'enc:g1:Alice');
      // 逆変換で戻る
      expect(codec.decryptGroup(out).members!.single.name, 'Alice');
    });

    test('encryptMembersPrimed primes and encrypts name/contact only', () async {
      final out = await codec.encryptMembersPrimed(
        [_member(id: 'm1', name: 'Al', contact: 'a@e.com')],
        groupId: 'g9',
      );
      expect(cipher.primedGroupIds, contains('g9'));
      expect(out.single.name, 'enc:g9:Al');
      expect(out.single.contact, 'enc:g9:a@e.com');
      expect(out.single.memberId, 'm1');
    });

    test('decryptGroupsPrimed primes each distinct groupId once', () async {
      final groups = [
        SharedGroup(
          groupName: 'A',
          groupId: 'g1',
          ownerUid: 'o',
          allowedUid: const ['o'],
          members: [_member(name: 'enc:g1:Al', contact: 'enc:g1:a@e')],
        ),
        SharedGroup(
          groupName: 'B',
          groupId: 'g2',
          ownerUid: 'o',
          allowedUid: const ['o'],
          members: [_member(name: 'enc:g2:Bo', contact: 'enc:g2:b@e')],
        ),
      ];
      final out = await codec.decryptGroupsPrimed(groups);
      expect(cipher.primedGroupIds.toSet(), {'g1', 'g2'});
      expect(out[0].members!.single.name, 'Al');
      expect(out[1].members!.single.name, 'Bo');
    });

    test('encryptGroup is idempotent (no double encryption)', () {
      final group = SharedGroup(
        groupName: 'G',
        groupId: 'g1',
        ownerUid: 'o',
        ownerName: 'N',
        allowedUid: const ['o'],
        members: [_member(id: 'm1', name: 'A', contact: 'a@e.com')],
      );
      final once = codec.encryptGroup(group);
      final twice = codec.encryptGroup(once);
      expect(twice.members!.single.name, once.members!.single.name);
      expect(twice.ownerName, once.ownerName);
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
