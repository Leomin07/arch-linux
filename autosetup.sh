#!/bin/bash
#  _      ______ ____  __  __ _____ _   _
# | |    |  ____/ __ \|  \/  |_   _| \ | |
# | |    | |__ | |  | | \  / | | | |  \| |
# | |    |  __|| |  | | |\/| | | | | . ` |
# | |____| |___| |__| | |  | |_| |_| |\  |
# |______|______\____/|_|  |_|_____|_| \_|

set -euo pipefail

# --------------------------------------
# CONFIGURATION
# --------------------------------------

# Timezone setting
TIMEZONE="Asia/Ho_Chi_Minh"

# Git user config
USER_NAME="MinhTD"
USER_EMAIL="tranminhsvp@gmail.com"

# SSH key path
SSH_KEY_FILE="$HOME/.ssh/id_ed25519"

# Fish shell path and config file
FISH_SHELL="/usr/bin/fish"
FISH_CONFIG_DIR="$HOME/.config/fish"
FISH_CONFIG_FILE="$FISH_CONFIG_DIR/config.fish"

# Hyprland configuration
HYPR_CONFIG_DIR="$HOME/.config/hypr"
HYPR_CONFIG_FILE="$HYPR_CONFIG_DIR/hyprland.conf"
MAIN_MOD="SUPER"

# Base packages to install
PACKAGES=(
    python python-pip nodejs yarn npm fish ffmpeg vim neovim stow bat fzf tree dotnet-sdk
    mpv google-chrome brave-bin etcher-bin postman dbeaver visual-studio-code-bin tableplus
    telegram-desktop lazydocker ttf-jetbrains-mono-nerd noto-fonts-cjk noto-fonts ttf-dejavu
    ttf-liberation kitty alacritty btop fastfetch
)

# Input method packages for Vietnamese typing
DESKTOP_PACKAGES=(
    fcitx5 fcitx5-configtool fcitx5-qt fcitx5-gtk fcitx5-bamboo
)

# Fish plugins to install via Fisher
FISH_PLUGINS=(
    gazorby/fish-abbreviation-tips
    jhillyerd/plugin-git
    jethrokuan/z
    jorgebucaran/autopair.fish
)

# --------------------------------------
# HELPER FUNCTIONS
# --------------------------------------

# Logging utilities
log_info() { echo "[INFO] $1"; }
log_success() { echo "[OK]   $1"; }
log_warning() { echo "[WARN] $1"; }
log_error() { echo "[ERR]  $1"; }

# Check command result and exit on failure
check_result() {
    if [ "$1" -ne 0 ]; then
        log_error "$2"
        exit 1
    fi
}

# Check if a package is installed
is_installed() {
    pacman -Q "$1" &>/dev/null || yay -Q "$1" &>/dev/null
}

# Install a package if not already installed
install_package() {
    if ! is_installed "$1"; then
        log_info "Installing $1..."
        yay -S --noconfirm "$1"
    else
        log_info "$1 already installed. Skipping."
    fi
}

# Change default shell to Fish
set_default_shell() {
    local current_shell
    current_shell=$(getent passwd "$USER" | cut -d: -f7)
    if [ "$current_shell" != "$FISH_SHELL" ]; then
        log_info "Changing default shell to fish..."
        sudo chsh -s "$FISH_SHELL" "$USER"
    else
        log_info "Default shell already set to fish."
    fi
}

# Install Fisher and Fish plugins
install_fisher_and_plugins() {
    if ! fish -c "type -q fisher"; then
        log_info "Installing Fisher..."
        fish -c 'curl -sL https://git.io/fisher | source && fisher install jorgebucaran/fisher'
    fi

    for plugin in "${FISH_PLUGINS[@]}"; do
        if ! fish -c "fisher list | grep -q '$plugin'"; then
            log_info "Installing fish plugin: $plugin"
            fish -c "fisher install $plugin"
        else
            log_info "Fish plugin $plugin already installed."
        fi
    done
}

# Configure Git global settings and generate SSH key
configure_git_and_ssh() {
    git config --global user.name "$USER_NAME"
    git config --global user.email "$USER_EMAIL"

    if [ ! -f "$SSH_KEY_FILE" ]; then
        log_info "Generating SSH key..."
        ssh-keygen -t ed25519 -C "$USER_EMAIL" -f "$SSH_KEY_FILE" -N ""
    else
        log_info "SSH key already exists."
    fi
}

# Install and enable Docker
install_docker() {
    if is_installed "docker"; then
        log_info "Docker already installed."
        return
    fi

    log_info "Installing Docker..."
    sudo pacman -S --noconfirm docker docker-compose
    sudo systemctl enable --now docker.service
    sudo usermod -aG docker "$USER"
    log_success "Docker installed. Please log out or run 'newgrp docker'."

    # Test Docker
    sudo docker run hello-world
}

# Configure fcitx5 input method for Vietnamese typing
configure_fcitx5() {
    log_info "Configuring fcitx5..."

    # Install required packages
    for pkg in "${DESKTOP_PACKAGES[@]}"; do install_package "$pkg"; done

    mkdir -p "$FISH_CONFIG_DIR"

    # Add environment variables to Fish and Bash
    local envs_fish=(
        'set -gx GTK_IM_MODULE fcitx5'
        'set -gx QT_IM_MODULE fcitx5'
        'set -gx XMODIFIERS "@im=fcitx5"'
    )
    local envs_bash=(
        'export GTK_IM_MODULE=fcitx5'
        'export QT_IM_MODULE=fcitx5'
        'export XMODIFIERS="@im=fcitx5"'
    )

    for line in "${envs_fish[@]}"; do grep -qxF "$line" "$FISH_CONFIG_FILE" || echo "$line" >>"$FISH_CONFIG_FILE"; done
    for line in "${envs_bash[@]}"; do grep -qxF "$line" "$HOME/.bashrc" || echo "$line" >>"$HOME/.bashrc"; done
    grep -q "source ~/.bashrc" "$HOME/.bash_profile" || echo '[[ -f ~/.bashrc ]] && source ~/.bashrc' >>"$HOME/.bash_profile"

    log_success "Fcitx5 configured."
}

# Configure Hyprland environment
setup_hyprland() {
    log_info "Setting up Hyprland..."

    local keybindings="$HOME/.config/hypr/keybindings.conf"
    mkdir -p "$(dirname "$keybindings")"
    touch "$keybindings"

    # Replace keybinding examples
    sed -i 's|bindd = \$mainMod, T.*|bindd = $mainMod, Return, exec, $TERMINAL|' "$keybindings"
    sed -i 's|bindd = \$mainMod, E.*|bindd = $mainMod, E, exec, nautilus|' "$keybindings"
    sed -i 's|bindd = \$mainMod, C.*|bindd = $mainMod, C, exec, code|' "$keybindings"

    # Input method setup
    configure_fcitx5

    # Ensure fcitx5 starts with Hyprland
    mkdir -p "$HYPR_CONFIG_DIR"
    grep -q "exec-once = fcitx5 -d" "$HYPR_CONFIG_FILE" || echo "exec-once = fcitx5 -d" >>"$HYPR_CONFIG_FILE"

    # Enable Wayland mode for Chrome
    local chrome_desktop="/usr/share/applications/google-chrome.desktop"
    local chrome_exec='Exec=/usr/bin/google-chrome-stable --enable-features=UseOzonePlatform --ozone-platform=wayland --enable-wayland-ime %U'
    grep -Fq "$chrome_exec" "$chrome_desktop" || echo "$chrome_exec" | sudo tee -a "$chrome_desktop" >/dev/null

    log_success "Hyprland setup completed."
}

# Enable Bluetooth services
configure_bluetooth() {
    log_info "Configuring Bluetooth..."
    install_package "bluez"
    install_package "bluez-utils"
    sudo systemctl enable --now bluetooth.service
    log_success "Bluetooth configured."
}

# Clone wallpaper repo from GitHub
clone_wallpaper_repo() {
    mkdir -p ~/Pictures
    git clone --depth=1 https://github.com/mylinuxforwork/wallpaper.git ~/Pictures/wallpaper
    log_success "Wallpapers cloned."
}

# Remove unwanted GNOME default apps
remove_gnome_apps() {
    local apps=(gnome-maps gnome-weather gnome-logs gnome-contacts gnome-connections gnome-clocks gnome-characters)
    for app in "${apps[@]}"; do
        sudo pacman -Rns --noconfirm "$app" && log_info "Removed $app"
    done
}

# Prompt user for yes/no
ask_yes_no() {
    while true; do
        read -rp "$1 [y/n]: " yn
        case $yn in
        [Yy]*) return 0 ;;
        [Nn]*) return 1 ;;
        *) echo "Please answer yes or no." ;;
        esac
    done
}

# --------------------------------------
# MAIN EXECUTION
# --------------------------------------

# Install yay if not available
if ! is_installed "yay"; then
    log_info "Installing yay..."
    sudo pacman -S --noconfirm --needed git base-devel
    git clone https://aur.archlinux.org/yay.git
    cd yay && makepkg -si --noconfirm && cd .. && rm -rf yay
fi

# Set timezone and update system
sudo timedatectl set-timezone "$TIMEZONE"
sudo pacman -Syu --noconfirm

# Install all base packages
for pkg in "${PACKAGES[@]}"; do install_package "$pkg"; done

# Set Fish as default shell
set_default_shell

# Install Fisher + plugins
install_fisher_and_plugins

# Setup Git and SSH
configure_git_and_ssh

# Docker installation
install_docker

# Optional setups
if ask_yes_no "Configure Hyprland and fcitx5?"; then setup_hyprland; fi
if ask_yes_no "Configure fcitx5 environment (GNOME)?"; then configure_fcitx5; fi
if ask_yes_no "Configure Bluetooth?"; then configure_bluetooth; fi
if ask_yes_no "Clone wallpaper repository?"; then clone_wallpaper_repo; fi
if ask_yes_no "Remove unwanted GNOME apps?"; then remove_gnome_apps; fi
if ask_yes_no "Load GNOME extension settings from file?"; then
    dconf load /org/gnome/shell/extensions/ <dump_extensions.txt
fi

log_success "Arch Linux setup script completed!"
