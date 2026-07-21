#!/usr/bin/env pwsh
# deploy.ps1 - Tương đương deploy.sh nhưng chạy trên Windows
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$APP_DIR      = if ($env:APP_DIR)      { $env:APP_DIR }      else { 'C:\Kendy-deploy' }
$ENV_FILE     = Join-Path $APP_DIR '.env'
$COMPOSE_FILE = Join-Path $APP_DIR 'docker-compose.prod.yml'

# Kiểm tra file bắt buộc phải có
if (-not (Test-Path $ENV_FILE)) {
    Write-Error "Missing $ENV_FILE"
    exit 1
}
if (-not (Test-Path $COMPOSE_FILE)) {
    Write-Error "Missing $COMPOSE_FILE"
    exit 1
}

Set-Location $APP_DIR

# Cập nhật BACKEND_IMAGE trong .env nếu được truyền vào
if ($env:BACKEND_IMAGE) {
    $content = Get-Content $ENV_FILE -Raw
    if ($content -match '(?m)^BACKEND_IMAGE=') {
        $content = $content -replace '(?m)^BACKEND_IMAGE=.*', "BACKEND_IMAGE=$($env:BACKEND_IMAGE)"
    } else {
        $content += "`nBACKEND_IMAGE=$($env:BACKEND_IMAGE)`n"
    }
    Set-Content $ENV_FILE $content -NoNewline
    Write-Host "Updated BACKEND_IMAGE -> $($env:BACKEND_IMAGE)"
}

# Cập nhật FRONTEND_IMAGE trong .env nếu được truyền vào
if ($env:FRONTEND_IMAGE) {
    $content = Get-Content $ENV_FILE -Raw
    if ($content -match '(?m)^FRONTEND_IMAGE=') {
        $content = $content -replace '(?m)^FRONTEND_IMAGE=.*', "FRONTEND_IMAGE=$($env:FRONTEND_IMAGE)"
    } else {
        $content += "`nFRONTEND_IMAGE=$($env:FRONTEND_IMAGE)`n"
    }
    Set-Content $ENV_FILE $content -NoNewline
    Write-Host "Updated FRONTEND_IMAGE -> $($env:FRONTEND_IMAGE)"
}

# Kéo image mới và khởi động lại container
Write-Host "Pulling images moi tu Docker Hub..."
docker compose -f $COMPOSE_FILE pull

Write-Host "Starting containers..."
docker compose -f $COMPOSE_FILE up -d --remove-orphans

Write-Host "Trang thai containers:"
docker compose -f $COMPOSE_FILE ps
