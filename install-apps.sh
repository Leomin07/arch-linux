#!/bin/bash
#  _       ______ ____  __  __ _____ _  _
# | |     | ____/ __ \ \/ / |  ___| \ | |
# | |     | |__ | |  | \  /  | |_  |  \| |
# | |     |  __|| |  | |\/|  |  _| | . ` |
# | |____ | |___| |__| |  |  | |  | |\  |
# |______|______\____/|_|  |_|_____|_| \_|

set -e

# --- Configuration ---
TIMEZONE="Asia/Ho_Chi_Minh"
USER_NAME="MinhTD"
USER_EMAIL="tranminhsvp@gmail.com"
SSH_KEY_FILE="$HOME/.ssh/id_ed25519"
FISH_SHELL="/usr/bin/fish"

PACKAGES=(
    "google-chrome"
    "postman"
    "dbeaver"
    "visual-studio-code-bin"
    "mongodb-compass"
    "fish"
    "docker"
    "python"
    "nodejs"
    "yarn"
    "fcitx5"
    "fcitx5-configtool"
    "fcitx5-qt"
    "fcitx5-gtk"
    "fcitx5-bamboo"
    "qt6-base-git"
    "cloudflare-warp-bin"
)

FISH_PLUGINS=(
    "gazorby/fish-abbreviation-tips"
    "jhillyerd/plugin-git"
    "jethrokuan/z"
    "jorgebucaran/autopair.fish"
)

HYPR_CONFIG_FILE="$HOME/.config/hypr/hyprland.conf"
FISH_CONFIG_FILE="$HOME/.config/fish/config.fish"
# --- End Configuration ---

# --- Helper Functions ---
log_info() {
    echo ">> $1"
}

log_success() {
    echo "✅ $1"
}

log_warning() {
    echo "⚠️ $1"
}

is_installed() {
    local pkg="$1"
    pacman -Q "$pkg" &>/dev/null || yay -Q "$pkg" &>/dev/null
}

install_package() {
    local pkg="$1"
    if ! is_installed "$pkg"; then
        log_info "Installing $pkg..."
        yay -S --noconfirm "$pkg"
    else
        log_info "$pkg is already installed, skipping."
    fi
}

install_docker() {
    if ! is_installed "docker"; then
        log_info "Installing Docker..."
        sudo pacman -S --noconfirm docker && sudo systemctl enable --now docker
    else
        log_info "Docker is already installed, skipping."
    fi
}

set_default_shell() {
    local current_shell=$(getent passwd "$USER" | cut -d: -f7)
    if [ "$current_shell" != "$FISH_SHELL" ]; then
        log_info "Changing default shell to fish for user $USER..."
        sudo chsh -s "$FISH_SHELL" "$USER"
    else
        log_info "Default shell is already fish."
    fi
}

install_fisher() {
    if ! fish -c "type -q fisher"; then
        log_info "Installing fisher..."
        fish -c 'curl -sL https://git.io/fisher | source && fisher install jorgebucaran/fisher'
    else
        log_info "Fisher is already installed, skipping."
    fi
}

install_fish_plugins() {
    for plugin in "${FISH_PLUGINS[@]}"; do
        fish -c "fisher install $plugin"
    done
}

install_wine() {
    if ! is_installed "wine"; then
        log_info "Installing Wine..."
        sudo pacman -S --noconfirm wine wine-mono wine-gecko winetricks
    else
        log_info "Wine is already installed, skipping."
    fi
}

configure_git() {
    git config --global user.name "$USER_NAME"
    git config --global user.email "$USER_EMAIL"

    if [ ! -f "$SSH_KEY_FILE" ]; then
        log_info "Generating SSH key..."
        ssh-keygen -t ed25519 -C "$USER_EMAIL" -f "$SSH_KEY_FILE" -N ""
        eval "$(ssh-agent -s)"
        ssh-add --apple-use-keychain "$SSH_KEY_FILE"
        pbcopy <"$SSH_KEY_FILE.pub"
        log_success "SSH key đã copy vào clipboard. Dán lên GitHub: https://github.com/settings/keys"
    else
        log_success "SSH key đã tồn tại (bỏ qua)"
    fi
}

configure_fcitx5() {
    log_info "Setting up fcitx5..."

    # Install necessary packages
    install_package "fcitx5"
    install_package "fcitx5-configtool"
    install_package "fcitx5-qt"
    install_package "fcitx5-gtk"
    install_package "fcitx5-bamboo"

    # Set environment variables in Fish shell
    if ! grep -q "GTK_IM_MODULE fcitx" "$FISH_CONFIG_FILE"; then
        log_info "Setting up environment variables for fcitx5 in Fish shell..."
        cat <<EOF >>"$FISH_CONFIG_FILE"
# fcitx5 environment variables
set -Ux GTK_IM_MODULE fcitx
set -Ux QT_IM_MODULE fcitx
set -Ux XMODIFIERS @im=fcitx
set -Ux SDL_IM_MODULE fcitx
set -Ux GLFW_IM_MODULE fcitx
set -Ux INPUT_METHOD fcitx
EOF
    else
        log_info "Environment variables for fcitx5 are already set in Fish shell, skipping."
    fi

    # Add fcitx5 to Hyprland autostart
    if ! grep -q "exec-once = fcitx5 -d" "$HYPR_CONFIG_FILE"; then
        log_info "Adding fcitx5 to Hyprland autostart..."
        echo "exec-once = fcitx5 -d" >>"$HYPR_CONFIG_FILE"
    else
        log_info "fcitx5 is already in Hyprland autostart, skipping."
    fi

    # Install Qt6
    install_package "qt6-base-git"
}

configure_warp() {
    log_info "Setting up Cloudflare WARP..."
    install_package "cloudflare-warp-bin"

    if warp-cli status | grep -q "Disconnected"; then
        log_info "Registering Cloudflare WARP..."
        warp-cli registration new
        log_info "Connecting to Cloudflare WARP..."
        warp-cli connect
        if warp-cli status | grep -q "Connected"; then
            log_success "Cloudflare WARP connected successfully."
        else
            log_warning "Failed to connect to Cloudflare WARP. Check logs with 'journalctl -u warp-svc'."
        fi
    else
        log_info "Cloudflare WARP is already connected or in a connecting state."
    fi
}
# --- End Helper Functions ---

# --- Main Script ---

log_info "Setting timezone to $TIMEZONE"
sudo timedatectl set-timezone "$TIMEZONE"

log_info "Updating system..."
sudo pacman -Syu --noconfirm

# Install packages
for pkg in "${PACKAGES[@]}"; do
    install_package "$pkg"
done

install_docker
set_default_shell
install_fisher
install_fish_plugins
install_wine
configure_fcitx5
configure_warp
configure_git

log_info "Reloading Hyprland to apply changes..."
hyprctl reload

log_success "Thiết lập hoàn tất!"

# --- End Main Script ---
