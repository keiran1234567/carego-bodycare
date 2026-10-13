param(
    [string]$Token
)

$ErrorActionPreference = 'Stop'

$storeNgrokPath = Join-Path $env:LOCALAPPDATA 'Microsoft\WindowsApps\ngrok.exe'
$laragonNgrokPath = 'C:\laragon\bin\ngrok\ngrok.exe'
$ngrokPath = if (Test-Path $storeNgrokPath) {
    $storeNgrokPath
} else {
    $laragonNgrokPath
}

if (-not (Test-Path $ngrokPath)) {
    Write-Host "File ngrok tidak ditemukan di: $ngrokPath" -ForegroundColor Red
    Write-Host "Letakkan ngrok.exe terbaru di folder itu dulu, lalu jalankan script ini lagi." -ForegroundColor Yellow
    exit 1
}

if ([string]::IsNullOrWhiteSpace($Token)) {
    $Token = Read-Host 'Tempel authtoken ngrok Anda'
}

if ([string]::IsNullOrWhiteSpace($Token)) {
    Write-Host 'Authtoken tidak boleh kosong.' -ForegroundColor Red
    exit 1
}

Write-Host 'Memasang authtoken ngrok...' -ForegroundColor Cyan
& $ngrokPath config add-authtoken $Token

Write-Host ''
Write-Host 'Berhasil. Langkah berikutnya:' -ForegroundColor Green
Write-Host '1. Jalankan backend Laravel:' -ForegroundColor White
Write-Host '   cd "C:\Users\muham\OneDrive\Documents\New project\backend"' -ForegroundColor Gray
Write-Host '   php artisan serve --host=0.0.0.0 --port=8000' -ForegroundColor Gray
Write-Host ''
Write-Host '2. Jalankan tunnel ngrok:' -ForegroundColor White
Write-Host '   & "C:\laragon\bin\ngrok\ngrok.exe" http 8000' -ForegroundColor Gray
Write-Host ''
Write-Host '3. Copy URL https://... yang muncul, lalu tempel ke menu "Alamat API Server" di aplikasi CareGo.' -ForegroundColor White
