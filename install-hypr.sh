cd
sudo git clone https://aur.archlinux.org/yay.git
sudo chown -R minhtd:minhtd yay-git/
cd yay/
makepkg -s
yay -Suy
cd /opt
sudo git clone https://github.com/SolDoesTech/hyprland.git
sudo chown -R minhtd:minhtd hyprland/
cd hyprland/
chmod +x set-hypr
./set-hypr
