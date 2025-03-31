#!/bin/bash

# Lấy username của người dùng hiện tại
USER_NAME=$(whoami)

# Cài đặt yay
echo "Đang cài đặt yay..."
sudo git clone https://aur.archlinux.org/yay.git
sudo chown -R $USER_NAME:$USER_NAME yay
cd yay
makepkg -s
cd ..
rm -rf yay  # Xóa thư mục sau khi cài đặt yay xong

# Cập nhật hệ thống với yay
yay -Suy --noconfirm

# Cài đặt Hyprland
echo "Đang cài đặt Hyprland..."
cd /opt
sudo git clone https://github.com/SolDoesTech/hyprland.git
sudo chown -R $USER_NAME:$USER_NAME hyprland
cd hyprland
chmod +x set-hypr
./set-hypr
