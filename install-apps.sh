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
WORKSPACE_CONFIG="$HOME/.config/hypr/workspaces.conf"
OLD_MONITOR="monitor:DP-1"
NEW_MONITOR="monitor:HDMI-A-1"

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
)

FISH_PLUGINS=(
    "gazorby/fish-abbreviation-tips"
    "jhillyerd/plugin-git"
    "jethrokuan/z"
    "jorgebucaran/autopair.fish"
)
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
        sudo pacman -S --noconfirm docker
        sudo systemctl enable --now docker
    else
        log_info "Docker is already installed, skipping."
    fi
}

set_default_shell() {
    local current_shell=$(getent passwd "$USER" | cut -d: -f7)
    if [ "$current_shell" != "$FISH_SHELL" ]; then
        log_info "Changing default shell to fish for user $USER..."
        chsh -s "$FISH_SHELL" "$USER"
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
        ssh-keygen -t ed25519 -C "$USER_EMAIL" -f "$SSH_KEY_FILE" -N ""
        eval "$(ssh-agent -s)"
        ssh-add --apple-use-keychain "$SSH_KEY_FILE"
        pbcopy < "$SSH_KEY_FILE.pub"
        log_success "SSH key đã copy vào clipboard. Dán lên GitHub: https://github.com/settings/keys"
    else
        log_success "SSH key đã tồn tại (bỏ qua)"
    fi
}

replace_monitor_in_config() {
    if [ -f "$WORKSPACE_CONFIG" ]; then
        sed -i "s/$OLD_MONITOR/$NEW_MONITOR/g" "$WORKSPACE_CONFIG"
        log_info "Replaced all instances of '$OLD_MONITOR' with '$NEW_MONITOR' in '$WORKSPACE_CONFIG'."
        # cat "$WORKSPACE_CONFIG" # Optional: Print the modified file
    else
        log_warning "Workspace config file '$WORKSPACE_CONFIG' not found, skipping monitor replacement."
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
configure_git

# Replace monitor in Hyprland workspace config
replace_monitor_in_config

log_success "Thiết lập hoàn tất!"

# --- End Main Script ---
