#!/bin/bash

#  _      ______ ____  __  __ _____ _   _
# | |    |  ____/ __ \|  \/  |_   _| \ | |
# | |    | |__ | |  | | \  / | | | |  \| |
# | |    |  __|| |  | | |\/| | | | | . ` |
# | |____| |___| |__| | |  | |_| |_| |\  |
# |______|______\____/|_|  |_|_____|_| \_|

sudo pacman -Syu --noconfirm

sudo pacman -S --needed base-devel git --noconfirm

git clone https://aur.archlinux.org/yay-bin.git

cd yay-bin

makepkg -si --noconfirm

cd ..
rm -rf yay-bin

yay --version

git clone --depth 1 https://github.com/HyDE-Project/HyDE ~/HyDE
cd ~/HyDE/Scripts
./install.sh
