#!/bin/bash
#  _      ______ ____  __  __ _____ _   _
# | |    |  ____/ __ \|  \/  |_   _| \ | |
# | |    | |__ | |  | | \  / | | | |  \| |
# | |    |  __|| |  | | |\/| | | | | . ` |
# | |____| |___| |__| | |  | |_| |_| |\  |
# |______|______\____/|_|  |_|_____|_| \_|

set -e

# Cài đặt múi giờ
echo ">> Setting timezone to Asia/Ho_Chi_Minh"
sudo timedatectl set-timezone Asia/Ho_Chi_Minh

# Cập nhật hệ thống
echo ">> Updating system..."
sudo pacman -Syu --noconfirm

# Hàm cài đặt nếu gói chưa có
install_if_not_exist() {
    if ! pacman -Q "$1" &>/dev/null && ! yay -Q "$1" &>/dev/null; then
        echo ">> Installing $1..."
        yay -S --noconfirm "$1"
    else
        echo ">> $1 is already installed, skipping."
    fi
}

# Cài đặt các gói phần mềm
packages=(
    google-chrome
    postman
    dbeaver
    visual-studio-code-bin
    mongodb-compass
    fish
    docker
)

for pkg in "${packages[@]}"; do
    install_if_not_exist "$pkg"
done

# Cài Docker nếu chưa có
if ! pacman -Q docker &>/dev/null; then
    echo ">> Installing Docker..."
    sudo pacman -S --noconfirm docker
    sudo systemctl enable --now docker
else
    echo ">> Docker is already installed, skipping."
fi

# Đổi shell mặc định sang fish nếu chưa
CURRENT_SHELL=$(getent passwd "$USER" | cut -d: -f7)
if [ "$CURRENT_SHELL" != "/usr/bin/fish" ]; then
    echo ">> Changing default shell to fish for user $USER..."
    chsh -s /usr/bin/fish "$USER"
else
    echo ">> Default shell is already fish."
fi

# Cài fisher nếu chưa có
if ! fish -c "type -q fisher"; then
    echo ">> Installing fisher..."
    fish -c 'curl -sL https://git.io/fisher | source && fisher install jorgebucaran/fisher'
else
    echo ">> Fisher is already installed, skipping."
fi

# Cài các plugin cho Fish
fish_plugins=(
    gazorby/fish-abbreviation-tips
    jhillyerd/plugin-git
    jethrokuan/z
    jorgebucaran/autopair.fish
)

for plugin in "${fish_plugins[@]}"; do
    fish -c "fisher install $plugin"
done

# Kiểm tra fcitx5 đã có chưa
if ! pacman -Q fcitx5 &>/dev/null && ! yay -Q fcitx5 &>/dev/null; then
    echo ">> Installing fcitx5 and necessary packages..."
    sudo pacman -S --noconfirm fcitx5 fcitx5-configtool fcitx5-qt fcitx5-gtk yay
    yay -S --noconfirm fcitx5-bamboo
else
    echo ">> fcitx5 is already installed, skipping."
fi

# Kiểm tra xem các biến môi trường đã có trong file config.fish chưa
if ! grep -q "GTK_IM_MODULE fcitx" ~/.config/fish/config.fish; then
    echo ">> Setting up environment variables for fcitx5 in Fish shell..."
    cat <<EOF >>~/.config/fish/config.fish
# fcitx5 environment variables
set -Ux GTK_IM_MODULE fcitx
set -Ux QT_IM_MODULE fcitx
set -Ux XMODIFIERS @im=fcitx
set -Ux SDL_IM_MODULE fcitx
set -Ux GLFW_IM_MODULE fcitx
set -Ux INPUT_METHOD fcitx
EOF
else
    echo ">> Environment variables for fcitx5 are already set in Fish shell, skipping."
fi

# Thêm fcitx5 vào Hyprland để tự khởi động
echo ">> Adding fcitx5 to Hyprland..."
echo "exec-once = fcitx5 -d" >>~/.config/hypr/hyprland.conf

# Kiểm tra và cài Qt6 nếu chưa có
if ! pacman -Qi qt6-base &>/dev/null; then
    echo ">> Installing Qt6..."
    yay -S --noconfirm qt6-base-git
else
    echo ">> Qt6 is already installed, skipping."
fi

# Define the path for the Hyprland config
HYPR_CONFIG_FILE="$HOME/.config/hypr/hyprland.conf"

# Check if the config already contains the dock entry, if not, append it
if ! grep -q "nwg-dock-hyprland" "$HYPR_CONFIG_FILE"; then
    echo "exec-once = nwg-dock-hyprland --monitor HDMI-A-1 --dock-position bottom" >>"$HYPR_CONFIG_FILE"
    echo "Dock has been configured to appear on the HDMI-A-1 monitor."
else
    echo "Dock configuration already exists in $HYPR_CONFIG_FILE. Skipping."
fi

# Reload Hyprland to apply changes
echo "Reloading Hyprland..."
hyprctl reload

# Kiểm tra và cài đặt Wine nếu chưa có
if ! pacman -Q wine &>/dev/null; then
    echo ">> Installing Wine..."
    sudo pacman -S --noconfirm wine wine-mono wine-gecko winetricks
else
    echo ">> Wine is already installed, skipping."
fi
