#!/bin/bash

# Cập nhật hệ thống
echo "Cập nhật hệ thống..."
sudo pacman -Syu --noconfirm

# Cài đặt Postman từ AUR
echo "Cài đặt Postman..."
yay -S --noconfirm postman

# Cài đặt DBeaver từ AUR
echo "Cài đặt DBeaver..."
yay -S --noconfirm dbeaver

# Cài đặt Visual Studio Code (VSCode) từ AUR
echo "Cài đặt Visual Studio Code..."
yay -S --noconfirm visual-studio-code-bin

# Cài đặt Docker
echo "Cài đặt Docker..."
sudo pacman -S --noconfirm docker

# Cài đặt MongoDB Compass từ AUR
echo "Cài đặt MongoDB Compass..."
yay -S --noconfirm mongodb-compass

# Cài đặt Google Chrome từ AUR
echo "Cài đặt Google Chrome..."
yay -S --noconfirm google-chrome

# Bắt đầu Docker service
echo "Khởi động Docker..."
sudo systemctl start docker
sudo systemctl enable docker

# Kiểm tra Docker version
docker --version

