# Dừng và xóa container
podman stop winpodx-windows 2>/dev/null
podman rm -f winpodx-windows 2>/dev/null

# Xóa image Windows (nếu còn)
podman rmi -f ghcr.io/dockur/windows:latest 2>/dev/null
podman image prune -af

# Xóa dữ liệu WinPodX
rm -rf ~/.local/share/winpodx
rm -rf ~/.config/winpodx
rm -rf ~/.cache/winpodx

# Xóa launcher
rm -f ~/.local/share/applications/winpodx.desktop

# Làm mới menu
update-desktop-database ~/.local/share/applications 2>/dev/null || true