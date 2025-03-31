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
