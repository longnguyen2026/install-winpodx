#!/usr/bin/env bash
#
# WinPodX Installer Bootstrap
# Author : Long Nguyen
# Github : https://github.com/longnguyen2026
#

set -e

REPO="https://raw.githubusercontent.com/longnguyen2026/winpodx-installer/main"
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

#!/usr/bin/env bash

set -e

#####################################
# Colors
#####################################
GREEN="\033[1;32m"
RED="\033[1;31m"
YELLOW="\033[1;33m"
BLUE="\033[1;34m"
NC="\033[0m"

log() {
    echo -e "${GREEN}[OK]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

die() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

section() {
    echo
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}"
}

#####################################
# Root check
#####################################

section "Checking sudo"

sudo -v || die "This installer requires sudo."

#####################################
# Linux distribution
#####################################

section "Checking Linux"

if [ ! -f /etc/os-release ]; then
    die "Cannot determine Linux distribution."
fi

source /etc/os-release

log "Detected: $PRETTY_NAME"

#####################################
# Architecture
#####################################

section "Checking CPU"

ARCH=$(uname -m)

case "$ARCH" in
    x86_64)
        log "64-bit CPU detected"
        ;;
    *)
        die "Only x86_64 is supported."
        ;;
esac

#####################################
# Virtualization
#####################################

section "Checking virtualization"

if grep -Eq "(vmx|svm)" /proc/cpuinfo; then
    log "CPU virtualization supported"
else
    die "VT-x / AMD-V is disabled."
fi

#####################################
# KVM
#####################################

section "Checking KVM"

if [ -e /dev/kvm ]; then
    log "KVM available"
else
    warn "/dev/kvm not found"
fi

#####################################
# RAM
#####################################

section "Checking memory"

RAM=$(free -g | awk '/Mem:/ {print $2}')

echo "RAM : ${RAM} GB"

if [ "$RAM" -lt 8 ]; then
    warn "8 GB or more is recommended."
fi

#####################################
# Disk
#####################################

section "Checking disk"

FREE=$(df -BG "$HOME" | awk 'NR==2 {gsub("G","",$4);print $4}')

echo "Free : ${FREE} GB"

if [ "$FREE" -lt 60 ]; then
    warn "At least 60 GB free space is recommended."
fi

#####################################
# Internet
#####################################

section "Checking network"

ping -c1 github.com >/dev/null \
    && log "Internet OK" \
    || die "No Internet connection."

#####################################
# Update packages
#####################################

section "Updating APT"

sudo apt update

log "APT updated"

#####################################
# Continue
#####################################

echo
log "System preparation completed."
echo
echo "Next step:"
echo "Install Podman"
echo "Install WinPodX"

#####################################
# PART 3/5
# Install Dependencies
#####################################

section "Installing required packages"

sudo apt install -y \
    curl \
    wget \
    git \
    python3 \
    python3-pip \
    podman \
    uidmap \
    slirp4netns \
    fuse-overlayfs \
    freerdp3-x11

log "Dependencies installed."

#####################################
# Check Podman
#####################################

section "Checking Podman"

if ! command -v podman >/dev/null 2>&1; then
    die "Podman installation failed."
fi

PODMAN_VER=$(podman --version)

log "$PODMAN_VER"

#####################################
# Rootless Podman
#####################################

section "Testing rootless Podman"

if podman info >/dev/null 2>&1; then
    log "Rootless Podman is ready."
else
    warn "Podman needs additional configuration."
fi

#####################################
# Check FreeRDP
#####################################

section "Checking FreeRDP"

if command -v xfreerdp >/dev/null 2>&1; then
    log "FreeRDP detected."
else
    warn "FreeRDP not found."
fi

#####################################
# Ready
#####################################

log "System is ready for WinPodX installation."

#####################################
# PART 4/5
# Install WinPodX
#####################################

section "Installing WinPodX"

curl -fsSL https://raw.githubusercontent.com/kernalix7/winpodx/main/install.sh | bash

log "WinPodX installer completed."
#####################################
# PART 5/5
# Final Configuration
#####################################

section "Final configuration"

# Tạo thư mục cấu hình
mkdir -p "$HOME/.config/winpodx"

log "Configuration directory ready."

#####################################
# Desktop database
#####################################

section "Updating desktop database"

if command -v update-desktop-database >/dev/null 2>&1; then
    update-desktop-database "$HOME/.local/share/applications" 2>/dev/null || true
fi

#####################################
# Refresh icon cache
#####################################

section "Refreshing icon cache"

gtk-update-icon-cache -f -t /usr/share/icons/hicolor 2>/dev/null || true

#####################################
# Success
#####################################

clear

echo
echo "========================================================"
echo "          WinPodX Installation Completed!"
echo "========================================================"
echo
echo "Next steps:"
echo
echo "1. Launch WinPodX"
echo "2. Install Windows (first run only)"
echo "3. Wait until Windows setup finishes"
echo "4. Install your Windows applications"
echo
echo "Recommended:"
echo " • Zalo"
echo " • iVMS-4200"
echo " • CapCut"
echo
echo "Enjoy!"
echo
