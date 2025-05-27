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

# Hyprland configuration
HYPR_CONFIG_DIR="$HOME/.config/hypr"
HYPR_CONFIG_FILE="$HYPR_CONFIG_DIR/hyprland.conf"
MAIN_MOD="SUPER"

# List of base packages to install
PACKAGES=(
    python python-pip tk python-virtualenv ffmpeg vim neovim stow bat fzf tree dotnet-sdk-7.0 dotnet-runtime-7.0 ripgrep tldr
    kitty alacritty zoxide btop fastfetch visual-studio-code-bin mission-center discord
    mpv google-chrome brave-bin etcher-bin postman dbeaver
    telegram-desktop lazydocker ttf-jetbrains-mono-nerd
)

# Input method packages for Vietnamese typing
DESKTOP_PACKAGES=(
    fcitx5 fcitx5-configtool fcitx5-qt fcitx5-gtk fcitx5-bamboo
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

# Check if a package is installed (via pacman or yay)
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

# --------------------------------------
# GIT CONFIGURATION & SSH KEY GENERATION
# --------------------------------------
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

# --------------------------------------
# DOCKER INSTALLATION & ACTIVATION
# --------------------------------------
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

    # Test Docker installation
    sudo docker run hello-world
}

# --------------------------------------
# FCITX5 VIETNAMESE INPUT METHOD CONFIGURATION
# --------------------------------------
configure_fcitx5() {
    log_info "Configuring fcitx5 (Vietnamese input method)..."

    local fcitx5_packages=(fcitx5 fcitx5-frontend-gtk3 fcitx5-configtool fcitx5-bamboo)
    for pkg in "${fcitx5_packages[@]}"; do install_software "$pkg"; done

    local env_vars=(
        'GTK_IM_MODULE=fcitx5'
        'QT_IM_MODULE=fcitx5'
        'XMODIFIERS="@im=fcitx5"'
    )

    # Helper to add environment variables if missing
    add_env_if_missing() {
        local file=$1
        local var_name
        for env in "${env_vars[@]}"; do
            var_name="${env%%=*}" # get the variable name
            if ! grep -qE "^\s*export\s+$var_name=" "$file" 2>/dev/null; then
                echo "export $env" >>"$file"
                log_info "Added export $env to $file"
            else
                log_info "$var_name already set in $file, skipping..."
            fi
        done
    }

    # --- Bash ---
    local BASH_FILE="$HOME/.bashrc"
    log_info "Checking Bash config: $BASH_FILE"
    add_env_if_missing "$BASH_FILE"

    # Source .bashrc from .bash_profile if not already
    local BASH_PROFILE="$HOME/.bash_profile"
    grep -q '[[ -f ~/.bashrc ]] && source ~/.bashrc' "$BASH_PROFILE" 2>/dev/null || echo '[[ -f ~/.bashrc ]] && source ~/.bashrc' >>"$BASH_PROFILE"

    # --- Zsh ---
    local ZSH_FILE="$HOME/.zshrc"
    log_info "Checking Zsh config: $ZSH_FILE"
    add_env_if_missing "$ZSH_FILE"

    # Source .zshrc from .zprofile if not already
    local ZSH_PROFILE="$HOME/.zprofile"
    grep -q '[[ -f ~/.zshrc ]] && source ~/.zshrc' "$ZSH_PROFILE" 2>/dev/null || echo '[[ -f ~/.zshrc ]] && source ~/.zshrc' >>"$ZSH_PROFILE"

    log_success "Fcitx5 environment variables configured."
    echo "➡️  Please restart your graphical session or reboot for the changes to take effect."
}

# --------------------------------------
# HYPRLAND CONFIGURATION (WAYLAND + KEYBINDINGS + CHROME)
# --------------------------------------
setup_hyprland() {
    log_info "Setting up Hyprland..."

    local keybindings="$HOME/.config/hypr/keybindings.conf"
    mkdir -p "$(dirname "$keybindings")"
    touch "$keybindings"

    # Replace example keybindings
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

# --------------------------------------
# BLUETOOTH CONFIGURATION
# --------------------------------------
configure_bluetooth() {
    log_info "Configuring Bluetooth..."
    install_package "bluez"
    install_package "bluez-utils"
    sudo systemctl enable --now bluetooth.service
    log_success "Bluetooth configured."
}

# --------------------------------------
# CLONE WALLPAPER FROM GITHUB
# --------------------------------------
clone_wallpaper_repo() {
    mkdir -p ~/Pictures
    git clone --depth=1 https://github.com/Leomin07/wallpaper.git ~/Pictures/wallpaper
    log_success "Wallpapers cloned."
}

# --------------------------------------
# REMOVE UNWANTED DEFAULT GNOME APPS
# --------------------------------------
remove_gnome_apps() {
    local apps=(gnome-maps gnome-weather gnome-logs gnome-contacts gnome-connections gnome-clocks gnome-characters gnome-calendar gnome-music)
    for app in "${apps[@]}"; do
        sudo pacman -Rns --noconfirm "$app" && log_info "Removed $app"
    done
}

# --------------------------------------
# INSTALL NODEJS (NVM + YARN)
# --------------------------------------
install_nodejs() {
    # Download and install nvm
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash

    # Source nvm script for current session
    \. "$HOME/.nvm/nvm.sh"

    # Install latest LTS Node.js
    nvm install --lts

    # Install Yarn
    npm install --global yarn
}

# --------------------------------------
# YES/NO PROMPT FUNCTION
# --------------------------------------
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
# INSTALL CLOUDFLARE WARP VPN
# --------------------------------------
install_warp_client() {
    install_package "cloudflare-warp-bin"
    log_info "Registering Cloudflare WARP..."
    sudo systemctl start warp-svc
    warp-cli registration new
    log_info "Connecting Cloudflare WARP..."
    warp-cli connect
}

# --------------------------------------
# GNOME KEYRING FOR GIT/VSCODE
# --------------------------------------
config_gnome_keyring() {
    sudo pacman -S --noconfirm gnome-keyring
    sudo pacman -S --noconfirm libsecret
    git config --global credential.helper /usr/lib/git-core/git-credential-libsecret
}

# --------------------------------------
# INSTALL & CONFIGURE ZSH (Oh My Zsh + plugins)
# --------------------------------------
install_zsh() {
    if ! command -v zsh &>/dev/null; then
        log_info "Installing Zsh..."
        sudo pacman -S --noconfirm zsh && log_success "Zsh installed." || {
            log_error "Failed to install Zsh."
            return 1
        }
    else
        log_info "Zsh is already installed, skipping."
    fi

    if [ ! -d "$HOME/.oh-my-zsh" ]; then
        log_info "Installing Oh My Zsh..."
        RUNZSH=no CHSH=no KEEP_ZSHRC=yes \
            sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" &&
            log_success "Oh My Zsh installed." || {
            log_error "Failed to install Oh My Zsh."
            return 1
        }
    else
        log_info "Oh My Zsh is already installed, skipping."
    fi

    local real_user="${SUDO_USER:-$USER}"
    local current_shell
    current_shell="$(getent passwd "$real_user" | cut -d: -f7)"

    if [ "$current_shell" != "$(which zsh)" ]; then
        log_info "Changing default shell to Zsh for user $real_user..."
        sudo chsh -s "$(which zsh)" "$real_user" &&
            log_success "Default shell changed to Zsh (log out to apply)." || log_error "Failed to change default shell to Zsh."
    else
        log_info "Default shell is already Zsh."
    fi
}

install_zsh_plugins() {
    local plugins_dir="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins"

    declare -A plugins=(
        ["zsh-autosuggestions"]="https://github.com/zsh-users/zsh-autosuggestions"
        ["zsh-syntax-highlighting"]="https://github.com/zsh-users/zsh-syntax-highlighting"
        ["zsh-completions"]="https://github.com/zsh-users/zsh-completions"
    )

    for name in "${!plugins[@]}"; do
        local dir="$plugins_dir/$name"
        if [ ! -d "$dir" ]; then
            log_info "Installing Zsh plugin: $name..."
            git clone "${plugins[$name]}" "$dir" && log_success "Plugin '$name' installed." || log_error "Failed to install plugin '$name'."
        else
            log_info "Zsh plugin '$name' is already installed, skipping."
        fi
    done

    log_warning "📌 Add the following plugins to your ~/.zshrc: plugins=(git zsh-autosuggestions zsh-syntax-highlighting zsh-completions z docker docker-compose)"
}

config_zsh_plugins() {
    local zshrc="$HOME/.zshrc"
    local desired_plugins="plugins=(git zsh-autosuggestions zsh-syntax-highlighting zsh-completions z docker docker-compose)"

    if grep -qE '^plugins=\(.*\)' "$zshrc"; then
        log_info "Updating plugins list in ~/.zshrc..."
        sed -i 's/^plugins=(.*)/'"$desired_plugins"'/' "$zshrc" &&
            log_success "Updated plugins in ~/.zshrc." ||
            log_error "Failed to update plugins in ~/.zshrc."
    else
        log_info "Adding plugins list to ~/.zshrc..."
        echo "$desired_plugins" >>"$zshrc" &&
            log_success "Added plugins to ~/.zshrc." ||
            log_error "Failed to add plugins to ~/.zshrc."
    fi
}

# --------------------------------------
# INSTALL & CONFIGURE STARSHIP PROMPT
# --------------------------------------
install_starship() {
    log_info "Installing Starship prompt..."

    # Install Starship if not already installed
    if ! command -v starship &>/dev/null; then
        log_info "Starship not found. Downloading and installing..."
        curl -sS https://starship.rs/install.sh | sh -s -- -y &&
            log_success "Starship installed successfully." || log_error "Failed to install Starship."
    else
        log_info "Starship is already installed. Skipping installation."
    fi

    # Function to append init command if not already present
    add_starship_init() {
        local shell_rc="$1"
        local shell_name="$2"
        local init_cmd="eval \"\$(starship init $shell_name)\""

        if ! grep -Fxq "$init_cmd" "$shell_rc"; then
            echo "$init_cmd" >>"$shell_rc"
            log_info "Added Starship init to $shell_rc"
        else
            log_info "Starship init already exists in $shell_rc. Skipping."
        fi
    }

    # Configure for bash
    [ -f ~/.bashrc ] && add_starship_init ~/.bashrc bash

    # Configure for zsh
    [ -f ~/.zshrc ] && add_starship_init ~/.zshrc zsh

    log_success "Starship setup completed."
}

# --------------------------------------
# ZOXIDE (SMART CD) CONFIGURATION
# --------------------------------------
config_zoxide() {
    local bashrc="$HOME/.bashrc"
    local zshrc="$HOME/.zshrc"

    local bash_init='eval "$(zoxide init bash)"'
    local zsh_init='eval "$(zoxide init zsh)"'

    # Add to Bash config
    if [ -f "$bashrc" ] && ! grep -Fxq "$bash_init" "$bashrc"; then
        echo "$bash_init" >>"$bashrc"
        echo "[✔] Added zoxide init to $bashrc"
    else
        echo "[✔] zoxide already configured in $bashrc or file not found"
    fi

    # Add to Zsh config
    if [ -f "$zshrc" ] && ! grep -Fxq "$zsh_init" "$zshrc"; then
        echo "$zsh_init" >>"$zshrc"
        echo "[✔] Added zoxide init to $zshrc"
    else
        echo "[✔] zoxide already configured in $zshrc or file not found"
    fi
}

# --------------------------------------
# FONTS INSTALLATION
# --------------------------------------
install_fonts() {
    local font_packages=(
        noto-fonts
        adobe-source-han-sans-otc-fonts
        noto-fonts-emoji
        ttf-dejavu
        ttf-roboto
        ttf-liberation
        adobe-source-han-sans-otc-fonts
    )

    for pkg in "${font_packages[@]}"; do
        if ! pacman -Q "$pkg" &>/dev/null; then
            echo "[INFO] Installing font: $pkg"
            yay -S --noconfirm "$pkg"
        else
            echo "[INFO] Font '$pkg' already installed, skipping."
        fi
    done
}

# --------------------------------------
# GNOME FULL ENVIRONMENT SETUP (Bluetooth, keyring, remove apps, extensions)
# --------------------------------------
configure_gnome_environment() {
    log_info "=== Configuring GNOME environment... ==="
    configure_bluetooth
    config_gnome_keyring
    remove_gnome_apps
    if [ -f dump_extensions.txt ]; then
        log_info "Loading GNOME extension settings from dump_extensions.txt"
        dconf load /org/gnome/shell/extensions/ <dump_extensions.txt
    else
        log_warning "File dump_extensions.txt not found. Skipping GNOME extension load."
    fi
    log_success "=== GNOME environment configuration complete! ==="
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

# Set timezone & update system
sudo timedatectl set-timezone "$TIMEZONE"
sudo pacman -Syu --noconfirm

# Install all base packages
for pkg in "${PACKAGES[@]}"; do install_package "$pkg"; done

# Install and configure Zsh & plugins
install_zsh
install_zsh_plugins
config_zsh_plugins

# Install NodeJS (nvm, yarn)
install_nodejs

# Configure Git and SSH key
configure_git_and_ssh

# Install and enable Docker
install_docker

# Install and configure Starship prompt
install_starship

# Optional setups with yes/no prompt
if ask_yes_no "Install recommended fonts?"; then install_fonts; fi
if ask_yes_no "Configure config_zoxide?"; then config_zoxide; fi
if ask_yes_no "Configure Hyprland and fcitx5?"; then setup_hyprland; fi
if ask_yes_no "Configure fcitx5 environment (GNOME)?"; then configure_fcitx5; fi
if ask_yes_no "Install warp client?"; then install_warp_client; fi
if ask_yes_no "Clone wallpaper repository?"; then clone_wallpaper_repo; fi

if ask_yes_no "Configure full GNOME environment (Bluetooth, keyring, remove apps, GNOME extensions)?"; then
    configure_gnome_environment
fi

log_success "Arch Linux setup script completed!"
