Set-Location 'I:\FlutterProject\goshopping'

$content = Get-Content -Path 'pubspec.yaml' -Raw
$content = $content -replace 'version: 1\.1\.0\+19', 'version: 1.1.0+20'
Set-Content -Path 'pubspec.yaml' -Value $content -NoNewline
Write-Host 'Updated pubspec.yaml to build number 20'

& 'C:\Users\fatim\fvm\versions\stable\bin\flutter.bat' build appbundle --release --flavor prod --dart-define=FLAVOR=prod --build-number=20
