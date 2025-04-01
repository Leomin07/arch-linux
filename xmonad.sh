#!/bin/bash
sudo pacman -Syu
sudo pacman -S xmonad xmonad-contrib ghc
mkdir -p ~/.xmonad
sudo pacman -S xmobar

git clone https://gitlab.com/dwt1/dotfiles.git
