import 'app_texts.dart';

/// 日本語テキスト実装
class AppTextsJa extends AppTexts {
  // ========================================
  // 共通
  // ========================================
  @override
  String get appName => 'GoShopping';

  @override
  String get ok => 'OK';

  @override
  String get cancel => 'キャンセル';

  @override
  String get save => '保存';

  @override
  String get delete => '削除';

  @override
  String get edit => '編集';

  @override
  String get close => '閉じる';

  @override
  String get back => '戻る';

  @override
  String get next => '次へ';

  @override
  String get done => '完了';

  @override
  String get loading => '読み込み中...';

  @override
  String get error => 'エラー';

  @override
  String get retry => '再試行';

  @override
  String get confirm => '確認';

  @override
  String get yes => 'はい';

  @override
  String get no => 'いいえ';

  // ========================================
  // 認証
  // ========================================
  @override
  String get signIn => 'サインイン';

  @override
  String get signUp => 'アカウント作成';

  @override
  String get signOut => 'サインアウト';

  @override
  String get email => 'メールアドレス';

  @override
  String get password => 'パスワード';

  @override
  String get displayName => 'ディスプレイネーム';

  @override
  String get createAccount => 'アカウントを作成';

  @override
  String get alreadyHaveAccount => '既にアカウントをお持ちですか？';

  @override
  String get dontHaveAccount => 'アカウントをお持ちでないですか？';

  @override
  String get forgotPassword => 'パスワードを忘れた場合';

  @override
  String get emailRequired => 'メールアドレスを入力してください';

  @override
  String get passwordRequired => 'パスワードを入力してください';

  @override
  String get displayNameRequired => 'ディスプレイネームを入力してください';

  @override
  String get invalidEmail => 'メールアドレスの形式が正しくありません';

  @override
  String get passwordTooShort => 'パスワードは6文字以上で入力してください';

  // ========================================
  // グループ
  // ========================================
  @override
  String get group => 'グループ';

  @override
  String get groups => 'グループ一覧';

  @override
  String get createGroup => 'グループを作成';

  @override
  String get editGroup => 'グループを編集';

  @override
  String get deleteGroup => 'グループを削除';

  @override
  String get groupName => 'グループ名';

  @override
  String get groupMembers => 'メンバー';

  @override
  String get addMember => 'メンバーを追加';

  @override
  String get removeMember => 'メンバーを削除';

  @override
  String get owner => 'オーナー';

  @override
  String get member => 'メンバー';

  @override
  String get leaveGroup => 'グループから退出';

  @override
  String get selectGroup => 'グループを選択';

  @override
  String get noGroups => 'グループがありません';

  @override
  String get groupCreated => 'グループを作成しました';

  @override
  String get groupDeleted => 'グループを削除しました';

  @override
  String get groupUpdated => 'グループを更新しました';

  @override
  String get groupNameRequired => 'グループ名を入力してください';

  @override
  String get duplicateGroupName => 'そのグループ名は既に使用されています';

  @override
  String get confirmDeleteGroup => 'このグループを削除してもよろしいですか？';

  // ========================================
  // リスト
  // ========================================
  @override
  String get list => 'リスト';

  @override
  String get lists => 'リスト一覧';

  @override
  String get createList => 'リストを作成';

  @override
  String get editList => 'リストを編集';

  @override
  String get deleteList => 'リストを削除';

  @override
  String get listName => 'リスト名';

  @override
  String get sharedList => '共有リスト';

  @override
  String get selectList => 'リストを選択';

  @override
  String get noLists => 'リストがありません';

  @override
  String get listCreated => 'リストを作成しました';

  @override
  String get listDeleted => 'リストを削除しました';

  @override
  String get listUpdated => 'リストを更新しました';

  @override
  String get listNameRequired => 'リスト名を入力してください';

  @override
  String get duplicateListName => 'そのリスト名は既に使用されています';

  @override
  String get confirmDeleteList => 'このリストを削除してもよろしいですか？';

  // ========================================
  // アイテム
  // ========================================
  @override
  String get item => 'アイテム';

  @override
  String get items => 'アイテム一覧';

  @override
  String get addItem => 'アイテムを追加';

  @override
  String get editItem => 'アイテムを編集';

  @override
  String get deleteItem => 'アイテムを削除';

  @override
  String get itemName => 'アイテム名';

  @override
  String get quantity => '数量';

  @override
  String get purchased => '購入済み';

  @override
  String get notPurchased => '未購入';

  @override
  String get noItems => 'アイテムがありません';

  @override
  String get itemAdded => 'アイテムを追加しました';

  @override
  String get itemDeleted => 'アイテムを削除しました';

  @override
  String get itemUpdated => 'アイテムを更新しました';

  @override
  String get itemNameRequired => 'アイテム名を入力してください';

  @override
  String get confirmDeleteItem => 'このアイテムを削除してもよろしいですか？';

  @override
  String get markAsPurchased => '購入済みにする';

  @override
  String get markAsNotPurchased => '未購入にする';

  // ========================================
  // QR招待
  // ========================================
  @override
  String get invitation => '招待';

  @override
  String get inviteMembers => 'メンバーを招待';

  @override
  String get scanQRCode => 'QRコードをスキャン';

  @override
  String get generateQRCode => 'QRコードを生成';

  @override
  String get acceptInvitation => '招待を受け入れる';

  @override
  String get invitationAccepted => '招待を受け入れました';

  @override
  String get invitationExpired => '招待の有効期限が切れています';

  @override
  String get invitationInvalid => '招待が無効です';

  @override
  String get alreadyMember => '既にメンバーです';

  @override
  String get scanningQRCode => 'QRコードをスキャン中...';

  @override
  String get qrCodeGenerated => 'QRコードを生成しました';

  // ========================================
  // 設定
  // ========================================
  @override
  String get settings => '設定';

  @override
  String get profile => 'プロフィール';

  @override
  String get notifications => '通知';

  @override
  String get language => '言語';

  @override
  String get theme => 'テーマ';

  @override
  String get about => 'アプリについて';

  @override
  String get version => 'バージョン';

  @override
  String get privacyPolicy => 'プライバシーポリシー';

  @override
  String get termsOfService => '利用規約';

  @override
  String get logout => 'ログアウト';

  @override
  String get deleteAccount => 'アカウントを削除';

  @override
  String get confirmDeleteAccount => 'アカウントを削除してもよろしいですか？この操作は取り消せません。';

  // ========================================
  // 通知
  // ========================================
  @override
  String get notification => '通知';

  @override
  String get notificationHistory => '通知履歴';

  @override
  String get markAsRead => '既読にする';

  @override
  String get deleteNotification => '通知を削除';

  @override
  String get noNotifications => '通知がありません';

  @override
  String get notificationSettings => '通知設定';

  @override
  String get enableNotifications => '通知を有効にする';

  // ========================================
  // ホワイトボード
  // ========================================
  @override
  String get whiteboard => 'ホワイトボード';

  @override
  String get whiteboards => 'ホワイトボード一覧';

  @override
  String get createWhiteboard => 'ホワイトボードを作成';

  @override
  String get editWhiteboard => 'ホワイトボードを編集';

  @override
  String get deleteWhiteboard => 'ホワイトボードを削除';

  @override
  String get whiteboardName => 'ホワイトボード名';

  @override
  String get drawingMode => '描画モード';

  @override
  String get scrollMode => 'スクロールモード';

  @override
  String get penColor => 'ペンの色';

  @override
  String get penWidth => 'ペンの太さ';

  @override
  String get eraseAll => '全消去';

  @override
  String get undo => '元に戻す';

  @override
  String get redo => 'やり直す';

  @override
  String get zoom => 'ズーム';

  // ========================================
  // 同期・データ管理
  // ========================================
  @override
  String get sync => '同期';

  @override
  String get syncing => '同期中...';

  @override
  String get syncCompleted => '同期完了';

  @override
  String get syncFailed => '同期に失敗しました';

  @override
  String get manualSync => '手動同期';

  @override
  String get lastSyncTime => '最終同期時刻';

  @override
  String get offlineMode => 'オフラインモード';

  @override
  String get onlineMode => 'オンラインモード';

  @override
  String get dataMaintenance => 'データメンテナンス';

  @override
  String get cleanupData => 'データをクリーンアップ';

  // ========================================
  // エラーメッセージ
  // ========================================
  @override
  String get networkError => 'ネットワークエラーが発生しました';

  @override
  String get serverError => 'サーバーエラーが発生しました';

  @override
  String get unknownError => '不明なエラーが発生しました';

  @override
  String get permissionDenied => '権限がありません';

  @override
  String get authenticationRequired => '認証が必要です';

  @override
  String get operationFailed => '操作に失敗しました';

  @override
  String get tryAgainLater => '後でもう一度お試しください';

  // ========================================
  // 日時・単位
  // ========================================
  @override
  String get today => '今日';

  @override
  String get yesterday => '昨日';

  @override
  String get daysAgo => '日前';

  @override
  String get hoursAgo => '時間前';

  @override
  String get minutesAgo => '分前';

  @override
  String get justNow => 'たった今';

  @override
  String get pieces => '個';

  @override
  String get person => '人';

  @override
  String get people => '人';

  // ========================================
  // アクション確認
  // ========================================
  @override
  String get areYouSure => 'よろしいですか？';

  @override
  String get cannotBeUndone => 'この操作は取り消せません';

  @override
  String get continueAction => '続ける';

  @override
  String get cancelAction => 'キャンセル';

  @override
  String get sharedListAppSubtitle => 'リスト共有アプリ';

  @override
  String get switchToSignIn => 'サインインへ';

  @override
  String get switchToCreateAccount => 'アカウント作成へ';

  @override
  String get rememberEmail => 'メールアドレスを保存';

  @override
  String get forNewUsers => '初めての方へ';

  @override
  String get howToUse => 'アプリの使い方';

  @override
  String get noTasks => 'タスクがありません';

  @override
  String get noShoppingItems => '買い物アイテムがありません';

  @override
  String get privacyAbout => 'プライバシーについて';

  @override
  String get create => '作成';
  @override
  String get update => '更新';
  @override
  String get add => '追加';
  @override
  String get leave => '退出';

  @override
  String get current => 'カレント';
  @override
  String get noCurrentGroup => 'カレントグループが選択されていません';
  @override
  String get loadingGroups => 'グループを読み込み中...';
  @override
  String get preparingGroup => 'デフォルトグループを準備しています';
  @override
  String get groupLoadFailed => 'グループの読み込みに失敗しました';
  @override
  String get createFirstGroupHint => '最初のグループを作成するか\nQRコードをスキャンして参加してください';
  @override
  String get createGroupHint => '右下の ＋ ボタンからグループを作成できます';
  @override
  String get deleteGroupWarning => 'この操作は取り消せません。\nグループ内のすべてのデータが削除されます。';
  @override
  String get leaveGroupWarning => 'あなたの情報がこのグループから削除されます。\n再度参加するには、招待が必要です。';
  @override
  String get deletingGroup => 'グループを削除中...';
  @override
  String get leavingGroup => 'グループを退出中...';
  @override
  String get copyMembersFrom => 'メンバーをコピーする既存グループ (任意):';
  @override
  String get selectGroupHint => 'グループを選択...';
  @override
  String get newGroupNoMembers => '新しいグループ (メンバーなし)';
  @override
  String get selectMembersToCopy => 'コピーするメンバーとその役割を選択:';
  @override
  String get noMembersInGroup => '選択されたグループにはメンバーがいません';
  @override
  String get selectGroupToCopyMembers => '既存グループを選択するとメンバーをコピーできます';
  @override
  String get creatingGroup => 'グループを作成中...';
  @override
  String get manager => '管理者';
  @override
  String get partner => 'パートナー';

  @override
  String get selectGroupFirst => 'グループ画面でグループを選択してください';
  @override
  String get noGroupSelected => 'グループが選択されていません';
  @override
  String get descriptionOptional => '説明（任意）';
  @override
  String get editTask => 'タスクを編集';
  @override
  String get addTask => 'タスクを追加';
  @override
  String get addShoppingItem => '買い物アイテムを追加';
  @override
  String get productName => '商品名';
  @override
  String get purchaseIntervalOptional => '購入間隔（任意）';
  @override
  String get perDay => '日ごと';
  @override
  String get perWeek => '週ごと';
  @override
  String get perMonth => 'ヶ月ごと';
  @override
  String get noRepeatPurchase => '繰り返し購入なし';
  @override
  String get selectDeadlineOptional => '購入期限を選択（任意）';
  @override
  String get quantityRequired => '数量を入力してください';
  @override
  String get quantityInvalid => '数量は1以上の数値を入力してください';
  @override
  String get deadlineMustBeFuture => '期限は本日以降の日付を選択してください';

  // UI管理モード
  @override
  String get managementMode => '管理モード';
  @override
  String get singleModeLabel => 'シングル';
  @override
  String get multiModeLabel => 'マルチ';
  @override
  String get singleModeDesc => 'シングルモード：1グループ・1リストで使用';
  @override
  String get multiModeDesc => 'マルチモード：複数のグループ・リストを管理';
  @override
  String get switchToSingleMode => 'シングルモードに切り替え';
  @override
  String get switchToSingleModeBody =>
      '現在のカレントグループとカレントリストのみ表示されます。\n他のデータは削除されません。';
  @override
  String get switchedToSingleMode => 'シングルモードに切り替えました';
  @override
  String get switchedToMultiMode => 'マルチモードに切り替えました';
  @override
  String get selectGroupBeforeSwitch => 'グループを選択してからシングルモードに切り替えてください';
  @override
  String get selectListBeforeSwitch => 'カレントリストを選択してからシングルモードに切り替えてください';
  @override
  String get doSwitch => '切り替える';

  // グループメンバー管理
  @override
  String get groupInfo => 'グループ情報';
  @override
  String get inviteOnlyForAdmins => 'メンバーを招待できるのはオーナー、管理者、パートナーのみです';
  @override
  String get errorOccurred => 'エラーが発生しました';
  @override
  String get copyGroupTooltip => 'このグループをコピーして新規作成';
  @override
  String get inviteByQR => 'QRコードで招待';
  @override
  String get inviteByQRDesc => 'QRコードを生成して相手にスキャンしてもらう';
  @override
  String get inviteByEmail => 'メールで招待';
  @override
  String get inviteByEmailDesc => 'メールアドレスを指定して招待を送信';
  @override
  String get addMemberManually => '手動でメンバー追加';
  @override
  String get addMemberManuallyDesc => 'メンバー情報を直接入力';
  @override
  String get enterEmailToInvite => '招待するメールアドレスを入力してください';
  @override
  String get sendInvitation => '招待を送信';
  @override
  String get emailInviteUnavailable => 'メール招待は利用できません。QR招待をご利用ください。';
  @override
  String get enterGroupName => 'グループ名を入力してください';

  // アカウント削除
  @override
  String get reauthRequired => '再認証が必要です';
  @override
  String get reauthDescription => 'セキュリティのため、パスワードを再入力してください。';
  @override
  String get finalConfirmation => '最終確認';
  @override
  String get deleteCompletely => '完全に削除';
  @override
  String get deletingAccount => 'アカウントを削除中...';
  @override
  String get deletingAccountProgress => 'データ削除 → 認証削除';
  @override
  String get authError => '認証エラー';
  @override
  String get wrongPassword => 'パスワードが正しくありません。';
  @override
  String get authFailed => '認証に失敗しました。';

  // QR招待
  @override
  String get qrCodeInvite => 'QRコード招待';
  @override
  String get copyData => 'データをコピー';
  @override
  String get share => '共有';
  @override
  String get processingInvitation => '招待を処理中...';
  @override
  String get cannotScanOwnCode => '自分自身の招待コードはスキャンできません';
  @override
  String get groupInvitation => 'グループ招待';
  @override
  String get accept => '受諾';
  @override
  String get signInRequired => 'サインインが必要です';
  @override
  String get signInRequiredForInvite => 'グループ招待を受諾するにはサインインが必要です。';
  @override
  String get invitationSavedForLater => '招待情報を保存しました。\nサインイン後に自動的に処理されます。';

  // その他UIラベル
  @override
  String get memberListLabel => 'メンバーリスト';
  @override
  String get selectInviteMethod => 'メンバー招待方法を選択';
  @override
  String get noMembers => 'メンバーがいません';
  @override
  String get inviteMemberHint => '右上の + ボタンから\nメンバーを招待してください';
  @override
  String get recommendPortrait => '縦向きでの使用を推奨します';

  // 共通メニュー / AppBar
  @override
  String get errorHistory => 'エラー履歴';
  @override
  String get help => 'ヘルプ';
  @override
  String get versionInfo => 'バージョン情報';

  // 認証パネル
  @override
  String get loginOrRegister => 'ログイン・新規登録';
  @override
  String get login => 'ログイン';
  @override
  String get register => '新規登録';
  @override
  String get saveEmail => 'メールアドレスを保存する';
  @override
  String get enterUserName => 'ユーザー名を入力してください';

  // アカウント削除（追加）
  @override
  String get deletionComplete => '削除完了';
  @override
  String get deletionFailed => '削除失敗';
  @override
  String get deleteAccountAndData => 'アカウントと全てのデータを完全に削除します';
  @override
  String get cannotUndoWarning => '⚠️ この操作は取り消せません';

  // ボトムナビ / ホーム
  @override
  String get home => 'ホーム';
  @override
  String get signedOut => 'ログアウトしました';
  @override
  String get signOutError => 'ログアウトエラー';
  @override
  String get displayNameHint => '例: 太郎';
  @override
  String get displayNameHelper => 'グループメンバーに表示される名前です';
  @override
  String get passwordHint => '6文字以上';
  @override
  String welcomeUser(String name) => 'アカウントを作成しました！ようこそ、$nameさん';
  // 同期管理ウィジェット
  @override
  String get syncManagement => '同期管理';
  @override
  String get syncingFirestore => 'Firestoreから同期';
  @override
  String get clearCache => 'キャッシュクリア';
  @override
  String get clearCacheTitle => 'キャッシュクリア';
  @override
  String get clearCacheConfirm =>
      'ローカルキャッシュをクリアしますか？\n次回起動時にFirestoreから再取得されます。';
  @override
  String get clearCacheSuccess => 'キャッシュをクリアしました';
  @override
  String get debugLabel => 'デバッグ用';
  @override
  String get onlineStatus => 'オンライン状態';
  @override
  String get connected => '接続中';
  @override
  String get offline => 'オフライン';
  @override
  String get localModeNoSync => 'ローカルモード（同期機能なし）';

  // 認証・アカウント（追加）
  @override
  String get appDescription => '家族やグループで買い物リストを共有できるアプリです。';
  @override
  String get mainFeatures => '主な機能:';
  @override
  String get featureGroupSharing => '• グループでの買い物リストの共有';
  @override
  String get featureRealtimeSync => '• リアルタイム同期';
  @override
  String get featureOfflineSupport => '• オフライン対応';
  @override
  String get featureMemberManagement => '• メンバー管理';
  @override
  String get accountNotFound => 'アカウントが見つかりません';
  @override
  String get createNew => '新規作成';
  @override
  String get signUpRequiredTitle => 'サインアップが必要です';
  @override
  String get signUpToUseAll => 'サインアップして全機能を利用';
  @override
  String get later => '後で';
  @override
  String get scanQRRequiresSignUp => 'QRコード（要サインアップ）';
  @override
  String get inviteRequiresSignUp => '招待（要サインアップ）';
  @override
  String get inviteMemberLabel => 'メンバー招待';
  @override
  String get groupListSharing => 'グループでのリスト共有';
  @override
  String get qrInviteFeature => 'QRコード招待機能';
  @override
  String get accountCreated => 'アカウントを作成しました';
  @override
  String get accountCreationFailed => 'アカウント作成に失敗しました';
  @override
  String accountNotFoundBody(String email) =>
      '$email のアカウントが見つかりません。\n新規アカウントを作成しますか？';

  // 招待・メンバー管理（追加）
  @override
  String get generateInviteCode => '新しい招待コードを生成';
  @override
  String get deleteInviteCode => '招待を削除';
  @override
  String get deleteInviteCodeConfirm => 'この招待コードを削除しますか？';
  @override
  String get inviteManagement => '招待管理';
  @override
  String get activeInviteCodes => '有効な招待コード';
  @override
  String get noActiveInvites => '有効な招待コードはありません';
  @override
  String get copy => 'コピー';
  @override
  String get selectFromPool => 'プールから選択';
  @override
  String get newMember => '新規メンバー';
  @override
  String get noMembersInPool => 'プールにメンバーがいません';
  @override
  String get promoteToAdmin => '管理者に昇格';
  @override
  String get demoteToMember => 'メンバーに降格';
  @override
  String get promote => '昇格';
  @override
  String get demote => '降格';
  @override
  String get invitationResults => '招待結果';
  @override
  String get errorDetails => 'エラー詳細:';
  @override
  String promotedToAdmin(String name) => '$name さんを管理者に昇格しました';
  @override
  String demotedToMember(String name) => '$name さんをメンバーに降格しました';
  @override
  String sendInvitationsCount(int count) => '招待を送信 ($count個)';

  // QR・スキャン（追加）
  @override
  String get qrCodeReader => 'QRコード読み取り';
  @override
  String get manualInput => '手動入力';
  @override
  String get enter8CharCode => '8桁の英数字を入力してください';
  @override
  String get invalidQRFormat => '無効なQRコード形式です';
  @override
  String get checkCameraPermission => 'カメラの権限を確認してください';
  @override
  String get individualGroupInvite => '個別グループ招待';
  @override
  String get individualGroupInviteDesc => 'このグループのみにアクセス可能';
  @override
  String get friendInvite => 'フレンド招待';
  @override
  String get friendInviteDesc => 'あなたのすべてのグループにアクセス可能';
  @override
  String get enterInviteCode => '招待コードを入力';
  @override
  String inviteCodeRecognized(String code) => '招待コード「$code」を認識しました';
  @override
  String inviteToGroup(String groupName) => '「$groupName」への招待';

  // 招待モニター（追加）
  @override
  String get checkingInvitations => '招待状況を確認中...';
  @override
  String get processAll => 'すべて処理';
  @override
  String get rejectInvitation => '招待を拒否';
  @override
  String get reject => '拒否';
  @override
  String get invitationStats => '招待統計';
  @override
  String get joinGroup => 'グループに参加';
  @override
  String get joinGroupQuestion => '以下のグループに参加しますか？';
  @override
  String get join => '参加する';
  @override
  String joinAsRole(String role) => '$role として参加';
  @override
  String approvedJoin(String name) => '$name の参加を承認しました';
  @override
  String rejectConfirm(String name) => '$name の参加を拒否しますか？';
  @override
  String rejectedInvite(String name) => '$name の招待を拒否しました';
  @override
  String alreadyJoinedGroup(String name) => 'すでに「$name」に参加しています';

  // エラー・通知履歴（追加）
  @override
  String get noErrorHistory => 'エラー履歴はありません';
  @override
  String get markReadAndClose => '既読にして閉じる';
  @override
  String get markedAsRead => '既読にしました';
  @override
  String get deleteReadErrors => '既読エラーを削除';
  @override
  String get deleteReadErrorsConfirm => '既読のエラーログをすべて削除しますか？\nこの操作は元に戻せません。';
  @override
  String get noReadNotifications => '既読通知はありません';
  @override
  String markedReadFailed(String e) => '既読にできませんでした: $e';
  @override
  String deletedErrorLogs(int count) => '$count件のエラーログを削除しました';
  @override
  String deleteErrorLogFailed(String e) => 'エラーログの削除に失敗しました: $e';
  @override
  String deletedReadNotifications(int count) => '$count件の既読通知を削除しました';

  // ニュース・フィードバック（追加）
  @override
  String get thankYou => 'ご協力ありがとうございます！';
  @override
  String get surveyAction => 'アンケートに答える';
  @override
  String get remindLater => '後でお願いします';
  @override
  String get premiumPlan => 'プレミアムプラン';
  @override
  String get remindTomorrow => '明日また通知します';
  @override
  String get cannotOpenLink => 'リンクを開けませんでした';
  @override
  String get invalidLink => 'リンクが無効です';
  @override
  String get thanks => 'ありがとうございます！';
  @override
  String cannotOpenForm(String e) => 'フォームを開けませんでした: $e';

  // プレミアム・広告（追加）
  @override
  String get trialStarted => '無料体験を開始しました';
  @override
  String get startTrial => '体験開始';
  @override
  String get resetToFree => '無料プランにリセットしました';
  @override
  String get selectPlan => '選択';
  @override
  String get upgradedToAnnualPlan => '年間プランにアップグレードしました！';
  @override
  String get upgradedTo3YearPlan => '3年プランにアップグレードしました！';
  @override
  String get groupManagement => 'グループ管理';
  @override
  String get noGroupData => 'グループデータがありません';
  @override
  String get featureInProgress => '機能準備中';
  @override
  String get addGroupInProgress => 'グループ追加機能は現在準備中です。';
  @override
  String get toPremium => 'プレミアムへ';
  @override
  String get premiumBenefits => '✨ プレミアム特典';
  @override
  String get benefitNoAds => '• 広告の完全非表示';
  @override
  String get benefitPremiumSupport => '• プレミアムサポート';
  @override
  String get benefitEarlyAccess => '• 新機能の優先アクセス';
  @override
  String get pricePlan => '料金プラン';
  @override
  String get userChangedDetected => 'ユーザー変更を検知';
  @override
  String get differentUserLoggedIn => '異なるユーザーでログインしました。';
  @override
  String userPrevious(String user) => '前回: $user';
  @override
  String userCurrent(String user) => '今回: $user';
  @override
  String get whatToDoWithOldData => '以前のデータをどうしますか？';
  @override
  String get dataMigrationDescription =>
      '• 引き継ぐ: 既存のグループとショッピングリストが新しいユーザーに移行されます\n• 消去: 新しいユーザー用に空の状態から開始します';
  @override
  String get clearData => '消去';
  @override
  String get keepData => '引き継ぐ';
  @override
  String get secretModeEnabled => 'シークレットモードが有効です';
  @override
  String get groupDataRequiresLogin => 'グループデータを表示するにはログインが必要です';
  @override
  String get newGroup => '新しいグループ';
  @override
  String signInToUseGroup(String groupName) =>
      '$groupName機能を使用するには、まずサインインしてください';
  @override
  String get noSharedList => 'リストがありません';
  @override
  String createNewSharedList(String listName) => '新しい$listNameを作成';
  @override
  String duplicateListNameAlert(String name) => '「$name」という名前のリストは既に存在します';
  @override
  String deleteListConfirm(String name) => '「$name」を削除しますか？';
  @override
  String get listCreateHint => '例: 週末の買い物';
  @override
  String get listChangeNotification => 'リスト変更通知';
  @override
  String get listChangeNotificationDesc => 'アイテムの追加・削除・購入完了を5分ごとに通知';
  @override
  String get listNotificationOn => 'リスト変更通知をオンにしました';
  @override
  String get listNotificationOff => 'リスト変更通知をオフにしました';
  @override
  String get viewNotificationHistory => '通知履歴を見る';
  @override
  String get listChangeNotificationSettings => 'リスト変更通知の設定';
  @override
  String get shoppingListMode => '買い物リスト';
  @override
  String get todoShareMode => 'TODO共有';
  @override
  String modeChanged(String modeName) => 'モードを「$modeName」に変更しました';
  @override
  String get userNameSetting => 'ユーザー名設定';
  @override
  String get userNameSettingDesc => 'アプリ内で表示されるユーザー名を設定してください';
  @override
  String get userNameLabel => 'ユーザー名';
  @override
  String get userNameHint => '表示名を入力してください';
  @override
  String get userNameRequired => 'ユーザー名を入力してください';
  @override
  String get userNameTooShort => 'ユーザー名は2文字以上で入力してください';
  @override
  String get userNameTooLong => 'ユーザー名は20文字以内で入力してください';
  @override
  String get saving => '保存中...';
  @override
  String get saveUserName => 'ユーザー名を保存';
  @override
  String get userNameSaved => 'ユーザー名を保存しました';
  @override
  String saveFailed(Object e) => '保存に失敗しました: $e';
  @override
  String get currentPrefix => '現在';
  @override
  String get newsPanelTitle => '📰 ニュース・お知らせ';
  @override
  String get newsCardTitle => 'ニュース';
  @override
  String get newsLoading => 'ニュースを読み込み中...';
  @override
  String get tipsLabel => 'Tips';
  @override
  String get tipTapTitle => '基本操作: タップ';
  @override
  String get tipTapBody => 'アイテムの購入状態切替、グループのカレント選択などメイン操作はタップで行えます。';
  @override
  String get tipDoubleTapTitle => '骸技: ダブルタップ';
  @override
  String get tipDoubleTapBody => 'アイテムの編集、メンバーのホワイトボード表示などはダブルタップで開きます。';
  @override
  String get tipLongPressTitle => '安全操作: 長押し';
  @override
  String get tipLongPressBody => 'アイテム削除、グループ退出といった破壊的な操作は長押しで安全に実行できます。';
  @override
  String get tipGroupScreenTitle => 'グループ画面';
  @override
  String get tipGroupScreenBody => 'グループをタップ→カレント選択、ダブルタップ→メンバー管理、長押し→削除/退出です。';
  @override
  String get tipMemberScreenTitle => 'メンバー一覧画面';
  @override
  String get tipMemberScreenBody =>
      'メンバータップ→ロール変更（オーナー）または情報表示、ダブルタップ→ホワイトボード。';
}
