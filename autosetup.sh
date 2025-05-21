#!/bin/bash

#  _      ______ ____  __  __ _____ _   _
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
    "dotnet-sdk"
    "mpv"
    "google-chrome"
    "brave-bin"
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
    "noto-fonts-cjk"
    "noto-fonts"
    "ttf-dejavu"
    "ttf-liberation"
    "kitty"
    "alacritty"
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

log_error() {
    echo "❌ $1"
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
        if [ "$?" -ne 0 ]; then
            log_error "Failed to change default shell."
            exit 1
        fi
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
        if [ "$?" -ne 0 ]; then
            log_error "Failed to generate SSH key."
            exit 1
        fi
        log_success "Generated SSH key"
    else
        log_success "SSH key already exists (skipping)"
    fi
}

configure_warp_client() {
    if ! is_installed "cloudflare-warp-bin"; then
        install_package "cloudflare-warp-bin"
    fi

    #sudo systemctl enable --now warp-svc

    log_info "Đăng ký Cloudflare WARP..."
    warp-cli registration new

    log_info "Kết nối Cloudflare WARP..."
    warp-cli connect
    #warp-cli dns families off

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

install_nerdfont() {
    # Kiểm tra xem font JetBrainsMono đã có trong thư mục fonts chưa
    if fc-list | grep -i "JetBrainsMono" &>/dev/null; then
        log_info "Font JetBrainsMono đã được cài đặt, bỏ qua."
    else
        log_info "Đang tải và cài đặt font JetBrainsMono..."
        wget -P ~/.local/share/fonts https://github.com/ryanoasis/nerd-fonts/releases/download/v3.0.2/JetBrainsMono.zip &&
            cd ~/.local/share/fonts &&
            unzip JetBrainsMono.zip &&
            rm JetBrainsMono.zip &&
            fc-cache -fv

        log_success "Đã cài đặt font JetBrainsMono thành công."
    fi
}

# Sets up Hyprland configurations.
setup_hyde() {
    # Safely replaces a line in a file if it exists.
    safe_replace_in_file() {
        local file="$1"
        local old_line="$2"
        local new_line="$3"

        if grep -qF "$old_line" "$file"; then
            sed -i "s|$old_line|$new_line|g" "$file"
            log_success "Đã thay thế: $old_line"
        else
            log_warning "Không tìm thấy dòng: $old_line"
        fi
    }

    log_info "Configuring Hyprland keybindings..."
    local file_keybindings="$HOME/.config/hypr/keybindings.conf"

    # Old and new strings for replacement
    local old_terminal='bindd = $mainMod, T, $d terminal emulator , exec, $TERMINAL'
    local new_terminal='bindd = $mainMod, Return, $d terminal emulator , exec, $TERMINAL'

    local old_file_explorer='bindd = $mainMod, E, $d file explorer , exec, $EXPLORER'
    local new_file_explorer='bindd = $mainMod, E, $d file explorer , exec, nautilus'

    local old_editor='bindd = $mainMod, C, $d text editor , exec, $EDITOR'
    local new_editor='bindd = $mainMod, C, $d text editor , exec, code'

    # Call function to replace
    safe_replace_in_file "$file_keybindings" "$old_terminal" "$new_terminal"
    safe_replace_in_file "$file_keybindings" "$old_file_explorer" "$new_file_explorer"
    safe_replace_in_file "$file_keybindings" "$old_editor" "$new_editor"
    log_success "Hyprland keybindings configured."

    # Configures Fcitx5 for input method.
    configure_fcitx5() {
        log_info "Setting up fcitx5..."

        # Install necessary packages
        for pkg in "${DESKTOP_PACKAGES[@]}"; do
            install_package "$pkg"
        done

        # Fish shell configuration
        mkdir -p "$FISH_CONFIG_DIR"
        local fish_envs=(
            'set -gx GTK_IM_MODULE fcitx5'
            'set -gx QT_IM_MODULE fcitx5'
            'set -gx XMODIFIERS "@im=fcitx5"'
        )
        local fish_file="$FISH_CONFIG_FILE"
        local fish_missing=false

        for env in "${fish_envs[@]}"; do
            if ! grep -Fxq "$env" "$fish_file"; then
                fish_missing=true
                break
            fi
        done

        if $fish_missing; then
            log_info "Adding fcitx5 environment variables to Fish config..."
            cat <<EOF >>"$fish_file"

# fcitx5 environment variables
${fish_envs[0]}
${fish_envs[1]}
${fish_envs[2]}
EOF
        else
            log_info "Fish config already contains fcitx5 environment variables. Skipping."
        fi

        # Bash shell configuration
        local bashrc="$HOME/.bashrc"
        local bash_profile="$HOME/.bash_profile"
        local bash_envs=(
            'export GTK_IM_MODULE=fcitx'
            'export QT_IM_MODULE=fcitx'
            'export XMODIFIERS=@im=fcitx'
        )
        local bash_missing=false

        for env in "${bash_envs[@]}"; do
            if ! grep -Fxq "$env" "$bashrc"; then
                bash_missing=true
                break
            fi
        done

        if $bash_missing; then
            log_info "Adding fcitx5 environment variables to .bashrc..."
            cat <<EOF >>"$bashrc"

# fcitx5 environment variables
${bash_envs[0]}
${bash_envs[1]}
${bash_envs[2]}
EOF
        else
            log_info ".bashrc already contains fcitx5 environment variables. Skipping."
        fi

        # Ensure .bash_profile loads .bashrc
        if [ ! -f "$bash_profile" ] || ! grep -q "source ~/.bashrc" "$bash_profile"; then
            echo '[[ -f ~/.bashrc ]] && source ~/.bashrc' >>"$bash_profile"
            log_info "Linked ~/.bashrc from ~/.bash_profile."
        fi

        # Hyprland autostart
        mkdir -p "$HYPR_CONFIG_DIR" # Ensure directory exists
        if ! grep -q "exec-once = fcitx5 -d" "$HYPR_CONFIG_FILE"; then
            log_info "Adding fcitx5 to Hyprland autostart..."
            echo "exec-once = fcitx5 -d" >>"$HYPR_CONFIG_FILE"
        else
            log_info "fcitx5 is already in Hyprland autostart. Skipping."
        fi
        log_success "Fcitx5 setup complete."
    }

    configure_fcitx5 # Call fcitx5 setup from within setup_hyde

    # Appends Wayland Exec line to Google Chrome .desktop file without replacing the original.
    configure_chrome_wayland() {
        local chrome_desktop_file="/usr/share/applications/google-chrome.desktop"
        local new_exec_line="Exec=/usr/bin/google-chrome-stable --enable-features=UseOzonePlatform --ozone-platform=wayland --enable-wayland-ime %U"

        if [ -f "$chrome_desktop_file" ]; then
            if grep -qF -- "$new_exec_line" "$chrome_desktop_file"; then
                log_info "Google Chrome .desktop file already contains Wayland Exec line. Skipping."
            else
                log_info "Appending Wayland Exec line to Google Chrome .desktop file..."
                echo "$new_exec_line" | sudo tee -a "$chrome_desktop_file" >/dev/null &&
                    log_success "Wayland Exec line appended to Google Chrome .desktop file." ||
                    log_error "Failed to append Wayland Exec line."
            fi
        else
            log_warning "Google Chrome .desktop file not found at $chrome_desktop_file. Skipping Wayland configuration."
        fi
    }

    configure_chrome_wayland
}

config_bluetooth() {
    log_info "Configuring Bluetooth..."
    install_package "bluez"
    install_package "bluez-utils"

    log_info "Enabling and starting Bluetooth service..."
    sudo systemctl enable bluetooth.service
    sudo systemctl start bluetooth.service
    if [ "$?" -ne 0 ]; then
        log_error "Failed to enable or start Bluetooth service."
        exit 1
    fi
    log_success "Bluetooth configuration completed."
}

clone_wallpaper() {
    cd ~/Pictures # You can also choose a different location
    git clone --depth=1 https://github.com/mylinuxforwork/wallpaper.git
}

config_gnome() {
    local PACKAGES_TO_REMOVE=(
        gnome-maps
        gnome-weather
        gnome-logs
        gnome-contacts
        gnome-connections
        gnome-clocks
        gnome-characters
    )

    is_installed "gnome-tweaks"

    # Loop through the array and attempt to remove each package
    for package in "${PACKAGES_TO_REMOVE[@]}"; do
        echo "---"
        echo "Attempting to uninstall: $package"
        sudo pacman -Rns --noconfirm "$package"
        if [ $? -eq 0 ]; then
            echo "Successfully uninstalled $package."
        else
            echo "Failed to uninstall $package. It might not be installed or there was an issue."
        fi
        echo "---"
    done
}

configure_fcitx5_kde() {
    log_info "Setting up fcitx5..."

    # Install necessary packages
    for pkg in "${DESKTOP_PACKAGES[@]}"; do
        install_package "$pkg"
    done

    # Fish shell configuration
    mkdir -p "$FISH_CONFIG_DIR"
    local fish_envs=(
        'set -gx XMODIFIERS "@im=fcitx5"'
    )
    local fish_file="$FISH_CONFIG_FILE"
    local fish_missing=false

    for env in "${fish_envs[@]}"; do
        if ! grep -Fxq "$env" "$fish_file"; then
            fish_missing=true
            break
        fi
    done

    if $fish_missing; then
        log_info "Adding fcitx5 environment variables to Fish config..."
        cat <<EOF >>"$fish_file"

# fcitx5 environment variables
${fish_envs[0]}
EOF
    else
        log_info "Fish config already contains fcitx5 environment variables. Skipping."
    fi

    # Bash shell configuration
    local bashrc="$HOME/.bashrc"
    local bash_profile="$HOME/.bash_profile"
    local bash_envs=(
        'export XMODIFIERS=@im=fcitx'
    )
    local bash_missing=false

    for env in "${bash_envs[@]}"; do
        if ! grep -Fxq "$env" "$bashrc"; then
            bash_missing=true
            break
        fi
    done

    if $bash_missing; then
        log_info "Adding fcitx5 environment variables to .bashrc..."
        cat <<EOF >>"$bashrc"

# fcitx5 environment variables
${bash_envs[0]}
EOF
    else
        log_info ".bashrc already contains fcitx5 environment variables. Skipping."
    fi

    # Ensure .bash_profile loads .bashrc
    if [ ! -f "$bash_profile" ] || ! grep -q "source ~/.bashrc" "$bash_profile"; then
        echo '[[ -f ~/.bashrc ]] && source ~/.bashrc' >>"$bash_profile"
        log_info "Linked ~/.bashrc from ~/.bash_profile."
    fi

    log_success "Fcitx5 setup complete."
}

configure_fcitx5_gnome() {
    log_info "Setting up fcitx5..."

    # Install necessary packages
    for pkg in "${DESKTOP_PACKAGES[@]}"; do
        install_package "$pkg"
    done

    # Fish shell configuration
    mkdir -p "$FISH_CONFIG_DIR"
    local fish_envs=(
        'set -gx GTK_IM_MODULE fcitx5'
        'set -gx QT_IM_MODULE fcitx5'
        'set -gx XMODIFIERS "@im=fcitx5"'
    )
    local fish_file="$FISH_CONFIG_FILE"
    local fish_missing=false

    for env in "${fish_envs[@]}"; do
        if ! grep -Fxq "$env" "$fish_file"; then
            fish_missing=true
            break
        fi
    done

    if $fish_missing; then
        log_info "Adding fcitx5 environment variables to Fish config..."
        cat <<EOF >>"$fish_file"

# fcitx5 environment variables
${fish_envs[0]}
${fish_envs[1]}
${fish_envs[2]}
EOF
    else
        log_info "Fish config already contains fcitx5 environment variables. Skipping."
    fi

    # Bash shell configuration
    local bashrc="$HOME/.bashrc"
    local bash_profile="$HOME/.bash_profile"
    local bash_envs=(
        'export GTK_IM_MODULE=fcitx'
        'export QT_IM_MODULE=fcitx'
        'export XMODIFIERS=@im=fcitx'
    )
    local bash_missing=false

    for env in "${bash_envs[@]}"; do
        if ! grep -Fxq "$env" "$bashrc"; then
            bash_missing=true
            break
        fi
    done

    if $bash_missing; then
        log_info "Adding fcitx5 environment variables to .bashrc..."
        cat <<EOF >>"$bashrc"

# fcitx5 environment variables
${bash_envs[0]}
${bash_envs[1]}
${bash_envs[2]}
EOF
    else
        log_info ".bashrc already contains fcitx5 environment variables. Skipping."
    fi

    # Ensure .bash_profile loads .bashrc
    if [ ! -f "$bash_profile" ] || ! grep -q "source ~/.bashrc" "$bash_profile"; then
        echo '[[ -f ~/.bashrc ]] && source ~/.bashrc' >>"$bash_profile"
        log_info "Linked ~/.bashrc from ~/.bash_profile."
    fi

    log_success "Fcitx5 setup complete."
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

# --- Main Script ---

# Check if yay is installed, and install it if it's not
if ! is_installed "yay"; then
    log_info "Installing yay..."
    sudo pacman -S --noconfirm --needed git base-devel
    git clone https://aur.archlinux.org/yay.git
    cd yay
    makepkg -si --noconfirm
    cd ..
    rm -rf yay
    log_success "yay installed successfully."
else
    log_info "yay is already installed."
fi

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
#configure_warp_client
install_docker

# Ask user if they want to run setup_hyde
if ask_yes_no "Do you want to install and configure Hyprland and Fcitx5 (setup_hyde)?"; then
    setup_hyde # Call the hyprland and fcitx5 setup function
else
    log_info "Skipping Hyprland and Fcitx5 setup."
fi

# Ask user if they want to configure Fcitx5
if ask_yes_no "Do you want to install and configure Fcitx5?"; then
    configure_fcitx5_gnome
else
    log_info "Skipping Fcitx5 setup."
fi

# Ask user if they want to configure Bluetooth
if ask_yes_no "Do you want to configure Bluetooth?"; then
    config_bluetooth
else
    log_info "Skipping Bluetooth configuration."
fi

# Ask user if they want to clone wallpaper
if ask_yes_no "Do you want to clone wallpaper?"; then
    clone_wallpaper
else
    log_info "Skipping clone wallpaper."
fi

# Ask user if they want to install warp_client
if ask_yes_no "Do you want to install warp_client?"; then
    configure_warp_client
else
    log_info "Skipping to install warp_client."
fi

# Ask user if they want to config_gnome
if ask_yes_no "Do you want to config_gnome?"; then
    config_gnome
else
    log_info "Skipping to config_gnome."
fi

if ask_yes_no "Do you want to load dump setting extensions?"; then
    dconf load /org/gnome/shell/extensions/ <dump_extensions.txt
else
    log_info "Skipping to dump setting extensions."
fi

log_success "Arch Linux setup script completed!"

# --- End Main Script ---
