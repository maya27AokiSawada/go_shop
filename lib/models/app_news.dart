/// Firestoreニュースの表示モデル
class AppNews {
  final String title;
  final String content;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isActive;
  final String? imageUrl;
  final String? actionUrl;
  final String? actionText;

  const AppNews({
    required this.title,
    required this.content,
    required this.createdAt,
    this.updatedAt,
    this.isActive = true,
    this.imageUrl,
    this.actionUrl,
    this.actionText,
  });

  factory AppNews.fromMap(Map<String, dynamic> map) {
    return AppNews(
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(
          (map['createdAt'] as num?)?.toInt() ?? 0),
      updatedAt: map['updatedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              (map['updatedAt'] as num).toInt())
          : null,
      isActive: map['isActive'] ?? true,
      imageUrl: map['imageUrl'],
      actionUrl: map['actionUrl'],
      actionText: map['actionText'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'content': content,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt?.millisecondsSinceEpoch,
      'isActive': isActive,
      'imageUrl': imageUrl,
      'actionUrl': actionUrl,
      'actionText': actionText,
    };
  }

  /// 空のニュース（デフォルト表示用）
  static final AppNews empty = AppNews(
    title: 'GoShoppingへようこそ',
    content: 'GoShoppingは家族・グループ向けの買い物リスト共有アプリです。便利な機能をお楽しみください！',
    createdAt: DateTime.now(),
  );

  AppNews copyWith({
    String? title,
    String? content,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    String? imageUrl,
    String? actionUrl,
    String? actionText,
  }) {
    return AppNews(
      title: title ?? this.title,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      imageUrl: imageUrl ?? this.imageUrl,
      actionUrl: actionUrl ?? this.actionUrl,
      actionText: actionText ?? this.actionText,
    );
  }
}
