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

# Clone repo Arch-Hyprland
echo "Cloning Arch-Hyprland repository..."
git clone https://github.com/JaKooLit/Arch-Hyprland.git ~/Arch-Hyprland

# Chạy script cài đặt của Arch-Hyprland
echo "Running Arch-Hyprland install script..."
cd ~/Arch-Hyprland && chmod +x install.sh && ./install.sh

