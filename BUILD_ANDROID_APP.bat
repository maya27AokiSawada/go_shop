@echo off
echo ========================================
echo Android APKビルド開始
echo ========================================
echo.

echo 1. Flutterクリーン...
flutter clean

echo.
echo 2. 依存関係取得...
flutter pub get

echo.
echo 3. APKビルド（Releaseモード）...
flutter build apk --release

echo.
echo ========================================
echo ビルド完了！
echo.
echo APK保存先: build\app\outputs\flutter-apk\app-release.apk
echo ========================================
pause
