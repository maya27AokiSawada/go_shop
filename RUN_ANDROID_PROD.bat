@echo off
setlocal

echo ========================================
echo Run Android (prod) with config check
echo ========================================
echo.

echo 1. Firebase config check (prod)...
powershell -ExecutionPolicy Bypass -File scripts\check_firebase_placeholders.ps1 -Flavor prod
if errorlevel 1 (
  echo.
  echo Firebase config check failed. Abort.
  pause
  exit /b 1
)

echo.
echo 2. Run app (release/prod)...
if "%~1"=="" (
  flutter run --release --flavor prod --dart-define=FLAVOR=prod
) else (
  flutter run --release --flavor prod --dart-define=FLAVOR=prod -d %1
)

endlocal
