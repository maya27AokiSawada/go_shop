// lib/helpers/validation_service.dart
import '../models/shared_group.dart';
import '../models/shared_list.dart';

/// アプリ全体で使用される重複チェックとバリデーション機能を提供するサービス
class ValidationService {
  // ================== グループ名重複チェック ==================

  /// グループ名の重複をチェック
  /// [groupName] チェック対象のグループ名
  /// [existingGroups] 既存のグループリスト
  /// [excludeGroupId] 除外するグループID（編集時に自分自身を除外）
  static ValidationResult validateGroupName(
      String groupName, List<SharedGroup> existingGroups,
      {String? excludeGroupId}) {
    // 空文字チェック
    if (groupName.trim().isEmpty) {
      return ValidationResult.error('グループ名を入力してください');
    }

    // 長さチェック
    if (groupName.trim().length > 50) {
      return ValidationResult.error('グループ名は50文字以内で入力してください');
    }

    // 重複チェック
    final trimmedName = groupName.trim();
    final duplicateGroup = existingGroups.firstWhere(
      (group) =>
          group.groupName.toLowerCase() == trimmedName.toLowerCase() &&
          group.groupId != excludeGroupId,
      orElse: () => const SharedGroup(groupName: '', groupId: ''),
    );

    if (duplicateGroup.groupName.isNotEmpty) {
      return ValidationResult.error('グループ名「$trimmedName」は既に使用されています');
    }

    return ValidationResult.valid();
  }

  // ================== メンバー重複チェック ==================

  /// メンバーのメールアドレス重複をチェック
  /// [email] チェック対象のメールアドレス
  /// [existingMembers] 既存のメンバーリスト
  /// [excludeMemberId] 除外するメンバーID（編集時に自分自身を除外）
  static ValidationResult validateMemberEmail(
      String email, List<SharedGroupMember> existingMembers,
      {String? excludeMemberId}) {
    // 空文字チェック
    if (email.trim().isEmpty) {
      return ValidationResult.error('メールアドレスを入力してください');
    }

    // メールアドレス形式チェック
    final emailRegex =
        RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(email.trim())) {
      return ValidationResult.error('正しいメールアドレス形式で入力してください');
    }

    // 重複チェック
    final trimmedEmail = email.trim().toLowerCase();
    final duplicateMember = existingMembers.firstWhere(
      (member) =>
          member.contact.toLowerCase() == trimmedEmail &&
          member.memberId != excludeMemberId,
      orElse: () => SharedGroupMember.create(
          name: '', contact: '', role: SharedGroupRole.member),
    );

    if (duplicateMember.contact.isNotEmpty) {
      return ValidationResult.duplicate(duplicateMember);
    }

    return ValidationResult.valid();
  }

  /// メンバー名の重複をチェック（同一グループ内）
  /// [name] チェック対象の名前
  /// [existingMembers] 既存のメンバーリスト
  /// [excludeMemberId] 除外するメンバーID（編集時に自分自身を除外）
  static ValidationResult validateMemberName(
      String name, List<SharedGroupMember> existingMembers,
      {String? excludeMemberId}) {
    // 空文字チェック
    if (name.trim().isEmpty) {
      return ValidationResult.error('名前を入力してください');
    }

    // 長さチェック
    if (name.trim().length > 30) {
      return ValidationResult.error('名前は30文字以内で入力してください');
    }

    // 重複チェック（名前は大小文字区別で同一グループ内では重複不可）
    final trimmedName = name.trim();
    final duplicateMember = existingMembers.firstWhere(
      (member) =>
          member.name == trimmedName && member.memberId != excludeMemberId,
      orElse: () => SharedGroupMember.create(
          name: '', contact: '', role: SharedGroupRole.member),
    );

    if (duplicateMember.name.isNotEmpty) {
      return ValidationResult.error('メンバー名「$trimmedName」は既に使用されています');
    }

    return ValidationResult.valid();
  }

  // ================== リスト名重複チェック ==================

  /// ショッピングリスト名の重複をチェック（同一グループ内）
  /// 注意: 現在のモデルではリスト名は groupId ベースで管理されているため、
  /// 将来的にリスト名が独立して管理される場合に備えた実装
  static ValidationResult validateListName(
      String listName, List<SharedList> existingLists, String groupId,
      {String? excludeListId}) {
    // 空文字チェック
    if (listName.trim().isEmpty) {
      return ValidationResult.error('リスト名を入力してください');
    }

    // 長さチェック
    if (listName.trim().length > 40) {
      return ValidationResult.error('リスト名は40文字以内で入力してください');
    }

    // 同一グループ内での重複チェック
    final trimmedName = listName.trim();
    final duplicateList = existingLists.firstWhere(
      (list) =>
          list.groupName.toLowerCase() == trimmedName.toLowerCase() &&
          list.groupId == groupId &&
          list.groupId != excludeListId,
      orElse: () => SharedList.create(
          ownerUid: '',
          groupId: '',
          groupName: '',
          listName: '',
          description: '',
          items: {}),
    );

    if (duplicateList.groupName.isNotEmpty) {
      return ValidationResult.error('リスト名「$listName」は既に使用されています');
    }

    return ValidationResult.valid();
  }

  // ================== アイテム名重複チェック ==================

  /// ショッピングアイテム名の重複をチェック（同一リスト内）
  /// [itemName] チェック対象のアイテム名
  /// [existingItems] 既存のアイテムリスト
  /// [memberId] アイテムを登録するメンバーID
  static ValidationResult validateItemName(
      String itemName, List<SharedItem> existingItems, String memberId,
      {String? excludeItemId}) {
    // 空文字チェック
    if (itemName.trim().isEmpty) {
      return ValidationResult.error('アイテム名を入力してください');
    }

    // 長さチェック
    if (itemName.trim().length > 30) {
      return ValidationResult.error('アイテム名は30文字以内で入力してください');
    }

    // 同一メンバーによる同名アイテムの重複チェック
    final trimmedName = itemName.trim();
    final duplicateItem = existingItems.firstWhere(
      (item) =>
          item.name.toLowerCase() == trimmedName.toLowerCase() &&
          item.memberId == memberId &&
          !item.isPurchased, // 未購入のアイテムのみチェック
      orElse: () => SharedItem.createNow(memberId: '', name: ''),
    );

    if (duplicateItem.name.isNotEmpty) {
      return ValidationResult.warning('「$trimmedName」は既にリストに追加されています');
    }

    return ValidationResult.valid();
  }

  // ================== 一般的なバリデーション ==================

  /// 文字列の一般的なバリデーション
  static ValidationResult validateText(String text, String fieldName,
      {int? maxLength, bool allowEmpty = false}) {
    if (!allowEmpty && text.trim().isEmpty) {
      return ValidationResult.error('$fieldNameを入力してください');
    }

    if (maxLength != null && text.trim().length > maxLength) {
      return ValidationResult.error('$fieldNameは$maxLength文字以内で入力してください');
    }

    return ValidationResult.valid();
  }

  /// 数値のバリデーション
  static ValidationResult validateNumber(String numberStr, String fieldName,
      {int? min, int? max}) {
    if (numberStr.trim().isEmpty) {
      return ValidationResult.error('$fieldNameを入力してください');
    }

    final number = int.tryParse(numberStr.trim());
    if (number == null) {
      return ValidationResult.error('$fieldNameは数値で入力してください');
    }

    if (min != null && number < min) {
      return ValidationResult.error('$fieldNameは$min以上で入力してください');
    }

    if (max != null && number > max) {
      return ValidationResult.error('$fieldNameは$max以下で入力してください');
    }

    return ValidationResult.valid();
  }
}

/// バリデーション結果を表すクラス
class ValidationResult {
  final bool isValid;
  final String? errorMessage;
  final SharedGroupMember? duplicateMember;
  final ValidationResultType type;

  const ValidationResult._({
    required this.isValid,
    this.errorMessage,
    this.duplicateMember,
    required this.type,
  });

  /// 有効な結果
  factory ValidationResult.valid() {
    return const ValidationResult._(
      isValid: true,
      type: ValidationResultType.valid,
    );
  }

  /// エラー結果
  factory ValidationResult.error(String message) {
    return ValidationResult._(
      isValid: false,
      errorMessage: message,
      type: ValidationResultType.error,
    );
  }

  /// 警告結果（継続可能）
  factory ValidationResult.warning(String message) {
    return ValidationResult._(
      isValid: true,
      errorMessage: message,
      type: ValidationResultType.warning,
    );
  }

  /// 重複検出結果
  factory ValidationResult.duplicate(SharedGroupMember member) {
    return ValidationResult._(
      isValid: false,
      duplicateMember: member,
      type: ValidationResultType.duplicate,
    );
  }

  bool get hasError => !isValid;
  bool get hasWarning => type == ValidationResultType.warning;
  bool get hasDuplicate => type == ValidationResultType.duplicate;
}

enum ValidationResultType {
  valid,
  error,
  warning,
  duplicate,
}
