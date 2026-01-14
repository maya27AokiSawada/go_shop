/// 8ビットフラグによる権限管理システム
///
/// 各ビットが特定の権限を表し、ビット演算で効率的に権限チェックを行う
class Permission {
  // 基本権限（個別ビット）
  static const int NONE = 0x00; // 0000 0000 - アクセス不可
  static const int READ = 0x01; // 0000 0001 - 閲覧
  static const int DONE = 0x02; // 0000 0010 - 完了チェック
  static const int COMMENT = 0x04; // 0000 0100 - コメント追加
  static const int ITEM_CREATE = 0x08; // 0000 1000 - アイテム追加
  static const int ITEM_EDIT = 0x10; // 0001 0000 - アイテム編集
  static const int LIST_CREATE = 0x20; // 0010 0000 - リスト作成
  static const int MEMBER_INVITE = 0x40; // 0100 0000 - メンバー招待
  static const int ADMIN = 0x80; // 1000 0000 - 管理者権限

  // プリセット権限（よく使う組み合わせ）
  static const int VIEWER = READ | DONE; // 0x03 - 閲覧者
  static const int CONTRIBUTOR = READ | DONE | ITEM_CREATE; // 0x0B - 貢献者
  static const int EDITOR = READ | DONE | ITEM_CREATE | ITEM_EDIT; // 0x1B - 編集者
  static const int MANAGER =
      VIEWER | ITEM_CREATE | ITEM_EDIT | LIST_CREATE; // 0x3B - マネージャー
  static const int FULL = 0xFF; // 0xFF - 全権限

  /// 権限チェック
  ///
  /// [userPerm] ユーザーが持つ権限
  /// [requiredPerm] 必要な権限
  /// 戻り値: ユーザーが必要な権限を全て持っているか
  static bool hasPermission(int userPerm, int requiredPerm) {
    return (userPerm & requiredPerm) == requiredPerm;
  }

  /// 権限追加
  ///
  /// [current] 現在の権限
  /// [newPerm] 追加する権限
  /// 戻り値: 追加後の権限
  static int addPermission(int current, int newPerm) {
    return current | newPerm;
  }

  /// 権限削除
  ///
  /// [current] 現在の権限
  /// [removePerm] 削除する権限
  /// 戻り値: 削除後の権限
  static int removePermission(int current, int removePerm) {
    return current & ~removePerm;
  }

  /// 権限トグル（持っていれば削除、持っていなければ追加）
  ///
  /// [current] 現在の権限
  /// [togglePerm] トグルする権限
  /// 戻り値: トグル後の権限
  static int togglePermission(int current, int togglePerm) {
    return current ^ togglePerm;
  }

  /// 権限を持っているか個別チェック
  static bool canRead(int perm) => hasPermission(perm, READ);
  static bool canMarkDone(int perm) => hasPermission(perm, DONE);
  static bool canComment(int perm) => hasPermission(perm, COMMENT);
  static bool canCreateItem(int perm) => hasPermission(perm, ITEM_CREATE);
  static bool canEditItem(int perm) => hasPermission(perm, ITEM_EDIT);
  static bool canCreateList(int perm) => hasPermission(perm, LIST_CREATE);
  static bool canInviteMember(int perm) => hasPermission(perm, MEMBER_INVITE);
  static bool isAdmin(int perm) => hasPermission(perm, ADMIN);

  /// 権限を人間可読な文字列に変換
  static String toString(int perm) {
    if (perm == NONE) return 'アクセス不可';
    if (perm == FULL) return '全権限';

    final permissions = <String>[];
    if (canRead(perm)) permissions.add('閲覧');
    if (canMarkDone(perm)) permissions.add('完了チェック');
    if (canComment(perm)) permissions.add('コメント');
    if (canCreateItem(perm)) permissions.add('アイテム追加');
    if (canEditItem(perm)) permissions.add('アイテム編集');
    if (canCreateList(perm)) permissions.add('リスト作成');
    if (canInviteMember(perm)) permissions.add('メンバー招待');
    if (isAdmin(perm)) permissions.add('管理者');

    return permissions.join('、');
  }

  /// プリセット名を取得
  static String getPresetName(int perm) {
    if (perm == VIEWER) return '閲覧者';
    if (perm == CONTRIBUTOR) return '貢献者';
    if (perm == EDITOR) return '編集者';
    if (perm == MANAGER) return 'マネージャー';
    if (perm == FULL) return '管理者';
    return 'カスタム';
  }
}
