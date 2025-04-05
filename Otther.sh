
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

echo ">> Installation complete!"
