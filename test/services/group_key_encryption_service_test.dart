import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:goshopping/services/group_key_encryption_service.dart';

void main() {
  late GroupKeyEncryptionService service;

  setUp(() {
    service = GroupKeyEncryptionService();
  });

  group('GroupKeyEncryptionService', () {
    test('generateGroupKey returns base64 encoded bytes', () {
      final key = service.generateGroupKey();

      expect(key, isNotEmpty);
      expect(base64.decode(key).length, 32);
    });

    test('encrypt and decrypt round trip with same secret', () {
      final groupKey = service.generateGroupKey();
      final recipientSecret = service.generateRecipientSecret();

      final encrypted = service.encryptGroupKey(
        groupKey: groupKey,
        recipientSecret: recipientSecret,
      );

      final decrypted = service.decryptGroupKey(
        encryptedGroupKey: encrypted,
        recipientSecret: recipientSecret,
      );

      expect(decrypted, equals(groupKey));
    });

    test('decryption fails when recipient secret is different', () {
      final groupKey = service.generateGroupKey();
      final encrypted = service.encryptGroupKey(
        groupKey: groupKey,
        recipientSecret: 'recipient-secret-1',
      );

      expect(
        () => service.decryptGroupKey(
          encryptedGroupKey: encrypted,
          recipientSecret: 'recipient-secret-2',
        ),
        throwsA(isA<FormatException>()),
      );
    });

    test('invalid payload throws a format exception', () {
      expect(
        () => service.decryptGroupKey(
          encryptedGroupKey: 'not-a-valid-payload',
          recipientSecret: 'secret',
        ),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
