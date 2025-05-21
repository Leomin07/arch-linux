#!/bin/bash
set -euo pipefail

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

log_error() {
    echo "❌ $1"
}

is_installed() {
    local pkg="$1"
    pacman -Q "$pkg" &>/dev/null || yay -Q "$pkg" &>/dev/null
}

remove_package() {
    local pkg="$1"
    if is_installed "$pkg"; then
        log_info "Removing $pkg..."
        yay -Rns --noconfirm "$pkg"
    else
        log_info "$pkg is not installed, skipping removal."
    fi
}

remove_fish_plugin() {
    local plugin="$1"
    if fish -c "fisher list | grep -q '$plugin'"; then
        log_info "Removing Fish plugin: $plugin"
        fish -c "fisher remove $plugin"
    else
        log_info "Fish plugin '$plugin' is not installed."
    fi
}

# --- Variables ---
USER_NAME="MinhTD"
USER_EMAIL="tranminhsvp@gmail.com"
SSH_KEY_FILE="$HOME/.ssh/id_ed25519"
FISH_CONFIG_FILE="$HOME/.config/fish/config.fish"
HYPR_CONFIG_DIR="$HOME/.config/hypr"
HYPR_CONFIG_FILE="$HYPR_CONFIG_DIR/hyprland.conf"
CHROME_DESKTOP_FILE="/usr/share/applications/google-chrome.desktop"

PACKAGES=(
    "python"
    "python-pip"
    "nodejs"
    "yarn"
    "npm"
    "fish"
    "ffmpeg"
    "vim"
    "neovim"
    "stow"
    "bat"
    "fzf"
    "ripgrep" 
    "tree"    
    "wget"    
    "dotnet-sdk"
    "google-chrome"
    "etcher-bin"
    "postman"
    "dbeaver"
    "visual-studio-code-bin"
    #"mongodb-compass"
    "tableplus"  
    "telegram-desktop"
    #"nwg-displays"
    #"nautilus"
    "lazydocker"
    "ttf-jetbrains-mono-nerd"
)

DESKTOP_PACKAGES=(
    "fcitx5"
    "fcitx5-configtool"
    "fcitx5-qt"
    "fcitx5-gtk"
    "fcitx5-bamboo"
)

FISH_PLUGINS=(
    "gazorby/fish-abbreviation-tips"
    "jhillyerd/plugin-git"
    "jethrokuan/z"
    "jorgebucaran/autopair.fish"
)

# --- Uninstall functions ---

log_info "Starting uninstall process..."

# 1. Remove all installed packages
for pkg in "${PACKAGES[@]}" "${DESKTOP_PACKAGES[@]}"; do
    remove_package "$pkg"
done

# 2. Remove Fish plugins
for plugin in "${FISH_PLUGINS[@]}"; do
    remove_fish_plugin "$plugin"
done

# 3. Remove user SSH key if exists (prompt first)
if [ -f "$SSH_KEY_FILE" ]; then
    if read -rp "Remove SSH key file $SSH_KEY_FILE? [y/N]: " yn && [[ $yn =~ ^[Yy]$ ]]; then
        rm -f "$SSH_KEY_FILE" "$SSH_KEY_FILE.pub"
        log_success "SSH key files removed."
    else
        log_info "SSH key files kept."
    fi
else
    log_info "No SSH key files found to remove."
fi

# 4. Remove Fish config additions for fcitx5 environment variables (if any)
if [ -f "$FISH_CONFIG_FILE" ]; then
    log_info "Cleaning fcitx5 environment variables from Fish config..."
    sudo sed -i '/# fcitx5 environment variables/,/set -gx XMODIFIERS fcitx5/d' "$FISH_CONFIG_FILE" || true
    log_success "Fish config cleaned."
fi

# 5. Remove fcitx5 autostart line from hyprland.conf if exists
if [ -f "$HYPR_CONFIG_FILE" ]; then
    log_info "Removing fcitx5 autostart line from $HYPR_CONFIG_FILE..."
    sudo sed -i '/exec-once = fcitx5 -d/d' "$HYPR_CONFIG_FILE" || true
    log_success "Hyprland config cleaned."
fi

# 6. Remove Wayland Exec line from google-chrome.desktop (if exists)
if [ -f "$CHROME_DESKTOP_FILE" ]; then
    log_info "Removing Wayland Exec line from Google Chrome .desktop file if exists..."
    sudo sed -i '/^Exec=\/usr\/bin\/google-chrome-stable --enable-features=UseOzonePlatform --ozone-platform=wayland --enable-wayland-ime %U/d' "$CHROME_DESKTOP_FILE" || true
    log_success "Google Chrome .desktop file cleaned."
fi

# 7. Reset default shell to bash for current user if it was changed to fish
current_shell=$(getent passwd "$USER" | cut -d: -f7)
if [ "$current_shell" = "/usr/bin/fish" ]; then
    log_info "Resetting default shell to /bin/bash for user $USER..."
    sudo chsh -s /bin/bash "$USER" && log_success "Default shell reset to bash." || log_error "Failed to reset shell."
else
    log_info "Default shell is not fish. No need to reset."
fi

# 8. Disable and stop Docker service and remove user from docker group
if systemctl is-active --quiet docker.service; then
    log_info "Stopping Docker service..."
    sudo systemctl stop docker.service
fi

if systemctl is-enabled --quiet docker.service; then
    log_info "Disabling Docker service..."
    sudo systemctl disable docker.service
fi

if groups "$USER" | grep -q "\bdocker\b"; then
    log_info "Removing user $USER from docker group..."
    sudo gpasswd -d "$USER" docker
fi

log_success "Uninstall script finished! Please review and manually clean any leftover configs or files if needed."
