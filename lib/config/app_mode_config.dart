// lib/config/app_mode_config.dart

/// アプリケーションモード
enum AppMode {
  shopping, // 買い物リストモード
  todo, // TODOリストモード
}

/// アプリモード別の用語定義
class AppModeConfig {
  final AppMode mode;

  const AppModeConfig(this.mode);

  // グループ関連
  String get groupName {
    switch (mode) {
      case AppMode.shopping:
        return 'グループ';
      case AppMode.todo:
        return 'チーム';
    }
  }

  String get groupNamePlural {
    switch (mode) {
      case AppMode.shopping:
        return 'グループ';
      case AppMode.todo:
        return 'チーム';
    }
  }

  String get createGroup {
    switch (mode) {
      case AppMode.shopping:
        return 'グループ作成';
      case AppMode.todo:
        return 'チーム作成';
    }
  }

  String get selectGroup {
    switch (mode) {
      case AppMode.shopping:
        return 'グループ選択';
      case AppMode.todo:
        return 'チーム選択';
    }
  }

  String get groupMembers {
    switch (mode) {
      case AppMode.shopping:
        return 'メンバー';
      case AppMode.todo:
        return 'メンバー';
    }
  }

  String get defaultGroupSuffix {
    switch (mode) {
      case AppMode.shopping:
        return 'グループ';
      case AppMode.todo:
        return 'のタスク';
    }
  }

  // リスト関連
  String get listName {
    switch (mode) {
      case AppMode.shopping:
        return 'リスト';
      case AppMode.todo:
        return 'プロジェクト';
    }
  }

  String get listNamePlural {
    switch (mode) {
      case AppMode.shopping:
        return 'リスト';
      case AppMode.todo:
        return 'プロジェクト';
    }
  }

  String get createList {
    switch (mode) {
      case AppMode.shopping:
        return 'リスト作成';
      case AppMode.todo:
        return 'プロジェクト作成';
    }
  }

  String get selectList {
    switch (mode) {
      case AppMode.shopping:
        return 'リスト選択';
      case AppMode.todo:
        return 'プロジェクト選択';
    }
  }

  String get shoppingList {
    switch (mode) {
      case AppMode.shopping:
        return '買い物リスト';
      case AppMode.todo:
        return 'タスクリスト';
    }
  }

  // アイテム関連
  String get itemName {
    switch (mode) {
      case AppMode.shopping:
        return 'アイテム';
      case AppMode.todo:
        return 'タスク';
    }
  }

  String get itemNamePlural {
    switch (mode) {
      case AppMode.shopping:
        return 'アイテム';
      case AppMode.todo:
        return 'タスク';
    }
  }

  String get addItem {
    switch (mode) {
      case AppMode.shopping:
        return 'アイテム追加';
      case AppMode.todo:
        return 'タスク追加';
    }
  }

  String get itemPlaceholder {
    switch (mode) {
      case AppMode.shopping:
        return '商品名を入力';
      case AppMode.todo:
        return 'タスク名を入力';
    }
  }

  String get itemCompleted {
    switch (mode) {
      case AppMode.shopping:
        return '購入済み';
      case AppMode.todo:
        return '完了';
    }
  }

  String get itemPending {
    switch (mode) {
      case AppMode.shopping:
        return '未購入';
      case AppMode.todo:
        return '未完了';
    }
  }

  // アクション関連
  String get markAsCompleted {
    switch (mode) {
      case AppMode.shopping:
        return '購入済みにする';
      case AppMode.todo:
        return '完了にする';
    }
  }

  String get markAsPending {
    switch (mode) {
      case AppMode.shopping:
        return '未購入に戻す';
      case AppMode.todo:
        return '未完了に戻す';
    }
  }

  // 画面タイトル
  String get homeTitle {
    switch (mode) {
      case AppMode.shopping:
        return 'Go Shop';
      case AppMode.todo:
        return 'Go Task';
    }
  }

  String get groupPageTitle {
    switch (mode) {
      case AppMode.shopping:
        return 'グループ管理';
      case AppMode.todo:
        return 'チーム管理';
    }
  }

  String get listPageTitle {
    switch (mode) {
      case AppMode.shopping:
        return '買い物リスト';
      case AppMode.todo:
        return 'タスク管理';
    }
  }

  // メッセージ
  String get emptyListMessage {
    switch (mode) {
      case AppMode.shopping:
        return 'アイテムがありません\n「+」ボタンで商品を追加';
      case AppMode.todo:
        return 'タスクがありません\n「+」ボタンでタスクを追加';
    }
  }

  String get emptyGroupMessage {
    switch (mode) {
      case AppMode.shopping:
        return 'グループがありません\n「+」ボタンでグループを作成';
      case AppMode.todo:
        return 'チームがありません\n「+」ボタンでチームを作成';
    }
  }

  String itemAddedMessage(String itemName) {
    switch (mode) {
      case AppMode.shopping:
        return '$itemName を追加しました';
      case AppMode.todo:
        return 'タスク「$itemName」を追加しました';
    }
  }

  String itemCompletedMessage(String itemName) {
    switch (mode) {
      case AppMode.shopping:
        return '$itemName を購入済みにしました';
      case AppMode.todo:
        return 'タスク「$itemName」を完了しました';
    }
  }

  String itemDeletedMessage(String itemName) {
    switch (mode) {
      case AppMode.shopping:
        return '$itemName を削除しました';
      case AppMode.todo:
        return 'タスク「$itemName」を削除しました';
    }
  }

  // 詳細フィールド
  String get quantityLabel {
    switch (mode) {
      case AppMode.shopping:
        return '数量';
      case AppMode.todo:
        return '見積時間';
    }
  }

  String get categoryLabel {
    switch (mode) {
      case AppMode.shopping:
        return 'カテゴリ';
      case AppMode.todo:
        return 'カテゴリ';
    }
  }

  String get memoLabel {
    switch (mode) {
      case AppMode.shopping:
        return 'メモ';
      case AppMode.todo:
        return '詳細';
    }
  }

  String get assigneeLabel {
    switch (mode) {
      case AppMode.shopping:
        return '担当者';
      case AppMode.todo:
        return '担当者';
    }
  }

  String get priorityLabel {
    switch (mode) {
      case AppMode.shopping:
        return '優先度';
      case AppMode.todo:
        return '優先度';
    }
  }

  String get dueDateLabel {
    switch (mode) {
      case AppMode.shopping:
        return '購入期限';
      case AppMode.todo:
        return '期限';
    }
  }
}

/// グローバルなアプリモード設定
class AppModeSettings {
  static AppMode _currentMode = AppMode.shopping;

  static AppMode get currentMode => _currentMode;

  static AppModeConfig get config => AppModeConfig(_currentMode);

  /// アプリモードを変更
  static void setMode(AppMode mode) {
    _currentMode = mode;
  }

  /// 設定ファイルからモードを読み込み
  static Future<void> loadMode() async {
    // TODO: SharedPreferencesから読み込み
    // final prefs = await SharedPreferences.getInstance();
    // final modeIndex = prefs.getInt('app_mode') ?? 0;
    // _currentMode = AppMode.values[modeIndex];
  }

  /// 設定ファイルにモードを保存
  static Future<void> saveMode(AppMode mode) async {
    _currentMode = mode;
    // TODO: SharedPreferencesに保存
    // final prefs = await SharedPreferences.getInstance();
    // await prefs.setInt('app_mode', mode.index);
  }
}
