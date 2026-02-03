# Sentry セットアップガイド

## 概要

GoShoppingアプリはWindows/Linux/macOS版でSentryを使用してクラッシュレポートを収集します。
Android/iOS版は既存のFirebase Crashlyticsを継続使用します。

## 1. Sentryプロジェクト作成

1. [Sentry.io](https://sentry.io/)にアクセス
2. アカウント作成（無料プラン: 月5,000イベント）
3. 新規プロジェクト作成
   - **Platform**: Flutter
   - **Project Name**: goshopping
   - **Team**: 任意

## 2. DSN取得

プロジェクト作成後、以下の画面でDSNが表示されます：

```
https://YOUR_KEY@o123456.ingest.sentry.io/789012
```

このDSNをコピーしてください。

## 3. DSN設定

### 方法1: 環境変数（推奨）

`.env`ファイルに追加：

```env
SENTRY_DSN=https://YOUR_KEY@o123456.ingest.sentry.io/789012
```

`lib/main.dart`を修正：

```dart
await SentryFlutter.init(
  (options) {
    options.dsn = dotenv.env['SENTRY_DSN'] ?? '';  // 環境変数から取得
    // ...
  },
);
```

### 方法2: 直接ハードコード

`lib/main.dart`の36行目を修正：

```dart
options.dsn = 'https://YOUR_KEY@o123456.ingest.sentry.io/789012';
```

## 4. 動作確認

### テストクラッシュ送信

Windows版アプリを起動し、意図的にエラーを発生させます：

```dart
// 任意の場所に追加
throw Exception('Sentry test crash');
```

### Sentryダッシュボードで確認

1. [Sentry.io](https://sentry.io/)にログイン
2. **Issues**タブを開く
3. 数秒後にエラーレポートが表示される

## 5. プライバシー設定

個人情報マスキングは自動設定済み：

```dart
options.beforeSend = (event, hint) {
  // ユーザーIDマスキング（abc*** 形式）
  if (event.user?.id != null) {
    event = event.copyWith(
      user: event.user?.copyWith(
        id: AppLogger.maskUserId(event.user?.id),
      ),
    );
  }
  return event;
};
```

## 6. 料金プラン

- **無料プラン**: 月5,000イベント
- **Developer**: $26/月（月50,000イベント）
- **Team**: $80/月（月100,000イベント）

通常の使用では無料プランで十分です。

## 7. トラブルシューティング

### エラー送信されない

1. DSNが正しく設定されているか確認
2. インターネット接続を確認
3. Sentryのステータスページを確認: [status.sentry.io](https://status.sentry.io/)

### デバッグモードで動作確認

```dart
options.debug = true;  // コンソールにSentryログ表示
```

## 8. 関連ファイル

- `pubspec.yaml`: Line 41 - `sentry_flutter: ^8.9.0`
- `lib/main.dart`: Lines 25-61 - Sentry初期化
- `lib/pages/whiteboard_editor_page.dart`: Lines 738-759 - エラー送信実装

## 9. 参考リンク

- [Sentry Flutter公式ドキュメント](https://docs.sentry.io/platforms/flutter/)
- [Sentryダッシュボード](https://sentry.io/)
- [プライバシーポリシー更新](https://docs.sentry.io/product/security-legal-pii/)
