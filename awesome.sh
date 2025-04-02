#!/bin/bash

# Cập nhật hệ thống
sudo pacman -Syu --noconfirm

# Cài đặt các gói cần thiết
sudo pacman -S git awesome sddm betterlockscreen --noconfirm

# Clone repository
cd ~
git clone https://github.com/MeledoJames/awesome-setup

# Sao chép cấu hình
cp -r ~/awesome-setup/config/* ~/.config
cp -r ~/awesome-setup/fonts/* ~/.local/share/fonts

# Tải lại cache font
fc-cache -v -f

# Cấu hình SDDM
sudo cp -r ~/.config/sddm/sugar-candy /usr/share/sddm/themes/
sudo cp -r ~/.config/sddm/sddm.conf /etc/

# Kích hoạt betterlockscreen
systemctl enable betterlockscreen@$USER

# Sao chép các file cấu hình cá nhân
cp -r ~/awesome-setup/cmatrix.sh \
      ~/awesome-setup/grubupdate.sh \
      ~/awesome-setup/.xinitrc \
      ~/awesome-setup/.Xresources \
      ~/awesome-setup/.zprofile \
      ~/awesome-setup/.zshrc ~/

# Thông báo hoàn thành
echo "Cài đặt Awesome WM hoàn tất! Hãy khởi động lại hệ thống."
