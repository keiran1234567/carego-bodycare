$ErrorActionPreference = 'Stop'

$projectRoot = $PSScriptRoot
$backendPath = Join-Path $projectRoot 'backend'
$storeNgrokPath = Join-Path $env:LOCALAPPDATA 'Microsoft\WindowsApps\ngrok.exe'
$laragonNgrokPath = 'C:\laragon\bin\ngrok\ngrok.exe'
$ngrokPath = if (Test-Path $storeNgrokPath) {
    $storeNgrokPath
} else {
    $laragonNgrokPath
}
$phpPath = 'C:\laragon\bin\php\php-8.1.10-Win32-vs16-x64\php.exe'
$laravelPort = 8000

if (-not (Test-Path $backendPath)) {
    Write-Host "Folder backend tidak ditemukan: $backendPath" -ForegroundColor Red
    exit 1
}

if (-not (Test-Path $ngrokPath)) {
    Write-Host "File ngrok tidak ditemukan: $ngrokPath" -ForegroundColor Red
    exit 1
}

if (-not (Test-Path $phpPath)) {
    Write-Host "File PHP Laragon tidak ditemukan: $phpPath" -ForegroundColor Red
    Write-Host 'Ubah path PHP di dalam script jika versi PHP Laragon kamu berbeda.' -ForegroundColor Yellow
    exit 1
}

try {
    $response = Invoke-WebRequest -UseBasicParsing "http://127.0.0.1:$laravelPort/api/v1/layanans" -TimeoutSec 5
    Write-Host "Backend sudah aktif: HTTP $($response.StatusCode)" -ForegroundColor Yellow
} catch {
    Write-Host 'Menyalakan backend Laravel CareGo...' -ForegroundColor Cyan
    Start-Process -FilePath $phpPath `
        -ArgumentList @('artisan', 'serve', '--host=0.0.0.0', "--port=$laravelPort") `
        -WorkingDirectory $backendPath `
        -WindowStyle Hidden
    Start-Sleep -Seconds 4
}

try {
    $response = Invoke-WebRequest -UseBasicParsing "http://127.0.0.1:$laravelPort/api/v1/layanans" -TimeoutSec 8
    Write-Host "Backend OK: HTTP $($response.StatusCode)" -ForegroundColor Green
} catch {
    Write-Host 'Backend belum merespons dengan benar. Pastikan database dan Laravel siap.' -ForegroundColor Red
    throw
}

Write-Host ''
Write-Host 'Menjalankan ngrok...' -ForegroundColor Cyan
Write-Host 'Biarkan jendela ngrok ini tetap terbuka.' -ForegroundColor Yellow
Write-Host ''
& $ngrokPath http $laravelPort
