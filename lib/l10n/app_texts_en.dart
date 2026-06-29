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
  String get initPreparingApp => 'Preparing application...';

  @override
  String get initCheckingData => 'Checking data...';

  @override
  String get initPreparingUser => 'Preparing user profile...';

  @override
  String get initReady => 'Ready';

  @override
  String get initErrorButContinue =>
      'An initialization error occurred, but continuing...';

  @override
  String get initPreparingService => 'Preparing services...';

  @override
  String get initSyncingGroups => 'Syncing group data...';

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

  @override
  String get defaultShoppingListName => 'Shopping list';

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
  String get resetPassword => 'Reset Password';

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
  String initialSetupDesc(String listName) =>
      'Share $listName with your group.\nFirst, create a group or\njoin an existing group.';
  @override
  String get createFirstGroup => 'Create first group';
  @override
  String get joinGroupByQR => 'Join group by QR code';
  @override
  String get aboutGroups => 'About Groups';
  @override
  String get aboutGroupsDesc =>
      '\u2022 Share shopping lists within your group\n'
      '\u2022 Create multiple groups for family, friends, work\n'
      '\u2022 Invite & join easily with QR codes';
  @override
  String get groupNameHint => 'e.g. Family, Friends, Work';
  @override
  String get createGroupFailed => 'Failed to create group';
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
  String get leaveRequestSent =>
      'Leave request sent. Group will disappear once processed.';
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
  String get tipTapBody =>
      'Tap to toggle item status, select current group, and more.';
  @override
  String get tipDoubleTapTitle => 'Pro tip: Double-tap';
  @override
  String get tipDoubleTapBody =>
      'Double-tap to edit items, view member whiteboards, and more.';
  @override
  String get tipLongPressTitle => 'Safe action: Long-press';
  @override
  String get tipLongPressBody =>
      'Long-press for destructive actions like deleting items or leaving groups.';
  @override
  String get tipGroupScreenTitle => 'Group screen';
  @override
  String get tipGroupScreenBody =>
      'Tap → select current, double-tap → manage members, long-press → delete/leave.';
  @override
  String get tipMemberScreenTitle => 'Members screen';
  @override
  String get tipMemberScreenBody =>
      'Tap → change role (owner) or view info, double-tap → whiteboard.';

  // Sync status icons
  @override
  String get syncStatusSynced => 'Synced';
  @override
  String get syncStatusSyncing => 'Syncing...';
  @override
  String get syncStatusOffline => 'Disconnected';
  @override
  String get syncStatusNotLoggedIn => 'Not logged in';
  @override
  String get networkOfflineStatus => 'Network failure';
  @override
  String get checkingConnectionStatus => 'Checking connection...';
  @override
  String get notSignedIn => 'Not signed in';

  // Help dialog
  @override
  String get helpTitle => 'Help';
  @override
  String get helpBasicUsage => 'Basic Usage';
  @override
  String helpBasicUsagePoint(int n) {
    const points = [
      'Create a group and invite members',
      'Share lists and sync in real time',
      'Add items and mark them as purchased',
    ];
    return n >= 1 && n <= points.length ? points[n - 1] : '';
  }

  @override
  String get helpGroupInvite => 'Group Invitation';
  @override
  String helpGroupInvitePoint(int n) {
    const points = [
      'Show a QR code to invite members',
      'Scan a QR code to join a group',
      'Invitations are valid for 24 hours, up to 5 members',
    ];
    return n >= 1 && n <= points.length ? points[n - 1] : '';
  }

  @override
  String get helpSyncIcons => 'Sync Status Icons';
  @override
  String helpSyncIconPoint(int n) {
    const points = [
      '🟢 Green: Synced',
      '🟠 Orange: Syncing',
      '🔴 Red: Disconnected',
      '⚪ Gray: Not logged in',
    ];
    return n >= 1 && n <= points.length ? points[n - 1] : '';
  }

  @override
  String get legalTitle => 'Legal';
  @override
  String get versionInfoTitle => 'Version Info';
  @override
  String get versionLabel => 'Version';
  @override
  String get buildNumberLabel => 'Build Number';
  @override
  String get packageNameLabel => 'Package Name';
  @override
  String get appFooterSubtitle => 'Sharing App';

  // Invitation accept widget
  @override
  String get inviteAcceptTitle => 'Accept Invitation';
  @override
  String get inviteAcceptDesc =>
      'Invited to a group?\nScan a QR code or enter an invite code.';
  @override
  String get invalidQRCodeMsg => 'Invalid QR code format';
  @override
  String get cameraErrorPrefix => 'Camera error:';
  @override
  String get unknownGroup => 'Unknown group';
  @override
  String invitationPendingApproval(String groupName) =>
      'Waiting for approval from $groupName';

  // Home page
  @override
  String get privacyPoint1 =>
      'Only login info and display name are shared initially';
  @override
  String get privacyPoint2 => 'Lists are only shared with users you share with';
  @override
  String get privacyPoint3 => 'Users joining your group follow the same policy';
  @override
  String get privacyPoint4 => 'A Firebase account is required to use the app';
  @override
  String get forNewUsersDesc =>
      'Create an account or sign in with your email and password.\nIf you already have an account, sign in with the same credentials.';
  @override
  String howToUsePoint(int n) {
    const points = [
      'Manage groups in the "Groups" tab at the bottom',
      'Select a group to view its lists',
      'Invite family and friends with a QR code',
      'Configure app settings in the "Settings" tab',
    ];
    return n >= 1 && n <= points.length ? points[n - 1] : '';
  }

  // Auth error messages
  @override
  String get signUpFailed => 'Failed to create account';
  @override
  String get emailAlreadyInUse => 'This email address is already in use';
  @override
  String get weakPassword => 'Password is too weak';
  @override
  String get signInFailed => 'Sign in failed';
  @override
  String get userNotFoundSignIn => 'User not found. Please create an account';
  @override
  String get wrongEmailOrPassword => 'Incorrect email or password';

  // Shared list
  @override
  String quantityDisplay(int quantity) => 'Qty: $quantity';
  @override
  String deadlineDisplay(String date) => 'Due: $date';
  @override
  String intervalDisplay(int days) => 'Every ${days}d';
  @override
  String itemDeletedName(String name) => 'Deleted "$name"';
  @override
  String itemDeleteFailed(String e) => 'Failed to delete: $e';
  @override
  String itemDeleteConfirm(String name) => 'Delete "$name"?';

  // Account deletion
  @override
  String deleteAccountWarningBody(String listName) =>
      '⚠️ This cannot be undone\n\nThe following will be permanently deleted:\n• Account info\n• All $listName\n• Groups you own\n• Whiteboard data\n• Notification history\n\nAre you sure?';
  @override
  String finalConfirmationBody(String email) =>
      'Email: $email\n\nAre you sure you want to delete this account?\n\nThis action cannot be undone.';
  @override
  String get deletionCompleteBody =>
      'Your account and all data have been deleted.\n\nThank you for using Go Shop.';
  @override
  String deletionFailedBody(String e) =>
      'An error occurred while deleting the account.\n\nError:\n$e\n\nPlease contact the developer.';

  // Group list
  @override
  String memberCount(int count) => 'Members: $count';
  @override
  String ownerDisplay(String name) => 'Owner: $name';
  @override
  String syncErrorMessage(String error) => 'Sync error: $error';

  // Language settings panel
  @override
  String get displayLanguageTitle => 'Display Language / 表示言語';
  @override
  String get displayLanguageDesc =>
      'Select app language (restart for full effect)';
  @override
  String get languageJa => '日本語';
  @override
  String get languageChangedEn =>
      'Language changed to English. Restart for full effect.';
  @override
  String get languageChangedJa =>
      'Language changed to Japanese. Restart for full effect.';

  // QR scan overlay
  @override
  String get qrCodeHereOverlay => 'Place QR code here';

  // App mode-dependent display names
  @override
  String sharedListNameForMode(bool isShopping) =>
      isShopping ? 'Shopping List' : 'Task List';
  @override
  String groupNameForMode(bool isShopping) => isShopping ? 'Group' : 'Team';

  // Item edit modal
  @override
  String get itemNameHintMilk => 'e.g., Milk';
  @override
  String get intervalNone => '0 (none)';
  @override
  String intervalDaysSuffix(int days) => 'Every $days day(s)';

  // Whiteboard settings panel
  @override
  String get whiteboardSettingsTitle => 'Whiteboard Settings';
  @override
  String get customColorSettingsTitle => 'Custom Color Settings';
  @override
  String get customColorSettingsDesc =>
      'In addition to 4 basic colors (black, red, green, yellow), you can set 2 custom colors';
  @override
  String colorSlot(int n) => 'Color $n: ';
  @override
  String get errorWithPrefix => 'Error';

  // Feedback section
  @override
  String get feedbackSectionTitle => 'Send Feedback';
  @override
  String get feedbackSectionDesc => 'Share your feedback with us';
  @override
  String get feedbackSectionSubDesc =>
      'Help improve the beta version. Takes about 1 minute.';
  @override
  String get feedbackButton => 'Take Survey';
  @override
  String get feedbackThanks => 'Thank you for your feedback!';
  @override
  String get formOpenFailed => 'Could not open the form';

  // Settings page
  @override
  String get settingsPagePlaceholder => 'Settings';
  @override
  String get goShopSettingsLabel => 'Go Shop Settings';
  @override
  String get checkingAuthStatus => 'Checking authentication...';
  @override
  String get errorOccurredTitle => 'An error occurred';

  // App mode switcher panel
  @override
  String get appModeTitle => 'App Mode';
  @override
  String get appModeDesc => 'Switch the display mode of the app';

  // Auth state helper
  @override
  String featureRequiresSignUp(String feature) => 'To use $feature';
  @override
  String get signUpRequiredMsg => 'Sign up is required';
  @override
  String get welcomeToGoShop => 'Welcome to GoShopping!';
  @override
  String get welcomeSubtitle =>
      'Share lists with family or group,\nfor more convenient management';
  @override
  String get availableFeatures => '✨ Available Features';
  @override
  String personalListCreate(String listType) => 'Create personal $listType';
  @override
  String get signUpPromptBody => 'An account is required to use this feature.\n'
      'By signing up, you can use:\n\n'
      '• Shared group lists\n'
      '• Easy QR code invitation\n'
      '• Member management\n'
      '• Backup and data sync';

  // Notification history page
  @override
  String get weeksAgo => ' weeks ago';
  @override
  String get monthsAgo => ' months ago';
  @override
  String get yearsAgo => ' years ago';
  @override
  String get timeUnknown => 'Unknown time';
  @override
  String get unread => 'Unread';
  @override
  String get tooltipMarkRead => 'Mark as read';
  @override
  String get tooltipDeleteRead => 'Delete read notifications';
  @override
  String get tooltipReload => 'Reload';
  @override
  String get firestoreIndexRequired => 'Firestore index required';
  @override
  String get firestoreIndexDesc =>
      'Please create a composite index in Firebase Console';
  @override
  String get errorWithDetail => 'An error occurred: ';

  // Error history page
  @override
  String get unknownOperation => 'Unknown operation';
  @override
  String get noErrorDetailMsg => 'No error details';
  @override
  String get permissionErrorLabel => 'Permission error';
  @override
  String get networkErrorLabel => 'Network error';
  @override
  String get syncErrorLabel => 'Sync error';
  @override
  String get validationErrorLabel => 'Validation error';
  @override
  String get operationErrorLabel => 'Operation error';
  @override
  String get unknownErrorLabel => 'Unknown error';
  @override
  String get operationLabel => 'Operation';
  @override
  String get messageLabel => 'Message';
  @override
  String get occurredAtLabel => 'Occurred at';
  @override
  String get contextLabel => 'Context';
  @override
  String get stackTraceLabel => 'Stack trace:';

  // QR code display/scan screens
  @override
  String get qrScanInstruction => 'Align the QR code within the frame';
  @override
  String get qrManualInputHint =>
      'If the QR code cannot be scanned, you can manually enter the invite code using the keyboard icon in the top right.';
  @override
  String get inviteGenFailed => 'Failed to generate invitation: ';
  @override
  String get qrScanDialogTitle => 'QR Code Invitation';
  @override
  String get qrScanDialogContent =>
      'Scan the group invitation QR code\nto join the group';
  @override
  String get qrScanButton => 'Scan QR Code';

  // Group invitation page
  @override
  String get inviteType => 'Invitation type';
  @override
  String get inviteByQRTitle => 'Invite by QR code';
  @override
  String get scanQRToJoinDesc => 'Scan this QR code to join the group';
  @override
  String maxInviteCount(int n) => 'Max invitees: $n';
  @override
  String get howToInviteTitle => 'How to invite';
  @override
  String get howToInviteDesc => '1. Have the other person scan the QR code\n'
      '2. They will be automatically added as a member after accepting in the app\n'
      '3. Check the group once you receive the acceptance notification';

  // QR scan screen extras
  @override
  String get checkingInviteCode => 'Checking invite code...';
  @override
  String get tooltipManualInput => 'Enter code manually';

  @override
  String notifListCreated(String name, String list) => '$name created "$list"';
  @override
  String notifListDeleted(String name, String list) => '$name deleted "$list"';
  @override
  String notifRenamed(String name, String oldName, String newName) =>
      '$name renamed "$oldName" to "$newName"';
  @override
  String notifMemberJoined(String name, String group) =>
      '$name joined "$group"';
  @override
  String notifMembershipApproved(String group) => group.isNotEmpty
      ? 'You joined "$group"'
      : 'Your group membership was approved';
  @override
  String notifGroupDeleted(String name, String group) =>
      '$name deleted "$group"';
  @override
  String notifMemberLeft(String name, String group) => '$name left "$group"';
  @override
  String notifYouLeft(String group) => 'You left "$group"';
  @override
  String notifItemAdded(String name, String item, String list) =>
      '$name added "$item" to "$list"';
  @override
  String notifItemRemoved(String name, String item, String list) =>
      '$name removed "$item" from "$list"';
  @override
  String notifItemPurchased(String name, String item, String list) =>
      '$name purchased "$item" from "$list"';
  @override
  String notifWhiteboardUpdated(String name) => '$name updated the whiteboard';
  @override
  String notifWhiteboardEditStarted(String name) =>
      '$name started drawing on the whiteboard';
  @override
  String notifWhiteboardEditEnded(String name) =>
      '$name finished drawing on the whiteboard';

  @override
  String get opSignIn => 'Sign In';
  @override
  String get opCreateAccount => 'Create Account';
  @override
  String get opSaveUserName => 'Save Username';
  @override
  String get opResetPassword => 'Reset Password';
  @override
  String get opSignUp => 'Sign Up';
  @override
  String get opAddMember => 'Add Member';
  @override
  String get opUpdateGroupName => 'Update Group Name';
  @override
  String get opSaveWhiteboard => 'Save Whiteboard';
  @override
  String get opClearWhiteboard => 'Clear Whiteboard';
  @override
  String get opUpdatePurchaseStatus => 'Update Purchase Status';
  @override
  String get opUpdateGroupMember => 'Update Group Member';
  @override
  String get opSendNotification => 'Send Notification';
  @override
  String get opLoadUserName => 'Load Username';
  @override
  String get opUpdateAllGroupUserNames => 'Update All Group Usernames';
  @override
  String get opGetGroupUserName => 'Get Group Username';
  @override
  String get opGetGroupMembers => 'Get Group Members';
  @override
  String get opSignOutClear => 'Clear on Sign Out';
  @override
  String get opGetFirestoreUserName => 'Get Firestore Username';
  @override
  String get opSaveFirestoreUserName => 'Save Firestore Username';
  @override
  String get opDeleteFirestoreUserName => 'Delete Firestore Username';
  @override
  String get opCreateUserProfile => 'Create User Profile';
  @override
  String get opSaveBillingType => 'Save Billing Type';
  @override
  String get opSearchInvitableGroups => 'Search Invitable Groups';
  @override
  String get opSendInvite => 'Send Invite';
  @override
  String get opAcceptInvitation => 'Accept Invitation';
  @override
  String get opSearchPendingInvitations => 'Search Pending Invitations';
  @override
  String get opRecordInvitation => 'Record Invitation';
  @override
  String get opGetPendingInvitations => 'Get Pending Invitations';
  @override
  String get opMarkInvitationProcessed => 'Mark Invitation Processed';
  @override
  String get opDeleteInvitation => 'Delete Invitation';
  @override
  String get opCreateQrInvite => 'Create QR Invite';
  @override
  String get opDecodeQrCode => 'Decode QR Code';
  @override
  String get opGetQrInviteDetails => 'Get QR Invite Details';
  @override
  String get opAcceptQrInvite => 'Accept QR Invite';
  @override
  String currentRoleLabel(String role) => 'Current role: $role';
  @override
  String get promoteToManagerDesc =>
      'Promoting to manager allows inviting members and editing lists.';
  @override
  String get demoteToMemberDesc =>
      'Demoting to member will revoke management permissions.';
  @override
  String get promoteToManager => 'Promote to Manager';
  @override
  String get demoteToMemberAction => 'Demote to Member';
  @override
  String promotedToManager(String name) => 'Promoted $name to manager';
  @override
  String demotedToMemberMsg(String name) => 'Demoted $name to member';
  @override
  String get doubleTapWhiteboardHint => 'Double-tap to view whiteboard';
  @override
  String get doubleTapToOpen => 'Double-tap to open';
  @override
  String get doubleTapToView => 'Double-tap to view';
  @override
  String memberAddedMsg(String name) => 'Added $name';
  @override
  String get memberAddFailed => 'Failed to add member';
  @override
  String get createAccountFailed => 'Failed to create account';
  @override
  String groupNameChangedMsg(String name) => 'Group name changed to "$name"';
  @override
  String get groupNameUpdateFailed => 'Failed to update group name';
  @override
  String get inviteFromPlusButton =>
      'Use the + button at top right\nto invite members';
}
