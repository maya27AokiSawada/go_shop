param(
    [ValidateSet('prod', 'dev')]
    [string]$Flavor = 'prod'
)

$ErrorActionPreference = 'Stop'

function Test-PlaceholderValue {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Value
    )

    if ([string]::IsNullOrWhiteSpace($Value)) {
        return $true
    }

    $patterns = @(
        '^YOUR_',
        'your_',
        'CHANGE_ME',
        'example.com',
        '<.*>'
    )

    foreach ($pattern in $patterns) {
        if ($Value -match $pattern) {
            return $true
        }
    }

    return $false
}

function Get-JsonValue {
    param(
        [Parameter(Mandatory = $true)] $Object,
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    $current = $Object
    foreach ($segment in $Path.Split('.')) {
        if ($segment -match '^(.+)\[(\d+)\]$') {
            $name = $matches[1]
            $index = [int]$matches[2]
            $current = $current.$name[$index]
        }
        else {
            $current = $current.$segment
        }

        if ($null -eq $current) {
            return $null
        }
    }

    return [string]$current
}

$root = Resolve-Path (Join-Path $PSScriptRoot '..')
$envPath = Join-Path $root '.env'
$googleServicesPath = Join-Path $root "android/app/src/$Flavor/google-services.json"

$errors = New-Object System.Collections.Generic.List[string]

if (-not (Test-Path $envPath)) {
    $errors.Add(".env not found: $envPath")
}
else {
    $envMap = @{}
    Get-Content $envPath | ForEach-Object {
        if ($_ -match '^\s*#' -or $_ -notmatch '=') {
            return
        }

        $parts = $_.Split('=', 2)
        $key = $parts[0].Trim()
        $value = $parts[1]
        if ($key) {
            $envMap[$key] = $value
        }
    }

    $requiredEnvKeys = @(
        'FIREBASE_PROJECT_ID',
        'FIREBASE_MESSAGING_SENDER_ID',
        'FIREBASE_APP_ID_ANDROID',
        'FIREBASE_API_KEY_ANDROID'
    )

    foreach ($key in $requiredEnvKeys) {
        if (-not $envMap.ContainsKey($key)) {
            $errors.Add(".env missing key: $key")
            continue
        }

        if (Test-PlaceholderValue -Value $envMap[$key]) {
            $errors.Add(".env key has placeholder value: $key")
        }
    }
}

if (-not (Test-Path $googleServicesPath)) {
    $errors.Add("google-services.json not found: $googleServicesPath")
}
else {
    $json = Get-Content $googleServicesPath -Raw | ConvertFrom-Json

    $requiredJsonPaths = @(
        'project_info.project_id',
        'project_info.project_number',
        'client[0].client_info.mobilesdk_app_id',
        'client[0].api_key[0].current_key'
    )

    foreach ($path in $requiredJsonPaths) {
        $value = Get-JsonValue -Object $json -Path $path

        if ([string]::IsNullOrWhiteSpace($value)) {
            $errors.Add("google-services value is empty: $path")
            continue
        }

        if (Test-PlaceholderValue -Value $value) {
            $errors.Add("google-services value is placeholder: $path")
        }
    }
}

if ($errors.Count -gt 0) {
    Write-Host "[ERROR] Firebase config check failed (flavor=$Flavor)" -ForegroundColor Red
    foreach ($err in $errors) {
        Write-Host " - $err" -ForegroundColor Red
    }
    exit 1
}

Write-Host "[OK] Firebase config check passed (flavor=$Flavor)" -ForegroundColor Green
exit 0
