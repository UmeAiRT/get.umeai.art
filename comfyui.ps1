# ============================================================================
# UmeAiRT ComfyUI — Remote One-Liner Installer (PowerShell)
#
# Usage:
#   irm https://get.umeai.art/comfyui.ps1 | iex
#
# This script downloads the installer and delegates to Install.bat.
# Sources: GitHub (git) → HuggingFace (ZIP) → ModelScope (ZIP)
# ============================================================================

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host "          UmeAiRT ComfyUI — Auto-Installer" -ForegroundColor Cyan
Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host ""

# --- Config ---
$InstallerDir = Join-Path $env:TEMP "ComfyUI-Auto_installer"
$RepoUrl      = "https://github.com/UmeAiRT/ComfyUI-Auto_installer-Python.git"
$Branch        = "main"
$HF_ZIP       = "https://huggingface.co/UmeAiRT/ComfyUI-Auto-Installer-Assets/resolve/main/releases/ComfyUI-Auto_installer-latest.zip"
$MS_ZIP       = "https://www.modelscope.ai/datasets/UmeAiRT/ComfyUI-Auto-Installer-Assets/resolve/master/releases/ComfyUI-Auto_installer-latest.zip"

$downloaded = $false

# --- Source 1: Git (preferred) ---
if (Get-Command git -ErrorAction SilentlyContinue) {
    if (Test-Path (Join-Path $InstallerDir ".git")) {
        Write-Host "[INFO] Updating installer (Git)..." -ForegroundColor Cyan
        git -C $InstallerDir pull --ff-only --quiet 2>$null
        if ($LASTEXITCODE -ne 0) {
            Write-Host "[INFO] Pull failed, re-cloning..." -ForegroundColor Yellow
            Remove-Item -Recurse -Force $InstallerDir
            git clone --depth 1 -b $Branch $RepoUrl $InstallerDir --quiet
        }
    } else {
        Write-Host "[INFO] Downloading installer (Git)..." -ForegroundColor Cyan
        if (Test-Path $InstallerDir) { Remove-Item -Recurse -Force $InstallerDir }
        git clone --depth 1 -b $Branch $RepoUrl $InstallerDir --quiet
    }
    if ($LASTEXITCODE -eq 0) { $downloaded = $true }
}

# --- Source 2: HuggingFace ZIP fallback ---
if (-not $downloaded) {
    Write-Host "[INFO] Git unavailable or failed. Trying HuggingFace..." -ForegroundColor Yellow
    try {
        $zipPath = Join-Path $env:TEMP "ComfyUI-Auto_installer.zip"
        if (Test-Path $InstallerDir) { Remove-Item -Recurse -Force $InstallerDir }
        Invoke-WebRequest -Uri $HF_ZIP -OutFile $zipPath -UseBasicParsing
        Expand-Archive -Path $zipPath -DestinationPath $env:TEMP -Force
        Remove-Item $zipPath -Force
        $downloaded = $true
        Write-Host "[INFO] Downloaded from HuggingFace." -ForegroundColor Green
    } catch {
        Write-Host "[WARN] HuggingFace download failed." -ForegroundColor Yellow
    }
}

# --- Source 3: ModelScope ZIP fallback ---
if (-not $downloaded) {
    Write-Host "[INFO] Trying ModelScope..." -ForegroundColor Yellow
    try {
        $zipPath = Join-Path $env:TEMP "ComfyUI-Auto_installer.zip"
        if (Test-Path $InstallerDir) { Remove-Item -Recurse -Force $InstallerDir }
        Invoke-WebRequest -Uri $MS_ZIP -OutFile $zipPath -UseBasicParsing
        Expand-Archive -Path $zipPath -DestinationPath $env:TEMP -Force
        Remove-Item $zipPath -Force
        $downloaded = $true
        Write-Host "[INFO] Downloaded from ModelScope." -ForegroundColor Green
    } catch {
        Write-Host "[ERROR] All download sources failed." -ForegroundColor Red
        Write-Host "        Try manually: $HF_ZIP" -ForegroundColor Yellow
        return
    }
}

# --- Verify integrity ---
$InstallBat = Join-Path $InstallerDir "Install.bat"
$PyProject  = Join-Path $InstallerDir "pyproject.toml"
if (-not (Test-Path $InstallBat) -or -not (Test-Path $PyProject)) {
    Write-Host "[ERROR] Downloaded installer appears corrupted (missing key files)." -ForegroundColor Red
    Remove-Item -Recurse -Force $InstallerDir -ErrorAction SilentlyContinue
    return
}

Write-Host "[INFO] Installer ready." -ForegroundColor Green
Write-Host ""

# --- Launch Install.bat ---
Push-Location $InstallerDir
cmd /c "`"$InstallBat`""
Pop-Location
