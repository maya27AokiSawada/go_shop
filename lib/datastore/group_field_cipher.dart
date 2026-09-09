import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/group_key_exchange_service.dart';
import 'shared_group_firestore_codec.dart';

/// [GroupKeyExchangeService] を [GroupFieldCipher] として使うためのアダプター。
///
/// 注意: 暗号化・復号とも [GroupKeyExchangeService] のメモリキャッシュ済みグループ鍵を
/// 参照する。復号前に [primeKey]（= `getPersistedGroupKey`）でキャッシュを温めること。
/// アイテム名暗号化と鍵キャッシュを共有するため、必ず provider シングルトンの
/// [GroupKeyExchangeService] を渡す（`GroupKeyExchangeService()` を new すると別キャッシュ）。
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

  @override
  Future<void> primeKey(String groupId) async {
    // ローカル永続鍵をメモリキャッシュへ再ロード（戻り値は使わない）。
    await _service.getPersistedGroupKey(groupId: groupId);
  }
}

/// Phase 2（decrypt-only）: cipher 付きコーデックをアプリ全体へ適用する。
///
/// アプリ初期化で一度 `ref.read(sharedGroupCodecProvider)` すると、
/// [configureSharedGroupCodec] が呼ばれて全 `SharedGroups` 読み書きサイトが
/// 復号対応になる（書き込みの暗号化は Phase 3 まで OFF）。
final sharedGroupCodecProvider = Provider<SharedGroupFirestoreCodec>((ref) {
  final keyService = ref.read(groupKeyExchangeServiceProvider);
  final codec = SharedGroupFirestoreCodec(
    cipher: GroupKeyServiceFieldCipher(keyService),
    encryptOnWrite: false, // Phase 2: 復号のみ。Phase 3 で true にする。
  );
  configureSharedGroupCodec(codec);
  return codec;
});
