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
    );
    expect(service.isEncryptedGroupField(encrypted), isTrue);
    expect(encrypted, isNot('Alice Example'));

    final decrypted = service.decryptGroupField(
      ciphertext: encrypted,
      groupId: groupId,
    );
    expect(decrypted, 'Alice Example');
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

  test('decrypt falls back to the keyless secret for legacy ciphertext', () {
    const groupId = 'group-f';
    // groupKey なしで暗号化された旧データ相当。
    final legacy = service.encryptGroupField(
      plaintext: 'legacy@example.com',
      groupId: groupId,
      groupKey: '',
    );

    // 呼び出し側が groupKey を渡しても、新方式で失敗したら keyless で復号できる。
    final decrypted = service.decryptGroupField(
      ciphertext: legacy,
      groupId: groupId,
      groupKey: 'some-current-key',
    );
    expect(decrypted, 'legacy@example.com');
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
