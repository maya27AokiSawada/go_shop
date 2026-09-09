import '../services/group_key_exchange_service.dart';
import 'shared_group_firestore_codec.dart';

/// [GroupKeyExchangeService] を [GroupFieldCipher] として使うためのアダプター。
///
/// 注意: 暗号化・復号ともローカルキャッシュ済みのグループ鍵を参照するため、
/// 呼び出し前に `GroupKeyExchangeService.getPersistedGroupKey(groupId: ...)` で
/// 鍵をキャッシュへ載せておくこと（アイテム名暗号化と同じ前提）。
class GroupKeyServiceFieldCipher implements GroupFieldCipher {
  const GroupKeyServiceFieldCipher(this._service);

  final GroupKeyExchangeService _service;

  @override
  String encrypt({required String plaintext, required String groupId}) =>
      _service.encryptGroupField(plaintext: plaintext, groupId: groupId);

  @override
  String decrypt({required String ciphertext, required String groupId}) =>
      _service.decryptGroupField(ciphertext: ciphertext, groupId: groupId);

  @override
  bool isEncrypted(String value) => _service.isEncryptedGroupField(value);
}
