# データクリアスクリプト

昼休み後の初期状態デバッグ用にデータクリアスクリプトを準備しました。

## 🧹 使用方法

### 完全リセット（推奨）
```bash
dart run scripts/reset_all_data.dart
```

### 個別実行

#### Firebase Authentication ユーザー削除のみ
```bash
dart run scripts/clear_auth_user.dart
```

#### Firestore データ削除のみ
```bash
dart run scripts/clear_firestore_data.dart
```

#### Hive ローカルデータ削除のみ
```bash
dart run scripts/clear_hive_data.dart
```

## 🔄 リセット後の手順

1. **Android端末のアプリをアンインストール**
2. **プロジェクトクリーン**
   ```bash
   flutter clean
   flutter pub get
   ```
3. **アプリ再インストール**
   ```bash
   flutter run --device-id "192.168.0.18:40289"
   ```
4. **新規ユーザー登録から開始**

## 💡 昼休み後のデバッグ計画

1. 完全に初期状態からユーザー作成
2. グループ作成と権限の確認
3. 権限チェックのデバッグログで問題箇所を特定
4. QRコード招待機能の実装

## ⚠️ 注意事項

- これらのスクリプトは**全データを削除**します
- 実行前に必要なデータはバックアップしてください
- 本番環境では使用しないでください