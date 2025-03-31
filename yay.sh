#!/bin/bash

# Cập nhật hệ thống
sudo pacman -Syu --noconfirm

# Cài đặt các gói cần thiết để biên dịch AUR packages
sudo pacman -S --needed base-devel git --noconfirm

# Clone kho chứa yay từ AUR
git clone https://aur.archlinux.org/yay-bin.git

# Di chuyển vào thư mục yay-bin
cd yay-bin

# Biên dịch và cài đặt yay
makepkg -si --noconfirm

# Quay lại thư mục trước đó và xóa thư mục cài đặt
cd ..
rm -rf yay-bin

# Kiểm tra phiên bản yay để xác nhận cài đặt thành công
yay --version
