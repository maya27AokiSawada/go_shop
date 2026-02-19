# 開発日報 - 2026年02月19日（水）

## 📋 本日の作業概要

### iOS Firebase設定と動作確認

#### 1. Firebase設定（iOS） ✅

**目的**: iOS版でFirebaseを正常に動作させるための設定を完了

**実装内容**:

**GoogleService-Info.plist設定**:

- Firebase ConsoleからiOS用設定ファイルをダウンロード
- `ios/GoogleService-Info.plist`に配置
- Xcodeプロジェクト（`ios/Runner.xcodeproj/project.pbxproj`）に参照を追加（6箇所）
- ビルドフェーズのリソースに追加

**セキュリティ対策**:

- `.gitignore`に`GoogleService-Info.plist`の除外パターン追加
  - `ios/GoogleService-Info.plist`
  - `ios/Runner/GoogleService-Info.plist`
- テンプレートファイル作成: `ios/GoogleService-Info.plist.template`
- プレースホルダー値で構造を示す（API_KEY, PROJECT_ID等）

**ドキュメント更新**:

- `SETUP.md`: iOS Firebase設定手順を追加
- `docs/SECURITY_ACTION_REQUIRED.md`: セキュリティ対応記録

**コミット**: `b8157b1` - "security: iOS Firebase設定の機密情報保護"

---

#### 2. iOS版DeviceIdServiceエラーハンドリング強化 ✅

**目的**: iOS特有のidentifierForVendor取得失敗に対応

**背景**:

- グループ作成時に使用するデバイスIDプレフィックスの生成
- iOSの`identifierForVendor`がnullまたは空の場合の対処が不十分

**実装内容**:

**iOS固有のtry-catchブロック追加** (`lib/services/device_id_service.dart`):

```dart
} else if (Platform.isIOS) {
  try {
    final iosInfo = await deviceInfo.iosInfo;
    final vendorId = iosInfo.identifierForVendor;

    if (vendorId != null && vendorId.isNotEmpty) {
      // 正常パス: vendorIdの最初の8文字を使用
      final cleanId = vendorId.replaceAll('-', '');
      if (cleanId.length >= 8) {
        prefix = _sanitizePrefix(cleanId.substring(0, 8));
      } else {
        throw Exception('iOS Vendor ID too short');
      }
    } else {
      throw Exception('iOS Vendor ID is null');
    }
  } catch (iosError) {
    // iOS固有エラー時のフォールバック
    final uuid = const Uuid().v4().replaceAll('-', '');
    prefix = 'ios${uuid.substring(0, 5)}'; // "ios" + 5文字 = 8文字
    AppLogger.warning('⚠️ [DEVICE_ID] iOS Vendor ID取得失敗、フォールバック使用');
  }
}
```

**変更点**:

- `identifierForVendor`のnullチェック追加
- vendorIdの長さチェック追加（8文字未満の場合も対応）
- エラー時は`ios` + UUID（5文字）のフォールバックを使用
- Android/Windows/Linux/macOSには影響なし

**技術的価値**:

- ✅ iOS特有のデバイスID取得失敗に対応
- ✅ グループID生成の堅牢性向上
- ✅ Android版への影響ゼロ（iOS専用の条件分岐内）
- ✅ フォールバックによりアプリクラッシュを防止

**コードフォーマット改善**:

- 長い行を複数行に分割（AppLogger.info等）
- 可読性向上

**コミット**: `a485846` - "fix(ios): iOS版DeviceIdServiceのエラーハンドリング強化"

---

#### 3. iOS動作確認 ✅

**実施内容**:

**環境**:

- デバイス: iPhone 16e Simulator (iOS 26.2)
- Xcode: 最新版
- CocoaPods: 51個のポッド（Firebase関連含む）

**動作確認項目**:

- ✅ アプリ起動成功
- ✅ Firebase初期化成功
- ✅ グループ作成機能正常動作
- ✅ デバイスIDプレフィックス生成正常動作

**実行コマンド**:

```bash
flutter run -d 89C2977C-F407-4F73-914C-BFC95398E11B
```

**注意点**:

- `--flavor dev`オプションはiOSで使用不可（Xcodeプロジェクトにカスタムスキームがないため）
- 通常のflutter runコマンドで実行

**結果**: ✅ すべての動作確認完了

---

### 4. ウィジェットクラスリファレンス作成 ✅

**目的**: プロジェクトで使用される全ウィジェットクラスの一覧と概要を整理

**実装内容**:

**新規ファイル**: `docs/specifications/widget_classes_reference.md` (約650行)

**ドキュメント構造**:

**凡例マーク**:

- 📱 画面全体/ページウィジェット
- 🎨 UI部品/コンポーネント
- ⚙️ 設定パネル
- 🔐 認証関連
- 📊 データ表示
- 🔄 同期・初期化
- 🎯 専用機能

**収録ウィジェット数**: 42個（メイン37個 + 設定5個）

**主要ウィジェット**:

**認証関連（5個）**:

- AuthPanelWidget（サインアップ/サインイン切り替え）
- SignupDialog、SignupProcessingWidget

**グループ管理（7個）**:

- GroupListWidget（グループ一覧）
- GroupSelectorWidget（グループ選択ドロップダウン）
- GroupCreationWithCopyDialog（メンバー・リストコピー機能）

**招待・QR（8個）**:

- AcceptInvitationWidget（プラットフォーム別QRスキャナー）
- QRCodePanelWidget、InviteWidget
- GroupInvitationDialog（リアルタイム招待一覧）

**リスト・アイテム（3個）**:

- SharedListHeaderWidget（リスト選択・作成）
- SharedItemEditModal（アイテム編集フル機能）

**同期・初期化（5個）**:

- AppInitializeWidget（8ステップ初期化統合）
- SyncStatusWidget（4種類の同期状態表示）
- DataMigrationWidget（UID変更時のデータ移行）

**UI部品（6個）**:

- CommonAppBar（同期状態表示、フローティングメニュー）
- NewsWidget（Markdownレンダリング、既読管理）
- AdBannerWidget（位置情報ベース広告）

**ホワイトボード（2個）**:

- WhiteboardPreviewWidget（CustomPainter描画）
- MemberTileWithWhiteboard（個人ホワイトボードアクセス）

**設定パネル（5個）**:

- AppModeSwitcherPanel（買い物 ⇄ TODO切替）
- NotificationSettingsPanel、PrivacySettingsPanel
- AuthStatusPanel、FirestoreSyncStatusPanel

**各ウィジェットの記載内容**:

- **ファイルパス**: ソースファイルの場所
- **種類**: ConsumerWidget/ConsumerStatefulWidget/StatefulWidget
- **目的**: 役割・用途の簡潔な説明
- **主要機能**: 実装機能のリスト
- **使用場所**: 使用されているページ/画面
- **特徴**: 特筆すべき実装パターン

**ドキュメント方針**:

- ✅ 詳細な実装コードは省略（ソースコード参照で十分）
- ✅ 目的・機能・使用場所に焦点
- ✅ アルファベット順で検索性向上
- ✅ 実用的な情報を優先

**付録セクション**:

**ウィジェット分類統計**:

- カテゴリ別（認証、グループ管理、招待、同期等）
- 状態管理タイプ別（ConsumerWidget: 23個、ConsumerStatefulWidget: 11個、StatefulWidget: 8個）

**重要な設計パターン**:

1. Riverpod統合パターン
2. プラットフォーム別UI（iOS/Android/Windows）
3. StreamBuilder統合（リアルタイム同期）
4. ダイアログ返却パターン
5. エラーハンドリング統合

**技術的価値**:

- ✅ 新規開発者のオンボーディング時間短縮
- ✅ UI構成の全体把握が容易
- ✅ コンポーネント再利用の判断材料
- ✅ プラットフォーム別実装パターンの把握
- ✅ Riverpod統合パターンの理解促進

---

### 5. ページウィジェットリファレンス作成 ✅

**目的**: アプリ全体の画面構成とナビゲーション構造を体系的に整理し、アプリアーキテクチャの理解を促進

**背景**:

- `lib/pages/` 配下に17個のページウィジェットが存在
- ページ間のナビゲーション構造が不明瞭
- 本番ページとテスト/デバッグページの区別が曖昧
- 各ページの役割・依存関係・設計パターンが文書化されていない

**実装内容**:

**新規ファイル**: `docs/specifications/page_widgets_reference.md` (約1100行)

**ドキュメント構造**:

**凡例マーク**:

- 🏠 メイン画面
- 📊 データ表示
- ⚙️ 設定・管理
- ✏️ 編集・作成
- 📜 履歴表示
- ℹ️ 情報表示
- 🧪 テスト・デバッグ

**収録ページ数**: 17個（本番11個 + テスト/デバッグ6個）

**本番ページ（11個）**:

1. **HomePage** (931行) - 認証・ニュース統合メイン画面
   - サインアップ/サインイン切り替え
   - ユーザー名パネル（SharedPreferences連携）
   - ニュース＋広告統合表示
   - アプリ起動回数カウント

2. **SharedListPage** (1181行) - 買い物リスト管理画面
   - カレントグループ初期化
   - グループ変更検出
   - アイテムCRUD操作
   - ソート機能（購入済み/未購入/名前順）

3. **SettingsPage** (2665行) - 総合設定ハブ（6パネル統合）
   - 認証状態パネル
   - 同期状態パネル
   - アプリモード切替（買い物 ⇄ TODO）
   - プライバシー設定
   - 通知設定
   - データメンテナンス
   - アカウント削除（再認証機能付き）

4. **GroupInvitationPage** (308行) - QRコード招待生成
   - StreamBuilderでリアルタイム招待一覧
   - QRコード生成（qr_flutter）
   - 招待削除・コピー機能

5. **GroupMemberManagementPage** (683行) - メンバー管理・役割制御
   - メンバー一覧（役割別フィルタリング）
   - 役割ベースアクセス制御（owner/admin/partner/member）
   - ホワイトボードプレビュー統合
   - メンバー招待

6. **WhiteboardEditorPage** (1902行) - フルスクリーン描画エディター
   - 2層レンダリング（背景CustomPaint + 前景Signature）
   - 編集ロック（30秒タイムアウト）
   - Undo/Redo（50履歴）
   - 差分保存（90%ネットワーク削減達成）
   - Firestoreリアルタイム同期

7. **NotificationHistoryPage** (331行) - Firestoreリアルタイム通知履歴
   - StreamBuilderで自動更新
   - 通知タイプ別アイコン・色
   - 既読/未読管理

8. **ErrorHistoryPage** (407行) - ローカルエラーログ表示
   - SharedPreferencesベース
   - エラータイプ別分類
   - 既読/未読管理

9. **NewsPage** (194行) - ニュース・セール情報
   - 位置情報サービス連携（Geolocator）
   - Markdownレンダリング
   - 既読管理

10. **PremiumPage** (491行) - プレミアムサブスクリプション管理
    - サブスクリプション状態管理
    - 機能比較表
    - 価格表示

11. **HelpPage** (824行) - ユーザーガイド
    - 検索機能付き
    - セクション別ヘルプ
    - よくある質問

**テスト/デバッグページ（6個）**:

- TestGroupPage, DebugEmailTestPage, EnhancedInvitationTestPage, HybridSyncTestPage, SharedGroupPage, SharedGroupPageSimple

**統計情報**:

**カテゴリ別内訳**:

| カテゴリ   | 個数 | 主要ページ                                                    |
| ---------- | ---- | ------------------------------------------------------------- |
| メイン画面 | 1    | HomePage                                                      |
| データ表示 | 4    | SharedListPage, GroupMemberManagementPage, NewsPage, HelpPage |
| 設定・管理 | 1    | SettingsPage                                                  |
| 編集・作成 | 2    | WhiteboardEditorPage, GroupInvitationPage                     |
| 履歴表示   | 2    | NotificationHistoryPage, ErrorHistoryPage                     |
| 情報表示   | 1    | PremiumPage                                                   |
| テスト     | 6    | TestGroupPage, DebugEmailTestPage等                           |

**Widgetタイプ別**:

- ConsumerStatefulWidget: 11個
- ConsumerWidget: 3個
- StatefulWidget: 3個

**行数ランキング（Top 5）**:

1. SettingsPage (2665行) - 6パネル統合の総合設定
2. WhiteboardEditorPage (1902行) - 編集ロック・2層レンダリング
3. SharedListPage (1181行) - リスト管理・ソート機能
4. HomePage (931行) - 認証・ニュース・広告統合
5. HelpPage (824行) - 検索機能付きガイド

**ナビゲーション構造**:

BottomNavigationBar（4タブ）:

```
HomePage → ホームタブ
  ├─ SignupDialog（ダイアログ）
  ├─ NewsPage（ニュース詳細）
  └─ PremiumPage（プレミアム案内）

GroupListWidget → グループタブ
  ├─ GroupInvitationPage（招待管理）
  └─ GroupMemberManagementPage（メンバー管理）
      └─ WhiteboardEditorPage（ホワイトボード編集）

SharedListPage → 買い物リストタブ

SettingsPage → 設定タブ
  ├─ NotificationHistoryPage（通知履歴）
  ├─ ErrorHistoryPage（エラー履歴）
  └─ HelpPage（ヘルプ）
```

**重要な設計パターン**:

1. **認証状態管理**: `authStateProvider` → HomePage/SettingsPageで監視
2. **カレント選択管理**: `selectedGroupIdProvider`, `currentListProvider` → 複数ページで共有
3. **リアルタイム同期**: `StreamBuilder` → WhiteboardEditorPage/NotificationHistoryPage
4. **エラーハンドリング**: `AppLogger` + `ErrorLogService` → 全ページ統合
5. **ダイアログパターン**: Modal Bottom Sheet → SharedListPage/GroupInvitationPage
6. **Firestore優先読み込み**: 認証必須アプリとして全ページでFirestore→Hiveキャッシュ

**アーキテクチャ的価値**:

- ✅ アプリ全体のナビゲーション構造を可視化
- ✅ ページ間の依存関係を明確化
- ✅ 本番環境とテスト環境の分離を体系化
- ✅ 設計パターンの抽出で開発ガイドライン確立
- ✅ 各ページの役割・責務を明確化

**関連ドキュメント**:

- `docs/specifications/data_classes_reference.md` - データモデル層
- `docs/specifications/widget_classes_reference.md` - UIコンポーネント層
- （次回）サービスクラスリファレンス - ビジネスロジック層

**技術的価値**:

- ✅ アプリ全体のアーキテクチャ把握が容易
- ✅ ナビゲーションフローの理解促進
- ✅ ページ別の責務分担を明確化
- ✅ 設計パターンの一貫性確認
- ✅ 新規開発者のオンボーディング効率化

---

## 🔧 技術的学習事項

### 1. iOS Firebase設定の注意点

**Xcodeプロジェクトファイルへの登録**:

- `GoogleService-Info.plist`の配置だけでは不十分
- `project.pbxproj`にファイル参照を追加する必要あり
  - PBXBuildFile（ビルドファイル定義）
  - PBXFileReference（ファイル参照）
  - PBXResourcesBuildPhase（リソースビルドフェーズ）

**確認方法**:

```bash
grep -c "GoogleService-Info.plist" ios/Runner.xcodeproj/project.pbxproj
# → 6以上の数字が表示されればOK
```

### 2. iOS identifierForVendorの特性

**取得できない場合**:

- アプリが初回インストール直後
- iOSバージョンやシミュレータの状態
- プライバシー設定により制限される場合

**対策**:

- 必ずnullチェックを実施
- フォールバックとしてランダムUUIDを使用
- SharedPreferencesにキャッシュして再利用

### 3. Flutter flavorとiOS

**問題**:

- `flutter run --flavor dev`はAndroidでは動作するが、iOSではエラー
- エラーメッセージ: "The Xcode project does not define custom schemes"

**原因**:

- iOSでflavorを使用するには、Xcodeプロジェクトにカスタムスキームの設定が必要
- `ios/Runner.xcodeproj/xcshareddata/xcschemes/`にスキーム定義ファイルが必要

**対応**:

- 現時点ではflavorなしで実行: `flutter run -d <device-id>`
- 将来的にiOS flavorが必要な場合は、Xcodeでスキーム設定を追加

---

## 📝 Modified Files

**実装ファイル**:

- `lib/services/device_id_service.dart` - iOS固有エラーハンドリング追加
- `ios/Runner.xcodeproj/project.pbxproj` - GoogleService-Info.plist参照追加

**設定ファイル**:

- `.gitignore` - Firebase設定ファイル除外パターン追加
- `ios/GoogleService-Info.plist.template` - テンプレートファイル作成

**ドキュメント**:

- `SETUP.md` - iOS Firebase設定手順追加
- `docs/SECURITY_ACTION_REQUIRED.md` - セキュリティ対応記録
- `docs/specifications/widget_classes_reference.md` - ウィジェットクラスリファレンス（新規作成、約650行）
- `docs/specifications/page_widgets_reference.md` - ページウィジェットリファレンス（新規作成、約1100行）
- `.github/copilot-instructions.md` - Recent Implementations更新（セクション4＋5追加）
- `docs/daily_reports/2026-02/daily_report_20260219.md` - 本日報（セクション4＋5追加）

---

## 🎯 Next Steps

### HIGH Priority

#### 1. ドキュメント整備（継続）

**次の優先度**:

- ⏳ サービスクラスリファレンス作成（`lib/services/` 配下）
- ⏳ プロバイダーリファレンス作成（`lib/providers/` 配下）
- ⏳ リポジトリクラスリファレンス作成（`lib/datastore/` 配下）

**メリット**:

- コードベース全体の理解向上
- 新規開発者のオンボーディング効率化
- アーキテクチャパターンの明確化

#### 2. iOS実機テスト

**確認項目**:

- Firebase認証・Firestore動作
- グループ作成・招待機能
- リアルタイム同期
- デバイスIDプレフィックス生成

**デバイス**:

- iPhone実機（iOS 15以上）
- 複数デバイスでの同時操作テスト

### MEDIUM Priority

#### 3. iOS flavorサポート追加（オプション）

**実装予定**:

- Xcodeでカスタムスキーム設定
- `Runner-Dev.xcscheme`, `Runner-Prod.xcscheme`作成
- `--flavor dev/prod`オプションの有効化

#### 4. macOS版対応（将来）

**DeviceIdServiceの拡張**:

- macOSでのデバイス識別子取得
- デスクトップ特有の動作検証

#### 5. CI/CD設定

**GitHub Actions**:

- iOS自動ビルドの追加
- TestFlightへの自動配信

---

#### 6. Production Bug修正: グループコピー時の赤画面エラー ✅

**Purpose**: Pixel 9で「コピー付き作成」時にFlutterエラー画面が表示される問題を修正

**背景**:

- ユーザー報告「コピー付き作成で赤画面発生しました Pixel 9です」
- グループ作成自体は成功するが、その後にエラー画面表示
- 再現条件: **別ユーザーがオーナーのグループをコピー**した場合

**調査プロセス**:

**Phase 1**: 初期仮説（Widget disposal during long async chain）

- 8秒以上の非同期処理チェーン中にWidgetが破棄される可能性を調査
- **結果**: Crashlyticsログにより仮説は誤りと判明

**Phase 2**: Crashlyticsログ分析 ✅

```
Fatal Exception: io.flutter.plugins.firebase.crashlytics.FlutterError
There should be exactly one item with [DropdownButton]'s value:
SharedGroup(groupName: CCすもも02191306, groupId: win0396f_1771473965650, ...)
Either zero or 2 or more [DropdownMenuItem]s were detected with the same value

'package:flutter/src/material/dropdown.dart':
Failed assertion: line 1830

at _GroupCreationWithCopyDialogState._buildDialog(group_creation_with_copy_dialog.dart:172)
```

**Phase 3**: 根本原因特定 ✅

- **Error Type**: Flutter DropdownButton assertion failure
- **Problem**: DropdownButtonFormFieldのitemsリストに同じgroupIdのグループが複数含まれる
- **Data Flow**: Hive → getAllGroups() → allGroupsProvider.build() → Dialog dropdown
- **Missing Logic**: `allGroupsProvider`がgroupIdで重複除去していなかった

**実装内容**:

**修正1: Dialog側（症状への直接対処）** - `lib/widgets/group_creation_with_copy_dialog.dart`

```dart
items: [
  const DropdownMenuItem<SharedGroup>(
    value: null,
    child: Text('新しいグループ (メンバーなし)'),
  ),
  // 🔥 FIX: groupIdで重複を除去
  ...existingGroups
      .fold<Map<String, SharedGroup>>(
        {},
        (map, group) {
          map[group.groupId] = group;
          return map;
        },
      )
      .values
      .map((group) => DropdownMenuItem<SharedGroup>(...)),
],
```

**修正2: Provider側（根本的対策）** - `lib/providers/purchase_group_provider.dart`

```dart
// AllGroupsNotifier.build()の戻り値で重複除去
final uniqueGroups = <String, SharedGroup>{};
for (final group in filteredGroups) {
  uniqueGroups[group.groupId] = group;
}
final deduplicatedGroups = uniqueGroups.values.toList();

final removedCount = filteredGroups.length - deduplicatedGroups.length;
if (removedCount > 0) {
  Log.warning('⚠️ [ALL GROUPS] 重複グループを除去: $removedCount グループ');
}

return deduplicatedGroups;
```

**技術的価値**:

- ✅ **二重保護**: DialogとProvider両方で重複を除去
- ✅ **ログ出力**: 重複検出時は警告ログを記録（調査用）
- ✅ **パフォーマンス**: Map<String, SharedGroup>による効率的な重複除去（O(n)）
- ✅ **安全性**: Flutter framework assertionエラーを防止

**Hive Storage Paradox** ⚠️:

- Hiveは`Box<SharedGroup>`（Mapベース）でgroupIdをキーとして使用
- `box.put(groupId, group)`は同じキーで上書きするため、理論上重複は発生しない
- しかし実際には重複が発生していた（Crashlyticsで確認）
- **推測**: Firestoreリスナーまたは複数のbox instanceによる並行書き込みの可能性

**Modified Files**:

- `lib/widgets/group_creation_with_copy_dialog.dart` (Line 190-210)
- `lib/providers/purchase_group_provider.dart` (Line 530-545)

**Status**: ✅ 実装完了・コンパイルエラーなし | ⏳ 実機テスト待ち（Pixel 9）

**Next Steps**:

1. ⏳ Pixel 9で再現テスト（別ユーザーがオーナーのグループをコピー）
2. ⏳ 赤画面が出ないことを確認
3. ⏳ グループ作成が正常に完了することを確認
4. ⏳ コピーされたメンバーが正しく追加されることを確認

---

## 📊 Status Summary

**Today's Achievements**:

- ✅ iOS Firebase設定完了
- ✅ セキュリティ対策実施（.gitignore、テンプレートファイル）
- ✅ iOS DeviceIdServiceエラーハンドリング強化
- ✅ iOS動作確認完了（iPhone 16e Simulator）
- ✅ グループ作成機能動作確認
- ✅ **ウィジェットクラスリファレンス作成**（42個のウィジェット網羅、約650行）
- ✅ **ページウィジェットリファレンス作成**（17個のページ網羅、約1100行）
- ✅ **Production Bug修正: グループコピー時の赤画面エラー**
  - Crashlyticsログ分析 → 根本原因特定（DropdownButton重複値エラー）
  - DialogとProvider両方で重複除去ロジック実装
  - 実機テストは後日実施予定

**Commits**:

- `b8157b1` - Firebase設定セキュリティ対応
- `a485846` - iOS DeviceIdServiceエラーハンドリング
- (今回) - ウィジェット・ページリファレンス作成、Production Bug修正

**Branch**: `future`

**Status**: ✅ All tasks completed

**Documentation Coverage**:

- ✅ データクラスリファレンス（26クラス、約500行）- 2026-02-18
- ✅ ウィジェットクラスリファレンス（42ウィジェット、約650行）- 2026-02-19
- ✅ ページウィジェットリファレンス（17ページ、約1100行）- 2026-02-19
- ⏳ サービスクラスリファレンス（次回）
- ⏳ プロバイダーリファレンス（次回）
- ⏳ リポジトリクラスリファレンス（次回）
