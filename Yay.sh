cd
sudo git clone https://aur.archlinux.org/yay.git
sudo chown -R minhtd:minhtd yay
cd yay
makepkg -si -y
yay -Suy -y
