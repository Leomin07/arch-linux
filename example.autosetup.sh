#!/bin/bash

#  _      ______ ____  __  __ _____ _   _
# | |    |  ____/ __ \|  \/  |_   _| \ | |
# | |    | |__ | |  | | \  / | | | |  \| |
# | |    |  __|| |  | | |\/| | | | | . ` |
# | |____| |___| |__| | |  | |_| |_| |\  |
# |______|______\____/|_|  |_|_____|_| \_|

set -euo pipefail

# --- Configuration ---
TIMEZONE="Asia/Ho_Chi_Minh"
USER_NAME="MinhTD"
USER_EMAIL="tranminhsvp@gmail.com"
SSH_KEY_FILE="$HOME/.ssh/id_ed25519"
FISH_SHELL="/usr/bin/fish"
FISH_CONFIG_DIR="$HOME/.config/fish"
FISH_CONFIG_FILE="$FISH_CONFIG_DIR/config.fish"
HYPR_CONFIG_DIR="$HOME/.config/hypr"
HYPR_CONFIG_FILE="$HYPR_CONFIG_DIR/hyprland.conf"
MAIN_MOD="SUPER"

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
    "tree"
    "dotnet-runtime-7.0"
    "dotnet-sdk-7.0"
    "mpv"
    "google-chrome"
    "brave-bin"
    "etcher-bin"
    "postman"
    "dbeaver"
    "visual-studio-code-bin"
    "telegram-desktop"
    "lazydocker"
    "ttf-jetbrains-mono-nerd"
    "noto-fonts-cjk"
    "noto-fonts"
    "ttf-dejavu"
    "ttf-liberation"
    "kitty"
    "alacritty"
    "btop"
    "fastfetch"
    #"mongodb-compass"
    #"nwg-displays"
    #"nautilus"

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

# --- Helper Functions ---
log_info() { echo ">> $1"; }
log_success() { echo "[OK] $1"; }
log_warning() { echo "[WARNING] $1"; }
log_error() { echo "[ERROR] $1"; }

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
    local current_shell
    current_shell=$(getent passwd "$USER" | cut -d: -f7)
    if [ "$current_shell" != "$FISH_SHELL" ]; then
        log_info "Changing default shell to fish for user $USER..."
        sudo chsh -s "$FISH_SHELL" "$USER" || {
            log_error "Failed to change default shell."
            exit 1
        }
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
        ssh-keygen -t ed25519 -C "$USER_EMAIL" -f "$SSH_KEY_FILE" -N "" || {
            log_error "Failed to generate SSH key."
            exit 1
        }
        log_success "Generated SSH key"
    else
        log_success "SSH key already exists"
    fi
}

configure_warp_client() {
    install_package "cloudflare-warp-bin"
    log_info "Registering Cloudflare WARP..."
    warp-cli registration new
    log_info "Connecting Cloudflare WARP..."
    warp-cli connect
}

install_docker() {
    if is_installed "docker"; then
        log_info "Docker is already installed. Skipping."
        return
    fi
    log_info "Installing Docker..."
    sudo pacman -S --noconfirm docker docker-compose || {
        log_error "Failed to install Docker."
        exit 1
    }
    sudo systemctl start docker.service
    sudo systemctl enable docker.service || {
        log_error "Failed to enable docker service."
        exit 1
    }
    sudo usermod -aG docker "$USER" || {
        log_error "Failed to add user to docker group."
        exit 1
    }
    log_success "Docker installed. Re-login or run 'newgrp docker' to apply changes."
    sudo docker run hello-world || {
        log_error "Docker test failed."
        exit 1
    }
    log_success "Docker installation verified."
}

configure_fcitx5() {
    log_info "Configuring fcitx5 for GNOME..."
    for pkg in "${DESKTOP_PACKAGES[@]}"; do install_package "$pkg"; done

    mkdir -p "$FISH_CONFIG_DIR"
    local fish_envs=(
        'set -gx GTK_IM_MODULE fcitx5'
        'set -gx QT_IM_MODULE fcitx5'
        'set -gx XMODIFIERS "@im=fcitx5"'
    )

    append_if_missing() {
        local file="$1"
        local header="$2"
        shift 2
        local added=false
        for line in "$@"; do
            if ! grep -Fxq "$line" "$file"; then
                if ! $added; then
                    echo -e "\n# $header" >>"$file"
                    added=true
                fi
                echo "$line" >>"$file"
                log_info "Added to $file: $line"
            else
                log_info "Already present in $file: $line"
            fi
        done
    }

    append_if_missing "$FISH_CONFIG_FILE" "fcitx5 env vars (Fish)" "${fish_envs[@]}"
    local bash_envs=(
        'export GTK_IM_MODULE=fcitx5'
        'export QT_IM_MODULE=fcitx5'
        'export XMODIFIERS="@im=fcitx5"'
    )
    append_if_missing "$HOME/.bashrc" "fcitx5 env vars (Bash)" "${bash_envs[@]}"

    local bash_profile="$HOME/.bash_profile"
    if [ ! -f "$bash_profile" ] || ! grep -q "source ~/.bashrc" "$bash_profile"; then
        echo '[[ -f ~/.bashrc ]] && source ~/.bashrc' >>"$bash_profile"
        log_info "Linked ~/.bashrc from ~/.bash_profile"
    else
        log_info "~/.bash_profile already sources ~/.bashrc"
    fi

    log_success "Fcitx5 configuration for GNOME completed."
}

setup_hyde() {
    log_info "Setting up Hyprland..."

    safe_replace_in_file() {
        local file="$1"
        local old="$2"
        local new="$3"
        if grep -Fxq "$old" "$file"; then
            sed -i "s|$old|$new|g" "$file"
            log_success "Replaced in $file: $old → $new"
        else
            log_warning "Line not found in $file: $old"
        fi
    }

    local key_file="$HOME/.config/hypr/keybindings.conf"
    mkdir -p "$(dirname "$key_file")"
    touch "$key_file"

    safe_replace_in_file "$key_file" 'bindd = $mainMod, T, $d terminal emulator , exec, $TERMINAL' 'bindd = $mainMod, Return, $d terminal emulator , exec, $TERMINAL'
    safe_replace_in_file "$key_file" 'bindd = $mainMod, E, $d file explorer , exec, $EXPLORER' 'bindd = $mainMod, E, $d file explorer , exec, nautilus'
    safe_replace_in_file "$key_file" 'bindd = $mainMod, C, $d text editor , exec, $EDITOR' 'bindd = $mainMod, C, $d text editor , exec, code'

    configure_fcitx5

    mkdir -p "$HYPR_CONFIG_DIR"
    if ! grep -q "exec-once = fcitx5 -d" "$HYPR_CONFIG_FILE"; then
        echo "exec-once = fcitx5 -d" >>"$HYPR_CONFIG_FILE"
        log_info "Added fcitx5 to Hyprland autostart"
    else
        log_info "fcitx5 autostart already configured"
    fi

    configure_chrome_wayland() {
        local chrome_file="/usr/share/applications/google-chrome.desktop"
        local chrome_exec='Exec=/usr/bin/google-chrome-stable --enable-features=UseOzonePlatform --ozone-platform=wayland --enable-wayland-ime %U'
        if [ -f "$chrome_file" ]; then
            if grep -Fq "$chrome_exec" "$chrome_file"; then
                log_info "Chrome already set to launch with Wayland"
            else
                echo "$chrome_exec" | sudo tee -a "$chrome_file" >/dev/null && log_success "Chrome set to Wayland mode"
            fi
        else
            log_warning "Chrome .desktop file not found"
        fi
    }

    configure_chrome_wayland
    log_success "Hyprland configuration completed."
}

config_bluetooth() {
    log_info "Installing and configuring Bluetooth..."
    install_package "bluez"
    install_package "bluez-utils"
    sudo systemctl enable bluetooth.service
    sudo systemctl start bluetooth.service || {
        log_error "Failed to start Bluetooth."
        exit 1
    }
    log_success "Bluetooth setup complete."
}

clone_wallpaper() {
    cd ~/Pictures || exit
    git clone --depth=1 https://github.com/mylinuxforwork/wallpaper.git
}

config_gnome() {
    local REMOVE_PKGS=(
        gnome-maps
        gnome-weather
        gnome-logs
        gnome-contacts
        gnome-connections
        gnome-clocks
        gnome-characters
    )
    is_installed "gnome-tweaks"
    for pkg in "${REMOVE_PKGS[@]}"; do
        sudo pacman -Rns --noconfirm "$pkg" || echo "Could not remove $pkg"
    done
}

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

# --- Main Execution ---

if ! is_installed "yay"; then
    log_info "Installing yay..."
    sudo pacman -S --noconfirm --needed git base-devel
    git clone https://aur.archlinux.org/yay.git
    cd yay || exit
    makepkg -si --noconfirm
    cd ..
    rm -rf yay
    log_success "yay installed."
else
    log_info "yay is already installed."
fi

log_info "Setting timezone to $TIMEZONE"
sudo timedatectl set-timezone "$TIMEZONE" || {
    log_error "Failed to set timezone."
    exit 1
}

log_info "Updating system..."
sudo pacman -Syu --noconfirm || {
    log_error "System update failed."
    exit 1
}

for pkg in "${PACKAGES[@]}"; do install_package "$pkg"; done

set_default_shell
install_fisher
install_fish_plugins
configure_git
install_docker

if ask_yes_no "Do you want to install and configure Hyprland and Fcitx5?"; then
    setup_hyde
else
    log_info "Skipping Hyprland setup."
fi

if ask_yes_no "Do you want to configure Fcitx5?"; then
    configure_fcitx5
else
    log_info "Skipping Fcitx5 setup."
fi

if ask_yes_no "Do you want to configure Bluetooth?"; then
    config_bluetooth
fi

if ask_yes_no "Do you want to clone wallpaper repository?"; then
    clone_wallpaper
fi

if ask_yes_no "Do you want to install and configure WARP client?"; then
    configure_warp_client
fi

if ask_yes_no "Do you want to remove unnecessary GNOME apps?"; then
    config_gnome
fi

if ask_yes_no "Do you want to load GNOME extensions settings from dump?"; then
    dconf load /org/gnome/shell/extensions/ <dump_extensions.txt
fi

log_success "Arch Linux setup script completed."
