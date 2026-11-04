import 'app_texts_en.dart';

/// Traditional Chinese (Taiwan) text implementation.
///
/// This class inherits all base strings from English and overrides
/// high-priority UI keys used across the app.
class AppTextsZhHant extends AppTextsEn {
  // ========================================
  // Common
  // ========================================
  @override
  String get appName => 'GoShopping';

  @override
  String get cancel => '取消';

  @override
  String get save => '儲存';

  @override
  String get delete => '刪除';

  @override
  String get edit => '編輯';

  @override
  String get close => '關閉';

  @override
  String get back => '返回';

  @override
  String get next => '下一步';

  @override
  String get done => '完成';

  @override
  String get loading => '載入中...';

  @override
  String get error => '錯誤';

  @override
  String get retry => '重試';

  @override
  String get confirm => '確認';

  @override
  String get yes => '是';

  @override
  String get no => '否';

  // ========================================
  // Authentication
  // ========================================
  @override
  String get signIn => '登入';

  @override
  String get signUp => '註冊';

  @override
  String get signOut => '登出';

  @override
  String get email => '電子郵件';

  @override
  String get password => '密碼';

  @override
  String get displayName => '顯示名稱';

  @override
  String get createAccount => '建立帳號';

  @override
  String get alreadyHaveAccount => '已經有帳號了嗎？';

  @override
  String get dontHaveAccount => '還沒有帳號嗎？';

  @override
  String get forgotPassword => '忘記密碼？';

  @override
  String get emailRequired => '請輸入電子郵件';

  @override
  String get passwordRequired => '請輸入密碼';

  @override
  String get displayNameRequired => '請輸入顯示名稱';

  @override
  String get invalidEmail => '請輸入有效的電子郵件地址';

  @override
  String get passwordTooShort => '密碼至少需要6個字元';

  // ========================================
  // Group
  // ========================================
  @override
  String get group => '群組';

  @override
  String get groups => '群組';

  @override
  String get createGroup => '建立群組';

  @override
  String get editGroup => '編輯群組';

  @override
  String get deleteGroup => '刪除群組';

  @override
  String get groupName => '群組名稱';

  @override
  String get groupMembers => '成員';

  @override
  String get addMember => '新增成員';

  @override
  String get removeMember => '移除成員';

  @override
  String get owner => '擁有者';

  @override
  String get member => '成員';

  @override
  String get leaveGroup => '退出群組';

  @override
  String get selectGroup => '選擇群組';

  @override
  String get noGroups => '沒有群組';

  @override
  String get groupCreated => '群組已建立';

  @override
  String get groupDeleted => '群組已刪除';

  @override
  String get groupUpdated => '群組已更新';

  @override
  String get groupNameRequired => '請輸入群組名稱';

  @override
  String get duplicateGroupName => '該群組名稱已被使用';

  @override
  String get confirmDeleteGroup => '確定要刪除此群組嗎？';

  @override
  String get current => '目前';

  @override
  String get noCurrentGroup => '未選擇群組';

  @override
  String get loadingGroups => '正在載入群組...';

  @override
  String get preparingGroup => '正在準備群組...';

  @override
  String get groupLoadFailed => '載入群組失敗';

  @override
  String get createFirstGroupHint => '建立你的第一個群組，\n或掃描QR碼加入';

  @override
  String get createGroupHint => '點選 + 按鈕建立群組';

  @override
  String initialSetupDesc(String listName) =>
      '與群組共享$listName。\n請先建立群組\n或加入現有群組。';

  @override
  String get createFirstGroup => '建立第一個群組';

  @override
  String get joinGroupByQR => '透過QR碼加入群組';

  @override
  String get createGroupFailed => '建立群組失敗';

  @override
  String get deleteGroupWarning => '此操作無法復原。\n群組的所有資料將被刪除。';

  @override
  String get leavingGroup => '正在退出群組...';

  @override
  String get creatingGroup => '正在建立群組...';

  @override
  String get manager => '管理員';

  @override
  String get partner => '協作者';

  // ========================================
  // List
  // ========================================
  @override
  String get list => '清單';

  @override
  String get lists => '清單';

  @override
  String get createList => '建立清單';

  @override
  String get editList => '編輯清單';

  @override
  String get deleteList => '刪除清單';

  @override
  String get listName => '清單名稱';

  @override
  String get sharedList => '共享清單';

  @override
  String get selectList => '選擇清單';

  @override
  String get noLists => '沒有清單';

  @override
  String get listCreated => '清單已建立';

  @override
  String get listDeleted => '清單已刪除';

  @override
  String get listUpdated => '清單已更新';

  @override
  String get listNameRequired => '請輸入清單名稱';

  @override
  String get duplicateListName => '該清單名稱已被使用';

  @override
  String get confirmDeleteList => '確定要刪除此清單嗎？';

  @override
  String get defaultShoppingListName => '購物清單';

  // ========================================
  // Item
  // ========================================
  @override
  String get item => '項目';

  @override
  String get items => '項目';

  @override
  String get addItem => '新增項目';

  @override
  String get editItem => '編輯項目';

  @override
  String get deleteItem => '刪除項目';

  @override
  String get itemName => '項目名稱';

  @override
  String get quantity => '數量';

  @override
  String get purchased => '已購買';

  @override
  String get notPurchased => '未購買';

  @override
  String get noItems => '沒有項目';

  @override
  String get itemAdded => '項目已新增';

  @override
  String get itemDeleted => '項目已刪除';

  @override
  String get itemUpdated => '項目已更新';

  @override
  String get itemNameRequired => '請輸入項目名稱';

  @override
  String get confirmDeleteItem => '確定要刪除此項目嗎？';

  @override
  String get markAsPurchased => '標記為已購買';

  @override
  String get markAsNotPurchased => '標記為未購買';

  @override
  String get addShoppingItem => '新增購物項目';

  @override
  String get productName => '商品名稱';

  @override
  String get quantityRequired => '請輸入數量';

  @override
  String get quantityInvalid => '請輸入有效數量（1或以上）';

  // ========================================
  // QR / Invitation
  // ========================================
  @override
  String get invitation => '邀請';

  @override
  String get inviteMembers => '邀請成員';

  @override
  String get scanQRCode => '掃描QR碼';

  @override
  String get generateQRCode => '產生QR碼';

  @override
  String get acceptInvitation => '接受邀請';

  @override
  String get invitationAccepted => '邀請已接受';

  @override
  String get invitationExpired => '邀請已過期';

  @override
  String get invitationInvalid => '無效邀請';

  @override
  String get alreadyMember => '已是成員';

  @override
  String get scanningQRCode => '正在掃描QR碼...';

  @override
  String get qrCodeGenerated => 'QR碼已產生';

  @override
  String get qrCodeInvite => 'QR碼邀請';

  @override
  String get processingInvitation => '正在處理邀請...';

  @override
  String get cannotScanOwnCode => '不能掃描自己的邀請碼';

  // ========================================
  // Settings / Notifications / Whiteboard
  // ========================================
  @override
  String get settings => '設定';

  @override
  String get profile => '個人資料';

  @override
  String get notifications => '通知';

  @override
  String get language => '語言';

  @override
  String get theme => '主題';

  @override
  String get about => '關於';

  @override
  String get version => '版本';

  @override
  String get privacyPolicy => '隱私政策';

  @override
  String get termsOfService => '服務條款';

  @override
  String get commercialDisclosure => '特定商業交易法披露（日本）';

  @override
  String get subscriptionNotesTitle => '訂閱說明';

  @override
  String get subscriptionNotesBody => '• 確認購買後，費用將從您的 Apple ID 帳戶中扣除。\n'
      '• 訂閱會自動續訂，除非在目前有效期結束前至少 24 小時關閉自動續訂。\n'
      '• 帳戶將在目前有效期結束前的 24 小時內扣除續訂費用。\n'
      '• 購買後，您可以前往 App Store 帳戶設定管理訂閱並關閉自動續訂。';

  @override
  String get subscriptionPreReleaseTitle => '預先開放中';

  @override
  String get subscriptionPreReleaseBody => '目前為預先開放階段，暫不接受 Premium 方案的訂閱。';

  @override
  String subscriptionSalesStartNotice(int year, int month) =>
      '付費功能預計於$year年$month月開放。';

  @override
  String get preOpenBenefitTitle => '預先開放特典使用中';

  @override
  String preOpenBenefitBody(int year, int month, int day) =>
      '感謝您在預先開放期間註冊，$year年$month月$day日前可使用相當於 Premium 的功能（無廣告、更多群組和成員）。';

  @override
  String get premiumPlanTitle => 'Premium 方案';

  @override
  String get premiumPlanActiveTitle => 'Premium 方案使用中';

  @override
  String get premiumPlanDetailsLink => '方案內容與價格';

  @override
  String get purchaseProcessing => '處理中';

  @override
  String purchaseEnablePremium(String price) => '啟用 Premium ($price)';

  @override
  String purchaseEnablePremiumYearly(String price) => '啟用年付 Premium ($price)';

  @override
  String get purchaseStoreUnavailable =>
      '無法連線到應用程式商店。請在裝有應用程式商店的 Android 或 iOS 裝置上重試。';

  @override
  String get purchaseProductUnavailable =>
      '無法從應用程式商店取得 Premium 商品。請確認用於購買的商店帳號和應用程式安裝來源。';

  @override
  String get purchaseRestoreButton => '回復購買';

  @override
  String subscriptionPreReleaseBlocked(int year, int month) =>
      '目前處於預先開放階段，無法購買 Premium 方案。付費功能預計於$year年$month月開放。';

  @override
  String get purchaseStatusCheckFailed => '無法確認購買狀態。請稍後再試。';

  @override
  String get purchaseInProgressAtStore => '正在應用程式商店中進行購買。';

  @override
  String get purchaseFailed => '購買過程中發生錯誤。';

  @override
  String get purchaseRestoreChecking => '正在確認購買記錄。';

  @override
  String get purchaseRestoreChecked => '已確認購買記錄。如有可回復的購買，將自動生效。';

  @override
  String get purchaseRestoreFailed => '無法回復購買。';

  @override
  String get purchaseApplyFailed => '無法套用購買狀態。請嘗試回復購買。';

  @override
  String get purchasePendingConfirmation => '正在確認購買。';

  @override
  String get purchaseEarlyBenefitActivated => '提前下載特典已生效。';

  @override
  String get purchasePremiumRestored => '已回復 Premium 方案。';

  @override
  String get purchasePremiumActivated => 'Premium 方案已生效。';

  @override
  String get purchaseErrorFallback => '處理購買時發生錯誤。';

  @override
  String get purchaseCanceled => '購買已取消。';

  @override
  String get logout => '登出';

  @override
  String get deleteAccount => '刪除帳號';

  @override
  String get confirmDeleteAccount => '確定要刪除帳號嗎？此操作無法復原。';

  @override
  String get notification => '通知';

  @override
  String get notificationHistory => '通知歷史';

  @override
  String get markAsRead => '標記為已讀';

  @override
  String get deleteNotification => '刪除通知';

  @override
  String get noNotifications => '沒有通知';

  @override
  String get whiteboard => '白板';

  @override
  String get drawingMode => '繪圖模式';

  @override
  String get scrollMode => '捲動模式';

  @override
  String get penColor => '畫筆顏色';

  @override
  String get penWidth => '畫筆粗細';

  @override
  String get eraseAll => '全部清除';

  @override
  String get undo => '復原';

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
  String get syncFailed => '同步失敗';

  @override
  String get manualSync => '手動同步';

  @override
  String get lastSyncTime => '上次同步時間';

  @override
  String get offlineMode => '離線模式';

  @override
  String get onlineMode => '線上模式';

  @override
  String get networkError => '發生網路錯誤';

  @override
  String get serverError => '發生伺服器錯誤';

  @override
  String get unknownError => '發生未知錯誤';

  @override
  String get permissionDenied => '權限被拒絕';

  @override
  String get authenticationRequired => '需要認證';

  @override
  String get operationFailed => '操作失敗';

  @override
  String get tryAgainLater => '請稍後重試';

  @override
  String get today => '今天';

  @override
  String get yesterday => '昨天';

  @override
  String get daysAgo => '天前';

  @override
  String get hoursAgo => '小時前';

  @override
  String get minutesAgo => '分鐘前';

  @override
  String get justNow => '剛剛';

  @override
  String get person => '人';

  @override
  String get people => '人';

  @override
  String get areYouSure => '確定嗎？';

  @override
  String get cannotBeUndone => '此操作無法復原';

  @override
  String get continueAction => '繼續';

  @override
  String get cancelAction => '取消';

  // ========================================
  // Home / Auth helpers
  // ========================================
  @override
  String get home => '首頁';

  @override
  String get signedOut => '已登出';

  @override
  String get signOutError => '登出失敗';

  @override
  String get displayNameHint => '例如：Taro';

  @override
  String get displayNameHelper => '該名稱將顯示給群組成員';

  @override
  String get passwordHint => '至少6個字元';

  @override
  String welcomeUser(String name) => '帳號建立成功！歡迎，$name';

  @override
  String featureRequiresSignUp(String feature) => '要使用$feature';

  @override
  String get signUpRequiredMsg => '需要註冊';

  @override
  String get welcomeToGoShop => '歡迎使用 GoShopping！';

  @override
  String get welcomeSubtitle => '與家人或群組共享清單，\n讓管理更便捷';

  @override
  String get availableFeatures => '✨ 可用功能';

  @override
  String personalListCreate(String listType) => '建立個人$listType';

  @override
  String get signUpPromptBody => '使用此功能需要帳號。\n'
      '註冊後可使用：\n\n'
      '• 群組共享清單\n'
      '• 便捷QR碼邀請\n'
      '• 成員管理\n'
      '• 備份與資料同步';

  // ========================================
  // Sync / status icons
  // ========================================
  @override
  String get syncManagement => '同步管理';

  @override
  String get syncingFirestore => '從 Firestore 同步';

  @override
  String get clearCache => '清除快取';

  @override
  String get clearCacheTitle => '清除快取';

  @override
  String get clearCacheConfirm => '要清除本機快取嗎？\n下次啟動時將從 Firestore 重新取得資料。';

  @override
  String get clearCacheSuccess => '快取已清除';

  @override
  String get debugLabel => '除錯';

  @override
  String get onlineStatus => '線上狀態';

  @override
  String get connected => '已連線';

  @override
  String get offline => '離線';

  @override
  String get localModeNoSync => '本機模式（不同步）';

  @override
  String get syncStatusSynced => '已同步';

  @override
  String get syncStatusSyncing => '同步中...';

  @override
  String get syncStatusOffline => '已中斷連線';

  @override
  String get syncStatusNotLoggedIn => '未登入';

  @override
  String get networkOfflineStatus => '網路故障';

  @override
  String get checkingConnectionStatus => '正在檢查連線...';

  @override
  String get notSignedIn => '未登入';

  // ========================================
  // Invitation / QR
  // ========================================
  @override
  String get qrCodeReader => 'QR碼讀取器';

  @override
  String get manualInput => '手動輸入';

  @override
  String get enter8CharCode => '請輸入8位字母數字邀請碼';

  @override
  String get invalidQRFormat => 'QR碼格式無效';

  @override
  String get checkCameraPermission => '請檢查相機權限';

  @override
  String get inviteType => '邀請類型';

  @override
  String get inviteByQRTitle => '透過QR碼邀請';

  @override
  String get scanQRToJoinDesc => '掃描此QR碼即可加入群組';

  @override
  String maxInviteCount(int n) => '最多邀請人數：$n';

  @override
  String get qrScanInstruction => '將QR碼對準取景框';

  @override
  String get qrScanButton => '掃描QR碼';

  @override
  String get checkingInviteCode => '正在檢查邀請碼...';

  @override
  String get tooltipManualInput => '手動輸入邀請碼';

  // ========================================
  // Help / menus
  // ========================================
  @override
  String get help => '說明';

  @override
  String get helpTitle => '說明';

  @override
  String get errorHistory => '錯誤歷史';

  @override
  String get versionInfo => '版本資訊';

  @override
  String get legalTitle => '法律資訊';

  @override
  String get versionInfoTitle => '版本資訊';

  @override
  String get versionLabel => '版本';

  @override
  String get buildNumberLabel => '建置編號';

  @override
  String get packageNameLabel => '套件名稱';

  @override
  String get appFooterSubtitle => '共享應用程式';

  @override
  String get displayLanguageTitle => '顯示語言 / Display Language';

  @override
  String get displayLanguageDesc => '選擇應用程式語言（重新啟動後可完全生效）';

  @override
  String get languageJa => '日文';

  @override
  String get languageChangedEn => '語言已切換為繁體中文。重新啟動後可完全生效。';

  @override
  String get languageChangedJa => '語言已切換為日文。重新啟動後可完全生效。';

  @override
  String get settingsPagePlaceholder => '設定頁面（臨時）';

  @override
  String get goShopSettingsLabel => 'Go Shop 設定';

  @override
  String get checkingAuthStatus => '正在檢查認證狀態...';

  @override
  String get errorOccurredTitle => '發生錯誤';

  @override
  String get appModeTitle => '應用程式模式';

  @override
  String get appModeDesc => '可在購物清單與任務共享之間切換';

  @override
  String get shoppingListMode => '購物清單模式';

  @override
  String get todoShareMode => '任務共享模式';

  @override
  String modeChanged(String modeName) => '模式已切換為：$modeName';

  @override
  String get switchedToMultiMode => '已切換到多模式';
  @override
  String get multiModeHint => '如需使用多個群組和清單，請在設定中切換到多模式';
  @override
  String get openSettings => '開啟設定';
  @override
  String get groupLimitExceededTitle => '群組數量超出了目前方案的上限';
  @override
  String groupLimitExceededMessage(int groupCount, int maxGroups) =>
      '目前方案最多可使用$maxGroups個群組（現有$groupCount個）。'
      '如需使用清單，請刪除${groupCount - maxGroups}個群組'
      '（以成員身份加入的群組可以退出）。';
  @override
  String get listBlockedByGroupLimit => '群組數量超出上限，無法開啟清單頁面';
  @override
  String get openGroupPage => '開啟群組頁面';

  @override
  String get selectGroupBeforeSwitch => '切換前請先選擇群組';

  @override
  String get selectListBeforeSwitch => '切換前請先選擇清單';

  @override
  String get switchedToSingleMode => '已切換到單模式';

  @override
  String get adPrivacyOptionsTitle => '廣告隱私設定';
  @override
  String get adPrivacyOptionsDesc =>
      '根據您所在國家或地區的法規，您可以隨時更改同意設定，或選擇退出廣告個性化及個人資料的使用。';
  @override
  String get adPrivacyOptionsButton => '管理隱私選項';
  @override
  String get multiModeAdConsentRequired =>
      '由於您尚未同意廣告，無法切換到多模式。同意廣告後即可使用多模式。';
  @override
  String get multiModeAdConsentRequiredWithPremium =>
      '由於您尚未同意廣告，無法切換到多模式。同意廣告或訂閱 Premium 方案後即可使用多模式。';
  @override
  String get adConsentAgainButton => '同意廣告';
  @override
  String get familyCouponTitle => '家庭優惠券';
  @override
  String familyCouponSponsorDesc(int limit) =>
      '將此優惠券告訴家人後，加入您群組的最多 $limit 位家人可以使用與 Premium 相同的功能（包括無廣告）。僅在您的 Premium 有效期間可用。';
  @override
  String get familyCouponCopy => '複製';
  @override
  String get familyCouponCopied => '已複製優惠券';
  @override
  String familyCouponMembers(int count, int limit) =>
      '正在使用優惠的家人（$count/$limit 人）';
  @override
  String get familyCouponNoMembers => '還沒有家人使用此優惠';
  @override
  String get familyCouponRemove => '解除';
  @override
  String get familyCouponRemoveConfirmTitle => '要解除家庭優惠嗎？';
  @override
  String familyCouponRemoveConfirmBody(String name) =>
      '將解除 $name 的家庭優惠。解除後會空出 1 個名額。';
  @override
  String get familyCouponRemoved => '已解除家庭優惠';
  @override
  String get familyCouponRedeemDesc =>
      '如果家人在使用 Premium，輸入從該家人處獲得的優惠券即可使用與 Premium 相同的功能。輸入前需要已加入該家人的群組。';
  @override
  String get familyCouponInputHint => '優惠券（例：ABCD-EFGH）';
  @override
  String get familyCouponRedeemButton => '領取優惠';
  @override
  String familyCouponRedeemed(String name) =>
      '已啟用來自 $name 的家庭優惠';
  @override
  String familyBenefitActive(String name) =>
      '正在透過 $name 的家庭優惠使用 Premium 功能';
  @override
  String familyBenefitSuspended(String name) =>
      '由於 $name 的 Premium 無效，家庭優惠已暫停。$name 的 Premium 恢復後會自動恢復。';
  @override
  String get familyNameUnknown => '您的家人';
  @override
  String familyCouponError(String reason) => switch (reason) {
      'invalid-code' => '優惠券無效',
      'own-coupon' => '不能使用自己的優惠券',
      'not-family' => '您未加入發行此優惠券的人的群組，無法使用',
      'sponsor-inactive' => '發行此優惠券的人的 Premium 未生效',
      'limit-reached' => '此優惠券的使用人數已達上限',
      'already-member' => '您已在使用此優惠券',
      'other-benefit-active' => '您已在使用其他家庭優惠',
      'not-premium' => '僅在 Premium 有效期間可以發行優惠券',
      _ => '無法處理優惠券，請稍後再試',
    };
  @override
  String get whiteboardSettingsTitle => '白板設定';

  @override
  String get customColorSettingsTitle => '自訂顏色設定';

  @override
  String get customColorSettingsDesc => '除4種基礎顏色（黑、紅、綠、黃）外，還可設定2種自訂顏色';

  @override
  String colorSlot(int n) => '顏色$n: ';

  @override
  String get errorWithPrefix => '錯誤';

  @override
  String get notificationSettings => '通知設定';

  @override
  String get listChangeNotificationSettings => '清單變更通知設定';

  @override
  String get listChangeNotification => '清單變更通知';

  @override
  String get listChangeNotificationDesc => '當清單項目有變更時接收通知';

  @override
  String get listNotificationOn => '通知已開啟';

  @override
  String get listNotificationOff => '通知已關閉';

  @override
  String get viewNotificationHistory => '檢視通知歷史';

  @override
  String get feedbackSectionTitle => '傳送意見回饋';

  @override
  String get feedbackSectionDesc => '歡迎告訴我們你的意見';

  @override
  String get feedbackSectionSubDesc => '說明我們改進測試版，約需1分鐘。';

  @override
  String get feedbackButton => '填寫問卷';

  @override
  String get feedbackThanks => '感謝你的意見回饋！';

  @override
  String get formOpenFailed => '無法開啟表單';

  @override
  String get reauthRequired => '需要重新驗證';

  @override
  String get reauthDescription => '刪除帳號前，請輸入目前密碼。';

  @override
  String get finalConfirmation => '最終確認';

  @override
  String get deleteCompletely => '徹底刪除';

  @override
  String get deletingAccount => '正在刪除帳號...';

  @override
  String get deletingAccountProgress => '正在移除帳號資料，請稍候。';

  @override
  String get authError => '認證錯誤';

  @override
  String get wrongPassword => '密碼錯誤';

  @override
  String get authFailed => '認證失敗';

  @override
  String get deletionComplete => '刪除完成';

  @override
  String get deletionFailed => '刪除失敗';

  @override
  String get deleteAccountAndData => '刪除帳號和資料';

  @override
  String get cannotUndoWarning => '此操作無法復原';

  @override
  String deleteAccountWarningBody(String listName) =>
      '⚠️ 此操作無法復原\n\n以下資料將被永久刪除：\n• 帳號資訊\n• 所有$listName\n• 你擁有的群組\n• 白板資料\n• 通知歷史\n\n確定要刪除嗎？';

  @override
  String finalConfirmationBody(String email) =>
      '電子郵件：$email\n\n確定要刪除此帳號嗎？\n\n此操作無法復原。';

  @override
  String get deletionCompleteBody => '你的帳號和所有資料已刪除。\n\n感謝使用 Go Shop。';

  @override
  String deletionFailedBody(String e) => '刪除帳號時發生錯誤。\n\n錯誤資訊：\n$e\n\n請聯絡開發者。';

  // ========================================
  // Notification templates
  // ========================================
  @override
  String notifListCreated(String name, String list) => '$name 建立了 "$list"';

  @override
  String notifListDeleted(String name, String list) => '$name 刪除了 "$list"';

  @override
  String notifRenamed(String name, String oldName, String newName) =>
      '$name 將 "$oldName" 重新命名為 "$newName"';

  @override
  String notifMemberJoined(String name, String group) => '$name 加入了 "$group"';

  @override
  String notifMembershipApproved(String group) =>
      group.isNotEmpty ? '你已加入 "$group"' : '你的加入申請已通過';

  @override
  String notifGroupDeleted(String name, String group) => '$name 刪除了 "$group"';

  @override
  String notifMemberLeft(String name, String group) => '$name 離開了 "$group"';

  @override
  String notifYouLeft(String group) => '你已離開 "$group"';

  @override
  String notifItemAdded(String name, String item, String list) =>
      '$name 在 "$list" 中新增了 "$item"';

  @override
  String notifItemRemoved(String name, String item, String list) =>
      '$name 從 "$list" 中移除了 "$item"';

  @override
  String notifItemPurchased(String name, String item, String list) =>
      '$name 在 "$list" 中購買了 "$item"';

  @override
  String notifWhiteboardUpdated(String name) => '$name 更新了白板';

  @override
  String notifWhiteboardEditStarted(String name) => '$name 開始在白板上繪製';

  @override
  String notifWhiteboardEditEnded(String name) => '$name 結束了白板繪製';

  // ========================================
  // Operation labels
  // ========================================
  @override
  String get opSignIn => '登入';

  @override
  String get opCreateAccount => '建立帳號';

  @override
  String get opSaveUserName => '儲存使用者名稱';

  @override
  String get opResetPassword => '重設密碼';

  @override
  String get opSignUp => '註冊';

  @override
  String get opAddMember => '新增成員';

  @override
  String get opUpdateGroupName => '更新群組名稱';

  @override
  String get opSaveWhiteboard => '儲存白板';

  @override
  String get opClearWhiteboard => '清空白板';

  @override
  String get opUpdatePurchaseStatus => '更新購買狀態';
  @override
  String get opPremiumPurchase => '購買 Premium';
  @override
  String get opRestorePurchases => '回復購買';

  @override
  String get opUpdateGroupMember => '更新群組成員';

  @override
  String get opSendNotification => '傳送通知';

  @override
  String get opLoadUserName => '載入使用者名稱';

  @override
  String get opUpdateAllGroupUserNames => '更新所有群組使用者名稱';

  @override
  String get opGetGroupUserName => '取得群組使用者名稱';

  @override
  String get opGetGroupMembers => '取得群組成員';

  @override
  String get opSignOutClear => '登出時清理';

  @override
  String get opGetFirestoreUserName => '取得 Firestore 使用者名稱';

  @override
  String get opSaveFirestoreUserName => '儲存 Firestore 使用者名稱';

  @override
  String get opDeleteFirestoreUserName => '刪除 Firestore 使用者名稱';

  @override
  String get opCreateUserProfile => '建立使用者資料';

  @override
  String get opSaveBillingType => '儲存計費類型';

  @override
  String get opSearchInvitableGroups => '搜尋可邀請群組';

  @override
  String get opSendInvite => '傳送邀請';

  @override
  String get opAcceptInvitation => '接受邀請';

  @override
  String get opSearchPendingInvitations => '搜尋待處理邀請';

  @override
  String get opRecordInvitation => '記錄邀請';

  @override
  String get opGetPendingInvitations => '取得待處理邀請';

  @override
  String get opMarkInvitationProcessed => '標記邀請已處理';

  @override
  String get opDeleteInvitation => '刪除邀請';

  @override
  String get opCreateQrInvite => '建立QR碼邀請';

  @override
  String get opDecodeQrCode => '解析QR碼';

  @override
  String get opGetQrInviteDetails => '取得QR碼邀請詳情';

  @override
  String get opAcceptQrInvite => '接受QR碼邀請';

  // ========================================
  // Tips / help
  // ========================================
  @override
  String get tipsLabel => '提示';

  @override
  String get tipTapTitle => '基礎：點選';

  @override
  String get tipTapBody => '點選可切換項目狀態、選擇目前群組等。';

  @override
  String get tipDoubleTapTitle => '進階：雙擊';

  @override
  String get tipDoubleTapBody => '雙擊可編輯項目、檢視成員白板等。';

  @override
  String get tipLongPressTitle => '安全操作：長按';

  @override
  String get tipLongPressBody => '刪除項目、退出群組等破壞性操作請使用長按。';

  @override
  String get tipGroupScreenTitle => '群組頁面';

  @override
  String get tipGroupScreenBody => '點選 -> 設為目前，雙擊 -> 管理成員，長按 -> 刪除/退出。';

  @override
  String get tipMemberScreenTitle => '成員頁面';

  @override
  String get tipMemberScreenBody => '點選 -> 修改角色（擁有者）或檢視資訊，雙擊 -> 白板。';

  @override
  String get helpBasicUsage => '基本使用';

  @override
  String helpBasicUsagePoint(int n) {
    const points = [
      '建立群組並邀請成員',
      '共享清單並即時同步',
      '新增項目並標記為已購買',
    ];
    return n >= 1 && n <= points.length ? points[n - 1] : '';
  }

  @override
  String get helpGroupInvite => '群組邀請';

  @override
  String helpGroupInvitePoint(int n) {
    const points = [
      '展示QR碼以邀請成員',
      '掃描QR碼加入群組',
      '邀請有效期24小時，最多5名成員',
    ];
    return n >= 1 && n <= points.length ? points[n - 1] : '';
  }

  @override
  String get helpSyncIcons => '同步狀態圖示';

  @override
  String helpSyncIconPoint(int n) {
    const points = [
      '🟢 綠色：已同步',
      '🟠 橙色：同步中',
      '🔴 紅色：已中斷連線',
      '⚪ 灰色：未登入',
    ];
    return n >= 1 && n <= points.length ? points[n - 1] : '';
  }

  @override
  String get howToInviteTitle => '邀請方法';

  @override
  String get howToInviteDesc => '1. 讓對方掃描QR碼\n'
      '2. 對方在應用程式中接受後會自動加入成員\n'
      '3. 收到接受通知後請在群組中確認';

  // ========================================
  // Error / notification history details
  // ========================================
  @override
  String get noErrorHistory => '沒有錯誤歷史';

  @override
  String get markReadAndClose => '標記為已讀並關閉';

  @override
  String get markedAsRead => '已標記為已讀';

  @override
  String get deleteReadErrors => '刪除已讀錯誤';

  @override
  String get deleteReadErrorsConfirm => '要刪除所有已讀錯誤記錄嗎？\n此操作無法復原。';

  @override
  String get noReadNotifications => '沒有已讀通知';

  @override
  String markedReadFailed(String e) => '標記已讀失敗：$e';

  @override
  String deletedErrorLogs(int count) => '已刪除 $count 條錯誤記錄';

  @override
  String deleteErrorLogFailed(String e) => '刪除錯誤記錄失敗：$e';

  @override
  String deletedReadNotifications(int count) => '已刪除 $count 條已讀通知';

  // ========================================
  // Invitation accept / member management
  // ========================================
  @override
  String get inviteAcceptTitle => '接受邀請';

  @override
  String get inviteAcceptDesc => '被邀請加入群組了嗎？\n請掃描QR碼或輸入邀請碼。';

  @override
  String get invalidQRCodeMsg => 'QR碼格式無效';

  @override
  String get cameraErrorPrefix => '相機錯誤：';

  @override
  String get unknownGroup => '未知群組';

  @override
  String invitationPendingApproval(String groupName) => '等待 $groupName 審核';

  @override
  String get groupInfo => '群組資訊';

  @override
  String get inviteOnlyForAdmins => '僅擁有者、管理員和協作者可邀請成員';

  @override
  String get selectInviteMethod => '請選擇邀請方式';

  @override
  String get noMembers => '沒有成員';

  @override
  String get inviteMemberHint => '使用右上角 + 按鈕\n邀請成員';

  @override
  String get memberListLabel => '成員清單';

  @override
  String get recommendPortrait => '建議使用直向畫面';

  @override
  String memberCount(int count) => '成員：$count';

  @override
  String ownerDisplay(String name) => '擁有者：$name';

  @override
  String syncErrorMessage(String error) => '同步錯誤：$error';

  // ========================================
  // Misc helper labels
  // ========================================
  @override
  String get currentPrefix => '目前';

  @override
  String get saving => '儲存中...';

  @override
  String get saveUserName => '儲存使用者名稱';

  @override
  String get userNameSaved => '使用者名稱已儲存';

  @override
  String saveFailed(Object e) => '儲存失敗：$e';

  // ========================================
  // Additional auth / onboarding
  // ========================================
  @override
  String get loginOrRegister => '登入 / 註冊';

  @override
  String get login => '登入';

  @override
  String get register => '註冊';

  @override
  String get saveEmail => '儲存電子郵件';

  @override
  String get enterUserName => '請輸入使用者名稱';

  @override
  String get signUpFailed => '建立帳號失敗';

  @override
  String get emailAlreadyInUse => '該電子郵件已被使用';

  @override
  String get weakPassword => '密碼強度過弱';

  @override
  String get signInFailed => '登入失敗';

  @override
  String get userNotFoundSignIn => '未找到使用者，請先建立帳號';

  @override
  String get wrongEmailOrPassword => '電子郵件或密碼錯誤';

  @override
  String get switchToSignIn => '切換到登入';

  @override
  String get switchToCreateAccount => '切換到建立帳號';

  @override
  String get resetPassword => '重設密碼';

  @override
  String get rememberEmail => '記住電子郵件';

  @override
  String get forNewUsers => '新使用者指南';

  @override
  String get howToUse => '使用方法';

  @override
  String get noTasks => '沒有任務';

  @override
  String get noShoppingItems => '沒有購物項目';

  @override
  String get privacyAbout => '隱私說明';

  @override
  String get forNewUsersDesc => '請使用電子郵件和密碼建立帳號或登入。\n若已有帳號，請使用相同憑證登入。';

  @override
  String howToUsePoint(int n) {
    const points = [
      '在底部「群組」標籤管理群組',
      '選擇群組後檢視該群組清單',
      '透過QR碼邀請家人和朋友',
      '在「設定」標籤中設定應用程式',
    ];
    return n >= 1 && n <= points.length ? points[n - 1] : '';
  }

  @override
  String get privacyPoint1 => '初始僅共享登入資訊和顯示名稱';

  @override
  String get privacyPoint2 => '清單僅與你共享給的使用者可見';

  @override
  String get privacyPoint3 => '加入你群組的使用者同樣遵循此政策';

  @override
  String get privacyPoint4 => '使用本應用程式需要 Firebase 帳號';

  // ========================================
  // Additional mode / list-item helpers
  // ========================================
  @override
  String get create => '建立';

  @override
  String get update => '更新';

  @override
  String get add => '新增';

  @override
  String get leave => '離開';

  @override
  String get managementMode => '管理模式';

  @override
  String get singleModeLabel => '單模式';

  @override
  String get multiModeLabel => '多模式';

  @override
  String get singleModeDesc => '單模式：一個群組和一個清單';

  @override
  String get multiModeDesc => '多模式：管理多個群組和清單';

  @override
  String get switchToSingleMode => '切換到單模式';

  @override
  String get switchToSingleModeBody => '僅顯示目前群組和清單。\n其他資料不會被刪除。';

  @override
  String get doSwitch => '切換';

  @override
  String get selectGroupFirst => '請先選擇群組';

  @override
  String get noGroupSelected => '未選擇群組';

  @override
  String get descriptionOptional => '說明（可選）';

  @override
  String get editTask => '編輯任務';

  @override
  String get addTask => '新增任務';

  @override
  String get purchaseIntervalOptional => '購買間隔（可選）';

  @override
  String get perDay => '每天';

  @override
  String get perWeek => '每週';

  @override
  String get perMonth => '每月';

  @override
  String get noRepeatPurchase => '不重複';

  @override
  String get selectDeadlineOptional => '設定截止日期（可選）';

  @override
  String get deadlineMustBeFuture => '截止日期必須是今天或之後';

  // ========================================
  // Additional news / feedback
  // ========================================
  @override
  String get newsPanelTitle => '📰 新聞與公告';

  @override
  String get newsCardTitle => '新聞';

  @override
  String get newsLoading => '正在載入新聞...';

  @override
  String get thankYou => '感謝你的意見回饋！';

  @override
  String get surveyAction => '填寫問卷';

  @override
  String get remindLater => '稍後提醒';

  @override
  String get premiumPlan => 'Premium 方案';

  @override
  String get remindTomorrow => '明天提醒';

  @override
  String get cannotOpenLink => '無法開啟連結';

  @override
  String get invalidLink => '無效連結';

  @override
  String get thanks => '謝謝！';

  @override
  String cannotOpenForm(String e) => '無法開啟表單：$e';

  // ========================================
  // Notification/error history detail labels
  // ========================================
  @override
  String get weeksAgo => ' 週前';

  @override
  String get monthsAgo => ' 個月前';

  @override
  String get yearsAgo => ' 年前';

  @override
  String get timeUnknown => '未知時間';

  @override
  String get unread => '未讀';

  @override
  String get tooltipMarkRead => '標記為已讀';

  @override
  String get tooltipDeleteRead => '刪除已讀通知';

  @override
  String get tooltipReload => '重新載入';

  @override
  String get firestoreIndexRequired => '需要 Firestore 索引';

  @override
  String get firestoreIndexDesc => '請在 Firebase Console 建立複合索引';

  @override
  String get errorWithDetail => '發生錯誤：';

  @override
  String get unknownOperation => '未知操作';

  @override
  String get noErrorDetailMsg => '沒有錯誤詳情';

  @override
  String get permissionErrorLabel => '權限錯誤';

  @override
  String get networkErrorLabel => '網路錯誤';

  @override
  String get syncErrorLabel => '同步錯誤';

  @override
  String get validationErrorLabel => '驗證錯誤';

  @override
  String get operationErrorLabel => '操作錯誤';

  @override
  String get unknownErrorLabel => '未知錯誤';

  @override
  String get operationLabel => '操作';

  @override
  String get messageLabel => '訊息';

  @override
  String get occurredAtLabel => '發生時間';

  @override
  String get contextLabel => '上下文';

  @override
  String get stackTraceLabel => '堆疊追蹤：';

  // ========================================
  // Group details / copy members
  // ========================================
  @override
  String get aboutGroups => '關於群組';

  @override
  String get aboutGroupsDesc => '• 在群組內共享清單\n'
      '• 可為家庭、朋友、工作建立多個群組\n'
      '• 可透過QR碼輕鬆邀請和加入';

  @override
  String get copyMembersFrom => '從現有群組複製成員（可選）：';

  @override
  String get selectGroupHint => '請選擇群組...';

  @override
  String get newGroupNoMembers => '新群組（無成員）';

  @override
  String get selectMembersToCopy => '請選擇要複製的成員和角色：';

  @override
  String get noMembersInGroup => '所選群組中沒有成員';

  @override
  String get selectGroupToCopyMembers => '請選擇一個現有群組以複製其成員';

  @override
  String get leaveGroupWarning => '你的資訊將從該群組中移除。\n若要重新加入需再次邀請。';

  @override
  String get leaveRequestSent => '退出請求已傳送。處理完成後該群組將消失。';

  @override
  String get deletingGroup => '正在刪除群組...';

  @override
  String get groupNameHint => '例如：家庭、朋友、工作';

  // ========================================
  // Invitation methods / member management
  // ========================================
  @override
  String get inviteByQR => '透過QR碼邀請';

  @override
  String get inviteByQRDesc => '產生QR碼供對方掃描';

  @override
  String get inviteByEmail => '透過電子郵件邀請';

  @override
  String get inviteByEmailDesc => '向指定電子郵件傳送邀請';

  @override
  String get addMemberManually => '手動新增成員';

  @override
  String get addMemberManuallyDesc => '直接輸入成員資訊';

  @override
  String get enterEmailToInvite => '請輸入要邀請的電子郵件地址';

  @override
  String get sendInvitation => '傳送邀請';

  @override
  String get emailInviteUnavailable => '電子郵件邀請不可用，請使用QR碼邀請。';

  @override
  String get enterGroupName => '請輸入群組名稱';

  @override
  String get generateInviteCode => '產生新邀請碼';

  @override
  String get inviteManagement => '邀請管理';

  @override
  String get activeInviteCodes => '有效邀請碼';

  @override
  String get noActiveInvites => '沒有有效邀請碼';

  @override
  String get deleteInviteCode => '刪除邀請';

  @override
  String get deleteInviteCodeConfirm => '確定要刪除此邀請碼嗎？';

  @override
  String get copy => '複製';

  @override
  String get selectFromPool => '從池中選擇';

  @override
  String get newMember => '新成員';

  @override
  String get noMembersInPool => '成員池中無成員';

  @override
  String get promoteToAdmin => '提升為管理員';

  @override
  String get demoteToMember => '降級為成員';

  @override
  String get promote => '提升';

  @override
  String get demote => '降級';

  @override
  String get invitationResults => '邀請結果';

  @override
  String get errorDetails => '錯誤詳情：';

  @override
  String promotedToAdmin(String name) => '$name 已提升為管理員';

  @override
  String demotedToMember(String name) => '$name 已降級為成員';

  @override
  String sendInvitationsCount(int count) => '傳送邀請（$count）';

  @override
  String get checkingInvitations => '正在檢查邀請...';

  @override
  String get processAll => '全部處理';

  @override
  String get rejectInvitation => '拒絕邀請';

  @override
  String get reject => '拒絕';

  @override
  String get invitationStats => '邀請統計';

  @override
  String get joinGroup => '加入群組';

  @override
  String get joinGroupQuestion => '要加入以下群組嗎？';

  @override
  String get join => '加入';

  @override
  String joinAsRole(String role) => '以 $role 身份加入';

  @override
  String approvedJoin(String name) => '已批准 $name 的加入請求';

  @override
  String rejectConfirm(String name) => '要拒絕 $name 的加入請求嗎？';

  @override
  String rejectedInvite(String name) => '已拒絕 $name 的邀請';

  @override
  String alreadyJoinedGroup(String name) => '已是 "$name" 的成員';

  // ========================================
  // Premium / migration / mode-dependent names
  // ========================================
  @override
  String get trialStarted => '免費試用已開始';

  @override
  String get startTrial => '開始試用';

  @override
  String get resetToFree => '還原為免費方案';

  @override
  String get selectPlan => '選擇';

  @override
  String get upgradedToAnnualPlan => '已升級為年費方案！';

  @override
  String get upgradedTo3YearPlan => '已升級為3年方案！';

  @override
  String get groupManagement => '群組管理';

  @override
  String get noGroupData => '沒有群組資料';

  @override
  String get featureInProgress => '功能開發中';

  @override
  String get addGroupInProgress => '新增群組功能正在開發中。';

  @override
  String get toPremium => '升級到 Premium';

  @override
  String get premiumBenefits => '✨ Premium 權益';

  @override
  String get benefitNoAds => '• 無廣告';

  @override
  String get benefitPremiumSupport => '• 優先支援';

  @override
  String get benefitEarlyAccess => '• 新功能搶先體驗';

  @override
  String get pricePlan => '價格方案';

  @override
  String get userChangedDetected => '偵測到使用者變更';

  @override
  String get differentUserLoggedIn => '偵測到其他使用者已登入。';

  @override
  String userPrevious(String user) => '之前：$user';

  @override
  String userCurrent(String user) => '目前：$user';

  @override
  String get whatToDoWithOldData => '如何處理舊資料？';

  @override
  String get dataMigrationDescription => '• 保留：現有群組和清單將遷移\n'
      '• 清除：為新使用者從零開始';

  @override
  String get clearData => '清除';

  @override
  String get keepData => '保留';

  @override
  String get secretModeEnabled => '秘密模式已啟用';

  @override
  String get groupDataRequiresLogin => '請先登入以檢視群組資料';

  @override
  String get newGroup => '新群組';

  @override
  String signInToUseGroup(String groupName) => '登入後可使用 $groupName 功能';

  @override
  String get noSharedList => '沒有清單';

  @override
  String createNewSharedList(String listName) => '建立新的$listName';

  @override
  String duplicateListNameAlert(String name) => '名為「$name」的清單已存在';

  @override
  String deleteListConfirm(String name) => '要刪除「$name」嗎？';

  @override
  String get listCreateHint => '例如：週末購物';

  @override
  String sharedListNameForMode(bool isShopping) => isShopping ? '購物清單' : '任務清單';

  @override
  String groupNameForMode(bool isShopping) => isShopping ? '群組' : '團隊';

  // ========================================
  // Final remaining keys
  // ========================================
  @override
  String get ok => '確定';

  @override
  String get initPreparingApp => '正在準備應用程式...';

  @override
  String get initCheckingData => '正在檢查資料...';

  @override
  String get initPreparingUser => '正在準備使用者資料...';

  @override
  String get initReady => '準備完成';

  @override
  String get initErrorButContinue => '初始化發生錯誤，但將繼續執行...';

  @override
  String get initPreparingService => '正在準備服務...';

  @override
  String get initSyncingGroups => '正在同步群組資料...';

  @override
  String get pieces => '';

  @override
  String get dataMaintenance => '資料維護';

  @override
  String get cleanupData => '清理資料';

  @override
  String get enableNotifications => '啟用通知';

  @override
  String get createWhiteboard => '建立白板';

  @override
  String get editWhiteboard => '編輯白板';

  @override
  String get deleteWhiteboard => '刪除白板';

  @override
  String get whiteboards => '白板';

  @override
  String get whiteboardName => '白板名稱';

  @override
  String get zoom => '縮放';

  @override
  String get appDescription => '可與家人和群組共享購物清單的應用程式。';

  @override
  String get mainFeatures => '主要功能：';

  @override
  String get featureGroupSharing => '• 群組共享清單';

  @override
  String get featureRealtimeSync => '• 即時同步';

  @override
  String get featureOfflineSupport => '• 離線支援';

  @override
  String get featureMemberManagement => '• 成員管理';

  @override
  String get accountNotFound => '未找到帳號';

  @override
  String get createNew => '建立';

  @override
  String get accountCreated => '帳號已建立';

  @override
  String get accountCreationFailed => '建立帳號失敗';

  @override
  String accountNotFoundBody(String email) => '未找到與 $email 對應的帳號。\n要建立新帳號嗎？';

  @override
  String get signUpRequiredTitle => '需要註冊';

  @override
  String get signUpToUseAll => '註冊後可使用全部功能';

  @override
  String get later => '稍後';

  @override
  String get scanQRRequiresSignUp => '掃描QR碼（需註冊）';

  @override
  String get inviteRequiresSignUp => '邀請（需註冊）';

  @override
  String get inviteMemberLabel => '邀請成員';

  @override
  String get groupListSharing => '群組清單共享';

  @override
  String get qrInviteFeature => 'QR碼邀請功能';

  @override
  String get groupInvitation => '群組邀請';

  @override
  String get accept => '接受';

  @override
  String get signInRequired => '需要登入';

  @override
  String get signInRequiredForInvite => '你需要登入後才能接受群組邀請。';

  @override
  String get invitationSavedForLater => '邀請已儲存。\n登入後將自動處理。';

  @override
  String get copyData => '複製資料';

  @override
  String get share => '分享';

  @override
  String get enterInviteCode => '輸入邀請碼';

  @override
  String inviteCodeRecognized(String code) => '已識別邀請碼「$code」';

  @override
  String inviteToGroup(String groupName) => '邀請加入「$groupName」';

  @override
  String get friendInvite => '好友邀請';

  @override
  String get friendInviteDesc => '可存取你所有群組';

  @override
  String get individualGroupInvite => '單群組邀請';

  @override
  String get individualGroupInviteDesc => '僅可存取此群組';

  @override
  String get qrScanDialogTitle => 'QR碼邀請';

  @override
  String get qrScanDialogContent => '掃描群組邀請QR碼\n即可加入群組';

  @override
  String get qrManualInputHint => '如果QR碼無法掃描，可使用右上角鍵盤圖示手動輸入邀請碼。';

  @override
  String get inviteGenFailed => '產生邀請失敗：';

  @override
  String get qrCodeHereOverlay => '請將QR碼置於此處';

  @override
  String get sharedListAppSubtitle => '共享清單應用程式';

  @override
  String get userNameSetting => '使用者名稱設定';

  @override
  String get userNameSettingDesc => '設定在應用程式中顯示的使用者名稱';

  @override
  String get userNameLabel => '使用者名稱';

  @override
  String get userNameHint => '請輸入顯示名稱';

  @override
  String get userNameRequired => '請輸入使用者名稱';

  @override
  String get userNameTooShort => '使用者名稱至少需要2個字元';

  @override
  String get userNameTooLong => '使用者名稱不能超過20個字元';

  @override
  String get itemNameHintMilk => '例如：牛奶';

  @override
  String get intervalNone => '0（無）';

  @override
  String intervalDaysSuffix(int days) => '每 $days 天';

  @override
  String intervalDisplay(int days) => '每 $days 天';

  @override
  String deadlineDisplay(String date) => '截止：$date';

  @override
  String quantityDisplay(int quantity) => '數量：$quantity';

  @override
  String itemDeletedName(String name) => '已刪除「$name」';

  @override
  String itemDeleteFailed(String e) => '刪除失敗：$e';

  @override
  String itemDeleteConfirm(String name) => '要刪除「$name」嗎？';

  @override
  String get errorOccurred => '發生錯誤';

  @override
  String get copyGroupTooltip => '複製群組並建立';

  @override
  String get createAccountFailed => '建立帳號失敗';

  @override
  String groupNameChangedMsg(String name) => '群組名稱已更改為「$name」';

  @override
  String get groupNameUpdateFailed => '更新群組名稱失敗';

  @override
  String memberAddedMsg(String name) => '已新增 $name';

  @override
  String get memberAddFailed => '新增成員失敗';

  @override
  String currentRoleLabel(String role) => '目前角色：$role';

  @override
  String get promoteToManager => '提升為管理者';

  @override
  String get demoteToMemberAction => '降級為成員';

  @override
  String get promoteToManagerDesc => '提升為管理者後可邀請成員並編輯清單。';

  @override
  String get demoteToMemberDesc => '降級為成員後將失去管理權限。';

  @override
  String promotedToManager(String name) => '已將 $name 提升為管理者';

  @override
  String demotedToMemberMsg(String name) => '已將 $name 降級為成員';

  @override
  String get doubleTapWhiteboardHint => '雙擊檢視白板';

  @override
  String get doubleTapToOpen => '雙擊開啟';

  @override
  String get doubleTapToView => '雙擊檢視';

  @override
  String get inviteFromPlusButton => '使用右上角 + 按鈕\n邀請成員';
}
