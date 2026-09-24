# Shellit Portal Backend (PocketBase) Quick Launcher for Windows

$ErrorActionPreference = "Stop"
$PBDropDir = $PSScriptRoot
Set-Location $PBDropDir

$PB_VERSION = "0.25.9"
$PB_EXE = Join-Path $PBDropDir "pocketbase.exe"

if (-not (Test-Path $PB_EXE)) {
    Write-Host "PocketBase binary not found. Downloading v$PB_VERSION for Windows..." -ForegroundColor Cyan
    $ZIP_URL = "https://github.com/pocketbase/pocketbase/releases/download/v$PB_VERSION/pocketbase_${PB_VERSION}_windows_amd64.zip"
    $ZIP_FILE = Join-Path $PBDropDir "pocketbase.zip"
    
    Invoke-WebRequest -Uri $ZIP_URL -OutFile $ZIP_FILE
    Expand-Archive -Path $ZIP_FILE -DestinationPath $PBDropDir -Force
    Remove-Item $ZIP_FILE -Force
    Write-Host "PocketBase installed successfully!" -ForegroundColor Green
}

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "  Shellit Portal Backend & Admin Panel" -ForegroundColor Yellow
Write-Host "  Admin Dashboard: http://127.0.0.1:8090/_/" -ForegroundColor Green
Write-Host "  REST & Realtime: http://127.0.0.1:8090/api/" -ForegroundColor Green
Write-Host "==========================================================" -ForegroundColor Cyan

& $PB_EXE serve --http="127.0.0.1:8090"
