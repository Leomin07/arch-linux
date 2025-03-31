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
yay -S hyprland waybar rofi dunst alacritty neovim --noconfirm

# Tạo thư mục cấu hình Hyprland
echo "Cấu hình Hyprland..."
mkdir -p ~/.config/hypr
cp /usr/share/hyprland/hyprland.conf ~/.config/hypr/

# Cấu hình biến môi trường
echo "Cấu hình biến môi trường..."
cat <<EOL >> ~/.bashrc
export XDG_SESSION_TYPE=wayland
export GDK_BACKEND=wayland
export QT_QPA_PLATFORM=wayland
export CLUTTER_BACKEND=wayland
EOL
source ~/.bashrc

# Chỉnh sửa file cấu hình Hyprland
echo "Chỉnh sửa file cấu hình Hyprland..."
cat <<EOL > ~/.config/hypr/hyprland.conf
monitor=,preferred,auto,auto

# Phím tắt
bind=SUPER, RETURN, exec, alacritty
bind=SUPER, Q, killactive
bind=SUPER, E, exec, rofi -show drun
bind=SUPER, V, togglefloating
bind=SUPER SHIFT, S, exec, grimblast copy area
bind=SUPER, F, fullscreen

# Hiệu ứng
animation=windows, 1, 3, default
animation=border, 1, 10, default

# Thanh trạng thái
exec-once=waybar &
exec-once=dunst &
EOL

# Cấu hình trình quản lý đăng nhập
sudo pacman -S sddm --noconfirm
echo "Cấu hình SDDM..."
sudo systemctl enable sddm


echo "Cài đặt và cấu hình hoàn tất! Khởi động lại hệ thống và chọn Hyprland."
