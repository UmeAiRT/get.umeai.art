# ============================================================================
# UmeAiRT ComfyUI — Migration One-Liner (PowerShell → Python)
#
# Usage:
#   irm https://get.umeai.art/migrate.ps1 | iex
#
# Downloads the migration script from the Python installer repo and runs it.
# ============================================================================

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host "    UmeAiRT ComfyUI — Migration PowerShell -> Python" -ForegroundColor Cyan
Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host ""

# --- Config ---
$InstallerDir = Join-Path $env:TEMP "ComfyUI-Auto_installer"
$RepoUrl      = "https://github.com/UmeAiRT/ComfyUI-Auto_installer-Python.git"
$Branch        = "main"
$HF_ZIP       = "https://huggingface.co/UmeAiRT/ComfyUI-Auto-Installer-Assets/resolve/main/releases/ComfyUI-Auto_installer-latest.zip"

$downloaded = $false

# --- Source 1: Git (preferred) ---
if (Get-Command git -ErrorAction SilentlyContinue) {
    if (Test-Path (Join-Path $InstallerDir ".git")) {
        Write-Host "[INFO] Updating installer (Git)..." -ForegroundColor Cyan
        git -C $InstallerDir pull --ff-only --quiet 2>$null
        if ($LASTEXITCODE -ne 0) {
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
    Write-Host "[INFO] Git unavailable. Trying HuggingFace..." -ForegroundColor Yellow
    try {
        $zipPath = Join-Path $env:TEMP "ComfyUI-Auto_installer.zip"
        if (Test-Path $InstallerDir) { Remove-Item -Recurse -Force $InstallerDir }
        Invoke-WebRequest -Uri $HF_ZIP -OutFile $zipPath -UseBasicParsing
        Expand-Archive -Path $zipPath -DestinationPath $env:TEMP -Force
        Remove-Item $zipPath -Force
        $downloaded = $true
    } catch {
        Write-Host "[ERROR] All download sources failed." -ForegroundColor Red
        Write-Host "        Download manually: https://github.com/UmeAiRT/ComfyUI-Auto_installer-Python" -ForegroundColor Yellow
        return
    }
}

# --- Verify and launch ---
$MigrateScript = Join-Path $InstallerDir "Migrate-from-PS.ps1"
if (-not (Test-Path $MigrateScript)) {
    Write-Host "[ERROR] Migration script not found in installer." -ForegroundColor Red
    Write-Host "        This may be an older version. Please update." -ForegroundColor Yellow
    return
}

Write-Host "[INFO] Launching migration script..." -ForegroundColor Green
Write-Host ""

& $MigrateScript
