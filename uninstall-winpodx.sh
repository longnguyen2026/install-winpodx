#!/usr/bin/env bash

set -e

echo "========================================"
echo "        WinPodX Uninstaller"
echo "========================================"
echo

echo "[1/5] Removing WinPodX container..."
podman stop winpodx-windows 2>/dev/null || true
podman rm -f winpodx-windows 2>/dev/null || true

echo "[2/5] Removing Windows image..."
podman rmi -f ghcr.io/dockur/windows:latest 2>/dev/null || true
podman image prune -af

echo "[3/5] Removing WinPodX data..."
rm -rf ~/.local/share/winpodx
rm -rf ~/.config/winpodx
rm -rf ~/.cache/winpodx

echo "[4/5] Removing launcher..."
rm -f ~/.local/share/applications/winpodx.desktop

echo "[5/5] Refreshing desktop database..."
if command -v update-desktop-database >/dev/null 2>&1; then
    update-desktop-database ~/.local/share/applications 2>/dev/null || true
fi

echo
echo "========================================"
echo " WinPodX has been removed successfully!"
echo "========================================"
echo
echo "You can reinstall WinPodX anytime using:"
echo
echo "bash <(curl -fsSL https://raw.githubusercontent.com/longnguyen2026/install-winpodx/main/install.sh)"
echo