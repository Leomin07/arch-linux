#!/bin/bash

echo "Cập nhật hệ thống và cài đặt yay..."
# Cập nhật hệ thống
sudo pacman -Syu --noconfirm

# Cài đặt base-devel và git nếu chưa có
sudo pacman -S --needed base-devel git --noconfirm

# Clone và cài đặt yay nếu chưa có
if ! command -v yay &> /dev/null; then
    git clone https://aur.archlinux.org/yay-bin.git
    cd yay-bin
    makepkg -si --noconfirm
    cd ..
    rm -rf yay-bin
else
    echo "yay đã được cài đặt!"
fi

# Kiểm tra phiên bản yay
yay --version

echo "Cài đặt HyprV2..."
# Clone repository HyprV2
git clone https://github.com/SolDoesTech/HyprV2.git

# Di chuyển vào thư mục HyprV2
cd HyprV2

# Cấp quyền thực thi cho script set-hypr
chmod +x set-hypr

# Chạy script set-hypr
./set-hypr
