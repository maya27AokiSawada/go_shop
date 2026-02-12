/// アプリ内の全UIテキストを定義する抽象クラス
///
/// 各言語は、このクラスを継承して実装します。
/// - 日本語: AppTextsJa
/// - 英語: AppTextsEn (未実装)
/// - 中国語: AppTextsZh (未実装)
/// - スペイン語: AppTextsEs (未実装)
abstract class AppTexts {
  // ========================================
  // 共通
  // ========================================
  String get appName;
  String get ok;
  String get cancel;
  String get save;
  String get delete;
  String get edit;
  String get close;
  String get back;
  String get next;
  String get done;
  String get loading;
  String get error;
  String get retry;
  String get confirm;
  String get yes;
  String get no;

  // ========================================
  // 認証
  // ========================================
  String get signIn;
  String get signUp;
  String get signOut;
  String get email;
  String get password;
  String get displayName;
  String get createAccount;
  String get alreadyHaveAccount;
  String get dontHaveAccount;
  String get forgotPassword;
  String get emailRequired;
  String get passwordRequired;
  String get displayNameRequired;
  String get invalidEmail;
  String get passwordTooShort;

  // ========================================
  // グループ
  // ========================================
  String get group;
  String get groups;
  String get createGroup;
  String get editGroup;
  String get deleteGroup;
  String get groupName;
  String get groupMembers;
  String get addMember;
  String get removeMember;
  String get owner;
  String get member;
  String get leaveGroup;
  String get selectGroup;
  String get noGroups;
  String get groupCreated;
  String get groupDeleted;
  String get groupUpdated;
  String get groupNameRequired;
  String get duplicateGroupName;
  String get confirmDeleteGroup;

  // ========================================
  // リスト
  // ========================================
  String get list;
  String get lists;
  String get createList;
  String get editList;
  String get deleteList;
  String get listName;
  String get sharedList;
  String get selectList;
  String get noLists;
  String get listCreated;
  String get listDeleted;
  String get listUpdated;
  String get listNameRequired;
  String get duplicateListName;
  String get confirmDeleteList;

  // ========================================
  // アイテム
  // ========================================
  String get item;
  String get items;
  String get addItem;
  String get editItem;
  String get deleteItem;
  String get itemName;
  String get quantity;
  String get purchased;
  String get notPurchased;
  String get noItems;
  String get itemAdded;
  String get itemDeleted;
  String get itemUpdated;
  String get itemNameRequired;
  String get confirmDeleteItem;
  String get markAsPurchased;
  String get markAsNotPurchased;

  // ========================================
  // QR招待
  // ========================================
  String get invitation;
  String get inviteMembers;
  String get scanQRCode;
  String get generateQRCode;
  String get acceptInvitation;
  String get invitationAccepted;
  String get invitationExpired;
  String get invitationInvalid;
  String get alreadyMember;
  String get scanningQRCode;
  String get qrCodeGenerated;

  // ========================================
  // 設定
  // ========================================
  String get settings;
  String get profile;
  String get notifications;
  String get language;
  String get theme;
  String get about;
  String get version;
  String get privacyPolicy;
  String get termsOfService;
  String get logout;
  String get deleteAccount;
  String get confirmDeleteAccount;

  // ========================================
  // 通知
  // ========================================
  String get notification;
  String get notificationHistory;
  String get markAsRead;
  String get deleteNotification;
  String get noNotifications;
  String get notificationSettings;
  String get enableNotifications;

  // ========================================
  // ホワイトボード
  // ========================================
  String get whiteboard;
  String get whiteboards;
  String get createWhiteboard;
  String get editWhiteboard;
  String get deleteWhiteboard;
  String get whiteboardName;
  String get drawingMode;
  String get scrollMode;
  String get penColor;
  String get penWidth;
  String get eraseAll;
  String get undo;
  String get redo;
  String get zoom;

  // ========================================
  // 同期・データ管理
  // ========================================
  String get sync;
  String get syncing;
  String get syncCompleted;
  String get syncFailed;
  String get manualSync;
  String get lastSyncTime;
  String get offlineMode;
  String get onlineMode;
  String get dataMaintenance;
  String get cleanupData;

  // ========================================
  // エラーメッセージ
  // ========================================
  String get networkError;
  String get serverError;
  String get unknownError;
  String get permissionDenied;
  String get authenticationRequired;
  String get operationFailed;
  String get tryAgainLater;

  // ========================================
  // 日時・単位
  // ========================================
  String get today;
  String get yesterday;
  String get daysAgo;
  String get hoursAgo;
  String get minutesAgo;
  String get justNow;
  String get pieces;
  String get person;
  String get people;

  // ========================================
  // アクション確認
  // ========================================
  String get areYouSure;
  String get cannotBeUndone;
  String get continueAction;
  String get cancelAction;
}
