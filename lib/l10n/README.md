# 多言語対応システム (l10n)

GoShoppingアプリの多言語対応を実現するためのローカライゼーションシステムです。

## 📁 ファイル構成

```
lib/l10n/
├── app_texts.dart              # 抽象基底クラス（全言語共通のインターフェース）
├── app_texts_ja.dart           # 日本語実装 ✅
├── app_localizations.dart      # グローバル管理クラス
├── l10n.dart                   # エクスポート＋ショートカット
├── USAGE_EXAMPLES.dart         # 使用例集
└── README.md                   # このファイル
```

## 🚀 クイックスタート

### 1. インポート

```dart
import 'package:goshopping/l10n/l10n.dart';
```

### 2. 使用

```dart
// グローバルショートカット（推奨）
Text(texts.groupName);          // "グループ名"
Text(texts.createGroup);        // "グループを作成"

// または直接アクセス
Text(AppLocalizations.current.groupName);
```

### 3. 言語切り替え

```dart
AppLocalizations.setLanguage('ja');  // 日本語
AppLocalizations.setLanguage('en');  // 英語（未実装）
```

## 📝 実装状況

| 言語       | コード | ファイル            | ステータス  |
| ---------- | ------ | ------------------- | ----------- |
| 日本語     | `ja`   | `app_texts_ja.dart` | ✅ 実装済み |
| 英語       | `en`   | `app_texts_en.dart` | ⏳ 未実装   |
| 中国語     | `zh`   | `app_texts_zh.dart` | ⏳ 未実装   |
| スペイン語 | `es`   | `app_texts_es.dart` | ⏳ 未実装   |

## 🌍 対応テキスト一覧

### 共通 (16項目)

- appName, ok, cancel, save, delete, edit, close, back, next, done...

### 認証 (16項目)

- signIn, signUp, email, password, displayName...

### グループ (20項目)

- group, createGroup, groupName, groupMembers, addMember...

### リスト (16項目)

- list, createList, listName, sharedList...

### アイテム (16項目)

- item, addItem, quantity, purchased...

### QR招待 (10項目)

- invitation, scanQRCode, generateQRCode...

### 設定 (14項目)

- settings, profile, notifications, language...

### 通知 (7項目)

- notification, notificationHistory, markAsRead...

### ホワイトボード (14項目)

- whiteboard, drawingMode, penColor, undo, redo...

### 同期・データ管理 (10項目)

- sync, syncing, syncCompleted, manualSync...

### エラーメッセージ (7項目)

- networkError, serverError, permissionDenied...

### 日時・単位 (8項目)

- today, yesterday, daysAgo, pieces, person...

### アクション確認 (4項目)

- areYouSure, cannotBeUndone, continueAction...

**合計: 約160項目**

## 🔨 新しい言語の追加方法

### Step 1: 実装クラスを作成

```dart
// lib/l10n/app_texts_en.dart
import 'app_texts.dart';

class AppTextsEn extends AppTexts {
  @override
  String get appName => 'GoShopping';

  @override
  String get createGroup => 'Create Group';

  @override
  String get groupName => 'Group Name';

  // ... 全160項目を実装
}
```

### Step 2: app_localizations.dartに登録

```dart
// lib/l10n/app_localizations.dart
import 'app_texts_en.dart';

static void setLanguage(String languageCode) {
  switch (languageCode) {
    case 'en':
      _currentTexts = AppTextsEn();  // 追加
      break;
    // ...
  }
}
```

### Step 3: supportedLanguagesに追加

```dart
static const List<String> supportedLanguages = [
  'ja',
  'en',  // 追加
];
```

## 💡 使用例

詳細は `USAGE_EXAMPLES.dart` を参照してください。

### ボタンラベル

```dart
ElevatedButton(
  onPressed: onSave,
  child: Text(texts.save),
)
```

### ダイアログ

```dart
AlertDialog(
  title: Text(texts.confirmDeleteGroup),
  content: Text(texts.cannotBeUndone),
  actions: [
    TextButton(child: Text(texts.cancel), onPressed: () {}),
    ElevatedButton(child: Text(texts.delete), onPressed: () {}),
  ],
)
```

### フォームバリデーション

```dart
TextFormField(
  decoration: InputDecoration(
    labelText: texts.groupName,
  ),
  validator: (value) {
    if (value?.isEmpty ?? true) {
      return texts.groupNameRequired;
    }
    return null;
  },
)
```

### スナックバー

```dart
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(content: Text(texts.groupCreated)),
);
```

## 🎯 今後のタスク

### 2026-02-13以降

1. **既存コードの移行**
   - home_page.dart
   - group_creation_with_copy_dialog.dart
   - shopping_list_page_v2.dart
   - settings_page.dart
   - など、全UIコンポーネント

2. **英語実装** (`app_texts_en.dart`)
   - 約160項目の翻訳
   - ネイティブチェック推奨

3. **中国語実装** (`app_texts_zh.dart`)
   - 簡体字 or 繁体字の選択
   - 約160項目の翻訳

4. **スペイン語実装** (`app_texts_es.dart`)
   - 約160項目の翻訳

5. **言語切り替えUI実装**
   - settings_page.dartに言語選択ドロップダウン追加
   - 選択後のUI再構築メカニズム（Riverpodで管理）

6. **言語設定の永続化**
   - SharedPreferencesに保存
   - アプリ起動時に復元

## 📚 参考情報

### Dart/Flutterの多言語対応

- 公式: [flutter_localizations](https://docs.flutter.dev/development/accessibility-and-localization/internationalization)
- このプロジェクトは独自実装（シンプル＆軽量）

### なぜ独自実装？

- ✅ **シンプル**: `.arb`ファイル不要
- ✅ **型安全**: コンパイル時エラー検出
- ✅ **IDE補完**: 全テキストでコード補完が効く
- ✅ **軽量**: 外部パッケージ不要
- ✅ **柔軟**: カスタマイズ自由

## 📞 作成情報

- **作成日**: 2026-02-12
- **バージョン**: 1.0.0
- **プロジェクト**: GoShopping
- **ステータス**: 日本語実装完了 / 英中西未実装
