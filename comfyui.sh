#!/usr/bin/env bash
# ============================================================================
# UmeAiRT ComfyUI — Remote One-Liner Installer
#
# Usage:
#   curl -fsSL https://get.umeai.art/comfyui.sh | sh
#
# This script downloads the installer and delegates to Install.sh.
# Sources: GitHub (git) → HuggingFace (ZIP) → ModelScope (ZIP)
# ============================================================================

set -e

echo ""
echo "============================================================================"
echo "          UmeAiRT ComfyUI — Auto-Installer"
echo "============================================================================"
echo ""

# --- Config ---
INSTALLER_DIR="${TMPDIR:-/tmp}/ComfyUI-Auto_installer"
REPO_URL="https://github.com/UmeAiRT/ComfyUI-Auto_installer-Python.git"
BRANCH="main"
HF_ZIP="https://huggingface.co/UmeAiRT/ComfyUI-Auto-Installer-Assets/resolve/main/releases/ComfyUI-Auto_installer-latest.zip"
MS_ZIP="https://www.modelscope.ai/datasets/UmeAiRT/ComfyUI-Auto-Installer-Assets/resolve/master/releases/ComfyUI-Auto_installer-latest.zip"

downloaded=false

# --- Helper: download ZIP ---
download_zip() {
    local url="$1"
    local zip_path="${TMPDIR:-/tmp}/ComfyUI-Auto_installer.zip"
    rm -rf "$INSTALLER_DIR"

    if command -v curl &>/dev/null; then
        curl -fsSL "$url" -o "$zip_path" || return 1
    elif command -v wget &>/dev/null; then
        wget -q "$url" -O "$zip_path" || return 1
    else
        echo "[ERROR] Neither curl nor wget found."
        return 1
    fi

    unzip -qo "$zip_path" -d "${TMPDIR:-/tmp}" && rm -f "$zip_path"
}

# --- Source 1: Git (preferred) ---
if command -v git &>/dev/null; then
    if [ -d "$INSTALLER_DIR/.git" ]; then
        echo "[INFO] Updating installer (Git)..."
        git -C "$INSTALLER_DIR" pull --ff-only --quiet 2>/dev/null || {
            echo "[INFO] Pull failed, re-cloning..."
            rm -rf "$INSTALLER_DIR"
            git clone --depth 1 -b "$BRANCH" "$REPO_URL" "$INSTALLER_DIR" --quiet
        }
    else
        echo "[INFO] Downloading installer (Git)..."
        rm -rf "$INSTALLER_DIR"
        git clone --depth 1 -b "$BRANCH" "$REPO_URL" "$INSTALLER_DIR" --quiet
    fi
    downloaded=true
fi

# --- Source 2: HuggingFace ZIP fallback ---
if [ "$downloaded" = false ]; then
    echo "[INFO] Git unavailable or failed. Trying HuggingFace..."
    if download_zip "$HF_ZIP"; then
        downloaded=true
        echo "[INFO] Downloaded from HuggingFace."
    else
        echo "[WARN] HuggingFace download failed."
    fi
fi

# --- Source 3: ModelScope ZIP fallback ---
if [ "$downloaded" = false ]; then
    echo "[INFO] Trying ModelScope..."
    if download_zip "$MS_ZIP"; then
        downloaded=true
        echo "[INFO] Downloaded from ModelScope."
    else
        echo "[ERROR] All download sources failed."
        echo "        Try manually: $HF_ZIP"
        exit 1
    fi
fi

# --- Verify integrity ---
INSTALL_SH="$INSTALLER_DIR/Install.sh"
PYPROJECT="$INSTALLER_DIR/pyproject.toml"
if [ ! -f "$INSTALL_SH" ] || [ ! -f "$PYPROJECT" ]; then
    echo "[ERROR] Downloaded installer appears corrupted (missing key files)."
    rm -rf "$INSTALLER_DIR"
    exit 1
fi

echo "[INFO] Installer ready."
echo ""

# --- Launch Install.sh ---
chmod +x "$INSTALL_SH"
cd "$INSTALLER_DIR"

# Reconnect standard input to the terminal so interactive prompts work
# when this script is run via `curl ... | sh`
if [ ! -t 0 ] && [ -c /dev/tty ]; then
    exec < /dev/tty
fi

exec "$INSTALL_SH"
