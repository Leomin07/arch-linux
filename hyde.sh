#!/bin/bash

# Script cài đặt Hyprland trên Debian Testing/Unstable
echo "Cập nhật hệ thống..."
sudo apt update && sudo apt full-upgrade -y

echo "Cài đặt các gói cần thiết..."
sudo apt install -y git curl wget

# Clone repo
INSTALL_DIR=~/Debian-Hyprland
echo "Cloning Debian-Hyprland repository..."
git clone --depth=1 https://github.com/JaKooLit/Debian-Hyprland.git $INSTALL_DIR
cd $INSTALL_DIR

# Cấp quyền thực thi và chạy script cài đặt
echo "Chạy script cài đặt..."
chmod +x install.sh
./install.sh

# Nếu sử dụng NVIDIA, chạy script liên quan
echo "Kiểm tra và chạy NVIDIA script nếu cần..."
if [ -f install-scripts/nvidia.sh ]; then
    chmod +x install-scripts/nvidia.sh
    ./install-scripts/nvidia.sh
fi

echo "Hoàn tất cài đặt Hyprland! Khởi động lại hệ thống để áp dụng thay đổi."
