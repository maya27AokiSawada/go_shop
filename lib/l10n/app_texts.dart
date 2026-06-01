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
  // 初期化・ローディング
  // ========================================
  String get initPreparingApp;
  String get initCheckingData;
  String get initPreparingUser;
  String get initReady;
  String get initErrorButContinue;
  String get initPreparingService;
  String get initSyncingGroups;

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
  String get defaultShoppingListName;

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
  String get resetPassword;
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
  // Initial setup widget
  String initialSetupDesc(String listName);
  String get createFirstGroup;
  String get joinGroupByQR;
  String get aboutGroups;
  String get aboutGroupsDesc;
  String get groupNameHint;
  String get createGroupFailed;
  String get deleteGroupWarning;
  String get leaveGroupWarning;
  String get deletingGroup;
  String get leavingGroup;
  String get leaveRequestSent;
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
  String get userChangedDetected;
  String get differentUserLoggedIn;
  String userPrevious(String user);
  String userCurrent(String user);
  String get whatToDoWithOldData;
  String get dataMigrationDescription;
  String get clearData;
  String get keepData;
  // Bottom nav / panel titles
  String get secretModeEnabled;
  String get groupDataRequiresLogin;
  String get newGroup;
  String signInToUseGroup(String groupName);
  String get noSharedList;
  String createNewSharedList(String listName);
  String duplicateListNameAlert(String name);
  String deleteListConfirm(String name);
  String get listCreateHint;
  String get listChangeNotification;
  String get listChangeNotificationDesc;
  String get listNotificationOn;
  String get listNotificationOff;
  String get viewNotificationHistory;
  String get listChangeNotificationSettings;
  String get shoppingListMode;
  String get todoShareMode;
  String modeChanged(String modeName);
  // User name panel
  String get userNameSetting;
  String get userNameSettingDesc;
  String get userNameLabel;
  String get userNameHint;
  String get userNameRequired;
  String get userNameTooShort;
  String get userNameTooLong;
  String get saving;
  String get saveUserName;
  String get userNameSaved;
  String saveFailed(Object e);
  String get currentPrefix;
  // News panel
  String get newsPanelTitle;
  String get newsCardTitle;
  String get newsLoading;
  // Tips
  String get tipsLabel;
  String get tipTapTitle;
  String get tipTapBody;
  String get tipDoubleTapTitle;
  String get tipDoubleTapBody;
  String get tipLongPressTitle;
  String get tipLongPressBody;
  String get tipGroupScreenTitle;
  String get tipGroupScreenBody;
  String get tipMemberScreenTitle;
  String get tipMemberScreenBody;

  // ========================================
  // 同期状態アイコン（AppBar）
  // ========================================
  String get syncStatusSynced;
  String get syncStatusSyncing;
  String get syncStatusOffline;
  String get syncStatusNotLoggedIn;
  String get networkOfflineStatus;
  String get checkingConnectionStatus;
  String get notSignedIn;

  // ========================================
  // ヘルプダイアログ
  // ========================================
  String get helpTitle;
  String get helpBasicUsage;
  String helpBasicUsagePoint(int n);
  String get helpGroupInvite;
  String helpGroupInvitePoint(int n);
  String get helpSyncIcons;
  String helpSyncIconPoint(int n);
  String get legalTitle;
  String get versionInfoTitle;
  String get versionLabel;
  String get buildNumberLabel;
  String get packageNameLabel;
  String get appFooterSubtitle;

  // ========================================
  // 招待受諾ウィジェット
  // ========================================
  String get inviteAcceptTitle;
  String get inviteAcceptDesc;
  String get invalidQRCodeMsg;
  String get cameraErrorPrefix;
  String get unknownGroup;
  String invitationPendingApproval(String groupName);

  // ========================================
  // ホームページ
  // ========================================
  String get privacyPoint1;
  String get privacyPoint2;
  String get privacyPoint3;
  String get privacyPoint4;
  String get forNewUsersDesc;
  String howToUsePoint(int n);

  // ========================================
  // 認証エラーメッセージ
  // ========================================
  String get signUpFailed;
  String get emailAlreadyInUse;
  String get weakPassword;
  String get signInFailed;
  String get userNotFoundSignIn;
  String get wrongEmailOrPassword;

  // ========================================
  // 共有リスト（アイテム表示）
  // ========================================
  String quantityDisplay(int quantity);
  String deadlineDisplay(String date);
  String intervalDisplay(int days);
  String itemDeletedName(String name);
  String itemDeleteFailed(String e);
  String itemDeleteConfirm(String name);

  // ========================================
  // アカウント削除（詳細テキスト）
  // ========================================
  String deleteAccountWarningBody(String listName);
  String finalConfirmationBody(String email);
  String get deletionCompleteBody;
  String deletionFailedBody(String e);

  // ========================================
  // グループリスト
  // ========================================
  String memberCount(int count);
  String ownerDisplay(String name);
  String syncErrorMessage(String error);

  // ========================================
  // 言語設定パネル
  // ========================================
  String get displayLanguageTitle;
  String get displayLanguageDesc;
  String get languageJa;
  String get languageChangedEn;
  String get languageChangedJa;

  // ========================================
  // QRスキャンオーバーレイ
  // ========================================
  String get qrCodeHereOverlay;

  // ========================================
  // アプリモード依存の表示名（l10n化）
  // ========================================
  /// shopping=true → '買い物リスト' / 'Shopping List'
  /// shopping=false → 'タスクリスト' / 'Task List'
  String sharedListNameForMode(bool isShopping);

  /// shopping=true → 'グループ' / 'Group'
  /// shopping=false → 'チーム' / 'Team'
  String groupNameForMode(bool isShopping);

  // ========================================
  // アイテム編集モーダル
  // ========================================
  String get itemNameHintMilk;
  String get intervalNone;
  String intervalDaysSuffix(int days);

  // ========================================
  // ホワイトボード設定パネル
  // ========================================
  String get whiteboardSettingsTitle;
  String get customColorSettingsTitle;
  String get customColorSettingsDesc;
  String colorSlot(int n);
  String get errorWithPrefix;

  // ========================================
  // フィードバックセクション
  // ========================================
  String get feedbackSectionTitle;
  String get feedbackSectionDesc;
  String get feedbackSectionSubDesc;
  String get feedbackButton;
  String get feedbackThanks;
  String get formOpenFailed;

  // ========================================
  // 設定ページ
  // ========================================
  String get settingsPagePlaceholder;
  String get goShopSettingsLabel;
  String get checkingAuthStatus;
  String get errorOccurredTitle;

  // ========================================
  // アプリモード切り替えパネル
  // ========================================
  String get appModeTitle;
  String get appModeDesc;

  // ========================================
  // 認証状態ヘルパー
  // ========================================
  String featureRequiresSignUp(String feature);
  String get signUpRequiredMsg;
  String get welcomeToGoShop;
  String get welcomeSubtitle;
  String get availableFeatures;
  String personalListCreate(String listType);
  String get signUpPromptBody;

  // ========================================
  // 通知履歴ページ
  // ========================================
  String get weeksAgo;
  String get monthsAgo;
  String get yearsAgo;
  String get timeUnknown;
  String get unread;
  String get tooltipMarkRead;
  String get tooltipDeleteRead;
  String get tooltipReload;
  String get firestoreIndexRequired;
  String get firestoreIndexDesc;
  String get errorWithDetail;

  // ========================================
  // エラー履歴ページ
  // ========================================
  String get unknownOperation;
  String get noErrorDetailMsg;
  String get permissionErrorLabel;
  String get networkErrorLabel;
  String get syncErrorLabel;
  String get validationErrorLabel;
  String get operationErrorLabel;
  String get unknownErrorLabel;
  String get operationLabel;
  String get messageLabel;
  String get occurredAtLabel;
  String get contextLabel;
  String get stackTraceLabel;

  // ========================================
  // QRコード表示・スキャン画面
  // ========================================
  String get qrScanInstruction;
  String get qrManualInputHint;
  String get inviteGenFailed;
  String get qrScanDialogTitle;
  String get qrScanDialogContent;
  String get qrScanButton;

  // ========================================
  // グループ招待ページ
  // ========================================
  String get inviteType;
  String get inviteByQRTitle;
  String get scanQRToJoinDesc;
  String maxInviteCount(int n);
  String get howToInviteTitle;
  String get howToInviteDesc;

  // ========================================
  // QRスキャン画面追加
  // ========================================
  String get checkingInviteCode;
  String get tooltipManualInput;

  // ========================================
  // 通知メッセージ（メタデータから再構築）
  // ========================================
  String notifListCreated(String name, String list);
  String notifListDeleted(String name, String list);
  String notifRenamed(String name, String oldName, String newName);
  String notifMemberJoined(String name, String group);
  String notifMembershipApproved(String group);
  String notifGroupDeleted(String name, String group);
  String notifMemberLeft(String name, String group);
  String notifYouLeft(String group);
  String notifItemAdded(String name, String item, String list);
  String notifItemRemoved(String name, String item, String list);
  String notifItemPurchased(String name, String item, String list);
  String notifWhiteboardUpdated(String name);
  String notifWhiteboardEditStarted(String name);
  String notifWhiteboardEditEnded(String name);

  // ========================================
  // エラーログ operation名
  // ========================================
  String get opSignIn;
  String get opCreateAccount;
  String get opSaveUserName;
  String get opResetPassword;
  String get opSignUp;
  String get opAddMember;
  String get opUpdateGroupName;
  String get opSaveWhiteboard;
  String get opClearWhiteboard;
  String get opUpdatePurchaseStatus;
  String get opUpdateGroupMember;
  String get opSendNotification;
  String get opLoadUserName;
  String get opUpdateAllGroupUserNames;
  String get opGetGroupUserName;
  String get opGetGroupMembers;
  String get opSignOutClear;
  String get opGetFirestoreUserName;
  String get opSaveFirestoreUserName;
  String get opDeleteFirestoreUserName;
  String get opCreateUserProfile;
  String get opSaveBillingType;
  String get opSearchInvitableGroups;
  String get opSendInvite;
  String get opAcceptInvitation;
  String get opSearchPendingInvitations;
  String get opRecordInvitation;
  String get opGetPendingInvitations;
  String get opMarkInvitationProcessed;
  String get opDeleteInvitation;
  String get opCreateQrInvite;
  String get opDecodeQrCode;
  String get opGetQrInviteDetails;
  String get opAcceptQrInvite;

  // ========================================
  // メンバーロール変更ダイアログ
  // ========================================
  String currentRoleLabel(String role);
  String get promoteToManagerDesc;
  String get demoteToMemberDesc;
  String get promoteToManager;
  String get demoteToMemberAction;
  String promotedToManager(String name);
  String demotedToMemberMsg(String name);
  String get doubleTapWhiteboardHint;
  String get doubleTapToOpen;
  String get doubleTapToView;

  // ========================================
  // グループメンバー管理画面
  // ========================================
  String memberAddedMsg(String name);
  String get memberAddFailed;
  String get createAccountFailed;
  String groupNameChangedMsg(String name);
  String get groupNameUpdateFailed;
  String get inviteFromPlusButton;
}
