Install Hyprland...

### Setting nwg-dock-hyprland

- Add option **-o HDMI-A-1 (or DP-1)**

```
 nwg-dock-hyprland -i 32 -w 5 -mb 10 -ml 10 -mr 10 -x -s $style -c  "rofi -show drun" -o HDMI-A-1
```
https://codeberg.org/XADE/dotbin/wiki
https://github.com/tokisuno/dotfiles
https://github.com/darkkal44/Cozytile/
https://github.com/antoniosarosi/dotfiles/tree/master/.config/qtile

### Setting fcitx5 

```
sudo nano /usr/share/applications/google-chrome.desktop
```
- Find line **Exec** and replace

```
Exec=/usr/bin/google-chrome-stable --enable-features=UseOzonePlatform --ozone-platform=wayland --enable-wayland-ime %U
```
