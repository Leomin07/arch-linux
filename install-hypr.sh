#!/bin/bash

git clone https://github.com/b3nj5m1n/dotfiles
cd dotfiles/other/arch-meta/
makepkg -s
source PKGBUILD && yay -Syu --needed
