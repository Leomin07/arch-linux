#!/bin/bash

# Cập nhật hệ thống
sudo pacman -Syu --noconfirm -y

# Cài đặt các gói cần thiết
sudo pacman -S --noconfirm -y git base-devel sddm wayland wayland-protocols wlroots xdg-desktop-portal-hyprland 
sudo pacman -S --noconfirm -y hyprland waybar kitty rofi dunst brightnessctl pavucontrol network-manager-applet 
sudo pacman -S --noconfirm -y grim slurp wl-clipboard xclip udisk2

# Cài đặt yay nếu chưa có
if ! command -v yay &> /dev/null; then
    git clone https://aur.archlinux.org/yay.git
    sudo chown -R $(whoami):$(whoami) yay
    cd yay
    makepkg -si --noconfirm -y
    cd ..
    rm -rf yay
fi

# Cài đặt các gói AUR
yay -S --noconfirm -y hyprland-git hyprpaper-git hyprcursor-git grimblast

# Kích hoạt SDDM
sudo systemctl enable sddm
sudo systemctl start sddm

# Tạo thư mục cấu hình
mkdir -p ~/.config/hypr

# Cấu hình Hyprland
cat <<EOT > ~/.config/hypr/hyprland.conf
# Hyprland Config

monitor=,preferred,auto,auto

general {
    gaps_in = 5
    gaps_out = 10
    border_size = 2
    col.active_border = rgba(33ccffee) 
    col.inactive_border = rgba(595959aa)
}

decoration {
    rounding = 10
    blur {
        enabled = true
        size = 8
        passes = 3
    }
}

animations {
    enabled = true
}

input {
    kb_layout = us
    follow_mouse = 1
}

exec-once = waybar &
exec-once = nm-applet &
exec-once = hyprpaper &
EOT

# Xử lý lỗi thường gặp
cat <<EOT > ~/.config/hypr/fix_common_issues.sh
#!/bin/bash

echo "Đang sửa lỗi thường gặp..."

# Kiểm tra và sửa lỗi missing xdg-desktop-portal
if ! pgrep -x "xdg-desktop-portal" > /dev/null; then
    echo "Khởi động xdg-desktop-portal"
    /usr/lib/xdg-desktop-portal &
fi

# Kiểm tra và sửa lỗi Wayland session
if [ -z "$WAYLAND_DISPLAY" ]; then
    echo "Wayland session chưa được thiết lập. Hãy đăng nhập lại với SDDM."
fi

# Sửa lỗi liên quan đến cấu hình không tồn tại
sed -i '/decoration:drop_shadow/d' ~/.config/hypr/hyprland.conf
sed -i '/decoration:shadow_range/d' ~/.config/hypr/hyprland.conf
sed -i '/decoration:shadow_render_power/d' ~/.config/hypr/hyprland.conf

echo "Hoàn tất sửa lỗi!"
EOT

chmod +x ~/.config/hypr/fix_common_issues.sh

# Khởi động lại để áp dụng thay đổi
echo "Cài đặt hoàn tất! Vui lòng khởi động lại máy."
