#!/usr/bin/env bash

set -e

#####################################
# PART 2/5 Colors
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

#############################################
# PART 3/5 WinPodX Configuration Wizard
#############################################

choose_windows() {

echo
echo "========================================="
echo "        Windows Edition"
echo "========================================="
echo "1) Windows 11 Pro"
echo "2) Windows 11 LTSC"
echo "3) Windows 10 Pro"
echo "4) Windows 10 LTSC"
echo "5) Tiny11"
echo

read -rp "Lựa chọn [1-5]: " WIN_CHOICE

case "$WIN_CHOICE" in
1) WIN_VERSION="11" ;;
2) WIN_VERSION="ltsc11" ;;
3) WIN_VERSION="10" ;;
4) WIN_VERSION="ltsc10" ;;
5) WIN_VERSION="tiny11" ;;
*) echo "Lựa chọn không hợp lệ!"; exit 1 ;;
esac

}

#############################################

choose_ram() {

echo
echo "========================================="
echo "             RAM"
echo "========================================="
echo "1) 4 GB"
echo "2) 8 GB"
echo "3) 12 GB"
echo "4) 16 GB"
echo "5) 24 GB"
echo "6) Tự nhập"
echo

read -rp "Lựa chọn [1-6]: " RAM_CHOICE

case "$RAM_CHOICE" in
1) RAM_SIZE="4G" ;;
2) RAM_SIZE="8G" ;;
3) RAM_SIZE="12G" ;;
4) RAM_SIZE="16G" ;;
5) RAM_SIZE="24G" ;;

6)

while true
do
read -rp "Nhập RAM (GB): " CUSTOM_RAM

if [[ "$CUSTOM_RAM" =~ ^[0-9]+$ ]] && [ "$CUSTOM_RAM" -ge 4 ]; then
RAM_SIZE="${CUSTOM_RAM}G"
break
fi

echo "RAM không hợp lệ!"

done

;;

*)

echo "Lựa chọn không hợp lệ!"
exit 1
;;

esac

}

#############################################

choose_cpu() {

echo
echo "========================================="
echo "             CPU"
echo "========================================="
echo "1) 2 Core"
echo "2) 4 Core"
echo "3) 6 Core"
echo "4) 8 Core"
echo "5) Tự nhập"
echo

read -rp "Lựa chọn [1-5]: " CPU_CHOICE

case "$CPU_CHOICE" in

1) CPU_CORES="2" ;;
2) CPU_CORES="4" ;;
3) CPU_CORES="6" ;;
4) CPU_CORES="8" ;;

5)

while true
do

read -rp "Nhập số Core: " CUSTOM_CPU

if [[ "$CUSTOM_CPU" =~ ^[0-9]+$ ]] && [ "$CUSTOM_CPU" -ge 2 ]; then
CPU_CORES="$CUSTOM_CPU"
break
fi

echo "CPU không hợp lệ!"

done

;;

*)

echo "Lựa chọn không hợp lệ!"
exit 1
;;

esac

}

#############################################

choose_disk() {

echo
echo "========================================="
echo "        Disk Size"
echo "========================================="
echo "1) 64 GB"
echo "2) 80 GB"
echo "3) 100 GB"
echo "4) 120 GB"
echo "5) 160 GB"
echo "6) Tự nhập"
echo

read -rp "Lựa chọn [1-6]: " DISK_CHOICE

case "$DISK_CHOICE" in

1) DISK_SIZE="64G" ;;
2) DISK_SIZE="80G" ;;
3) DISK_SIZE="100G" ;;
4) DISK_SIZE="120G" ;;
5) DISK_SIZE="160G" ;;

6)

while true
do

read -rp "Nhập dung lượng (GB): " CUSTOM_DISK

if [[ "$CUSTOM_DISK" =~ ^[0-9]+$ ]] && [ "$CUSTOM_DISK" -ge 64 ]; then
DISK_SIZE="${CUSTOM_DISK}G"
break
fi

echo "Disk tối thiểu 64GB!"

done

;;

*)

echo "Lựa chọn không hợp lệ!"
exit 1
;;

esac

}

#############################################

summary() {

clear

echo
echo "=========================================="
echo "        WINPODX CONFIGURATION"
echo "=========================================="

printf "%-15s %s\n" "Windows:" "$WIN_VERSION"
printf "%-15s %s\n" "RAM:" "$RAM_SIZE"
printf "%-15s %s\n" "CPU:" "$CPU_CORES Core"
printf "%-15s %s\n" "Disk:" "$DISK_SIZE"

echo
read -rp "Tiếp tục cài đặt? (Y/n): " CONFIRM

case "$CONFIRM" in

""|Y|y)

;;

*)

echo "Đã hủy."

exit 0

;;

esac

}

#############################################

choose_windows
choose_ram
choose_cpu
choose_disk
summary

#####################################
# PART 4/5
# Install WinPodX
#####################################

section "Select Windows Edition"

echo
echo "=========================================="
echo "        Select Windows Edition"
echo "=========================================="
echo "1) Windows 11 Pro"
echo "2) Windows 11 LTSC 2024 (Recommended)"
echo "3) Windows 10 Pro"
echo "4) Windows 10 LTSC"
echo "5) Tiny11"
echo

while true; do
    read -rp "Choose [1-5] (default: 2): " choice

    choice=${choice:-2}

    case "$choice" in
        1)
            export WINPODX_WIN_VERSION="11"
            WIN_NAME="Windows 11 Pro"
            break
            ;;
        2)
            export WINPODX_WIN_VERSION="ltsc11"
            WIN_NAME="Windows 11 LTSC 2024"
            break
            ;;
        3)
            export WINPODX_WIN_VERSION="10"
            WIN_NAME="Windows 10 Pro"
            break
            ;;
        4)
            export WINPODX_WIN_VERSION="ltsc10"
            WIN_NAME="Windows 10 LTSC"
            break
            ;;
        5)
            export WINPODX_WIN_VERSION="tiny11"
            WIN_NAME="Tiny11"
            break
            ;;
        *)
            echo
            echo "Invalid selection. Please choose a number from 1 to 5."
            echo
            ;;
    esac
done

echo
log "Selected Windows: $WIN_NAME"
echo

section "Installing WinPodX"

curl -fsSL https://raw.githubusercontent.com/kernalix7/winpodx/main/install.sh | bash

unset WINPODX_WIN_VERSION

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
