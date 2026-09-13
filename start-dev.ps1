$ErrorActionPreference = "Continue"

$appRoot = "C:\Users\tkach\Desktop\app"
$backend = Join-Path $appRoot "kb_backend"
$flutter = Join-Path $appRoot "flutter_application_1"
$adb = "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"
$emulator = "$env:LOCALAPPDATA\Android\Sdk\emulator\emulator.exe"

Write-Host "1. PostgreSQL..."
$pg = Get-Service postgresql-x64-18 -ErrorAction SilentlyContinue
if ($pg -and $pg.Status -ne "Running") {
    Start-Service postgresql-x64-18
}
Get-Service postgresql-x64-18 | Select-Object Status, Name

Write-Host "2. Emulator..."
$running = & $adb devices | Select-String "emulator-"
if (-not $running) {
    $avd = (& $emulator -list-avds | Select-Object -First 1)
    if ($avd) {
        Start-Process $emulator -ArgumentList "-avd", $avd
        Write-Host "Waiting for emulator..."
        Start-Sleep -Seconds 20
    }
}

Write-Host "3. Port forwarding..."
& $adb wait-for-device
& $adb reverse tcp:8000 tcp:8000
& $adb reverse --list

Write-Host "4. API..."
Start-Process powershell -ArgumentList @(
    "-NoExit",
    "-Command",
    "cd `"$backend`"; .\venv\Scripts\Activate.ps1; python -m uvicorn main:app --reload --host 0.0.0.0 --port 8000"
)

Write-Host "5. Flutter..."
Start-Process powershell -ArgumentList @(
    "-NoExit",
    "-Command",
    "cd `"$flutter`"; flutter run"
)