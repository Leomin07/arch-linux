#!/bin/bash

# Kiểm tra quyền root
if [ "$(id -u)" -ne 0 ]; then
  echo "Vui lòng chạy với quyền root."
  exit 1
fi

# Cài đặt các phụ thuộc cần thiết
echo "Cập nhật hệ thống và cài đặt các phụ thuộc..."
sudo pacman -Syu --noconfirm
sudo pacman -S --noconfirm git base-devel stack

# Clone repository XMonad và di chuyển đến thư mục cấu hình
echo "Cloning repository XMonad..."
git clone https://github.com/NeshHari/XMonad.git
mv XMonad starter_kit_dots
cd starter_kit_dots

# Xoá các file không cần thiết
echo "Xoá README.md và setup.sh..."
rm README.md setup.sh

# Sử dụng stow để áp dụng cấu hình
echo "Áp dụng cấu hình với stow..."
stow *

# Cài đặt và cấu hình XMonad
echo "Cài đặt XMonad từ nguồn..."
cd ~/.config/xmonad
rm -r xmonad xmonad-contrib
git clone https://github.com/xmonad/xmonad.git
git clone https://github.com/xmonad/xmonad-contrib.git

# Khởi tạo và cài đặt XMonad bằng stack
echo "Khởi tạo và cài đặt XMonad bằng stack..."
stack init
stack install

# Tạo liên kết tượng trưng cho xmonad
echo "Tạo liên kết tượng trưng cho xmonad..."
sudo ln -s ~/.local/bin/xmonad /usr/bin

# Biên dịch và khởi động lại XMonad
echo "Biên dịch lại và khởi động lại XMonad..."
xmonad --recompile && xmonad --restart

# echo "Cài đặt hoàn tất. Hệ thống của bạn đã sẵn sàng để sử dụng XMonad."
