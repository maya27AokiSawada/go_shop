import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/shared_group.dart';

SharedGroupFirestoreCodec _activeCodec = const SharedGroupFirestoreCodec();

/// アプリ全体で使う `SharedGroups` 用コーデックを取得する。
///
/// すべての `SharedGroups` 読み書きサイトはこれを経由すること。Phase 1 では
/// cipher なし（平文のまま・挙動不変）。Phase 3 で [configureSharedGroupCodec] に
/// cipher 付きコーデックを渡すと、全サイトが一括で暗号化へ切り替わる。
SharedGroupFirestoreCodec sharedGroupFirestoreCodec() => _activeCodec;

/// 全サイト共通のコーデックを差し替える（Phase 3 の暗号化 ON スイッチ）。
/// アプリ初期化時に一度だけ呼ぶ想定。テストでも利用可。
void configureSharedGroupCodec(SharedGroupFirestoreCodec codec) {
  _activeCodec = codec;
}

/// テスト用: 既定（cipher なし）へ戻す。
void resetSharedGroupCodec() {
  _activeCodec = const SharedGroupFirestoreCodec();
}

/// グループ共有フィールド（メンバーの name / contact、オーナーの name / email）の
/// 暗号化・復号を担う最小インターフェース。
///
/// 実体は [GroupKeyExchangeService]（`encryptGroupField` / `decryptGroupField` /
/// `isEncryptedGroupField`）。テストではフェイクを注入する。
abstract class GroupFieldCipher {
  String encrypt({required String plaintext, required String groupId});
  String decrypt({required String ciphertext, required String groupId});
  bool isEncrypted(String value);

  /// ローカル永続鍵をメモリキャッシュへ再ロードする。
  ///
  /// [encrypt] / [decrypt] は同期でキャッシュ直読みのため、アプリ再起動後など
  /// キャッシュが空の状態では復号に失敗する。復号前にこれを await して
  /// キャッシュを温めること（アイテム名暗号化の `getPersistedGroupKey` と同じ）。
  Future<void> primeKey(String groupId);
}

/// `SharedGroup` / `SharedGroupMember` と Firestore ドキュメントマップの
/// 相互変換を一元管理するコーデック。
///
/// これまで `firestore_shared_group_repository` / `firestore_group_sync_service` /
/// `sync_service` / `user_initialization_service` / `notification_service` /
/// `firestore_migration_service` が各自 `{'name': ..., 'contact': ...}` を
/// 手組みしていたが、暗号化と後方互換フォールバックを一箇所へ集約するため
/// すべての `SharedGroups` 読み書きを本コーデック経由に統一する。
///
/// [cipher] を渡さない場合は平文のまま（暗号化なし）。既存挙動と等価。
///
/// [encryptOnWrite] が false のときは**復号のみ**行い、書き込み時は暗号化しない
/// （Phase 2 の decrypt-only リリース用）。Phase 3 で true にする。
class SharedGroupFirestoreCodec {
  const SharedGroupFirestoreCodec({
    GroupFieldCipher? cipher,
    bool encryptOnWrite = true,
  })  : _cipher = cipher,
        _encryptOnWrite = encryptOnWrite;

  final GroupFieldCipher? _cipher;
  final bool _encryptOnWrite;

  /// 暗号化が有効か（= cipher が注入されているか）。
  bool get encryptionEnabled => _cipher != null;

  /// 書き込み時に暗号化するか（Phase 2 は false）。
  bool get encryptsOnWrite => _cipher != null && _encryptOnWrite;

  /// グループ鍵をローカル永続化からキャッシュへ再ロードする。
  /// cipher 未注入なら何もしない。
  Future<void> primeKey(String groupId) async {
    await _cipher?.primeKey(groupId);
  }

  /// [decryptGroup] の鍵 prime 付き非同期版。単一グループ読み出しの後段で使う。
  Future<SharedGroup> decryptGroupPrimed(SharedGroup group) async {
    if (_cipher == null) return group;
    await _cipher.primeKey(group.groupId);
    return decryptGroup(group);
  }

  /// 複数グループを、重複 groupId をまとめて prime してから復号する。
  Future<List<SharedGroup>> decryptGroupsPrimed(List<SharedGroup> groups) async {
    if (_cipher == null) return groups;
    for (final gid in groups.map((g) => g.groupId).toSet()) {
      await _cipher.primeKey(gid);
    }
    return groups.map(decryptGroup).toList();
  }

  // ===========================================================================
  // メンバー
  // ===========================================================================

  /// メンバー1件を Firestore 保存用マップへ変換する（name / contact を暗号化）。
  Map<String, dynamic> memberToMap(
    SharedGroupMember m, {
    required String groupId,
  }) {
    return {
      'memberId': m.memberId,
      'name': _enc(m.name, groupId),
      'contact': _enc(m.contact, groupId),
      'role': m.role.name,
      'invitedAt':
          m.invitedAt != null ? Timestamp.fromDate(m.invitedAt!) : null,
      'acceptedAt':
          m.acceptedAt != null ? Timestamp.fromDate(m.acceptedAt!) : null,
    };
  }

  /// Firestore マップからメンバー1件を復元する（name / contact を復号）。
  ///
  /// 旧データの別名フィールド（`uid` / `displayName` / `joinedAt`）にも対応する。
  SharedGroupMember memberFromMap(
    Map<String, dynamic> data, {
    required String groupId,
  }) {
    return SharedGroupMember(
      memberId: (data['uid'] ?? data['memberId'] ?? '') as String,
      name: _dec(
        (data['displayName'] ?? data['name'] ?? '') as String,
        groupId,
      ),
      contact: _dec((data['contact'] ?? '') as String, groupId),
      role: SharedGroupRole.values.firstWhere(
        (e) => e.name == data['role'],
        orElse: () => SharedGroupRole.member,
      ),
      invitedAt: _parseDateTime(data['invitedAt'] ?? data['joinedAt']),
      acceptedAt:
          _parseDateTimeNullable(data['acceptedAt'] ?? data['joinedAt']),
    );
  }

  List<Map<String, dynamic>> membersToMaps(
    Iterable<SharedGroupMember>? members, {
    required String groupId,
  }) {
    return (members ?? const [])
        .map((m) => memberToMap(m, groupId: groupId))
        .toList();
  }

  List<SharedGroupMember> membersFromMaps(
    List<dynamic>? raw, {
    required String groupId,
  }) {
    return (raw ?? const [])
        .whereType<Map>()
        .map((m) => memberFromMap(
              Map<String, dynamic>.from(m),
              groupId: groupId,
            ))
        .toList();
  }

  /// メンバー配列の name/contact だけを暗号化した写しを返す（他フィールドは不変）。
  /// 独自マップ形状で書き込むサイト向けのフック。`cipher == null` なら素通し。
  List<SharedGroupMember> encryptMembers(
    Iterable<SharedGroupMember>? members, {
    required String groupId,
  }) {
    if (!encryptsOnWrite || members == null) {
      return members?.toList() ?? const [];
    }
    return members
        .map((m) => m.copyWithExtra(
              name: _enc(m.name, groupId),
              contact: _enc(m.contact, groupId),
            ))
        .toList();
  }

  /// [encryptMembers] の逆。暗号文でない値・復号失敗はそのまま返す。
  List<SharedGroupMember> decryptMembers(
    Iterable<SharedGroupMember>? members, {
    required String groupId,
  }) {
    if (_cipher == null || members == null) {
      return members?.toList() ?? const [];
    }
    return members
        .map((m) => m.copyWithExtra(
              name: _dec(m.name, groupId),
              contact: _dec(m.contact, groupId),
            ))
        .toList();
  }

  // ===========================================================================
  // グループ本体
  // ===========================================================================

  /// `SharedGroup` を Firestore 保存用マップへ変換する。
  ///
  /// `ownerName` / `ownerEmail` と `members[].name` / `members[].contact` を暗号化する。
  /// `allowedUid` / `ownerUid` などアクセス制御・クエリに使うフィールドは平文のまま。
  Map<String, dynamic> groupToFirestore(SharedGroup group) {
    return {
      'groupName': group.groupName,
      'groupId': group.groupId,
      'ownerUid': group.ownerUid,
      'ownerName': _encNullable(group.ownerName, group.groupId),
      'ownerEmail': _encNullable(group.ownerEmail, group.groupId),
      'allowedUid': group.allowedUid,
      'members': membersToMaps(group.members, groupId: group.groupId),
      'createdAt': group.createdAt != null
          ? Timestamp.fromDate(group.createdAt!)
          : null,
      'updatedAt': group.updatedAt != null
          ? Timestamp.fromDate(group.updatedAt!)
          : null,
      'isDeleted': group.isDeleted,
    };
  }

  /// Firestore ドキュメントから `SharedGroup` を復元する。
  SharedGroup groupFromMap(Map<String, dynamic> data, {String? docId}) {
    final groupId = (data['groupId'] ?? docId ?? '') as String;
    return SharedGroup(
      groupName: (data['groupName'] ?? '') as String,
      groupId: groupId,
      ownerUid: (data['ownerUid'] ?? '') as String,
      ownerName: _decNullable(data['ownerName'] as String?, groupId),
      ownerEmail: _decNullable(data['ownerEmail'] as String?, groupId),
      allowedUid: List<String>.from(data['allowedUid'] ?? const []),
      members: membersFromMaps(data['members'] as List<dynamic>?,
          groupId: groupId),
      createdAt: _parseDateTime(data['createdAt']),
      updatedAt: _parseDateTime(data['updatedAt']),
      isDeleted: (data['isDeleted'] ?? false) as bool,
    );
  }

  SharedGroup groupFromDoc(DocumentSnapshot doc) {
    return groupFromMap(
      Map<String, dynamic>.from(doc.data() as Map),
      docId: doc.id,
    );
  }

  /// 読み出し済み `SharedGroup`（暗号文を含みうる）を復号済みに変換する。
  /// 直接 Firestore を読む経路が本コーデックを通さずに `SharedGroup` を
  /// 組み立てている場合の後段フックとして使う。
  SharedGroup decryptGroup(SharedGroup group) {
    if (_cipher == null) return group;
    return group.copyWith(
      ownerName: _decNullable(group.ownerName, group.groupId),
      ownerEmail: _decNullable(group.ownerEmail, group.groupId),
      members: group.members
          ?.map((m) => m.copyWithExtra(
                name: _dec(m.name, group.groupId),
                contact: _dec(m.contact, group.groupId),
              ))
          .toList(),
    );
  }

  /// `SharedGroup` の `ownerName` / `ownerEmail` / `members[].name` /
  /// `members[].contact` を暗号化した写しを返す（[decryptGroup] の逆）。
  ///
  /// 各書き込みサイトが独自のマップ形状（`isSignedIn` などの追加フィールド）を
  /// 保ったまま暗号化だけを差し込めるようにするためのフック。
  /// `cipher == null` なら素通し。すでに暗号化済みの値は二重暗号化しない。
  SharedGroup encryptGroup(SharedGroup group) {
    if (!encryptsOnWrite) return group;
    return group.copyWith(
      ownerName: _encNullable(group.ownerName, group.groupId),
      ownerEmail: _encNullable(group.ownerEmail, group.groupId),
      members: group.members
          ?.map((m) => m.copyWithExtra(
                name: _enc(m.name, group.groupId),
                contact: _enc(m.contact, group.groupId),
              ))
          .toList(),
    );
  }

  // ===========================================================================
  // 内部ヘルパー
  // ===========================================================================

  String _enc(String value, String groupId) {
    final cipher = _cipher;
    if (cipher == null || !_encryptOnWrite || value.isEmpty) return value;
    if (cipher.isEncrypted(value)) return value; // 二重暗号化を防ぐ
    return cipher.encrypt(plaintext: value, groupId: groupId);
  }

  String? _encNullable(String? value, String groupId) {
    if (value == null) return null;
    return _enc(value, groupId);
  }

  String _dec(String value, String groupId) {
    final cipher = _cipher;
    if (cipher == null || value.isEmpty || !cipher.isEncrypted(value)) {
      return value;
    }
    try {
      return cipher.decrypt(ciphertext: value, groupId: groupId);
    } catch (_) {
      // 鍵未取得などで復号できない場合は生値を返す（UI 側で表示は崩れる）。
      return value;
    }
  }

  String? _decNullable(String? value, String groupId) {
    if (value == null) return null;
    return _dec(value, groupId);
  }

  DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    try {
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.parse(value);
    } catch (_) {}
    return DateTime.now();
  }

  DateTime? _parseDateTimeNullable(dynamic value) {
    if (value == null) return null;
    try {
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.parse(value);
    } catch (_) {}
    return null;
  }
}
