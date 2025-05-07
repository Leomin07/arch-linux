#!/bin/bash

echo "Bắt đầu cài đặt DWM, Polybar, Rofi, SDDM và Yay..."

# Cập nhật danh sách gói
echo "Đang cập nhật danh sách gói..."
sudo pacman -Syu --noconfirm

# Cài đặt các gói cần thiết
echo "Đang cài đặt DWM, Polybar, Rofi, xorg-xinit, xterm, kitty và base-devel..."
sudo pacman -S --needed --noconfirm dwm polybar rofi xorg-xinit xterm kitty base-devel

# Cài đặt yay
echo "Đang cài đặt yay..."
git clone https://aur.archlinux.org/yay.git /tmp/yay
cd /tmp/yay
makepkg -si --noconfirm
cd ~
rm -rf /tmp/yay

# Sao chép cấu hình DWM
echo "Đang sao chép cấu hình DWM mặc định..."
mkdir -p ~/.dwm
cp /usr/share/dwm/config.def.h ~/.dwm/config.h

# Biên dịch và cài đặt DWM
echo "Đang biên dịch và cài đặt DWM..."
cd ~/.dwm
make
sudo make install
cd ~

# Tạo thư mục cấu hình Polybar
echo "Đang tạo thư mục cấu hình Polybar..."
mkdir -p ~/.config/polybar

# Sao chép cấu hình Polybar mặc định (nếu có) hoặc tạo tệp trống
if [ -f /etc/polybar/config ]; then
    echo "Đang sao chép cấu hình Polybar mặc định..."
    cp /etc/polybar/config ~/.config/polybar/config
else
    echo "Tạo tệp cấu hình Polybar trống..."
    touch ~/.config/polybar/config
fi

# Tạo thư mục cấu hình Rofi
echo "Đang tạo thư mục cấu hình Rofi..."
mkdir -p ~/.config/rofi
touch ~/.config/rofi/config

# Tạo script khởi động DWM với Kitty và Polybar
echo "Đang tạo script khởi động DWM..."
cat <<EOF > ~/.dwm-start
#!/bin/bash

killall -q polybar
if type "polybar" > /dev/null 2>&1; then
    polybar example &
fi
export TERMINAL=kitty
exec dwm
EOF
chmod +x ~/.dwm-start

# Cập nhật ~/.xinitrc
echo "Đang cập nhật ~/.xinitrc..."
if [ -f ~/.xinitrc ]; then
    echo "Đang sao lưu ~/.xinitrc cũ thành ~/.xinitrc.bak..."
    mv ~/.xinitrc ~/.xinitrc.bak
fi
cat <<EOF > ~/.xinitrc
#!/bin/bash
exec ~/.dwm-start
EOF
chmod +x ~/.xinitrc

# Cài đặt và kích hoạt SDDM
echo "Đang cài đặt và kích hoạt SDDM..."
sudo pacman -S --needed --noconfirm sddm
sudo systemctl enable sddm.service

echo "Hoàn tất cài đặt DWM, Polybar, Rofi, SDDM và Yay!"
echo "Khởi động lại hệ thống để sử dụng SDDM."
echo "Bạn có thể tùy chỉnh cấu hình trong ~/.dwm/, ~/.config/polybar/config và ~/.config/rofi/config."
