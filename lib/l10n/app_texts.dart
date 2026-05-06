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

  // ========================================
  // ホーム・リスト（追加）
  // ========================================
  String get sharedListAppSubtitle;
  String get switchToSignIn;
  String get switchToCreateAccount;
  String get rememberEmail;
  String get forNewUsers;
  String get howToUse;
  String get noTasks;
  String get noShoppingItems;
  String get privacyAbout;

  // ========================================
  // アクション（追加）
  // ========================================
  String get create;
  String get update;
  String get add;
  String get leave;

  // ========================================
  // グループ（追加）
  // ========================================
  String get current;
  String get noCurrentGroup;
  String get loadingGroups;
  String get preparingGroup;
  String get groupLoadFailed;
  String get createFirstGroupHint;
  String get createGroupHint;
  String get deleteGroupWarning;
  String get leaveGroupWarning;
  String get deletingGroup;
  String get leavingGroup;
  String get copyMembersFrom;
  String get selectGroupHint;
  String get newGroupNoMembers;
  String get selectMembersToCopy;
  String get noMembersInGroup;
  String get selectGroupToCopyMembers;
  String get creatingGroup;
  String get manager;
  String get partner;

  // ========================================
  // リスト・アイテム（追加）
  // ========================================
  String get selectGroupFirst;
  String get noGroupSelected;
  String get descriptionOptional;
  String get editTask;
  String get addTask;
  String get addShoppingItem;
  String get productName;
  String get purchaseIntervalOptional;
  String get perDay;
  String get perWeek;
  String get perMonth;
  String get noRepeatPurchase;
  String get selectDeadlineOptional;
  String get quantityRequired;
  String get quantityInvalid;
  String get deadlineMustBeFuture;

  // ========================================
  // UI管理モード（シングル / マルチ）
  // ========================================
  String get managementMode;
  String get singleModeLabel;
  String get multiModeLabel;
  String get singleModeDesc;
  String get multiModeDesc;
  String get switchToSingleMode;
  String get switchToSingleModeBody;
  String get switchedToSingleMode;
  String get switchedToMultiMode;
  String get selectGroupBeforeSwitch;
  String get selectListBeforeSwitch;
  String get doSwitch;

  // ========================================
  // グループメンバー管理
  // ========================================
  String get groupInfo;
  String get inviteOnlyForAdmins;
  String get errorOccurred;
  String get copyGroupTooltip;
  String get inviteByQR;
  String get inviteByQRDesc;
  String get inviteByEmail;
  String get inviteByEmailDesc;
  String get addMemberManually;
  String get addMemberManuallyDesc;
  String get enterEmailToInvite;
  String get sendInvitation;
  String get emailInviteUnavailable;
  String get enterGroupName;

  // ========================================
  // アカウント削除
  // ========================================
  String get reauthRequired;
  String get reauthDescription;
  String get finalConfirmation;
  String get deleteCompletely;
  String get deletingAccount;
  String get deletingAccountProgress;
  String get authError;
  String get wrongPassword;
  String get authFailed;

  // ========================================
  // QR招待
  // ========================================
  String get qrCodeInvite;
  String get copyData;
  String get share;
  String get processingInvitation;
  String get cannotScanOwnCode;
  String get groupInvitation;
  String get accept;
  String get signInRequired;
  String get signInRequiredForInvite;
  String get invitationSavedForLater;

  // ========================================
  // その他UIラベル
  // ========================================
  String get memberListLabel;
  String get selectInviteMethod;
  String get noMembers;
  String get inviteMemberHint;
  String get recommendPortrait;

  // ========================================
  // 共通メニュー / AppBar
  // ========================================
  String get errorHistory;
  String get help;
  String get versionInfo;

  // ========================================
  // 認証パネル
  // ========================================
  String get loginOrRegister;
  String get login;
  String get register;
  String get saveEmail;
  String get enterUserName;

  // ========================================
  // アカウント削除（追加）
  // ========================================
  String get deletionComplete;
  String get deletionFailed;
  String get deleteAccountAndData;
  String get cannotUndoWarning;

  // ========================================
  // ボトムナビ / ホーム
  // ========================================
  String get home;
  String get signedOut;
  String get signOutError;
  String get displayNameHint;
  String get displayNameHelper;
  String get passwordHint;
  String welcomeUser(String name);

  // ========================================
  // 同期管理ウィジェット
  // ========================================
  String get syncManagement;
  String get syncingFirestore;
  String get clearCache;
  String get clearCacheTitle;
  String get clearCacheConfirm;
  String get clearCacheSuccess;
  String get debugLabel;
  String get onlineStatus;
  String get connected;
  String get offline;
  String get localModeNoSync;

  // ========================================
  // 認証・アカウント（追加）
  // ========================================
  String get appDescription;
  String get mainFeatures;
  String get featureGroupSharing;
  String get featureRealtimeSync;
  String get featureOfflineSupport;
  String get featureMemberManagement;
  String get accountNotFound;
  String get createNew;
  String get signUpRequiredTitle;
  String get signUpToUseAll;
  String get later;
  String get scanQRRequiresSignUp;
  String get inviteRequiresSignUp;
  String get inviteMemberLabel;
  String get groupListSharing;
  String get qrInviteFeature;
  String get accountCreated;
  String get accountCreationFailed;
  String accountNotFoundBody(String email);

  // ========================================
  // 招待・メンバー管理（追加）
  // ========================================
  String get generateInviteCode;
  String get deleteInviteCode;
  String get deleteInviteCodeConfirm;
  String get inviteManagement;
  String get activeInviteCodes;
  String get noActiveInvites;
  String get copy;
  String get selectFromPool;
  String get newMember;
  String get noMembersInPool;
  String get promoteToAdmin;
  String get demoteToMember;
  String get promote;
  String get demote;
  String get invitationResults;
  String get errorDetails;
  String promotedToAdmin(String name);
  String demotedToMember(String name);
  String sendInvitationsCount(int count);

  // ========================================
  // QR・スキャン（追加）
  // ========================================
  String get qrCodeReader;
  String get manualInput;
  String get enter8CharCode;
  String get invalidQRFormat;
  String get checkCameraPermission;
  String get individualGroupInvite;
  String get individualGroupInviteDesc;
  String get friendInvite;
  String get friendInviteDesc;
  String get enterInviteCode;
  String inviteCodeRecognized(String code);
  String inviteToGroup(String groupName);

  // ========================================
  // 招待モニター（追加）
  // ========================================
  String get checkingInvitations;
  String get processAll;
  String get rejectInvitation;
  String get reject;
  String get invitationStats;
  String get joinGroup;
  String get joinGroupQuestion;
  String get join;
  String joinAsRole(String role);
  String approvedJoin(String name);
  String rejectConfirm(String name);
  String rejectedInvite(String name);
  String alreadyJoinedGroup(String name);

  // ========================================
  // エラー・通知履歴（追加）
  // ========================================
  String get noErrorHistory;
  String get markReadAndClose;
  String get markedAsRead;
  String get deleteReadErrors;
  String get deleteReadErrorsConfirm;
  String get noReadNotifications;
  String markedReadFailed(String e);
  String deletedErrorLogs(int count);
  String deleteErrorLogFailed(String e);
  String deletedReadNotifications(int count);

  // ========================================
  // ニュース・フィードバック（追加）
  // ========================================
  String get thankYou;
  String get surveyAction;
  String get remindLater;
  String get premiumPlan;
  String get remindTomorrow;
  String get cannotOpenLink;
  String get invalidLink;
  String get thanks;
  String cannotOpenForm(String e);

  // ========================================
  // プレミアム・広告（追加）
  // ========================================
  String get trialStarted;
  String get startTrial;
  String get resetToFree;
  String get selectPlan;
  String get upgradedToAnnualPlan;
  String get upgradedTo3YearPlan;
  String get groupManagement;
  String get noGroupData;
  String get featureInProgress;
  String get addGroupInProgress;
  String get toPremium;
  String get premiumBenefits;
  String get benefitNoAds;
  String get benefitPremiumSupport;
  String get benefitEarlyAccess;
  String get pricePlan;
}
