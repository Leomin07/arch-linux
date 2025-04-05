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
    python  # Thêm python vào danh sách
    nodejs  # Thêm nodejs vào danh sách
    yarn    # Thêm yarn vào danh sách
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
