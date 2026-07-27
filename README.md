# Cài đặt Winpodx
```` Bash
bash <(curl -fsSL https://raw.githubusercontent.com/longnguyen2026/install-winpodx/main/install.sh)
````
# Gỡ Winpodx
```` Bash
bash <(curl -fsSL https://raw.githubusercontent.com/longnguyen2026/install-winpodx/main/uninstall-winpodx.sh)
````
# Kiểm tra port chạy trên trình duyệt
Cửa sổ lệnh chạy:
```` Bash
podman port winpodx-windows
```
#Kết quả
3389/tcp -> 127.0.0.1:3390
445/tcp -> 127.0.0.1:4445
8006/tcp -> 127.0.0.1:8007
8765/tcp -> 127.0.0.1:8765
3389/udp -> 127.0.0.1:3390
=> Dòng thứ 3 là dòng địa chỉ sử dụng
