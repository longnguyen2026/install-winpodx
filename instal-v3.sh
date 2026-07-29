#!/usr/bin/env bash

set -e

REPO="https://raw.githubusercontent.com/longnguyen2026/install-winpodx/main"
SCRIPT="install-winpodx-v3.sh"

TMP="/tmp/$SCRIPT"

echo "Downloading WinPodX installer V3..."

curl -fsSL "$REPO/$SCRIPT" -o "$TMP"

chmod +x "$TMP"

exec bash "$TMP"
