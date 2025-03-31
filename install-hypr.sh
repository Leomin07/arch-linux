#!/bin/bash

# Cập nhật hệ thống
sudo pacman -Syu --noconfirm

# Cài đặt các gói cần thiết
sudo pacman -S --noconfirm git base-devel sddm wayland xorg-xwayland

# Cài đặt Yay
cd /opt
sudo git clone https://aur.archlinux.org/yay.git
sudo chown -R $(whoami):$(whoami) yay
cd yay
makepkg -si --noconfirm

# Cài đặt Hyprland
yay -S --noconfirm hyprland hyprpaper hyprlock hypridle

# Cấu hình SDDM
sudo systemctl enable sddm
sudo systemctl start sddm
