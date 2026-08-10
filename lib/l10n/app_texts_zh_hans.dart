import 'app_texts_en.dart';

/// Simplified Chinese text implementation.
///
/// This class inherits all base strings from English and overrides
/// high-priority UI keys used across the app.
class AppTextsZhHans extends AppTextsEn {
  // ========================================
  // Common
  // ========================================
  @override
  String get appName => 'GoShopping';

  @override
  String get cancel => '取消';

  @override
  String get save => '保存';

  @override
  String get delete => '删除';

  @override
  String get edit => '编辑';

  @override
  String get close => '关闭';

  @override
  String get back => '返回';

  @override
  String get next => '下一步';

  @override
  String get done => '完成';

  @override
  String get loading => '加载中...';

  @override
  String get error => '错误';

  @override
  String get retry => '重试';

  @override
  String get confirm => '确认';

  @override
  String get yes => '是';

  @override
  String get no => '否';

  // ========================================
  // Authentication
  // ========================================
  @override
  String get signIn => '登录';

  @override
  String get signUp => '注册';

  @override
  String get signOut => '退出登录';

  @override
  String get email => '邮箱';

  @override
  String get password => '密码';

  @override
  String get displayName => '显示名称';

  @override
  String get createAccount => '创建账号';

  @override
  String get alreadyHaveAccount => '已经有账号了吗？';

  @override
  String get dontHaveAccount => '还没有账号吗？';

  @override
  String get forgotPassword => '忘记密码？';

  @override
  String get emailRequired => '请输入邮箱';

  @override
  String get passwordRequired => '请输入密码';

  @override
  String get displayNameRequired => '请输入显示名称';

  @override
  String get invalidEmail => '请输入有效的邮箱地址';

  @override
  String get passwordTooShort => '密码至少需要6个字符';

  // ========================================
  // Group
  // ========================================
  @override
  String get group => '群组';

  @override
  String get groups => '群组';

  @override
  String get createGroup => '创建群组';

  @override
  String get editGroup => '编辑群组';

  @override
  String get deleteGroup => '删除群组';

  @override
  String get groupName => '群组名称';

  @override
  String get groupMembers => '成员';

  @override
  String get addMember => '添加成员';

  @override
  String get removeMember => '移除成员';

  @override
  String get owner => '所有者';

  @override
  String get member => '成员';

  @override
  String get leaveGroup => '退出群组';

  @override
  String get selectGroup => '选择群组';

  @override
  String get noGroups => '没有群组';

  @override
  String get groupCreated => '群组已创建';

  @override
  String get groupDeleted => '群组已删除';

  @override
  String get groupUpdated => '群组已更新';

  @override
  String get groupNameRequired => '请输入群组名称';

  @override
  String get duplicateGroupName => '该群组名称已被使用';

  @override
  String get confirmDeleteGroup => '确定要删除此群组吗？';

  @override
  String get current => '当前';

  @override
  String get noCurrentGroup => '未选择群组';

  @override
  String get loadingGroups => '正在加载群组...';

  @override
  String get preparingGroup => '正在准备群组...';

  @override
  String get groupLoadFailed => '加载群组失败';

  @override
  String get createFirstGroupHint => '创建你的第一个群组，\n或扫描二维码加入';

  @override
  String get createGroupHint => '点击 + 按钮创建群组';

  @override
  String initialSetupDesc(String listName) =>
      '与群组共享$listName。\n请先创建群组\n或加入现有群组。';

  @override
  String get createFirstGroup => '创建第一个群组';

  @override
  String get joinGroupByQR => '通过二维码加入群组';

  @override
  String get createGroupFailed => '创建群组失败';

  @override
  String get deleteGroupWarning => '此操作无法撤销。\n群组的所有数据将被删除。';

  @override
  String get leavingGroup => '正在退出群组...';

  @override
  String get creatingGroup => '正在创建群组...';

  @override
  String get manager => '管理员';

  @override
  String get partner => '协作者';

  // ========================================
  // List
  // ========================================
  @override
  String get list => '列表';

  @override
  String get lists => '列表';

  @override
  String get createList => '创建列表';

  @override
  String get editList => '编辑列表';

  @override
  String get deleteList => '删除列表';

  @override
  String get listName => '列表名称';

  @override
  String get sharedList => '共享列表';

  @override
  String get selectList => '选择列表';

  @override
  String get noLists => '没有列表';

  @override
  String get listCreated => '列表已创建';

  @override
  String get listDeleted => '列表已删除';

  @override
  String get listUpdated => '列表已更新';

  @override
  String get listNameRequired => '请输入列表名称';

  @override
  String get duplicateListName => '该列表名称已被使用';

  @override
  String get confirmDeleteList => '确定要删除此列表吗？';

  @override
  String get defaultShoppingListName => '购物清单';

  // ========================================
  // Item
  // ========================================
  @override
  String get item => '项目';

  @override
  String get items => '项目';

  @override
  String get addItem => '添加项目';

  @override
  String get editItem => '编辑项目';

  @override
  String get deleteItem => '删除项目';

  @override
  String get itemName => '项目名称';

  @override
  String get quantity => '数量';

  @override
  String get purchased => '已购买';

  @override
  String get notPurchased => '未购买';

  @override
  String get noItems => '没有项目';

  @override
  String get itemAdded => '项目已添加';

  @override
  String get itemDeleted => '项目已删除';

  @override
  String get itemUpdated => '项目已更新';

  @override
  String get itemNameRequired => '请输入项目名称';

  @override
  String get confirmDeleteItem => '确定要删除此项目吗？';

  @override
  String get markAsPurchased => '标记为已购买';

  @override
  String get markAsNotPurchased => '标记为未购买';

  @override
  String get addShoppingItem => '添加购物项目';

  @override
  String get productName => '商品名称';

  @override
  String get quantityRequired => '请输入数量';

  @override
  String get quantityInvalid => '请输入有效数量（1或以上）';

  // ========================================
  // QR / Invitation
  // ========================================
  @override
  String get invitation => '邀请';

  @override
  String get inviteMembers => '邀请成员';

  @override
  String get scanQRCode => '扫描二维码';

  @override
  String get generateQRCode => '生成二维码';

  @override
  String get acceptInvitation => '接受邀请';

  @override
  String get invitationAccepted => '邀请已接受';

  @override
  String get invitationExpired => '邀请已过期';

  @override
  String get invitationInvalid => '无效邀请';

  @override
  String get alreadyMember => '已是成员';

  @override
  String get scanningQRCode => '正在扫描二维码...';

  @override
  String get qrCodeGenerated => '二维码已生成';

  @override
  String get qrCodeInvite => '二维码邀请';

  @override
  String get processingInvitation => '正在处理邀请...';

  @override
  String get cannotScanOwnCode => '不能扫描自己的邀请码';

  // ========================================
  // Settings / Notifications / Whiteboard
  // ========================================
  @override
  String get settings => '设置';

  @override
  String get profile => '个人资料';

  @override
  String get notifications => '通知';

  @override
  String get language => '语言';

  @override
  String get theme => '主题';

  @override
  String get about => '关于';

  @override
  String get version => '版本';

  @override
  String get privacyPolicy => '隐私政策';

  @override
  String get termsOfService => '服务条款';

  @override
  String get logout => '退出';

  @override
  String get deleteAccount => '删除账号';

  @override
  String get confirmDeleteAccount => '确定要删除账号吗？此操作无法撤销。';

  @override
  String get notification => '通知';

  @override
  String get notificationHistory => '通知历史';

  @override
  String get markAsRead => '标记为已读';

  @override
  String get deleteNotification => '删除通知';

  @override
  String get noNotifications => '没有通知';

  @override
  String get whiteboard => '白板';

  @override
  String get drawingMode => '绘图模式';

  @override
  String get scrollMode => '滚动模式';

  @override
  String get penColor => '画笔颜色';

  @override
  String get penWidth => '画笔粗细';

  @override
  String get eraseAll => '全部清除';

  @override
  String get undo => '撤销';

  @override
  String get redo => '重做';

  // ========================================
  // Sync / Errors / Date
  // ========================================
  @override
  String get sync => '同步';

  @override
  String get syncing => '同步中...';

  @override
  String get syncCompleted => '同步完成';

  @override
  String get syncFailed => '同步失败';

  @override
  String get manualSync => '手动同步';

  @override
  String get lastSyncTime => '上次同步时间';

  @override
  String get offlineMode => '离线模式';

  @override
  String get onlineMode => '在线模式';

  @override
  String get networkError => '发生网络错误';

  @override
  String get serverError => '发生服务器错误';

  @override
  String get unknownError => '发生未知错误';

  @override
  String get permissionDenied => '权限被拒绝';

  @override
  String get authenticationRequired => '需要认证';

  @override
  String get operationFailed => '操作失败';

  @override
  String get tryAgainLater => '请稍后重试';

  @override
  String get today => '今天';

  @override
  String get yesterday => '昨天';

  @override
  String get daysAgo => '天前';

  @override
  String get hoursAgo => '小时前';

  @override
  String get minutesAgo => '分钟前';

  @override
  String get justNow => '刚刚';

  @override
  String get person => '人';

  @override
  String get people => '人';

  @override
  String get areYouSure => '确定吗？';

  @override
  String get cannotBeUndone => '此操作无法撤销';

  @override
  String get continueAction => '继续';

  @override
  String get cancelAction => '取消';

  // ========================================
  // Home / Auth helpers
  // ========================================
  @override
  String get home => '首页';

  @override
  String get signedOut => '已退出登录';

  @override
  String get signOutError => '退出失败';

  @override
  String get displayNameHint => '例如：Taro';

  @override
  String get displayNameHelper => '该名称将显示给群组成员';

  @override
  String get passwordHint => '至少6个字符';

  @override
  String welcomeUser(String name) => '账号创建成功！欢迎，$name';

  @override
  String featureRequiresSignUp(String feature) => '要使用$feature';

  @override
  String get signUpRequiredMsg => '需要注册';

  @override
  String get welcomeToGoShop => '欢迎使用 GoShopping！';

  @override
  String get welcomeSubtitle => '与家人或群组共享列表，\n让管理更便捷';

  @override
  String get availableFeatures => '✨ 可用功能';

  @override
  String personalListCreate(String listType) => '创建个人$listType';

  @override
  String get signUpPromptBody => '使用此功能需要账号。\n'
      '注册后可使用：\n\n'
      '• 群组共享列表\n'
      '• 便捷二维码邀请\n'
      '• 成员管理\n'
      '• 备份与数据同步';

  // ========================================
  // Sync / status icons
  // ========================================
  @override
  String get syncManagement => '同步管理';

  @override
  String get syncingFirestore => '从 Firestore 同步';

  @override
  String get clearCache => '清除缓存';

  @override
  String get clearCacheTitle => '清除缓存';

  @override
  String get clearCacheConfirm => '要清除本地缓存吗？\n下次启动时将从 Firestore 重新获取数据。';

  @override
  String get clearCacheSuccess => '缓存已清除';

  @override
  String get debugLabel => '调试';

  @override
  String get onlineStatus => '在线状态';

  @override
  String get connected => '已连接';

  @override
  String get offline => '离线';

  @override
  String get localModeNoSync => '本地模式（不同步）';

  @override
  String get syncStatusSynced => '已同步';

  @override
  String get syncStatusSyncing => '同步中...';

  @override
  String get syncStatusOffline => '已断开';

  @override
  String get syncStatusNotLoggedIn => '未登录';

  @override
  String get networkOfflineStatus => '网络故障';

  @override
  String get checkingConnectionStatus => '正在检查连接...';

  @override
  String get notSignedIn => '未登录';

  // ========================================
  // Invitation / QR
  // ========================================
  @override
  String get qrCodeReader => '二维码读取器';

  @override
  String get manualInput => '手动输入';

  @override
  String get enter8CharCode => '请输入8位字母数字邀请码';

  @override
  String get invalidQRFormat => '二维码格式无效';

  @override
  String get checkCameraPermission => '请检查相机权限';

  @override
  String get inviteType => '邀请类型';

  @override
  String get inviteByQRTitle => '通过二维码邀请';

  @override
  String get scanQRToJoinDesc => '扫描此二维码即可加入群组';

  @override
  String maxInviteCount(int n) => '最多邀请人数：$n';

  @override
  String get qrScanInstruction => '将二维码对准取景框';

  @override
  String get qrScanButton => '扫描二维码';

  @override
  String get checkingInviteCode => '正在检查邀请码...';

  @override
  String get tooltipManualInput => '手动输入邀请码';

  // ========================================
  // Help / menus
  // ========================================
  @override
  String get help => '帮助';

  @override
  String get helpTitle => '帮助';

  @override
  String get errorHistory => '错误历史';

  @override
  String get versionInfo => '版本信息';

  @override
  String get legalTitle => '法律信息';

  @override
  String get versionInfoTitle => '版本信息';

  @override
  String get versionLabel => '版本';

  @override
  String get buildNumberLabel => '构建号';

  @override
  String get packageNameLabel => '包名';

  @override
  String get appFooterSubtitle => '共享应用';

  @override
  String get displayLanguageTitle => '显示语言 / Display Language';

  @override
  String get displayLanguageDesc => '选择应用语言（重启后可完全生效）';

  @override
  String get languageJa => '日语';

  @override
  String get languageChangedEn => '语言已切换为简体中文。重启后可完全生效。';

  @override
  String get languageChangedJa => '语言已切换为日语。重启后可完全生效。';

  @override
  String get settingsPagePlaceholder => '设置页面（临时）';

  @override
  String get goShopSettingsLabel => 'Go Shop 设置';

  @override
  String get checkingAuthStatus => '正在检查认证状态...';

  @override
  String get errorOccurredTitle => '发生错误';

  @override
  String get appModeTitle => '应用模式';

  @override
  String get appModeDesc => '可在购物清单与任务共享之间切换';

  @override
  String get shoppingListMode => '购物清单模式';

  @override
  String get todoShareMode => '任务共享模式';

  @override
  String modeChanged(String modeName) => '模式已切换为：$modeName';

  @override
  String get switchedToMultiMode => '已切换到多模式';

  @override
  String get selectGroupBeforeSwitch => '切换前请先选择群组';

  @override
  String get selectListBeforeSwitch => '切换前请先选择列表';

  @override
  String get switchedToSingleMode => '已切换到单模式';

  @override
  String get whiteboardSettingsTitle => '白板设置';

  @override
  String get customColorSettingsTitle => '自定义颜色设置';

  @override
  String get customColorSettingsDesc => '除4种基础颜色（黑、红、绿、黄）外，还可设置2种自定义颜色';

  @override
  String colorSlot(int n) => '颜色$n: ';

  @override
  String get errorWithPrefix => '错误';

  @override
  String get notificationSettings => '通知设置';

  @override
  String get listChangeNotificationSettings => '列表变更通知设置';

  @override
  String get listChangeNotification => '列表变更通知';

  @override
  String get listChangeNotificationDesc => '当列表项目有变更时接收通知';

  @override
  String get listNotificationOn => '通知已开启';

  @override
  String get listNotificationOff => '通知已关闭';

  @override
  String get viewNotificationHistory => '查看通知历史';

  @override
  String get feedbackSectionTitle => '发送反馈';

  @override
  String get feedbackSectionDesc => '欢迎告诉我们你的意见';

  @override
  String get feedbackSectionSubDesc => '帮助我们改进测试版，约需1分钟。';

  @override
  String get feedbackButton => '填写问卷';

  @override
  String get feedbackThanks => '感谢你的反馈！';

  @override
  String get formOpenFailed => '无法打开表单';

  @override
  String get reauthRequired => '需要重新验证';

  @override
  String get reauthDescription => '删除账号前，请输入当前密码。';

  @override
  String get finalConfirmation => '最终确认';

  @override
  String get deleteCompletely => '彻底删除';

  @override
  String get deletingAccount => '正在删除账号...';

  @override
  String get deletingAccountProgress => '正在移除账号数据，请稍候。';

  @override
  String get authError => '认证错误';

  @override
  String get wrongPassword => '密码错误';

  @override
  String get authFailed => '认证失败';

  @override
  String get deletionComplete => '删除完成';

  @override
  String get deletionFailed => '删除失败';

  @override
  String get deleteAccountAndData => '删除账号和数据';

  @override
  String get cannotUndoWarning => '此操作无法撤销';

  @override
  String deleteAccountWarningBody(String listName) =>
      '⚠️ 此操作无法撤销\n\n以下数据将被永久删除：\n• 账号信息\n• 所有$listName\n• 你拥有的群组\n• 白板数据\n• 通知历史\n\n确定要删除吗？';

  @override
  String finalConfirmationBody(String email) =>
      '邮箱：$email\n\n确定要删除此账号吗？\n\n此操作无法撤销。';

  @override
  String get deletionCompleteBody => '你的账号和所有数据已删除。\n\n感谢使用 Go Shop。';

  @override
  String deletionFailedBody(String e) => '删除账号时发生错误。\n\n错误信息：\n$e\n\n请联系开发者。';

  // ========================================
  // Notification templates
  // ========================================
  @override
  String notifListCreated(String name, String list) => '$name 创建了 "$list"';

  @override
  String notifListDeleted(String name, String list) => '$name 删除了 "$list"';

  @override
  String notifRenamed(String name, String oldName, String newName) =>
      '$name 将 "$oldName" 重命名为 "$newName"';

  @override
  String notifMemberJoined(String name, String group) => '$name 加入了 "$group"';

  @override
  String notifMembershipApproved(String group) =>
      group.isNotEmpty ? '你已加入 "$group"' : '你的加群申请已通过';

  @override
  String notifGroupDeleted(String name, String group) => '$name 删除了 "$group"';

  @override
  String notifMemberLeft(String name, String group) => '$name 离开了 "$group"';

  @override
  String notifYouLeft(String group) => '你已离开 "$group"';

  @override
  String notifItemAdded(String name, String item, String list) =>
      '$name 在 "$list" 中添加了 "$item"';

  @override
  String notifItemRemoved(String name, String item, String list) =>
      '$name 从 "$list" 中移除了 "$item"';

  @override
  String notifItemPurchased(String name, String item, String list) =>
      '$name 在 "$list" 中购买了 "$item"';

  @override
  String notifWhiteboardUpdated(String name) => '$name 更新了白板';

  @override
  String notifWhiteboardEditStarted(String name) => '$name 开始在白板上绘制';

  @override
  String notifWhiteboardEditEnded(String name) => '$name 结束了白板绘制';

  // ========================================
  // Operation labels
  // ========================================
  @override
  String get opSignIn => '登录';

  @override
  String get opCreateAccount => '创建账号';

  @override
  String get opSaveUserName => '保存用户名';

  @override
  String get opResetPassword => '重置密码';

  @override
  String get opSignUp => '注册';

  @override
  String get opAddMember => '添加成员';

  @override
  String get opUpdateGroupName => '更新群组名称';

  @override
  String get opSaveWhiteboard => '保存白板';

  @override
  String get opClearWhiteboard => '清空白板';

  @override
  String get opUpdatePurchaseStatus => '更新购买状态';

  @override
  String get opUpdateGroupMember => '更新群组成员';

  @override
  String get opSendNotification => '发送通知';

  @override
  String get opLoadUserName => '加载用户名';

  @override
  String get opUpdateAllGroupUserNames => '更新所有群组用户名';

  @override
  String get opGetGroupUserName => '获取群组用户名';

  @override
  String get opGetGroupMembers => '获取群组成员';

  @override
  String get opSignOutClear => '退出时清理';

  @override
  String get opGetFirestoreUserName => '获取 Firestore 用户名';

  @override
  String get opSaveFirestoreUserName => '保存 Firestore 用户名';

  @override
  String get opDeleteFirestoreUserName => '删除 Firestore 用户名';

  @override
  String get opCreateUserProfile => '创建用户资料';

  @override
  String get opSaveBillingType => '保存计费类型';

  @override
  String get opSearchInvitableGroups => '搜索可邀请群组';

  @override
  String get opSendInvite => '发送邀请';

  @override
  String get opAcceptInvitation => '接受邀请';

  @override
  String get opSearchPendingInvitations => '搜索待处理邀请';

  @override
  String get opRecordInvitation => '记录邀请';

  @override
  String get opGetPendingInvitations => '获取待处理邀请';

  @override
  String get opMarkInvitationProcessed => '标记邀请已处理';

  @override
  String get opDeleteInvitation => '删除邀请';

  @override
  String get opCreateQrInvite => '创建二维码邀请';

  @override
  String get opDecodeQrCode => '解析二维码';

  @override
  String get opGetQrInviteDetails => '获取二维码邀请详情';

  @override
  String get opAcceptQrInvite => '接受二维码邀请';

  // ========================================
  // Tips / help
  // ========================================
  @override
  String get tipsLabel => '提示';

  @override
  String get tipTapTitle => '基础：点击';

  @override
  String get tipTapBody => '点击可切换项目状态、选择当前群组等。';

  @override
  String get tipDoubleTapTitle => '进阶：双击';

  @override
  String get tipDoubleTapBody => '双击可编辑项目、查看成员白板等。';

  @override
  String get tipLongPressTitle => '安全操作：长按';

  @override
  String get tipLongPressBody => '删除项目、退出群组等破坏性操作请使用长按。';

  @override
  String get tipGroupScreenTitle => '群组页面';

  @override
  String get tipGroupScreenBody => '点击 -> 设为当前，双击 -> 管理成员，长按 -> 删除/退出。';

  @override
  String get tipMemberScreenTitle => '成员页面';

  @override
  String get tipMemberScreenBody => '点击 -> 修改角色（所有者）或查看信息，双击 -> 白板。';

  @override
  String get helpBasicUsage => '基本使用';

  @override
  String helpBasicUsagePoint(int n) {
    const points = [
      '创建群组并邀请成员',
      '共享列表并实时同步',
      '添加项目并标记为已购买',
    ];
    return n >= 1 && n <= points.length ? points[n - 1] : '';
  }

  @override
  String get helpGroupInvite => '群组邀请';

  @override
  String helpGroupInvitePoint(int n) {
    const points = [
      '展示二维码以邀请成员',
      '扫描二维码加入群组',
      '邀请有效期24小时，最多5名成员',
    ];
    return n >= 1 && n <= points.length ? points[n - 1] : '';
  }

  @override
  String get helpSyncIcons => '同步状态图标';

  @override
  String helpSyncIconPoint(int n) {
    const points = [
      '🟢 绿色：已同步',
      '🟠 橙色：同步中',
      '🔴 红色：已断开',
      '⚪ 灰色：未登录',
    ];
    return n >= 1 && n <= points.length ? points[n - 1] : '';
  }

  @override
  String get howToInviteTitle => '邀请方法';

  @override
  String get howToInviteDesc => '1. 让对方扫描二维码\n'
      '2. 对方在应用中接受后会自动加入成员\n'
      '3. 收到接受通知后请在群组中确认';

  // ========================================
  // Error / notification history details
  // ========================================
  @override
  String get noErrorHistory => '没有错误历史';

  @override
  String get markReadAndClose => '标记为已读并关闭';

  @override
  String get markedAsRead => '已标记为已读';

  @override
  String get deleteReadErrors => '删除已读错误';

  @override
  String get deleteReadErrorsConfirm => '要删除所有已读错误日志吗？\n此操作无法撤销。';

  @override
  String get noReadNotifications => '没有已读通知';

  @override
  String markedReadFailed(String e) => '标记已读失败：$e';

  @override
  String deletedErrorLogs(int count) => '已删除 $count 条错误日志';

  @override
  String deleteErrorLogFailed(String e) => '删除错误日志失败：$e';

  @override
  String deletedReadNotifications(int count) => '已删除 $count 条已读通知';

  // ========================================
  // Invitation accept / member management
  // ========================================
  @override
  String get inviteAcceptTitle => '接受邀请';

  @override
  String get inviteAcceptDesc => '被邀请加入群组了吗？\n请扫描二维码或输入邀请码。';

  @override
  String get invalidQRCodeMsg => '二维码格式无效';

  @override
  String get cameraErrorPrefix => '相机错误：';

  @override
  String get unknownGroup => '未知群组';

  @override
  String invitationPendingApproval(String groupName) => '等待 $groupName 审核';

  @override
  String get groupInfo => '群组信息';

  @override
  String get inviteOnlyForAdmins => '仅所有者、管理员和协作者可邀请成员';

  @override
  String get selectInviteMethod => '请选择邀请方式';

  @override
  String get noMembers => '没有成员';

  @override
  String get inviteMemberHint => '使用右上角 + 按钮\n邀请成员';

  @override
  String get memberListLabel => '成员列表';

  @override
  String get recommendPortrait => '建议使用竖屏';

  @override
  String memberCount(int count) => '成员：$count';

  @override
  String ownerDisplay(String name) => '所有者：$name';

  @override
  String syncErrorMessage(String error) => '同步错误：$error';

  // ========================================
  // Misc helper labels
  // ========================================
  @override
  String get currentPrefix => '当前';

  @override
  String get saving => '保存中...';

  @override
  String get saveUserName => '保存用户名';

  @override
  String get userNameSaved => '用户名已保存';

  @override
  String saveFailed(Object e) => '保存失败：$e';

  // ========================================
  // Additional auth / onboarding
  // ========================================
  @override
  String get loginOrRegister => '登录 / 注册';

  @override
  String get login => '登录';

  @override
  String get register => '注册';

  @override
  String get saveEmail => '保存邮箱';

  @override
  String get enterUserName => '请输入用户名';

  @override
  String get signUpFailed => '创建账号失败';

  @override
  String get emailAlreadyInUse => '该邮箱已被使用';

  @override
  String get weakPassword => '密码强度过弱';

  @override
  String get signInFailed => '登录失败';

  @override
  String get userNotFoundSignIn => '未找到用户，请先创建账号';

  @override
  String get wrongEmailOrPassword => '邮箱或密码错误';

  @override
  String get switchToSignIn => '切换到登录';

  @override
  String get switchToCreateAccount => '切换到创建账号';

  @override
  String get resetPassword => '重置密码';

  @override
  String get rememberEmail => '记住邮箱';

  @override
  String get forNewUsers => '新用户指南';

  @override
  String get howToUse => '使用方法';

  @override
  String get noTasks => '没有任务';

  @override
  String get noShoppingItems => '没有购物项目';

  @override
  String get privacyAbout => '隐私说明';

  @override
  String get forNewUsersDesc => '请使用邮箱和密码创建账号或登录。\n若已有账号，请使用相同凭证登录。';

  @override
  String howToUsePoint(int n) {
    const points = [
      '在底部“群组”标签管理群组',
      '选择群组后查看该群组列表',
      '通过二维码邀请家人和朋友',
      '在“设置”标签中配置应用',
    ];
    return n >= 1 && n <= points.length ? points[n - 1] : '';
  }

  @override
  String get privacyPoint1 => '初始仅共享登录信息和显示名称';

  @override
  String get privacyPoint2 => '列表仅与你共享给的用户可见';

  @override
  String get privacyPoint3 => '加入你群组的用户同样遵循此策略';

  @override
  String get privacyPoint4 => '使用本应用需要 Firebase 账号';

  // ========================================
  // Additional mode / list-item helpers
  // ========================================
  @override
  String get create => '创建';

  @override
  String get update => '更新';

  @override
  String get add => '添加';

  @override
  String get leave => '离开';

  @override
  String get managementMode => '管理模式';

  @override
  String get singleModeLabel => '单模式';

  @override
  String get multiModeLabel => '多模式';

  @override
  String get singleModeDesc => '单模式：一个群组和一个列表';

  @override
  String get multiModeDesc => '多模式：管理多个群组和列表';

  @override
  String get switchToSingleMode => '切换到单模式';

  @override
  String get switchToSingleModeBody => '仅显示当前群组和列表。\n其他数据不会被删除。';

  @override
  String get doSwitch => '切换';

  @override
  String get selectGroupFirst => '请先选择群组';

  @override
  String get noGroupSelected => '未选择群组';

  @override
  String get descriptionOptional => '说明（可选）';

  @override
  String get editTask => '编辑任务';

  @override
  String get addTask => '添加任务';

  @override
  String get purchaseIntervalOptional => '购买间隔（可选）';

  @override
  String get perDay => '每天';

  @override
  String get perWeek => '每周';

  @override
  String get perMonth => '每月';

  @override
  String get noRepeatPurchase => '不重复';

  @override
  String get selectDeadlineOptional => '设置截止日期（可选）';

  @override
  String get deadlineMustBeFuture => '截止日期必须是今天或之后';

  // ========================================
  // Additional news / feedback
  // ========================================
  @override
  String get newsPanelTitle => '📰 新闻与公告';

  @override
  String get newsCardTitle => '新闻';

  @override
  String get newsLoading => '正在加载新闻...';

  @override
  String get thankYou => '感谢你的反馈！';

  @override
  String get surveyAction => '填写问卷';

  @override
  String get remindLater => '稍后提醒';

  @override
  String get premiumPlan => '高级计划';

  @override
  String get remindTomorrow => '明天提醒';

  @override
  String get cannotOpenLink => '无法打开链接';

  @override
  String get invalidLink => '无效链接';

  @override
  String get thanks => '谢谢！';

  @override
  String cannotOpenForm(String e) => '无法打开表单：$e';

  // ========================================
  // Notification/error history detail labels
  // ========================================
  @override
  String get weeksAgo => ' 周前';

  @override
  String get monthsAgo => ' 个月前';

  @override
  String get yearsAgo => ' 年前';

  @override
  String get timeUnknown => '未知时间';

  @override
  String get unread => '未读';

  @override
  String get tooltipMarkRead => '标记为已读';

  @override
  String get tooltipDeleteRead => '删除已读通知';

  @override
  String get tooltipReload => '重新加载';

  @override
  String get firestoreIndexRequired => '需要 Firestore 索引';

  @override
  String get firestoreIndexDesc => '请在 Firebase Console 创建复合索引';

  @override
  String get errorWithDetail => '发生错误：';

  @override
  String get unknownOperation => '未知操作';

  @override
  String get noErrorDetailMsg => '没有错误详情';

  @override
  String get permissionErrorLabel => '权限错误';

  @override
  String get networkErrorLabel => '网络错误';

  @override
  String get syncErrorLabel => '同步错误';

  @override
  String get validationErrorLabel => '校验错误';

  @override
  String get operationErrorLabel => '操作错误';

  @override
  String get unknownErrorLabel => '未知错误';

  @override
  String get operationLabel => '操作';

  @override
  String get messageLabel => '消息';

  @override
  String get occurredAtLabel => '发生时间';

  @override
  String get contextLabel => '上下文';

  @override
  String get stackTraceLabel => '堆栈跟踪：';

  // ========================================
  // Group details / copy members
  // ========================================
  @override
  String get aboutGroups => '关于群组';

  @override
  String get aboutGroupsDesc => '• 在群组内共享列表\n'
      '• 可为家庭、朋友、工作创建多个群组\n'
      '• 可通过二维码轻松邀请和加入';

  @override
  String get copyMembersFrom => '从现有群组复制成员（可选）：';

  @override
  String get selectGroupHint => '请选择群组...';

  @override
  String get newGroupNoMembers => '新群组（无成员）';

  @override
  String get selectMembersToCopy => '请选择要复制的成员和角色：';

  @override
  String get noMembersInGroup => '所选群组中没有成员';

  @override
  String get selectGroupToCopyMembers => '请选择一个现有群组以复制其成员';

  @override
  String get leaveGroupWarning => '你的信息将从该群组中移除。\n若要重新加入需再次邀请。';

  @override
  String get leaveRequestSent => '退出请求已发送。处理完成后该群组将消失。';

  @override
  String get deletingGroup => '正在删除群组...';

  @override
  String get groupNameHint => '例如：家庭、朋友、工作';

  // ========================================
  // Invitation methods / member management
  // ========================================
  @override
  String get inviteByQR => '通过二维码邀请';

  @override
  String get inviteByQRDesc => '生成二维码供对方扫描';

  @override
  String get inviteByEmail => '通过邮箱邀请';

  @override
  String get inviteByEmailDesc => '向指定邮箱发送邀请';

  @override
  String get addMemberManually => '手动添加成员';

  @override
  String get addMemberManuallyDesc => '直接输入成员信息';

  @override
  String get enterEmailToInvite => '请输入要邀请的邮箱地址';

  @override
  String get sendInvitation => '发送邀请';

  @override
  String get emailInviteUnavailable => '邮箱邀请不可用，请使用二维码邀请。';

  @override
  String get enterGroupName => '请输入群组名称';

  @override
  String get generateInviteCode => '生成新邀请码';

  @override
  String get inviteManagement => '邀请管理';

  @override
  String get activeInviteCodes => '有效邀请码';

  @override
  String get noActiveInvites => '没有有效邀请码';

  @override
  String get deleteInviteCode => '删除邀请';

  @override
  String get deleteInviteCodeConfirm => '确定要删除此邀请码吗？';

  @override
  String get copy => '复制';

  @override
  String get selectFromPool => '从池中选择';

  @override
  String get newMember => '新成员';

  @override
  String get noMembersInPool => '成员池中无成员';

  @override
  String get promoteToAdmin => '提升为管理员';

  @override
  String get demoteToMember => '降级为成员';

  @override
  String get promote => '提升';

  @override
  String get demote => '降级';

  @override
  String get invitationResults => '邀请结果';

  @override
  String get errorDetails => '错误详情：';

  @override
  String promotedToAdmin(String name) => '$name 已提升为管理员';

  @override
  String demotedToMember(String name) => '$name 已降级为成员';

  @override
  String sendInvitationsCount(int count) => '发送邀请（$count）';

  @override
  String get checkingInvitations => '正在检查邀请...';

  @override
  String get processAll => '全部处理';

  @override
  String get rejectInvitation => '拒绝邀请';

  @override
  String get reject => '拒绝';

  @override
  String get invitationStats => '邀请统计';

  @override
  String get joinGroup => '加入群组';

  @override
  String get joinGroupQuestion => '要加入以下群组吗？';

  @override
  String get join => '加入';

  @override
  String joinAsRole(String role) => '以 $role 身份加入';

  @override
  String approvedJoin(String name) => '已批准 $name 的加入请求';

  @override
  String rejectConfirm(String name) => '要拒绝 $name 的加入请求吗？';

  @override
  String rejectedInvite(String name) => '已拒绝 $name 的邀请';

  @override
  String alreadyJoinedGroup(String name) => '已是 "$name" 的成员';

  // ========================================
  // Premium / migration / mode-dependent names
  // ========================================
  @override
  String get trialStarted => '免费试用已开始';

  @override
  String get startTrial => '开始试用';

  @override
  String get resetToFree => '恢复为免费计划';

  @override
  String get selectPlan => '选择';

  @override
  String get upgradedToAnnualPlan => '已升级为年费计划！';

  @override
  String get upgradedTo3YearPlan => '已升级为3年计划！';

  @override
  String get groupManagement => '群组管理';

  @override
  String get noGroupData => '没有群组数据';

  @override
  String get featureInProgress => '功能开发中';

  @override
  String get addGroupInProgress => '添加群组功能正在开发中。';

  @override
  String get toPremium => '升级到 Premium';

  @override
  String get premiumBenefits => '✨ Premium 权益';

  @override
  String get benefitNoAds => '• 无广告';

  @override
  String get benefitPremiumSupport => '• 高级支持';

  @override
  String get benefitEarlyAccess => '• 新功能抢先体验';

  @override
  String get pricePlan => '价格方案';

  @override
  String get userChangedDetected => '检测到用户变更';

  @override
  String get differentUserLoggedIn => '检测到其他用户已登录。';

  @override
  String userPrevious(String user) => '之前：$user';

  @override
  String userCurrent(String user) => '当前：$user';

  @override
  String get whatToDoWithOldData => '如何处理旧数据？';

  @override
  String get dataMigrationDescription => '• 保留：现有群组和列表将迁移\n'
      '• 清除：为新用户从零开始';

  @override
  String get clearData => '清除';

  @override
  String get keepData => '保留';

  @override
  String get secretModeEnabled => '秘密模式已启用';

  @override
  String get groupDataRequiresLogin => '请先登录以查看群组数据';

  @override
  String get newGroup => '新群组';

  @override
  String signInToUseGroup(String groupName) => '登录后可使用 $groupName 功能';

  @override
  String get noSharedList => '没有列表';

  @override
  String createNewSharedList(String listName) => '创建新的$listName';

  @override
  String duplicateListNameAlert(String name) => '名为“$name”的列表已存在';

  @override
  String deleteListConfirm(String name) => '要删除“$name”吗？';

  @override
  String get listCreateHint => '例如：周末购物';

  @override
  String sharedListNameForMode(bool isShopping) => isShopping ? '购物清单' : '任务列表';

  @override
  String groupNameForMode(bool isShopping) => isShopping ? '群组' : '团队';

  // ========================================
  // Final remaining keys
  // ========================================
  @override
  String get ok => '确定';

  @override
  String get initPreparingApp => '正在准备应用...';

  @override
  String get initCheckingData => '正在检查数据...';

  @override
  String get initPreparingUser => '正在准备用户资料...';

  @override
  String get initReady => '准备完成';

  @override
  String get initErrorButContinue => '初始化发生错误，但将继续执行...';

  @override
  String get initPreparingService => '正在准备服务...';

  @override
  String get initSyncingGroups => '正在同步群组数据...';

  @override
  String get pieces => '';

  @override
  String get dataMaintenance => '数据维护';

  @override
  String get cleanupData => '清理数据';

  @override
  String get enableNotifications => '启用通知';

  @override
  String get createWhiteboard => '创建白板';

  @override
  String get editWhiteboard => '编辑白板';

  @override
  String get deleteWhiteboard => '删除白板';

  @override
  String get whiteboards => '白板';

  @override
  String get whiteboardName => '白板名称';

  @override
  String get zoom => '缩放';

  @override
  String get appDescription => '可与家人和群组共享购物清单的应用。';

  @override
  String get mainFeatures => '主要功能：';

  @override
  String get featureGroupSharing => '• 群组共享清单';

  @override
  String get featureRealtimeSync => '• 实时同步';

  @override
  String get featureOfflineSupport => '• 离线支持';

  @override
  String get featureMemberManagement => '• 成员管理';

  @override
  String get accountNotFound => '未找到账号';

  @override
  String get createNew => '新建';

  @override
  String get accountCreated => '账号已创建';

  @override
  String get accountCreationFailed => '创建账号失败';

  @override
  String accountNotFoundBody(String email) => '未找到与 $email 对应的账号。\n要创建新账号吗？';

  @override
  String get signUpRequiredTitle => '需要注册';

  @override
  String get signUpToUseAll => '注册后可使用全部功能';

  @override
  String get later => '稍后';

  @override
  String get scanQRRequiresSignUp => '扫描二维码（需注册）';

  @override
  String get inviteRequiresSignUp => '邀请（需注册）';

  @override
  String get inviteMemberLabel => '邀请成员';

  @override
  String get groupListSharing => '群组列表共享';

  @override
  String get qrInviteFeature => '二维码邀请功能';

  @override
  String get groupInvitation => '群组邀请';

  @override
  String get accept => '接受';

  @override
  String get signInRequired => '需要登录';

  @override
  String get signInRequiredForInvite => '你需要登录后才能接受群组邀请。';

  @override
  String get invitationSavedForLater => '邀请已保存。\n登录后将自动处理。';

  @override
  String get copyData => '复制数据';

  @override
  String get share => '分享';

  @override
  String get enterInviteCode => '输入邀请码';

  @override
  String inviteCodeRecognized(String code) => '已识别邀请码“$code”';

  @override
  String inviteToGroup(String groupName) => '邀请加入“$groupName”';

  @override
  String get friendInvite => '好友邀请';

  @override
  String get friendInviteDesc => '可访问你所有群组';

  @override
  String get individualGroupInvite => '单群组邀请';

  @override
  String get individualGroupInviteDesc => '仅可访问此群组';

  @override
  String get qrScanDialogTitle => '二维码邀请';

  @override
  String get qrScanDialogContent => '扫描群组邀请二维码\n即可加入群组';

  @override
  String get qrManualInputHint => '如果二维码无法扫描，可使用右上角键盘图标手动输入邀请码。';

  @override
  String get inviteGenFailed => '生成邀请失败：';

  @override
  String get qrCodeHereOverlay => '请将二维码置于此处';

  @override
  String get sharedListAppSubtitle => '共享清单应用';

  @override
  String get userNameSetting => '用户名设置';

  @override
  String get userNameSettingDesc => '设置在应用中显示的用户名';

  @override
  String get userNameLabel => '用户名';

  @override
  String get userNameHint => '请输入显示名称';

  @override
  String get userNameRequired => '请输入用户名';

  @override
  String get userNameTooShort => '用户名至少需要2个字符';

  @override
  String get userNameTooLong => '用户名不能超过20个字符';

  @override
  String get itemNameHintMilk => '例如：牛奶';

  @override
  String get intervalNone => '0（无）';

  @override
  String intervalDaysSuffix(int days) => '每 $days 天';

  @override
  String intervalDisplay(int days) => '每 $days 天';

  @override
  String deadlineDisplay(String date) => '截止：$date';

  @override
  String quantityDisplay(int quantity) => '数量：$quantity';

  @override
  String itemDeletedName(String name) => '已删除“$name”';

  @override
  String itemDeleteFailed(String e) => '删除失败：$e';

  @override
  String itemDeleteConfirm(String name) => '要删除“$name”吗？';

  @override
  String get errorOccurred => '发生错误';

  @override
  String get copyGroupTooltip => '复制群组并新建';

  @override
  String get createAccountFailed => '创建账号失败';

  @override
  String groupNameChangedMsg(String name) => '群组名称已更改为“$name”';

  @override
  String get groupNameUpdateFailed => '更新群组名称失败';

  @override
  String memberAddedMsg(String name) => '已添加 $name';

  @override
  String get memberAddFailed => '添加成员失败';

  @override
  String currentRoleLabel(String role) => '当前角色：$role';

  @override
  String get promoteToManager => '提升为管理者';

  @override
  String get demoteToMemberAction => '降级为成员';

  @override
  String get promoteToManagerDesc => '提升为管理者后可邀请成员并编辑列表。';

  @override
  String get demoteToMemberDesc => '降级为成员后将失去管理权限。';

  @override
  String promotedToManager(String name) => '已将 $name 提升为管理者';

  @override
  String demotedToMemberMsg(String name) => '已将 $name 降级为成员';

  @override
  String get doubleTapWhiteboardHint => '双击查看白板';

  @override
  String get doubleTapToOpen => '双击打开';

  @override
  String get doubleTapToView => '双击查看';

  @override
  String get inviteFromPlusButton => '使用右上角 + 按钮\n邀请成员';
}
