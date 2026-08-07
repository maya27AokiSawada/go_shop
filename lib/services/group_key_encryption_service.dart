import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

/// グループ共通鍵の配布用暗号化サービス。
///
/// ここでは簡便な実装として、共有鍵を Base64 で表現し、受信者秘密情報を
/// 共有鍵のハッシュとして利用して、AES 風の鍵導出を行う。
/// 実際の本実装では、より堅牢なライブラリに置き換える想定。
class GroupKeyEncryptionService {
  static const int _keyBytes = 32;

  /// ランダムな共通鍵を生成する。
  /// 生成値は Base64 文字列とし、Firestore 保存時にそのまま扱えるようにする。
  String generateGroupKey() {
    final bytes =
        List<int>.generate(_keyBytes, (_) => Random.secure().nextInt(256));
    return base64.encode(bytes);
  }

  /// 受信者ごとの秘密情報を生成する。
  /// 実運用では公開鍵の秘密鍵や受信者固有のシークレットを想定する。
  String generateRecipientSecret() {
    final bytes = List<int>.generate(32, (_) => Random.secure().nextInt(256));
    return base64.encode(bytes);
  }

  /// 共通鍵を受信者秘密情報で暗号化する。
  String encryptGroupKey({
    required String groupKey,
    required String recipientSecret,
  }) {
    final groupBytes = base64.decode(groupKey);
    final secretBytes = utf8.encode(recipientSecret);
    final derived = _deriveKey(secretBytes, groupBytes.length);

    final encrypted = <int>[];
    for (var i = 0; i < groupBytes.length; i++) {
      encrypted.add(groupBytes[i] ^ derived[i % derived.length]);
    }

    final tag = sha256.convert([...encrypted, ...secretBytes]).bytes;
    final payload = jsonEncode({
      'version': 1,
      'ciphertext': base64.encode(encrypted),
      'tag': base64.encode(tag),
    });

    return base64.encode(utf8.encode(payload));
  }

  /// 受信者秘密情報で暗号化済み共通鍵を復号する。
  String decryptGroupKey({
    required String encryptedGroupKey,
    required String recipientSecret,
  }) {
    try {
      final payload = jsonDecode(utf8.decode(base64.decode(encryptedGroupKey)))
          as Map<String, dynamic>;
      final encryptedBytes = base64.decode(payload['ciphertext'] as String);
      final expectedTag = base64.decode(payload['tag'] as String);

      final secretBytes = utf8.encode(recipientSecret);
      final derived = _deriveKey(secretBytes, encryptedBytes.length);

      final decrypted = <int>[];
      for (var i = 0; i < encryptedBytes.length; i++) {
        decrypted.add(encryptedBytes[i] ^ derived[i % derived.length]);
      }

      final actualTag =
          sha256.convert([...encryptedBytes, ...secretBytes]).bytes;
      if (!_equalBytes(actualTag, expectedTag)) {
        throw const FormatException('recipient secret does not match');
      }

      return base64.encode(decrypted);
    } on FormatException {
      rethrow;
    } catch (_) {
      throw const FormatException('invalid encrypted group key payload');
    }
  }

  List<int> _deriveKey(List<int> secretBytes, int length) {
    final digest = sha256.convert(secretBytes).bytes;
    final result = <int>[];
    while (result.length < length) {
      result.addAll(digest);
    }
    return result.take(length).toList();
  }

  bool _equalBytes(List<int> a, List<int> b) {
    if (a.length != b.length) {
      return false;
    }
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) {
        return false;
      }
    }
    return true;
  }
}
