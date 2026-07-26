#!/usr/bin/env bash

set -e

REPO="https://raw.githubusercontent.com/longnguyen2026/install-winpodx/main"
SCRIPT="install-winpodx.sh"

TMP="/tmp/$SCRIPT"

echo "Downloading WinPodX installer..."

curl -fsSL "$REPO/$SCRIPT" -o "$TMP"

chmod +x "$TMP"

exec bash "$TMP"