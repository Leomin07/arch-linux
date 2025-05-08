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
FISH_CONFIG_FILE="$HOME/.config/fish/config.fish"
HYPR_CONFIG_FILE="$HOME/.config/hypr/hyprland.conf"
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
        if ! fish -c "fisher list | grep -q '$plugin'"; then
            log_info "Installing Fish plugin: $plugin"
            fish -c "fisher install $plugin"
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
        log_success "Generating SSH key hoàn tất"
    else
        log_success "SSH key đã tồn tại (bỏ qua)"
    fi
}

configure_fcitx5() {
    log_info "Setting up fcitx5..."

    # Install necessary packages
    for pkg in "${DESKTOP_PACKAGES[@]}"; do
        install_package "$pkg"
    done

    # Set environment variables in Fish shell
    if ! grep -q "GTK_IM_MODULE fcitx5" "$FISH_CONFIG_FILE"; then
        log_info "Setting up environment variables for fcitx5 in Fish shell..."
        mkdir -p "$(dirname "$FISH_CONFIG_FILE")"
        cat <<EOF >>"$FISH_CONFIG_FILE"
# fcitx5 environment variables
set -Ux GTK_IM_MODULE fcitx5
set -Ux QT_IM_MODULE fcitx5
set -Ux XMODIFIERS @im=fcitx5
set -Ux SDL_IM_MODULE fcitx5
set -Ux GLFW_IM_MODULE fcitx5
set -Ux INPUT_METHOD fcitx5
EOF
    else
        log_info "Environment variables for fcitx5 are already set in Fish shell, skipping."
    fi

    if ! grep -q "exec-once = fcitx5 -d" "$HYPR_CONFIG_FILE"; then
        log_info "Adding fcitx5 to Hyprland autostart..."
        echo "exec-once = fcitx5 -d" >>"$HYPR_CONFIG_FILE"
    else
        log_info "fcitx5 is already in Hyprland autostart, skipping."
    fi

    
}

configure_hyprland_binds() {
    local file_path="$HYPR_CONFIG_FILE"
    # local ctrl_c_bind="bind = $MAIN_MOD, C, sendshortcut, CTRL, C"
    local ctrl_v_bind="bind = $MAIN_MOD, V, sendshortcut, CTRL, V"
    local ctrl_shift_c_bind="bind = CTRL SHIFT, C, exec, wl-copy"

    if [ ! -f "$file_path" ]; then
        log_warning "Hyprland configuration file not found at '$file_path'. Skipping keybind configuration."
        return 1
    fi

    if ! check_hyprland_bind "$ctrl_c_bind"; then
        log_info "Adding Hyprland bind: $ctrl_c_bind"
        echo "$ctrl_c_bind" >>"$file_path"
    else
        log_info "Hyprland bind already exists: $ctrl_c_bind"
    fi

    if ! check_hyprland_bind "$ctrl_v_bind"; then
        log_info "Adding Hyprland bind: $ctrl_v_bind"
        echo "$ctrl_v_bind" >>"$file_path"
    else
        log_info "Hyprland bind already exists: $ctrl_v_bind"
    fi

    if ! check_hyprland_bind "$ctrl_shift_c_bind"; then
        log_info "Adding Hyprland bind: $ctrl_shift_c_bind"
        echo "$ctrl_shift_c_bind" >>"$file_path"
    else
        log_info "Hyprland bind already exists: $ctrl_shift_c_bind"
    fi
}

check_hyprland_bind() {
    local bind_to_check="$1"
    local file_path="$HYPR_CONFIG_FILE"

    if grep -q "$bind_to_check" "$file_path"; then
        return 0 # Exists
    else
        return 1 # Does not exist
    fi
}

configure_warp_client() {
    if ! is_installed "cloudflare-warp-bin"; then
        install_package "cloudflare-warp-bin"
    fi

    if command -v warp-cli &>/dev/null; then
        log_info "Cloudflare WARP CLI tool found."
        sudo systemctl enable --now warp-svc
        if [ "$?" -ne 0 ]; then
            log_warning "Failed to enable and start warp-svc."
        fi
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
        log_warning "warp-cli command not found. Ensure cloudflare-warp-bin is installed correctly."
    fi
}

check_nwg_dock_line() {
    local file_path="$HOME/.config/nwg-dock-hyprland/launch.sh"
    local target_line='nwg-dock-hyprland -i 32 -w 5 -mb 10 -ml 10 -mr 10 -x -s \$style -c  "rofi -show drun" -o HDMI-A-1'
    local original_line='nwg-dock-hyprland -i 32 -w 5 -mb 10 -ml 10 -mr 10 -x -s \$style -c  "rofi -show drun"'

    if [ ! -f "$file_path" ]; then
        log_warning "File '$file_path' not found."
        return 1
    fi

    if ! grep -q "$target_line" "$file_path"; then
        if grep -q "$original_line" "$file_path"; then
            log_info "Replacing existing nwg-dock line with output specification..."
            sed -i "s|$original_line|$target_line|" "$file_path"
            if [ "$?" -eq 0 ]; then
                log_success "Successfully added output specification to nwg-dock line."
                return 0
            else
                log_warning "Failed to add output specification to nwg-dock line."
                return 1
            fi
        else
            log_info "Original nwg-dock line not found. Skipping modification."
            return 1
        fi
    else
        log_info "nwg-dock line with output specification already exists."
        return 0
    fi
}

# --- Main Script ---

log_info "Setting timezone to $TIMEZONE"
sudo timedatectl set-timezone "$TIMEZONE"

log_info "Updating system..."
sudo pacman -Syu --noconfirm

# Install base packages
for pkg in "${PACKAGES[@]}"; do
    install_package "$pkg"
done

set_default_shell
install_fisher
install_fish_plugins
configure_git
configure_fcitx5
configure_warp_client

#check_nwg_dock_line

log_success "Thiết lập hoàn tất!"

# --- End Main Script ---
