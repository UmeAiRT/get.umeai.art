#!/usr/bin/env bash
# ============================================================================
# UmeAiRT ComfyUI — Remote One-Liner Installer
#
# Usage:
#   curl -fsSL https://get.umeai.art/install.sh | sh
#
# This script clones the installer repo and delegates to Install.sh.
# ============================================================================

set -e

echo ""
echo "============================================================================"
echo "          UmeAiRT ComfyUI — Auto-Installer"
echo "============================================================================"
echo ""

# --- Check prerequisites ---
check_cmd() {
    if ! command -v "$1" &>/dev/null; then
        echo "[ERROR] $1 is required but not found."
        echo "        $2"
        exit 1
    fi
}

check_cmd git "Install from: https://git-scm.com or your package manager"
check_cmd curl "Install from your package manager (apt install curl)"

# --- Ask for install path ---
DEFAULT_PATH="$HOME/ComfyUI"
echo "Where would you like to install ComfyUI?"
echo "  Default: $DEFAULT_PATH"
echo ""
printf "Install path (Enter for default): "
read -r INSTALL_PATH
INSTALL_PATH="${INSTALL_PATH:-$DEFAULT_PATH}"

# Ensure directory exists
mkdir -p "$INSTALL_PATH"

echo ""
echo "[INFO] Install path: $INSTALL_PATH"

# --- Clone installer repo ---
INSTALLER_DIR="$INSTALL_PATH/.installer"
REPO_URL="https://github.com/UmeAiRT/ComfyUI-Auto_installer.git"

if [ -d "$INSTALLER_DIR/.git" ]; then
    echo "[INFO] Updating installer..."
    git -C "$INSTALLER_DIR" pull --ff-only --quiet 2>/dev/null || {
        echo "[INFO] Pull failed, re-cloning..."
        rm -rf "$INSTALLER_DIR"
        git clone --depth 1 "$REPO_URL" "$INSTALLER_DIR" --quiet
    }
else
    echo "[INFO] Downloading installer..."
    rm -rf "$INSTALLER_DIR"
    git clone --depth 1 "$REPO_URL" "$INSTALLER_DIR" --quiet
fi

echo "[INFO] Installer ready."
echo ""

# --- Launch the existing Install.sh ---
INSTALL_SH="$INSTALLER_DIR/Install.sh"
if [ ! -f "$INSTALL_SH" ]; then
    echo "[ERROR] Install.sh not found in cloned repo."
    exit 1
fi

chmod +x "$INSTALL_SH"
cd "$INSTALLER_DIR"
exec "$INSTALL_SH"
