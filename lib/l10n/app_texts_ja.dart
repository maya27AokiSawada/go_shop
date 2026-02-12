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
}
