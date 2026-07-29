#!/usr/bin/env bash

set -euo pipefail

#####################################
# WinPodX Installer v3
# Part 1/5 - System Check
#####################################

VERSION="3.0"

#####################################
# Colors
#####################################

GREEN="\033[1;32m"
RED="\033[1;31m"
YELLOW="\033[1;33m"
BLUE="\033[1;34m"
NC="\033[0m"

#####################################
# Functions
#####################################

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
# Banner
#####################################

clear

echo
echo "=================================================="
echo "           WinPodX Installer v${VERSION}"
echo "=================================================="
echo

#####################################
# Root check
#####################################

section "Checking sudo"

sudo -v || die "This installer requires sudo privileges."

log "Sudo access granted."

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
# CPU Architecture
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

section "Checking Virtualization"

if grep -Eq "(vmx|svm)" /proc/cpuinfo; then
    log "VT-x / AMD-V supported"
else
    die "VT-x / AMD-V is disabled in BIOS."
fi

#####################################
# KVM
#####################################

section "Checking KVM"

if [ -e /dev/kvm ]; then
    log "KVM available"
else
    warn "/dev/kvm not found."
    warn "Performance may be reduced."
fi

#####################################
# Memory
#####################################

section "Checking Memory"

TOTAL_RAM=$(free -g | awk '/Mem:/ {print $2}')

echo "Installed RAM : ${TOTAL_RAM} GB"

if [ "$TOTAL_RAM" -lt 8 ]; then
    warn "Recommended minimum RAM is 8 GB."
else
    log "Memory OK"
fi

#####################################
# CPU Cores
#####################################

section "Checking CPU Cores"

TOTAL_CPU=$(nproc)

echo "CPU Cores : ${TOTAL_CPU}"

#####################################
# Disk Space
#####################################

section "Checking Disk Space"

FREE_DISK=$(df -BG "$HOME" | awk 'NR==2 {gsub("G","",$4);print $4}')

echo "Available : ${FREE_DISK} GB"

if [ "$FREE_DISK" -lt 70 ]; then
    warn "Recommended free disk space is at least 70 GB."
else
    log "Disk space OK"
fi

#####################################
# Internet
#####################################

section "Checking Internet"

if ping -c1 github.com >/dev/null 2>&1; then
    log "Internet connection OK"
else
    die "No Internet connection."
fi

#####################################
# Summary
#####################################

section "System Summary"

echo "Linux      : $PRETTY_NAME"
echo "CPU        : ${TOTAL_CPU} Core(s)"
echo "RAM        : ${TOTAL_RAM} GB"
echo "Disk Free  : ${FREE_DISK} GB"

echo
log "System check completed."

echo
read -rp "Press Enter to continue..."

#####################################
# PART 2/5
# Install Dependencies
#####################################

section "Installing dependencies"

sudo apt update

PACKAGES=(
    curl
    wget
    git
    jq
    unzip
    qemu-utils
    genisoimage
    libvirt-clients
    uidmap
    slirp4netns
    fuse-overlayfs
)

for pkg in "${PACKAGES[@]}"; do
    if dpkg -s "$pkg" >/dev/null 2>&1; then
        log "$pkg already installed."
    else
        echo "Installing $pkg..."
        sudo apt install -y "$pkg"
    fi
done

#####################################
# Install Podman
#####################################

section "Installing Podman"

if command -v podman >/dev/null 2>&1; then

    log "Podman already installed."

else

    sudo apt install -y podman

    log "Podman installed."

fi

#####################################
# Install Podman Compose
#####################################

section "Installing Podman Compose"

if command -v podman-compose >/dev/null 2>&1; then

    log "podman-compose already installed."

else

    sudo apt install -y podman-compose

    log "podman-compose installed."

fi

#####################################
# Enable user services
#####################################

section "Configuring Podman"

systemctl --user daemon-reload || true

loginctl enable-linger "$USER" >/dev/null 2>&1 || true

#####################################
# Verify installation
#####################################

section "Verification"

echo
echo "Podman Version"

podman --version

echo

echo "Compose Version"

podman-compose --version || true

echo

log "Dependencies installed successfully."

echo
read -rp "Press Enter to continue..."

#####################################
# PART 3/5
# WinPodX Configuration Wizard
#####################################

section "WinPodX Configuration"

#####################################
# Auto Recommendation
#####################################

# RAM recommendation
if (( TOTAL_RAM <= 8 )); then
    REC_RAM="4G"
elif (( TOTAL_RAM <= 16 )); then
    REC_RAM="8G"
elif (( TOTAL_RAM <= 32 )); then
    REC_RAM="12G"
else
    REC_RAM="16G"
fi

# CPU recommendation
if (( TOTAL_CPU <= 4 )); then
    REC_CPU="2"
elif (( TOTAL_CPU <= 8 )); then
    REC_CPU="4"
else
    REC_CPU="6"
fi

# Disk recommendation
if (( FREE_DISK >= 160 )); then
    REC_DISK="120G"
elif (( FREE_DISK >= 120 )); then
    REC_DISK="100G"
elif (( FREE_DISK >= 80 )); then
    REC_DISK="80G"
else
    REC_DISK="64G"
fi

clear

echo
echo "=================================================="
echo "         Recommended Configuration"
echo "=================================================="
echo
printf "%-20s %s\n" "Detected RAM :" "${TOTAL_RAM} GB"
printf "%-20s %s\n" "Detected CPU :" "${TOTAL_CPU} Core"
printf "%-20s %s\n" "Free Disk :" "${FREE_DISK} GB"
echo
printf "%-20s %s\n" "Recommended RAM :" "$REC_RAM"
printf "%-20s %s\n" "Recommended CPU :" "$REC_CPU Core"
printf "%-20s %s\n" "Recommended Disk :" "$REC_DISK"
echo

read -rp "Use recommended settings? (Y/n): " AUTO

AUTO=${AUTO:-Y}

#####################################
# Windows
#####################################

while true; do

echo
echo "1) Windows 11 Pro"
echo "2) Windows 11 LTSC 2024 (Recommended)"
echo "3) Windows 10 Pro"
echo "4) Windows 10 LTSC"
echo "5) Tiny11"

read -rp "Choose Windows [1-5] (default:2): " WIN

WIN=${WIN:-2}

case "$WIN" in
1) WIN_VERSION="11"; WIN_NAME="Windows 11 Pro"; break ;;
2) WIN_VERSION="ltsc11"; WIN_NAME="Windows 11 LTSC 2024"; break ;;
3) WIN_VERSION="10"; WIN_NAME="Windows 10 Pro"; break ;;
4) WIN_VERSION="ltsc10"; WIN_NAME="Windows 10 LTSC"; break ;;
5) WIN_VERSION="tiny11"; WIN_NAME="Tiny11"; break ;;
*) echo "Invalid selection." ;;
esac

done

#####################################
# Auto Mode
#####################################

if [[ "$AUTO" =~ ^([Yy]|)$ ]]; then

RAM_SIZE="$REC_RAM"
CPU_CORES="$REC_CPU"
DISK_SIZE="$REC_DISK"

#####################################
# Custom Mode
#####################################

else

############ RAM ############

while true; do

read -rp "RAM (GB): " R

if [[ "$R" =~ ^[0-9]+$ ]] &&
(( R>=4 && R<=TOTAL_RAM )); then

RAM_SIZE="${R}G"
break

fi

echo "Invalid RAM."

done

############ CPU ############

while true; do

read -rp "CPU Cores: " C

if [[ "$C" =~ ^[0-9]+$ ]] &&
(( C>=2 && C<=TOTAL_CPU )); then

CPU_CORES="$C"
break

fi

echo "Invalid CPU."

done

############ DISK ###########

while true; do

read -rp "Disk Size (GB): " D

if [[ "$D" =~ ^[0-9]+$ ]] &&
(( D>=64 && D<=FREE_DISK )); then

DISK_SIZE="${D}G"
break

fi

echo "Invalid Disk."

done

fi

#####################################
# Summary
#####################################

clear

section "Configuration Summary"

printf "%-18s %s\n" "Windows :" "$WIN_NAME"
printf "%-18s %s\n" "RAM :" "$RAM_SIZE"
printf "%-18s %s\n" "CPU :" "$CPU_CORES Core"
printf "%-18s %s\n" "Disk :" "$DISK_SIZE"

echo

read -rp "Continue installation? (Y/n): " CONFIRM

case "$CONFIRM" in

""|Y|y)

export WIN_VERSION
export WINPODX_WIN_VERSION="$WIN_VERSION"

export RAM_SIZE
export CPU_CORES
export DISK_SIZE

log "Configuration saved."

;;

*)

die "Installation cancelled."

;;

esac

#####################################
# PART 4/5
# Install & Configure WinPodX
#####################################

section "Installing WinPodX"

curl -fsSL https://raw.githubusercontent.com/kernalix7/winpodx/main/install.sh | bash

log "WinPodX installation completed."

#####################################
# Paths
#####################################

CONFIG_DIR="$HOME/.config/winpodx"
COMPOSE_FILE="$CONFIG_DIR/compose.yaml"
TOML_FILE="$CONFIG_DIR/winpodx.toml"
IMAGE_FILE="$HOME/.local/share/winpodx/storage/data.img"

#####################################
# Wait for configuration files
#####################################

section "Waiting for WinPodX configuration"

for i in {1..30}; do
    if [[ -f "$COMPOSE_FILE" && -f "$TOML_FILE" ]]; then
        log "Configuration files detected."
        break
    fi
    sleep 1
done

[[ -f "$COMPOSE_FILE" ]] || die "compose.yaml not found."
[[ -f "$TOML_FILE" ]] || die "winpodx.toml not found."

#####################################
# Backup
#####################################

section "Creating backup"

cp -f "$COMPOSE_FILE" "$COMPOSE_FILE.bak"
cp -f "$TOML_FILE" "$TOML_FILE.bak"

log "Backup completed."

#####################################
# Update compose.yaml
#####################################

section "Updating compose.yaml"

sed -Ei "s|^([[:space:]]*)VERSION:.*|\1VERSION: \"$WIN_VERSION\"|" "$COMPOSE_FILE"
sed -Ei "s|^([[:space:]]*)RAM_SIZE:.*|\1RAM_SIZE: \"$RAM_SIZE\"|" "$COMPOSE_FILE"
sed -Ei "s|^([[:space:]]*)CPU_CORES:.*|\1CPU_CORES: \"$CPU_CORES\"|" "$COMPOSE_FILE"
sed -Ei "s|^([[:space:]]*)DISK_SIZE:.*|\1DISK_SIZE: \"$DISK_SIZE\"|" "$COMPOSE_FILE"

log "compose.yaml updated."

#####################################
# Update winpodx.toml
#####################################

section "Updating winpodx.toml"

RAM_GB="${RAM_SIZE%G}"

sed -i "s/^win_version = .*/win_version = \"$WIN_VERSION\"/" "$TOML_FILE"
sed -i "s/^cpu_cores = .*/cpu_cores = $CPU_CORES/" "$TOML_FILE"
sed -i "s/^ram_gb = .*/ram_gb = $RAM_GB/" "$TOML_FILE"
sed -i "s/^disk_size = .*/disk_size = \"$DISK_SIZE\"/" "$TOML_FILE"

log "winpodx.toml updated."

#####################################
# Resize virtual disk
#####################################

section "Checking virtual disk"

if [[ -f "$IMAGE_FILE" ]]; then

    CURRENT_SIZE=$(qemu-img info "$IMAGE_FILE" \
        | awk -F'[()]' '/virtual size/ {print $2}' \
        | sed 's/GiB/G/' \
        | cut -d'.' -f1)

    TARGET_SIZE="${DISK_SIZE%G}G"

    echo "Current : $CURRENT_SIZE"
    echo "Target  : $TARGET_SIZE"

    if [[ "$CURRENT_SIZE" != "$TARGET_SIZE" ]]; then

        section "Resizing virtual disk"

        qemu-img resize -f raw "$IMAGE_FILE" "$DISK_SIZE"

        log "Disk resized to $DISK_SIZE"

    else

        log "Virtual disk already at requested size."

    fi

else

    warn "data.img not found. Skipping resize."

fi

#####################################
# Restart WinPodX
#####################################

section "Restarting WinPodX"

cd "$CONFIG_DIR"

if command -v podman >/dev/null 2>&1; then

    podman compose down || true
    podman compose up -d

    log "WinPodX restarted."

else

    warn "Podman not found. Please restart WinPodX manually."

fi

#####################################
# Verify configuration
#####################################

section "Verification"

echo
grep "VERSION:" "$COMPOSE_FILE"
grep "RAM_SIZE:" "$COMPOSE_FILE"
grep "CPU_CORES:" "$COMPOSE_FILE"
grep "DISK_SIZE:" "$COMPOSE_FILE"

echo
grep "^win_version" "$TOML_FILE"
grep "^ram_gb" "$TOML_FILE"
grep "^cpu_cores" "$TOML_FILE"
grep "^disk_size" "$TOML_FILE"

echo
log "WinPodX configuration completed successfully."

###############################################################################
# P5 - Finish & Post Installation
###############################################################################

print_header() {
    echo
    echo "============================================================"
    echo " $1"
    echo "============================================================"
}

print_header "P5 - Finalizing Installation"

echo
echo "Checking WinPodX status..."

CONFIG_DIR="$HOME/.config/winpodx"
COMPOSE_FILE="$CONFIG_DIR/compose.yaml"
TOML_FILE="$CONFIG_DIR/winpodx.toml"

# Check configuration files
if [[ ! -f "$COMPOSE_FILE" ]]; then
    echo "❌ compose.yaml not found!"
    exit 1
fi

if [[ ! -f "$TOML_FILE" ]]; then
    echo "❌ winpodx.toml not found!"
    exit 1
fi

# Check Podman container
echo
echo "Container Status:"
podman ps --format "table {{.Names}}\t{{.Status}}" | grep -i winpod || true

echo
echo "Installed Configuration"
echo "----------------------------------------"
echo "Windows Version : $WIN_VERSION"
echo "RAM             : $RAM_SIZE"
echo "CPU Cores       : $CPU_CORES"
echo "Disk Size       : $DISK_SIZE"
echo "----------------------------------------"

echo
echo "Configuration files:"
echo "  $COMPOSE_FILE"
echo "  $TOML_FILE"

echo
echo "Useful Commands"
echo "----------------------------------------"
echo "Start VM   : cd ~/.config/winpodx && podman compose up -d"
echo "Stop VM    : cd ~/.config/winpodx && podman compose down"
echo "Restart VM : cd ~/.config/winpodx && podman compose restart"
echo "Logs       : cd ~/.config/winpodx && podman compose logs -f"
echo "----------------------------------------"

echo
echo "============================================================"
echo "          WinPodX Installation Completed!"
echo "============================================================"

echo
echo "Next steps:"
echo "  1. Open WinPodX from your Applications menu."
echo "  2. Wait for Windows initial setup."
echo "  3. Install WinApps if desired."
echo "  4. Enjoy Windows on Linux!"

echo
echo "Thank you for using WinPodX Installer."

