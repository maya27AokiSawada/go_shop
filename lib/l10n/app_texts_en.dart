import 'app_texts.dart';

/// English text implementation
class AppTextsEn extends AppTexts {
  // ========================================
  // Common
  // ========================================
  @override
  String get appName => 'GoShopping';

  @override
  String get ok => 'OK';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get delete => 'Delete';

  @override
  String get edit => 'Edit';

  @override
  String get close => 'Close';

  @override
  String get back => 'Back';

  @override
  String get next => 'Next';

  @override
  String get done => 'Done';

  @override
  String get loading => 'Loading...';

  @override
  String get error => 'Error';

  @override
  String get retry => 'Retry';

  @override
  String get confirm => 'Confirm';

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  // ========================================
  // Authentication
  // ========================================
  @override
  String get signIn => 'Sign In';

  @override
  String get signUp => 'Sign Up';

  @override
  String get signOut => 'Sign Out';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get displayName => 'Display Name';

  @override
  String get createAccount => 'Create Account';

  @override
  String get alreadyHaveAccount => 'Already have an account?';

  @override
  String get dontHaveAccount => "Don't have an account?";

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get emailRequired => 'Please enter your email address';

  @override
  String get passwordRequired => 'Please enter your password';

  @override
  String get displayNameRequired => 'Please enter your display name';

  @override
  String get invalidEmail => 'Please enter a valid email address';

  @override
  String get passwordTooShort => 'Password must be at least 6 characters';

  // ========================================
  // Group
  // ========================================
  @override
  String get group => 'Group';

  @override
  String get groups => 'Groups';

  @override
  String get createGroup => 'Create Group';

  @override
  String get editGroup => 'Edit Group';

  @override
  String get deleteGroup => 'Delete Group';

  @override
  String get groupName => 'Group Name';

  @override
  String get groupMembers => 'Members';

  @override
  String get addMember => 'Add Member';

  @override
  String get removeMember => 'Remove Member';

  @override
  String get owner => 'Owner';

  @override
  String get member => 'Member';

  @override
  String get leaveGroup => 'Leave Group';

  @override
  String get selectGroup => 'Select Group';

  @override
  String get noGroups => 'No groups';

  @override
  String get groupCreated => 'Group created';

  @override
  String get groupDeleted => 'Group deleted';

  @override
  String get groupUpdated => 'Group updated';

  @override
  String get groupNameRequired => 'Please enter a group name';

  @override
  String get duplicateGroupName => 'That group name is already in use';

  @override
  String get confirmDeleteGroup =>
      'Are you sure you want to delete this group?';

  // ========================================
  // List
  // ========================================
  @override
  String get list => 'List';

  @override
  String get lists => 'Lists';

  @override
  String get createList => 'Create List';

  @override
  String get editList => 'Edit List';

  @override
  String get deleteList => 'Delete List';

  @override
  String get listName => 'List Name';

  @override
  String get sharedList => 'Shared List';

  @override
  String get selectList => 'Select List';

  @override
  String get noLists => 'No lists';

  @override
  String get listCreated => 'List created';

  @override
  String get listDeleted => 'List deleted';

  @override
  String get listUpdated => 'List updated';

  @override
  String get listNameRequired => 'Please enter a list name';

  @override
  String get duplicateListName => 'That list name is already in use';

  @override
  String get confirmDeleteList => 'Are you sure you want to delete this list?';

  // ========================================
  // Item
  // ========================================
  @override
  String get item => 'Item';

  @override
  String get items => 'Items';

  @override
  String get addItem => 'Add Item';

  @override
  String get editItem => 'Edit Item';

  @override
  String get deleteItem => 'Delete Item';

  @override
  String get itemName => 'Item Name';

  @override
  String get quantity => 'Quantity';

  @override
  String get purchased => 'Purchased';

  @override
  String get notPurchased => 'Not Purchased';

  @override
  String get noItems => 'No items';

  @override
  String get itemAdded => 'Item added';

  @override
  String get itemDeleted => 'Item deleted';

  @override
  String get itemUpdated => 'Item updated';

  @override
  String get itemNameRequired => 'Please enter an item name';

  @override
  String get confirmDeleteItem => 'Are you sure you want to delete this item?';

  @override
  String get markAsPurchased => 'Mark as purchased';

  @override
  String get markAsNotPurchased => 'Mark as not purchased';

  // ========================================
  // QR Invitation
  // ========================================
  @override
  String get invitation => 'Invitation';

  @override
  String get inviteMembers => 'Invite Members';

  @override
  String get scanQRCode => 'Scan QR Code';

  @override
  String get generateQRCode => 'Generate QR Code';

  @override
  String get acceptInvitation => 'Accept Invitation';

  @override
  String get invitationAccepted => 'Invitation accepted';

  @override
  String get invitationExpired => 'Invitation has expired';

  @override
  String get invitationInvalid => 'Invalid invitation';

  @override
  String get alreadyMember => 'Already a member';

  @override
  String get scanningQRCode => 'Scanning QR code...';

  @override
  String get qrCodeGenerated => 'QR code generated';

  // ========================================
  // Settings
  // ========================================
  @override
  String get settings => 'Settings';

  @override
  String get profile => 'Profile';

  @override
  String get notifications => 'Notifications';

  @override
  String get language => 'Language';

  @override
  String get theme => 'Theme';

  @override
  String get about => 'About';

  @override
  String get version => 'Version';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get termsOfService => 'Terms of Service';

  @override
  String get logout => 'Logout';

  @override
  String get deleteAccount => 'Delete Account';

  @override
  String get confirmDeleteAccount =>
      'Are you sure you want to delete your account? This action cannot be undone.';

  // ========================================
  // Notifications
  // ========================================
  @override
  String get notification => 'Notification';

  @override
  String get notificationHistory => 'Notification History';

  @override
  String get markAsRead => 'Mark as read';

  @override
  String get deleteNotification => 'Delete notification';

  @override
  String get noNotifications => 'No notifications';

  @override
  String get notificationSettings => 'Notification Settings';

  @override
  String get enableNotifications => 'Enable Notifications';

  // ========================================
  // Whiteboard
  // ========================================
  @override
  String get whiteboard => 'Whiteboard';

  @override
  String get whiteboards => 'Whiteboards';

  @override
  String get createWhiteboard => 'Create Whiteboard';

  @override
  String get editWhiteboard => 'Edit Whiteboard';

  @override
  String get deleteWhiteboard => 'Delete Whiteboard';

  @override
  String get whiteboardName => 'Whiteboard Name';

  @override
  String get drawingMode => 'Drawing Mode';

  @override
  String get scrollMode => 'Scroll Mode';

  @override
  String get penColor => 'Pen Color';

  @override
  String get penWidth => 'Pen Width';

  @override
  String get eraseAll => 'Erase All';

  @override
  String get undo => 'Undo';

  @override
  String get redo => 'Redo';

  @override
  String get zoom => 'Zoom';

  // ========================================
  // Sync / Data Management
  // ========================================
  @override
  String get sync => 'Sync';

  @override
  String get syncing => 'Syncing...';

  @override
  String get syncCompleted => 'Sync completed';

  @override
  String get syncFailed => 'Sync failed';

  @override
  String get manualSync => 'Manual Sync';

  @override
  String get lastSyncTime => 'Last synced';

  @override
  String get offlineMode => 'Offline Mode';

  @override
  String get onlineMode => 'Online Mode';

  @override
  String get dataMaintenance => 'Data Maintenance';

  @override
  String get cleanupData => 'Clean Up Data';

  // ========================================
  // Error Messages
  // ========================================
  @override
  String get networkError => 'A network error occurred';

  @override
  String get serverError => 'A server error occurred';

  @override
  String get unknownError => 'An unknown error occurred';

  @override
  String get permissionDenied => 'Permission denied';

  @override
  String get authenticationRequired => 'Authentication required';

  @override
  String get operationFailed => 'Operation failed';

  @override
  String get tryAgainLater => 'Please try again later';

  // ========================================
  // Date / Units
  // ========================================
  @override
  String get today => 'Today';

  @override
  String get yesterday => 'Yesterday';

  @override
  String get daysAgo => 'days ago';

  @override
  String get hoursAgo => 'hours ago';

  @override
  String get minutesAgo => 'minutes ago';

  @override
  String get justNow => 'Just now';

  @override
  String get pieces => '';

  @override
  String get person => 'person';

  @override
  String get people => 'people';

  // ========================================
  // Action Confirmation
  // ========================================
  @override
  String get areYouSure => 'Are you sure?';

  @override
  String get cannotBeUndone => 'This action cannot be undone';

  @override
  String get continueAction => 'Continue';

  @override
  String get cancelAction => 'Cancel';

  @override
  String get sharedListAppSubtitle => 'Shared List App';

  @override
  String get switchToSignIn => 'Switch to Sign In';

  @override
  String get switchToCreateAccount => 'Switch to Create Account';

  @override
  String get rememberEmail => 'Remember email';

  @override
  String get forNewUsers => 'For new users';

  @override
  String get howToUse => 'How to use';

  @override
  String get noTasks => 'No tasks';

  @override
  String get noShoppingItems => 'No shopping items';

  @override
  String get privacyAbout => 'About Privacy';

  @override
  String get create => 'Create';
  @override
  String get update => 'Update';
  @override
  String get add => 'Add';
  @override
  String get leave => 'Leave';

  @override
  String get current => 'Current';
  @override
  String get noCurrentGroup => 'No group selected';
  @override
  String get loadingGroups => 'Loading groups...';
  @override
  String get preparingGroup => 'Preparing group...';
  @override
  String get groupLoadFailed => 'Failed to load groups';
  @override
  String get createFirstGroupHint =>
      'Create your first group or\nscan a QR code to join';
  @override
  String get createGroupHint => 'Tap the + button to create a group';
  @override
  String get deleteGroupWarning =>
      'This cannot be undone.\nAll group data will be deleted.';
  @override
  String get leaveGroupWarning =>
      'Your information will be removed from this group.\nYou will need an invitation to rejoin.';
  @override
  String get deletingGroup => 'Deleting group...';
  @override
  String get leavingGroup => 'Leaving group...';
  @override
  String get copyMembersFrom => 'Copy members from existing group (optional):';
  @override
  String get selectGroupHint => 'Select a group...';
  @override
  String get newGroupNoMembers => 'New group (no members)';
  @override
  String get selectMembersToCopy => 'Select members and roles to copy:';
  @override
  String get noMembersInGroup => 'No members in selected group';
  @override
  String get selectGroupToCopyMembers =>
      'Select an existing group to copy its members';
  @override
  String get creatingGroup => 'Creating group...';
  @override
  String get manager => 'Manager';
  @override
  String get partner => 'Partner';

  @override
  String get selectGroupFirst => 'Please select a group first';
  @override
  String get noGroupSelected => 'No group selected';
  @override
  String get descriptionOptional => 'Description (optional)';
  @override
  String get editTask => 'Edit Task';
  @override
  String get addTask => 'Add Task';
  @override
  String get addShoppingItem => 'Add Shopping Item';
  @override
  String get productName => 'Item name';
  @override
  String get purchaseIntervalOptional => 'Purchase interval (optional)';
  @override
  String get perDay => 'Per day';
  @override
  String get perWeek => 'Per week';
  @override
  String get perMonth => 'Per month';
  @override
  String get noRepeatPurchase => 'No repeat';
  @override
  String get selectDeadlineOptional => 'Set deadline (optional)';
  @override
  String get quantityRequired => 'Please enter a quantity';
  @override
  String get quantityInvalid => 'Enter a valid quantity (1 or more)';
  @override
  String get deadlineMustBeFuture => 'Deadline must be today or later';

  // UI mode
  @override
  String get managementMode => 'Management Mode';
  @override
  String get singleModeLabel => 'Single';
  @override
  String get multiModeLabel => 'Multi';
  @override
  String get singleModeDesc => 'Single mode: one group & one list';
  @override
  String get multiModeDesc => 'Multi mode: manage multiple groups & lists';
  @override
  String get switchToSingleMode => 'Switch to Single Mode';
  @override
  String get switchToSingleModeBody =>
      'Only the current group and list will be shown.\nYour other data will not be deleted.';
  @override
  String get switchedToSingleMode => 'Switched to Single Mode';
  @override
  String get switchedToMultiMode => 'Switched to Multi Mode';
  @override
  String get selectGroupBeforeSwitch =>
      'Please select a group before switching to Single Mode';
  @override
  String get selectListBeforeSwitch =>
      'Please select a list before switching to Single Mode';
  @override
  String get doSwitch => 'Switch';

  // Group member management
  @override
  String get groupInfo => 'Group Info';
  @override
  String get inviteOnlyForAdmins =>
      'Only owners, admins, and partners can invite members';
  @override
  String get errorOccurred => 'An error occurred';
  @override
  String get copyGroupTooltip => 'Copy group and create new';
  @override
  String get inviteByQR => 'Invite by QR code';
  @override
  String get inviteByQRDesc =>
      'Generate a QR code for the other person to scan';
  @override
  String get inviteByEmail => 'Invite by email';
  @override
  String get inviteByEmailDesc =>
      'Send an invitation to a specified email address';
  @override
  String get addMemberManually => 'Add member manually';
  @override
  String get addMemberManuallyDesc => 'Enter member information directly';
  @override
  String get enterEmailToInvite => 'Enter the email address to invite';
  @override
  String get sendInvitation => 'Send invitation';
  @override
  String get emailInviteUnavailable =>
      'Email invitation unavailable. Please use QR invitation.';
  @override
  String get enterGroupName => 'Please enter a group name';

  // Account deletion
  @override
  String get reauthRequired => 'Re-authentication required';
  @override
  String get reauthDescription =>
      'For security, please re-enter your password.';
  @override
  String get finalConfirmation => 'Final confirmation';
  @override
  String get deleteCompletely => 'Delete permanently';
  @override
  String get deletingAccount => 'Deleting account...';
  @override
  String get deletingAccountProgress => 'Delete data → Delete auth';
  @override
  String get authError => 'Authentication error';
  @override
  String get wrongPassword => 'Incorrect password.';
  @override
  String get authFailed => 'Authentication failed.';

  // QR invitation
  @override
  String get qrCodeInvite => 'QR code invitation';
  @override
  String get copyData => 'Copy data';
  @override
  String get share => 'Share';
  @override
  String get processingInvitation => 'Processing invitation...';
  @override
  String get cannotScanOwnCode => 'You cannot scan your own invitation code';
  @override
  String get groupInvitation => 'Group invitation';
  @override
  String get accept => 'Accept';
  @override
  String get signInRequired => 'Sign in required';
  @override
  String get signInRequiredForInvite =>
      'You need to sign in to accept the group invitation.';
  @override
  String get invitationSavedForLater =>
      'Invitation saved.\nIt will be processed automatically after sign-in.';

  // Other UI labels
  @override
  String get memberListLabel => 'Member list';
  @override
  String get selectInviteMethod => 'Select invitation method';
  @override
  String get noMembers => 'No members';
  @override
  String get inviteMemberHint =>
      'Use the + button in the top right\nto invite members';
  @override
  String get recommendPortrait => 'Portrait orientation recommended';

  // Common menu / AppBar
  @override
  String get errorHistory => 'Error history';
  @override
  String get help => 'Help';
  @override
  String get versionInfo => 'Version info';

  // Auth panel
  @override
  String get loginOrRegister => 'Sign In / Register';
  @override
  String get login => 'Sign in';
  @override
  String get register => 'Register';
  @override
  String get saveEmail => 'Save email address';
  @override
  String get enterUserName => 'Please enter a username';

  // Account deletion (additional)
  @override
  String get deletionComplete => 'Deletion complete';
  @override
  String get deletionFailed => 'Deletion failed';
  @override
  String get deleteAccountAndData =>
      'Permanently deletes your account and all data';
  @override
  String get cannotUndoWarning => '⚠️ This action cannot be undone';

  // Bottom nav / Home
  @override
  String get home => 'Home';
  @override
  String get signedOut => 'Signed out';
  @override
  String get signOutError => 'Sign out error';
  @override
  String get displayNameHint => 'e.g. Taro';
  @override
  String get displayNameHelper => 'This name will be shown to group members';
  @override
  String get passwordHint => '6 characters or more';
  @override
  String welcomeUser(String name) => 'Account created! Welcome, $name';

  // Sync management widget
  @override
  String get syncManagement => 'Sync Management';
  @override
  String get syncingFirestore => 'Sync from Firestore';
  @override
  String get clearCache => 'Clear Cache';
  @override
  String get clearCacheTitle => 'Clear Cache';
  @override
  String get clearCacheConfirm =>
      'Clear local cache?\nData will be re-fetched from Firestore on next launch.';
  @override
  String get clearCacheSuccess => 'Cache cleared';
  @override
  String get debugLabel => 'Debug';
  @override
  String get onlineStatus => 'Online Status';
  @override
  String get connected => 'Connected';
  @override
  String get offline => 'Offline';
  @override
  String get localModeNoSync => 'Local mode (no sync)';

  // Auth / Account (added)
  @override
  String get appDescription =>
      'An app for sharing shopping lists with family and groups.';
  @override
  String get mainFeatures => 'Main features:';
  @override
  String get featureGroupSharing => '\u2022 Shared shopping lists in groups';
  @override
  String get featureRealtimeSync => '\u2022 Real-time sync';
  @override
  String get featureOfflineSupport => '\u2022 Offline support';
  @override
  String get featureMemberManagement => '\u2022 Member management';
  @override
  String get accountNotFound => 'Account not found';
  @override
  String get createNew => 'Create new';
  @override
  String get signUpRequiredTitle => 'Sign up required';
  @override
  String get signUpToUseAll => 'Sign up to access all features';
  @override
  String get later => 'Later';
  @override
  String get scanQRRequiresSignUp => 'QR scan (requires sign-up)';
  @override
  String get inviteRequiresSignUp => 'Invite (requires sign-up)';
  @override
  String get inviteMemberLabel => 'Invite member';
  @override
  String get groupListSharing => 'Group list sharing';
  @override
  String get qrInviteFeature => 'QR code invite feature';
  @override
  String get accountCreated => 'Account created';
  @override
  String get accountCreationFailed => 'Failed to create account';
  @override
  String accountNotFoundBody(String email) =>
      'No account found for $email.\nCreate a new account?';

  // Invitation / Member management (added)
  @override
  String get generateInviteCode => 'Generate new invite code';
  @override
  String get inviteManagement => 'Invite Management';
  @override
  String get activeInviteCodes => 'Active Invite Codes';
  @override
  String get noActiveInvites => 'No active invite codes';
  @override
  String get deleteInviteCode => 'Delete invitation';
  @override
  String get deleteInviteCodeConfirm => 'Delete this invite code?';
  @override
  String get copy => 'Copy';
  @override
  String get selectFromPool => 'Select from pool';
  @override
  String get newMember => 'New member';
  @override
  String get noMembersInPool => 'No members in pool';
  @override
  String get promoteToAdmin => 'Promote to admin';
  @override
  String get demoteToMember => 'Demote to member';
  @override
  String get promote => 'Promote';
  @override
  String get demote => 'Demote';
  @override
  String get invitationResults => 'Invitation results';
  @override
  String get errorDetails => 'Error details:';
  @override
  String promotedToAdmin(String name) => 'Promoted $name to admin';
  @override
  String demotedToMember(String name) => 'Demoted $name to member';
  @override
  String sendInvitationsCount(int count) => 'Send invitations ($count)';

  // QR / Scan (added)
  @override
  String get qrCodeReader => 'QR Code Reader';
  @override
  String get manualInput => 'Manual input';
  @override
  String get enter8CharCode => 'Enter the 8-character alphanumeric code';
  @override
  String get invalidQRFormat => 'Invalid QR code format';
  @override
  String get checkCameraPermission => 'Check camera permissions';
  @override
  String get individualGroupInvite => 'Individual group invite';
  @override
  String get individualGroupInviteDesc => 'Access to this group only';
  @override
  String get friendInvite => 'Friend invite';
  @override
  String get friendInviteDesc => 'Access to all your groups';
  @override
  String get enterInviteCode => 'Enter invite code';
  @override
  String inviteCodeRecognized(String code) =>
      'Invite code \u201c$code\u201d recognized';
  @override
  String inviteToGroup(String groupName) =>
      'Invitation to \u201c$groupName\u201d';

  // Invitation monitor (added)
  @override
  String get checkingInvitations => 'Checking invitations...';
  @override
  String get processAll => 'Process all';
  @override
  String get rejectInvitation => 'Reject invitation';
  @override
  String get reject => 'Reject';
  @override
  String get invitationStats => 'Invitation stats';
  @override
  String get joinGroup => 'Join group';
  @override
  String get joinGroupQuestion => 'Join the following group?';
  @override
  String get join => 'Join';
  @override
  String joinAsRole(String role) => 'Join as $role';
  @override
  String approvedJoin(String name) => 'Approved $name\'s join request';
  @override
  String rejectConfirm(String name) => 'Reject $name\'s join request?';
  @override
  String rejectedInvite(String name) => 'Rejected $name\'s invitation';
  @override
  String alreadyJoinedGroup(String name) =>
      'Already a member of \u201c$name\u201d';

  // Error / Notification history (added)
  @override
  String get noErrorHistory => 'No error history';
  @override
  String get markReadAndClose => 'Mark as read and close';
  @override
  String get markedAsRead => 'Marked as read';
  @override
  String get deleteReadErrors => 'Delete read errors';
  @override
  String get deleteReadErrorsConfirm =>
      'Delete all read error logs?\nThis action cannot be undone.';
  @override
  String get noReadNotifications => 'No read notifications';
  @override
  String markedReadFailed(String e) => 'Failed to mark as read: $e';
  @override
  String deletedErrorLogs(int count) => 'Deleted $count error log(s)';
  @override
  String deleteErrorLogFailed(String e) => 'Failed to delete error logs: $e';
  @override
  String deletedReadNotifications(int count) =>
      'Deleted $count read notification(s)';

  // News / Feedback (added)
  @override
  String get thankYou => 'Thank you for your feedback!';
  @override
  String get surveyAction => 'Take the survey';
  @override
  String get remindLater => 'Remind me later';
  @override
  String get premiumPlan => 'Premium plan';
  @override
  String get remindTomorrow => 'Remind me tomorrow';
  @override
  String get cannotOpenLink => 'Could not open link';
  @override
  String get invalidLink => 'Invalid link';
  @override
  String get thanks => 'Thank you!';
  @override
  String cannotOpenForm(String e) => 'Could not open form: $e';

  // Premium / Ads (added)
  @override
  String get trialStarted => 'Free trial started';
  @override
  String get startTrial => 'Start trial';
  @override
  String get resetToFree => 'Reset to free plan';
  @override
  String get selectPlan => 'Select';
  @override
  String get upgradedToAnnualPlan => 'Upgraded to annual plan!';
  @override
  String get upgradedTo3YearPlan => 'Upgraded to 3-year plan!';
  @override
  String get groupManagement => 'Group Management';
  @override
  String get noGroupData => 'No group data';
  @override
  String get featureInProgress => 'Feature coming soon';
  @override
  String get addGroupInProgress =>
      'Add group feature is currently under development.';
  @override
  String get toPremium => 'Go Premium';
  @override
  String get premiumBenefits => '\u2728 Premium benefits';
  @override
  String get benefitNoAds => '\u2022 No ads';
  @override
  String get benefitPremiumSupport => '\u2022 Premium support';
  @override
  String get benefitEarlyAccess => '\u2022 Early access to new features';
  @override
  String get pricePlan => 'Pricing';
  @override
  String get userChangedDetected => 'User change detected';
  @override
  String get differentUserLoggedIn => 'A different user has logged in.';
  @override
  String userPrevious(String user) => 'Previous: $user';
  @override
  String userCurrent(String user) => 'Current: $user';
  @override
  String get whatToDoWithOldData => 'What to do with previous data?';
  @override
  String get dataMigrationDescription =>
      '• Keep: Existing groups and shopping lists will be transferred\n• Clear: Start fresh for the new user';
  @override
  String get clearData => 'Clear';
  @override
  String get keepData => 'Keep';
  @override
  String get secretModeEnabled => 'Secret mode is enabled';
  @override
  String get groupDataRequiresLogin => 'Sign in to view group data';
  @override
  String get newGroup => 'New Group';
  @override
  String signInToUseGroup(String groupName) =>
      'Sign in to use $groupName features';
  @override
  String get noSharedList => 'No lists';
  @override
  String createNewSharedList(String listName) => 'Create new $listName';
  @override
  String duplicateListNameAlert(String name) =>
      'A list named “$name” already exists';
  @override
  String deleteListConfirm(String name) => 'Delete “$name”?';
  @override
  String get listCreateHint => 'e.g. Weekend shopping';
  @override
  String get listChangeNotification => 'List change notifications';
  @override
  String get listChangeNotificationDesc =>
      'Notify every 5 minutes for item additions, deletions, and completions';
  @override
  String get listNotificationOn => 'List change notifications turned on';
  @override
  String get listNotificationOff => 'List change notifications turned off';
  @override
  String get viewNotificationHistory => 'View notification history';
  @override
  String get listChangeNotificationSettings =>
      'List change notification settings';
  @override
  String get shoppingListMode => 'Shopping List';
  @override
  String get todoShareMode => 'TODO Share';
  @override
  String modeChanged(String modeName) => 'Mode changed to “$modeName”';
  @override
  String get userNameSetting => 'Username Settings';
  @override
  String get userNameSettingDesc => 'Set the username displayed in the app';
  @override
  String get userNameLabel => 'Username';
  @override
  String get userNameHint => 'Enter your display name';
  @override
  String get userNameRequired => 'Please enter a username';
  @override
  String get userNameTooShort => 'Username must be at least 2 characters';
  @override
  String get userNameTooLong => 'Username must be 20 characters or less';
  @override
  String get saving => 'Saving...';
  @override
  String get saveUserName => 'Save Username';
  @override
  String get userNameSaved => 'Username saved';
  @override
  String saveFailed(Object e) => 'Failed to save: $e';
  @override
  String get currentPrefix => 'Current';
  @override
  String get newsPanelTitle => '📰 News & Announcements';
  @override
  String get newsCardTitle => 'News';
  @override
  String get newsLoading => 'Loading news...';
  @override
  String get tipsLabel => 'Tips';
  @override
  String get tipTapTitle => 'Basic: Tap';
  @override
  String get tipTapBody => 'Tap to toggle item status, select current group, and more.';
  @override
  String get tipDoubleTapTitle => 'Pro tip: Double-tap';
  @override
  String get tipDoubleTapBody => 'Double-tap to edit items, view member whiteboards, and more.';
  @override
  String get tipLongPressTitle => 'Safe action: Long-press';
  @override
  String get tipLongPressBody => 'Long-press for destructive actions like deleting items or leaving groups.';
  @override
  String get tipGroupScreenTitle => 'Group screen';
  @override
  String get tipGroupScreenBody => 'Tap → select current, double-tap → manage members, long-press → delete/leave.';
  @override
  String get tipMemberScreenTitle => 'Members screen';
  @override
  String get tipMemberScreenBody => 'Tap → change role (owner) or view info, double-tap → whiteboard.';
}
