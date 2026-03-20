# ============================================================================
# UmeAiRT ComfyUI — Remote One-Liner Installer (PowerShell)
#
# Usage:
#   irm https://get.umeai.art/install.ps1 | iex
#
# This script clones the installer repo and delegates to Install.bat.
# ============================================================================

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host "          UmeAiRT ComfyUI — Auto-Installer" -ForegroundColor Cyan
Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host ""

# --- Check prerequisites ---
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Host "[ERROR] Git is required but not found in PATH." -ForegroundColor Red
    Write-Host "        Install from: https://git-scm.com/downloads/win" -ForegroundColor Yellow
    return
}

# --- Ask for install path ---
$DefaultPath = Join-Path $env:USERPROFILE "ComfyUI"
Write-Host "Where would you like to install ComfyUI?"
Write-Host "  Default: $DefaultPath"
Write-Host ""
$InstallPath = Read-Host "Install path (Enter for default)"
if ([string]::IsNullOrWhiteSpace($InstallPath)) { $InstallPath = $DefaultPath }

# Ensure directory exists
if (-not (Test-Path $InstallPath)) {
    New-Item -ItemType Directory -Path $InstallPath -Force | Out-Null
}

Write-Host ""
Write-Host "[INFO] Install path: $InstallPath" -ForegroundColor Green

# --- Clone installer repo ---
$InstallerDir = Join-Path $InstallPath ".installer"
$RepoUrl = "https://github.com/UmeAiRT/ComfyUI-Auto_installer.git"

if (Test-Path $InstallerDir) {
    Write-Host "[INFO] Updating installer..." -ForegroundColor Cyan
    git -C $InstallerDir pull --ff-only --quiet 2>$null
    if ($LASTEXITCODE -ne 0) {
        Write-Host "[INFO] Pull failed, re-cloning..." -ForegroundColor Yellow
        Remove-Item -Recurse -Force $InstallerDir
        git clone --depth 1 $RepoUrl $InstallerDir --quiet
    }
} else {
    Write-Host "[INFO] Downloading installer..." -ForegroundColor Cyan
    git clone --depth 1 $RepoUrl $InstallerDir --quiet
}

if ($LASTEXITCODE -ne 0) {
    Write-Host "[ERROR] Failed to download installer. Check your internet connection." -ForegroundColor Red
    return
}

Write-Host "[INFO] Installer ready." -ForegroundColor Green
Write-Host ""

# --- Launch the existing Install.bat ---
$InstallBat = Join-Path $InstallerDir "Install.bat"
if (-not (Test-Path $InstallBat)) {
    Write-Host "[ERROR] Install.bat not found in cloned repo." -ForegroundColor Red
    return
}

Push-Location $InstallerDir
cmd /c "`"$InstallBat`""
Pop-Location
