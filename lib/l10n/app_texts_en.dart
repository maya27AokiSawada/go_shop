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
}
