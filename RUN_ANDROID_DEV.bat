@echo off
setlocal

echo ========================================
echo Run Android (dev) with config check
echo ========================================
echo.

echo 1. Firebase config check (dev)...
powershell -ExecutionPolicy Bypass -File scripts\check_firebase_placeholders.ps1 -Flavor dev
if errorlevel 1 (
  echo.
  echo Firebase config check failed. Abort.
  pause
  exit /b 1
)

echo.
echo 2. Run app (debug/dev)...
if "%~1"=="" (
  flutter run --flavor dev --dart-define=FLAVOR=dev
) else (
  flutter run --flavor dev --dart-define=FLAVOR=dev -d %1
)

endlocal
