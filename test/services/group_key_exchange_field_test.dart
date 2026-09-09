import 'package:flutter_test/flutter_test.dart';
import 'package:goshopping/services/group_key_exchange_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// グループ共有フィールド（members[].name / contact、ownerName / ownerEmail）用の
/// 暗号化 API の単体テスト。Firebase を触らない純粋な暗号処理のみを対象とする。
void main() {
  late GroupKeyExchangeService service;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    service = GroupKeyExchangeService();
  });

  test('round-trips a group field with the group-wide secret', () {
    const groupId = 'group-d';

    final encrypted = service.encryptGroupField(
      plaintext: 'Alice Example',
      groupId: groupId,
      groupKey: 'gk',
    );
    expect(service.isEncryptedGroupField(encrypted), isTrue);
    expect(encrypted, isNot('Alice Example'));

    final decrypted = service.decryptGroupField(
      ciphertext: encrypted,
      groupId: groupId,
      groupKey: 'gk',
    );
    expect(decrypted, 'Alice Example');
  });

  test('no usable key -> encryptGroupField returns plaintext (Phase 3 guard)',
      () {
    // 鍵未キャッシュ・groupKey 未指定なら暗号化しない（弱い暗号文を作らない）。
    final out = service.encryptGroupField(
      plaintext: 'Alice Example',
      groupId: 'group-nokey',
    );
    expect(out, 'Alice Example');
    expect(service.isEncryptedGroupField(out), isFalse);

    // 明示的に空文字を渡した場合も同じ。
    final out2 = service.encryptGroupField(
      plaintext: 'x@y.z',
      groupId: 'group-nokey',
      groupKey: '',
    );
    expect(out2, 'x@y.z');
  });

  test('encryptGroupField uses the persisted key once primed', () async {
    SharedPreferences.setMockInitialValues(
        {'group_key_v1:group-primed': 'persisted-key'});
    final primed = GroupKeyExchangeService();
    await primed.getPersistedGroupKey(groupId: 'group-primed');

    final encrypted = primed.encryptGroupField(
      plaintext: 'Bob',
      groupId: 'group-primed',
    );
    expect(primed.isEncryptedGroupField(encrypted), isTrue);
    expect(
      primed.decryptGroupField(ciphertext: encrypted, groupId: 'group-primed'),
      'Bob',
    );
  });

  test('does not require memberUid: same groupId + groupKey decrypts', () {
    const groupId = 'group-e';
    final encrypted = service.encryptGroupField(
      plaintext: 'contact@example.com',
      groupId: groupId,
      groupKey: 'shared-key',
    );

    final decrypted = service.decryptGroupField(
      ciphertext: encrypted,
      groupId: groupId,
      groupKey: 'shared-key',
    );
    expect(decrypted, 'contact@example.com');
  });

  test('isEncryptedGroupField is false for plaintext / empty', () {
    expect(service.isEncryptedGroupField('Bob'), isFalse);
    expect(service.isEncryptedGroupField('bob@example.com'), isFalse);
    expect(service.isEncryptedGroupField(''), isFalse);
  });

  test('encrypting the same value twice with the same key is deterministic', () {
    const groupId = 'group-g';
    final a = service.encryptGroupField(
        plaintext: 'x@y.z', groupId: groupId, groupKey: 'k');
    final b = service.encryptGroupField(
        plaintext: 'x@y.z', groupId: groupId, groupKey: 'k');
    expect(a, b);
  });
}
