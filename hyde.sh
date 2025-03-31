#!/bin/bash

# Cập nhật hệ thống
echo "Updating system..."
sudo pacman -Syu --noconfirm

# Cài đặt các gói cần thiết
echo "Installing required packages..."
sudo pacman -S --needed --noconfirm git base-devel

# Cài đặt yay (nếu chưa có)
if ! command -v yay &> /dev/null; then
    echo "Installing yay..."
    git clone https://aur.archlinux.org/yay.git
    cd yay && makepkg -si --noconfirm && cd .. && rm -rf yay
fi

# Clone repo Hyde
echo "Cloning Hyde repository..."
git clone https://github.com/Hyde-project/hyde.git ~/HyDE

# Chạy script cài đặt của Hyde
echo "Running Hyde install script..."
cd ~/HyDE/Scripts/ && chmod +x install.sh && ./install.sh

# Hoàn tất
echo "Hyde installation complete! Restart your session to use Hyde."
