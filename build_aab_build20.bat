@echo off
setlocal
cd /d "I:\FlutterProject\goshopping"

powershell -NoProfile -Command "$p = 'pubspec.yaml'; $c = Get-Content -Path $p -Raw; $c = $c -replace 'version: 1\.1\.0\+19', 'version: 1.1.0+20'; Set-Content -Path $p -Value $c -NoNewline"

"C:\Users\fatim\fvm\versions\stable\bin\flutter.bat" build appbundle --release --flavor prod --dart-define=FLAVOR=prod --build-name=1.1.0 --build-number=20
endlocal
