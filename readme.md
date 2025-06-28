### Setting fcitx5

```
sudo nano /usr/share/applications/google-chrome.desktop
```

- Find line **Exec** and replace

```
Exec=/usr/bin/google-chrome-stable --enable-features=UseOzonePlatform --ozone-platform=wayland --enable-wayland-ime %U
```

### Virtual Machine Manager

```
sudo apt isntall ssh-askpass virt-manager
```

### Dump setting extensions

- Dump

```
dconf dump /org/gnome/shell/extensions/ > dump_extensions.txt
```

- Load file

```
dconf load /org/gnome/shell/extensions/ < dump_extensions.txt
```
