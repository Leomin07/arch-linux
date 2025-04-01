#!/bin/bash

# Script cài đặt dots-hyprland từ end-4

set -e  # Dừng script khi có lỗi

# Cập nhật hệ thống
sudo pacman -Syu --noconfirm

# Cài đặt các gói cần thiết
sudo pacman -S --noconfirm git curl bash

# Tải và chạy script cài đặt từ repo chính thức
bash <(curl -s "https://end-4.github.io/dots-hyprland-wiki/setup.sh")

# Hoàn tất
echo "Cài đặt dots-hyprland hoàn tất! Hãy khởi động lại để áp dụng thay đổi."
