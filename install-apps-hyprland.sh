#!/bin/bash

#  _     ______ ____  __  __ _____ _  _
# | |    |  ____/ __ \|  \/  |_   _| \ | |
# | |    | |__ | |  | | \  / | | | |  \| |
# | |    |  __|| |  | | |\/| | | | | . ` |
# | |____| |___| |__| | |  | |_| |_| |\  |
# |______|______\____/|_|  |_|_____|_| \_|

set -euo pipefail # More robust error handling

# --- Configuration ---
TIMEZONE="Asia/Ho_Chi_Minh"
USER_NAME="MinhTD"
USER_EMAIL="tranminhsvp@gmail.com"
SSH_KEY_FILE="$HOME/.ssh/id_ed25519"
FISH_SHELL="/usr/bin/fish"
FISH_CONFIG_DIR="$HOME/.config/fish" # Consistent variable
FISH_CONFIG_FILE="$FISH_CONFIG_DIR/config.fish"
HYPR_CONFIG_DIR="$HOME/.config/hypr" # Consistent variable
HYPR_CONFIG_FILE="$HYPR_CONFIG_DIR/hyprland.conf"
MAIN_MOD="SUPER" # Assuming SUPER key for Hyprland binds

PACKAGES=(
    "google-chrome"
    "postman"
    "dbeaver"
    "visual-studio-code-bin"
    "mongodb-compass"
    "fish"
    "python"
    "nodejs"
    "yarn"
    "telegram-desktop"
    "nwg-displays"
    "ffmpeg"
    "dotnet"
    "docker"
    "vim"
    "neovim"
    "stow"
    "nautilus"
    "lazydocker"
    "sublime-text-4"
    "bat"
    "fzf"
    "ripgrep" # added ripgrep
    "tree"      # Added tree
    "wget"      # Add wget
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
    "francoiscariou/fish-foreign-env" # Add fish-foreign-env
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

log_error() {
    echo "❌ $1"
}

is_installed() {
    local pkg="$1"
    command -v "$pkg" &>/dev/null
}

install_package() {
    local pkg="$1"
    if ! is_installed "$pkg"; then
        log_info "Installing $pkg..."
        sudo pacman -S --noconfirm "$pkg"
        if [ "$?" -ne 0 ]; then
            log_error "Failed to install $pkg"
            exit 1
        fi
    else
        log_info "$pkg is already installed, skipping."
    fi
}

set_default_shell() {
    local current_shell=$(getent passwd "$USER" | cut -d: -f7)
    if [ "$current_shell" != "$FISH_SHELL" ]; then
        log_info "Changing default shell to fish for user $USER..."
        sudo chsh -s "$FISH_SHELL" "$USER"
        if [ "$?" -ne 0 ]; then
            log_error "Failed to change default shell."
            exit 1
        fi
    else
        log_info "Default shell is already fish."
    fi
}

install_fisher() {
    if ! is_installed "fisher"; then
        log_info "Installing fisher..."
        curl -sL https://git.io/fisher | source && fish -c "fisher install jorgebucaran/fisher"
        if [ "$?" -ne 0 ]; then
            log_error "Failed to install fisher."
            exit 1
        fi
    else
        log_info "Fisher is already installed, skipping."
    fi
}

install_fish_plugins() {
    for plugin in "${FISH_PLUGINS[@]}"; do
        if ! fish -c "fisher list | grep -q '$plugin'"; then
            log_info "Installing Fish plugin: $plugin"
            fish -c "fisher install $plugin"
             if [ "$?" -ne 0 ]; then
                log_error "Failed to install fish plugin: $plugin"
                exit 1
            fi
        else
            log_info "Fish plugin '$plugin' is already installed."
        fi
    done
}

configure_git() {
    git config --global user.name "$USER_NAME"
    git config --global user.email "$USER_EMAIL"

    if [ ! -f "$SSH_KEY_FILE" ]; then
        log_info "Generating SSH key..."
        ssh-keygen -t ed25519 -C "$USER_EMAIL" -f "$SSH_KEY_FILE" -N ""
        if [ "$?" -ne 0 ]; then
            log_error "Failed to generate SSH key."
            exit 1
        fi
        log_success "Generated SSH key"
    else
        log_success "SSH key already exists (skipping)"
    fi
}

configure_fcitx5() {
    log_info "Setting up fcitx5..."

    # Install necessary packages
    for pkg in "${DESKTOP_PACKAGES[@]}"; do
        install_package "$pkg"
    done

    # Create config dir if it does not exist
    mkdir -p "$FISH_CONFIG_DIR"

    # Set environment variables in Fish shell, check if the line exists
    if ! grep -q "set -Ux GTK_IM_MODULE fcitx5" "$FISH_CONFIG_FILE"; then
        log_info "Setting up environment variables for fcitx5 in Fish shell..."
        cat <<EOF >>"$FISH_CONFIG_FILE"
# fcitx5 environment variables
set -Ux GTK_IM_MODULE fcitx5
set -Ux QT_IM_MODULE fcitx5
set -Ux XMODIFIERS "@im=fcitx5"
set -Ux SDL_IM_MODULE fcitx5
set -Ux GLFW_IM_MODULE fcitx5
set -Ux INPUT_METHOD fcitx5
EOF
    else
        log_info "Environment variables for fcitx5 are already set in Fish shell, skipping."
    fi

    # Add fcitx5 to Hyprland autostart, check if the line exists
     if ! grep -q "exec-once = fcitx5 -d" "$HYPR_CONFIG_FILE"; then
        log_info "Adding fcitx5 to Hyprland autostart..."
        echo "exec-once = fcitx5 -d" >>"$HYPR_CONFIG_FILE"
    else
        log_info "fcitx5 is already in Hyprland autostart, skipping."
    fi
}



configure_hyprland_binds() {
    local file_path="$HYPR_CONFIG_FILE"
    local ctrl_c_bind="bind = $MAIN_MOD,C,copy" # Changed to "copy"
    local ctrl_v_bind="bind = $MAIN_MOD,V,paste" # Changed to "paste"
    local ctrl_shift_c_bind="bind = CTRL SHIFT,C,exec,wl-copy"

    if [ ! -f "$file_path" ]; then
        log_warning "Hyprland configuration file not found at '$file_path'. Skipping keybind configuration."
        return 1
    fi

    # Use check_hyprland_config function
    if ! check_hyprland_config "$ctrl_c_bind"; then
        log_info "Adding Hyprland bind: $ctrl_c_bind"
        echo "$ctrl_c_bind" >>"$file_path"
    else
        log_info "Hyprland bind already exists: $ctrl_c_bind"
    fi

    if ! check_hyprland_config "$ctrl_v_bind"; then
        log_info "Adding Hyprland bind: $ctrl_v_bind"
        echo "$ctrl_v_bind" >>"$file_path"
    else
        log_info "Hyprland bind already exists: $ctrl_v_bind"
    fi

    if ! check_hyprland_config "$ctrl_shift_c_bind"; then
        log_info "Adding Hyprland bind: $ctrl_shift_c_bind"
        echo "$ctrl_shift_c_bind" >>"$file_path"
    else
        log_info "Hyprland bind already exists: $ctrl_shift_c_bind"
    fi
}

# Function to check for existing Hyprland config lines
check_hyprland_config() {
    local config_line="$1"
    local file_path="$HYPR_CONFIG_FILE"
    grep -q "$config_line" "$file_path"
}


configure_warp_client() {
    local warp_package="cloudflare-warp-bin" # Consistent variable
    if ! is_installed "$warp_package"; then
        install_package "$warp_package"
    fi

    if is_installed "warp-cli"; then
        log_info "Cloudflare WARP CLI tool found."
        sudo systemctl enable --now warp-svc
        if [ "$?" -ne 0 ]; then
            log_error "Failed to enable and start warp-svc."
            exit 1
        fi
        log_info "Registering Cloudflare WARP..."
        warp-cli registration new
         if [ "$?" -ne 0 ]; then
            log_error "Failed to register WARP."
            exit 1
        fi
        log_info "Connecting to Cloudflare WARP..."
        warp-cli connect
         if [ "$?" -ne 0 ]; then
            log_error "Failed to connect to WARP."
            exit 1
        fi
        if warp-cli status | grep -q "Status: Connected"; then # Corrected the grep
            log_success "Cloudflare WARP connected successfully."
        else
            log_warning "Failed to connect to Cloudflare WARP. Check logs with 'journalctl -u warp-svc'."
        fi
    else
        log_warning "warp-cli command not found. Ensure $warp_package is installed correctly."
    fi
}

install_docker() {
    if is_installed "docker"; then
        log_info "Docker is already installed. Skipping installation."
        return
    fi

    log_info "Installing Docker..."
    sudo pacman -S --noconfirm docker docker-compose # Install docker-compose
     if [ "$?" -ne 0 ]; then
        log_error "Failed to install Docker."
        exit 1
    fi

    log_info "Enabling and starting Docker service..."
    sudo systemctl start docker.service
    
    sudo systemctl enable docker.service
     if [ "$?" -ne 0 ]; then
        log_error "Failed to enable docker service."
        exit 1
    fi

    
    log_info "Adding current user to docker group..."
    sudo usermod -aG docker "$USER"
     if [ "$?" -ne 0 ]; then
        log_error "Failed to add user to docker group.  You may need to log out and back in."
        exit 1
    fi

    log_success "Docker installation completed. Please log out and log back in or run 'newgrp docker' to apply group changes."

    log_info "Verifying Docker installation..."
    sudo docker run hello-world
     if [ "$?" -ne 0 ]; then
        log_error "Docker test failed. Try restarting or checking system logs."
        exit 1
    fi
    log_success "Docker installation verified."
}


# --- Main Script ---

log_info "Setting timezone to $TIMEZONE"
sudo timedatectl set-timezone "$TIMEZONE"
 if [ "$?" -ne 0 ]; then
    log_error "Failed to set timezone."
    exit 1
fi

log_info "Updating system..."
sudo pacman -Syu --noconfirm
 if [ "$?" -ne 0 ]; then
    log_error "Failed to update system."
    exit 1
fi

# Install base packages
for pkg in "${PACKAGES[@]}"; do
    install_package "$pkg"
done

set_default_shell
install_fisher
install_fish_plugins
configure_git
#configure_fcitx5
#configure_hyprland_binds # Call the hyprland config function
configure_warp_client
install_docker

# Install gedit using snap
if is_installed "snap"; then
    log_info "Installing gedit via snap..."
    sudo snap install gedit
     if [ "$?" -ne 0 ]; then
        log_error "Failed to install gedit via snap."
        exit 1
    fi
else
    log_warning "Snap is not installed.  Skipping gedit installation via snap."
fi

log_success "Setup completed!"

# --- End Main Script ---

