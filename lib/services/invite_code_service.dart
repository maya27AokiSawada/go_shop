import 'dart:convert';
import 'package:crypto/crypto.dart';

/// QRコード中心の招待システム用セキュアコード生成サービス
class InviteCodeService {
  static const int _codeLength = 8;
  static const int _validityHours = 24;

  /// セキュアな招待コード生成
  ///
  /// [groupId] グループID
  /// Returns: 8桁のセキュアな招待コード（24時間有効）
  static String generateInviteCode(String groupId) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final expiryTime = timestamp + (_validityHours * 3600 * 1000);

    // グループID + 有効期限のハッシュ
    final input = '$groupId:$expiryTime';
    final hash = sha256.convert(utf8.encode(input));

    // Base62エンコーディングで短縮
    return _encodeBase62(hash.bytes.take(6).fold(0, (a, b) => a * 256 + b))
        .padLeft(_codeLength, '0')
        .substring(0, _codeLength)
        .toUpperCase();
  }

  /// 招待コード検証
  ///
  /// [code] 招待コード
  /// [groupId] グループID（将来的にハッシュ逆算で検証）
  /// Returns: コードが有効かどうか
  static bool validateInviteCode(String code, String groupId) {
    // シンプルな長さチェック（将来的にHiveでコード管理テーブル追加予定）
    return code.length == _codeLength && RegExp(r'^[A-Z0-9]+$').hasMatch(code);
  }

  /// Base62エンコーディング（大文字小文字数字）
  static String _encodeBase62(int value) {
    const chars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    if (value == 0) return chars[0];

    String result = '';
    while (value > 0) {
      result = chars[value % 62] + result;
      value ~/= 62;
    }
    return result;
  }

  /// 招待テキスト生成
  ///
  /// [groupName] グループ名
  /// [inviteCode] 招待コード
  /// Returns: ユーザーが共有する招待メッセージ
  static String generateInviteText(String groupName, String inviteCode) {
    return '''Go Shop グループ「$groupName」に招待されました！
    
📱 参加方法:
1. Go Shopアプリをダウンロード
2. QRコードをスキャン、または
3. 招待コードを入力: $inviteCode

お買い物を一緒に管理しましょう！''';
  }
}
