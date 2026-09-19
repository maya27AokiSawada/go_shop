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
    // ローカル永続鍵をメモリキャッシュへ再ロード。
    await _service.getPersistedGroupKey(groupId: groupId);
    // 鍵ローテーション直後で旧鍵の暗号文が残っていれば、現在の鍵へ移行する。
    // 復号（decrypt）より前に呼ばれる前提のため、ここで直しておけば
    // 通常の decrypt は常に現行鍵で成功するようになる。
    await _service.reencryptGroupFieldsIfKeyChanged(groupId: groupId);
  }
}

/// cipher 付きコーデックをアプリ全体へ適用する。
///
/// アプリ初期化で一度 `ref.read(sharedGroupCodecProvider)` すると、
/// [configureSharedGroupCodec] が呼ばれて全 `SharedGroups` 読み書きサイトが
/// 暗号化・復号対応になる。
///
/// Phase 3: `encryptOnWrite: true`。以後の `SharedGroups` 書き込みは
/// members[].name/contact・ownerName/ownerEmail を暗号化する
/// （グループ鍵が設定済みのグループのみ。未設定なら平文のまま）。
/// 既存の平文ドキュメントは次回書き込みまで平文のまま（読みは復号フォールバックで対応）。
final sharedGroupCodecProvider = Provider<SharedGroupFirestoreCodec>((ref) {
  final keyService = ref.read(groupKeyExchangeServiceProvider);
  final codec = SharedGroupFirestoreCodec(
    cipher: GroupKeyServiceFieldCipher(keyService),
    encryptOnWrite: true, // Phase 3
  );
  configureSharedGroupCodec(codec);
  return codec;
});
