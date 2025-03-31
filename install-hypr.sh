#!/bin/bash

# Lấy tên người dùng hiện tại
USER_NAME=$(whoami)

# Cập nhật hệ thống
echo "Cập nhật hệ thống..."
sudo pacman -Syu --noconfirm

# Cài đặt yay nếu chưa có
echo "Cài đặt yay..."
sudo pacman -S --needed base-devel git --noconfirm
if ! command -v yay &> /dev/null; then
    git clone https://aur.archlinux.org/yay-bin.git
    cd yay-bin
    makepkg -si --noconfirm
    cd ..
    rm -rf yay-bin
fi

echo "Cập nhật hệ thống với yay..."
yay -Suy --noconfirm

# Cài đặt Hyprland và các gói liên quan
echo "Cài đặt Hyprland và các gói hỗ trợ..."
yay -S hyprland waybar rofi dunst alacritty neovim grimblast brightnessctl pavucontrol nwg-look --noconfirm

# Tạo thư mục cấu hình Hyprland
echo "Cấu hình Hyprland..."
mkdir -p ~/.config/hypr

# Chỉnh sửa file cấu hình Hyprland
echo "Chỉnh sửa file cấu hình Hyprland..."
cat <<EOL > ~/.config/hypr/hyprland.conf
monitor=,preferred,auto,auto

general {
    gaps_in = 5
    gaps_out = 10
    border_size = 3
    col.active_border = rgba(33ccffee) rgba(116677ff) 45deg
    col.inactive_border = rgba(595959aa)
    layout = dwindle
}

input {
    kb_layout = us
    follow_mouse = 1
    touchpad {
        natural_scroll = yes
    }
}

bind = SUPER, RETURN, exec, alacritty
bind = SUPER, Q, killactive
bind = SUPER, E, exec, rofi -show drun
bind = SUPER, V, togglefloating
bind = SUPER SHIFT, S, exec, grimblast copy area
bind = SUPER, F, fullscreen
bind = SUPER, LEFT, movefocus, l
bind = SUPER, RIGHT, movefocus, r
bind = SUPER, UP, movefocus, u
bind = SUPER, DOWN, movefocus, d
bind = SUPER ALT, LEFT, resizeactive, -20 0
bind = SUPER ALT, RIGHT, resizeactive, 20 0
bind = SUPER ALT, UP, resizeactive, 0 -20
bind = SUPER ALT, DOWN, resizeactive, 0 20
bind = SUPER, SPACE, togglefloating
bind = SUPER, TAB, cyclenext

animation {
    enabled = true
    animation = windows, 1, 5, default
    animation = border, 1, 10, default
    animation = fade, 1, 10, default
}

decoration {
    rounding = 10
    blur {
        enabled = true
        size = 10
        passes = 2
    }
    drop_shadow = true
    shadow_range = 20
    shadow_render_power = 2
}

autostart {
    waybar &
    dunst &
    nm-applet &
    pavucontrol &
}
EOL

# Cấu hình biến môi trường
echo "Cấu hình biến môi trường..."
cat <<EOL >> ~/.bashrc
export XDG_SESSION_TYPE=wayland
export GDK_BACKEND=wayland
export QT_QPA_PLATFORM=wayland
export CLUTTER_BACKEND=wayland
EOL
source ~/.bashrc

# Cấu hình trình quản lý đăng nhập
sudo pacman -S sddm --noconfirm
echo "Cấu hình SDDM..."
sudo systemctl enable sddm


echo "Cài đặt và cấu hình hoàn tất! Khởi động lại hệ thống và chọn Hyprland."
