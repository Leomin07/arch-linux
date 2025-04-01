#!/bin/bash

# Cập nhật hệ thống và cài đặt yay (nếu chưa có)
sudo pacman -Syu --noconfirm
sudo pacman -S --needed --noconfirm git base-devel

# Cài đặt yay từ AUR
git clone https://aur.archlinux.org/yay.git ~/yay
cd ~/yay
makepkg -si --noconfirm

# Cài đặt Hyprland từ AUR
yay -S hyprland

# Cài đặt các gói phụ trợ
sudo pacman -S firefox xorg-xwayland wayland wlroots hyprpaper hyprlock hypridle kitty rofi waybar mako polkit-kde-agent network-manager-applet pipewire wireplumber brightnessctl alsa-utils pavucontrol swaybg swaylock grim slurp

# Tạo thư mục cấu hình và sao chép cấu hình mặc định
mkdir -p ~/.config/hypr
cp /usr/share/hyprland/hyprland.conf ~/.config/hypr/

# Thêm Hyprland vào XDG_SESSION (nếu chưa có)
if ! grep -q 'exec Hyprland' ~/.xinitrc; then
  echo 'exec Hyprland' >> ~/.xinitrc
fi

# Khởi động Hyprland
Hyprland
