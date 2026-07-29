









#!/usr/bin/env bash

#############################################
# WinPodX Configuration Wizard
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
