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

# Tạo thư mục config
mkdir -p ~/.config/hypr

# Thêm cấu hình mặc định cho Hyprland
cat <<EOT > ~/.config/hypr/hyprland.conf
# Cấu hình cơ bản
monitor=,preferred,auto,auto
general {
  gaps_in=5
gaps_out=10
  border_size=2
  col.active_border=0xff89b4fa
  col.inactive_border=0xff6c7086
}

decoration {
  rounding=10
}

animations {
  enabled=1
  bezier=overshot,0.13,0.99,0.29,1.1
  animation=windows,1,7,overshot
  animation=border,1,10,default
  animation=fade,1,7,default
  animation=workspaces,1,6,overshot
}

master {
  new_is_master=true
}
EOT

# Thông báo hoàn tất
echo "Cài đặt hoàn tất! Khởi động lại hệ thống để áp dụng thay đổi."
