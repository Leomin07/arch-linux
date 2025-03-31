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

# Cài đặt Hyprland và các tiện ích
echo "Installing Hyprland and dependencies..."
yay -S --noconfirm hyprland rofi waybar wofi dunst kitty thunar pavucontrol \
     polkit-gnome grim slurp swappy mako alacritty starship \
     brightnessctl nwg-look ttf-jetbrains-mono-nerd

# Clone repo Hyprdots
echo "Cloning Hyprdots repository..."
git clone --recurse-submodules https://github.com/prasanthrangan/hyprdots.git ~/.config/hyprdots

# Chạy script cài đặt
echo "Running Hyprdots install script..."
cd ~/.config/hyprdots && ./install.sh

# Hoàn tất
echo "Hyprdots installation complete! Restart your session and select Hyprland."
