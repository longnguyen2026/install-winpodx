#!/usr/bin/env bash
#
# WinPodX Installer Bootstrap
# Author : Long Nguyen
# Github : https://github.com/longnguyen2026
#

set -e

REPO="https://raw.githubusercontent.com/longnguyen2026/insrall-winpodx/main"
SCRIPT="install-winpodx.sh"

GREEN="\033[1;32m"
YELLOW="\033[1;33m"
RED="\033[1;31m"
BLUE="\033[1;34m"
NC="\033[0m"

clear

echo -e "${BLUE}"
echo "=================================================="
echo "           WinPodX Installer for Linux"
echo "=================================================="
echo -e "${NC}"

########################################
# Check Internet
########################################

echo -e "${YELLOW}Checking Internet...${NC}"

if ! ping -c1 github.com >/dev/null 2>&1; then
    echo -e "${RED}"
    echo "No Internet Connection."
    echo "Please check your network."
    echo -e "${NC}"
    exit 1
fi

echo -e "${GREEN}Internet OK${NC}"

########################################
# Download installer
########################################

TMP="/tmp/$SCRIPT"

echo
echo -e "${YELLOW}Downloading installer...${NC}"

curl -fsSL "$REPO/$SCRIPT" -o "$TMP"

chmod +x "$TMP"

echo -e "${GREEN}Download completed.${NC}"

########################################
# Run installer
########################################

echo
echo -e "${YELLOW}Launching installer...${NC}"
echo

exec bash "$TMP"