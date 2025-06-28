#!/bin/bash
#  _      ______ ____  __  __ _____ _   _
# | |    |  ____/ __ \|  \/  |_   _| \ | |
# | |    | |__ | |  | | \  / | | | |  \| |
# | |    |  __|| |  | | |\/| | | | | . ` |
# | |____| |___| |__| | |  | |_| |_| |\  |
# |______|______\____/|_|  |_|_____|_| \_|

set -euo pipefail

# --------------------------------------
# CONFIGURATION SECTION: Set up variables, timezone, user, and package lists
# --------------------------------------

TIMEZONE="Asia/Ho_Chi_Minh" # Timezone for your system

USER_NAME="MinhTD"                 # Git global username
USER_EMAIL="tranminhsvp@gmail.com" # Git global email

SSH_KEY_FILE="$HOME/.ssh/id_ed25519" # Default SSH key file path

# Hyprland configuration directory and file
HYPR_CONFIG_DIR="$HOME/.config/hypr"
HYPR_CONFIG_FILE="$HYPR_CONFIG_DIR/hyprland.conf"
MAIN_MOD="SUPER" # Main modifier key for Hyprland shortcuts

# List of essential packages to install (system, dev, terminal, GUI, fonts, etc.)
PACKAGES=(
    # dotnet-sdk-7.0 dotnet-runtime-7.0
    python python-pip tk python-virtualenv ffmpeg vim neovim stow bat fzf tree ripgrep tldr
    kitty ghostty zoxide lazygit fastfetch visual-studio-code-bin mission-center discord
    mpv google-chrome brave-bin etcher-bin postman dbeaver
    telegram-desktop lazydocker ttf-jetbrains-mono-nerd xclip
    # file manager cinnamon nemo
)

# --------------------------------------
# HELPER FUNCTIONS SECTION: Utility, logging, package management
# --------------------------------------

# Logging functions for info, success, warning, and error
log_info() { echo "[INFO] $1"; }
log_success() { echo "[OK]   $1"; }
log_warning() { echo "[WARN] $1"; }
log_error() { echo "[ERR]  $1"; }

# Check result of a command, exit if non-zero
check_result() {
    if [ "$1" -ne 0 ]; then
        log_error "$2"
        exit 1
    fi
}

# Check if a package is installed (pacman or yay)
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
# GIT AND SSH KEY CONFIGURATION
# Setup global Git user and email, generate SSH key if not exists
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
# DOCKER INSTALLATION AND ENABLEMENT
# Install Docker and add current user to docker group
# --------------------------------------
install_docker() {
    log_info "Installing Docker..."
    local docker_packages=(docker docker-compose)

    # Install packages if not already present
    for pkg in "${docker_packages[@]}"; do
        install_package "$pkg"
    done

    # Enable and start docker service (nên bật)
    sudo systemctl enable --now docker.service

    # Đảm bảo thêm user thực (không phải root nếu chạy sudo)
    local real_user="${SUDO_USER:-$USER}"
    sudo usermod -aG docker "$real_user"

    log_success "Docker installed. Please log out or run 'newgrp docker'."
    # Test Docker with hello-world (dùng sudo vì user mới chưa có quyền ngay)
    sudo docker run hello-world
}

# --------------------------------------
# FCITX5 VIETNAMESE INPUT METHOD SETUP
# Install fcitx5 and set environment variables for input methods
# --------------------------------------
configure_fcitx5() {
    log_info "Configuring fcitx5 (Vietnamese input method)..."
    local fcitx5_packages=(fcitx5 fcitx5-frontend-gtk3 fcitx5-configtool fcitx5-bamboo)
    for pkg in "${fcitx5_packages[@]}"; do install_package "$pkg"; done

    local env_vars=(
        'GTK_IM_MODULE=fcitx5'
        'QT_IM_MODULE=fcitx5'
        'XMODIFIERS="@im=fcitx5"'
    )

    # Helper function to add environment variable if not already present
    add_env_if_missing() {
        local file=$1
        local var_name
        for env in "${env_vars[@]}"; do
            var_name="${env%%=*}"
            if ! grep -qE "^\s*export\s+$var_name=" "$file" 2>/dev/null; then
                echo "export $env" >>"$file"
                log_info "Added export $env to $file"
            else
                log_info "$var_name already set in $file, skipping..."
            fi
        done
    }

    # Add to ~/.bashrc and source from ~/.bash_profile
    local BASH_FILE="$HOME/.bashrc"
    log_info "Checking Bash config: $BASH_FILE"
    add_env_if_missing "$BASH_FILE"
    local BASH_PROFILE="$HOME/.bash_profile"
    grep -q '[[ -f ~/.bashrc ]] && source ~/.bashrc' "$BASH_PROFILE" 2>/dev/null || echo '[[ -f ~/.bashrc ]] && source ~/.bashrc' >>"$BASH_PROFILE"

    # Add to ~/.zshrc and source from ~/.zprofile
    local ZSH_FILE="$HOME/.zshrc"
    log_info "Checking Zsh config: $ZSH_FILE"
    add_env_if_missing "$ZSH_FILE"
    local ZSH_PROFILE="$HOME/.zprofile"
    grep -q '[[ -f ~/.zshrc ]] && source ~/.zshrc' "$ZSH_PROFILE" 2>/dev/null || echo '[[ -f ~/.zshrc ]] && source ~/.zshrc' >>"$ZSH_PROFILE"

    log_success "Fcitx5 environment variables configured."
    echo "➡️  Please restart your graphical session or reboot for the changes to take effect."
}

# --------------------------------------
# HYPRLAND CONFIGURATION (Wayland, keybindings, Chrome Wayland support)
# --------------------------------------
setup_hyprland() {
    log_info "Setting up Hyprland..."

    # Create keybindings file and set up example keybindings
    local keybindings="$HOME/.config/hypr/keybindings.conf"
    mkdir -p "$(dirname "$keybindings")"
    touch "$keybindings"
    sed -i 's|bindd = \$mainMod, T.*|bindd = $mainMod, Return, exec, $TERMINAL|' "$keybindings"
    sed -i 's|bindd = \$mainMod, E.*|bindd = $mainMod, E, exec, nautilus|' "$keybindings"
    sed -i 's|bindd = \$mainMod, C.*|bindd = $mainMod, C, exec, code|' "$keybindings"

    # Also setup fcitx5 input method
    configure_fcitx5

    # Ensure fcitx5 starts with Hyprland session
    mkdir -p "$HYPR_CONFIG_DIR"
    grep -q "exec-once = fcitx5 -d" "$HYPR_CONFIG_FILE" || echo "exec-once = fcitx5 -d" >>"$HYPR_CONFIG_FILE"

    # Enable Wayland mode for Chrome by editing .desktop file
    local chrome_desktop="/usr/share/applications/google-chrome.desktop"
    local chrome_exec='Exec=/usr/bin/google-chrome-stable --enable-features=UseOzonePlatform --ozone-platform=wayland --enable-wayland-ime %U'
    grep -Fq "$chrome_exec" "$chrome_desktop" || echo "$chrome_exec" | sudo tee -a "$chrome_desktop" >/dev/null

    log_success "Hyprland setup completed."
}

# --------------------------------------
# BLUETOOTH CONFIGURATION AND ENABLE
# --------------------------------------
configure_bluetooth() {
    log_info "Configuring Bluetooth..."
    install_package "bluez"
    install_package "bluez-utils"
    sudo systemctl enable --now bluetooth.service
    log_success "Bluetooth configured."
}

# --------------------------------------
# DOWNLOAD WALLPAPER REPOSITORY FROM GITHUB
# --------------------------------------

clone_wallpaper() {
    log_info "Cloning wallpaper repository..."
    if [ ! -d "~/Pictures/wallpaper" ]; then # Check if directory exists before cloning
        cd ~/Pictures                        # You can also choose a different location
        git clone --depth=1 https://github.com/Leomin07/wallpaper.git ~/Pictures/wallpaper &&
            log_success "Wallpaper repository cloned to ~/Pictures/wallpaper." || log_error "Failed to clone wallpaper repository."
    else
        log_info "Wallpaper repository already exists in ~/Pictures/wallpaper, skipping clone."
    fi
}

# --------------------------------------
# REMOVE UNWANTED GNOME DEFAULT APPS
# --------------------------------------
remove_gnome_apps() {
    local apps=(gnome-maps gnome-weather gnome-logs gnome-contacts gnome-connections gnome-clocks gnome-characters gnome-calendar gnome-music)
    for app in "${apps[@]}"; do
        sudo pacman -Rns --noconfirm "$app" && log_info "Removed $app"
    done
}

# --------------------------------------
# NODEJS (NVM + YARN) INSTALLATION
# --------------------------------------
install_nodejs() {
    # Download and install nvm
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
    # Source nvm for the current shell
    \. "$HOME/.nvm/nvm.sh"
    # Install latest LTS Node.js and Yarn
    nvm install --lts
    npm install --global yarn
}

# --------------------------------------
# YES/NO PROMPT FUNCTION FOR USER CONFIRMATION
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
# CLOUDFLARE WARP VPN INSTALLATION AND REGISTRATION
# --------------------------------------
install_warp_client() {
    install_package "cloudflare-warp-bin"
    log_info "Registering Cloudflare WARP..."
    sudo systemctl start warp-svc
    # warp-cli registration new
    log_info "Connecting Cloudflare WARP..."
    # warp-cli connect
}

# --------------------------------------
# GNOME KEYRING SETUP FOR GIT/VSCODE CREDENTIALS
# --------------------------------------
config_gnome_keyring() {
    sudo pacman -S --noconfirm gnome-keyring
    sudo pacman -S --noconfirm libsecret
    git config --global credential.helper /usr/lib/git-core/git-credential-libsecret
}

# --------------------------------------
# INSTALL AND CONFIGURE ZSH (Oh My Zsh + plugins)
# --------------------------------------
install_zsh() {
    # Install zsh if not present
    if ! command -v zsh &>/dev/null; then
        log_info "Installing Zsh..."
        sudo pacman -S --noconfirm zsh && log_success "Zsh installed." || {
            log_error "Failed to install Zsh."
            return 1
        }
    else
        log_info "Zsh is already installed, skipping."
    fi

    # Install Oh My Zsh for better Zsh experience
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

    # Set Zsh as default shell for user
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

# Install recommended Zsh plugins for productivity and completion
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

# Update ~/.zshrc plugins section with preferred plugins
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
# INSTALL AND CONFIGURE STARSHIP PROMPT (modern shell prompt)
# --------------------------------------
install_starship() {
    log_info "Installing Starship prompt..."
    if ! command -v starship &>/dev/null; then
        log_info "Starship not found. Downloading and installing..."
        curl -sS https://starship.rs/install.sh | sh -s -- -y &&
            log_success "Starship installed successfully." || log_error "Failed to install Starship."
    else
        log_info "Starship is already installed. Skipping installation."
    fi

    # Add initialization command to bash and zsh configs if missing
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
    [ -f ~/.bashrc ] && add_starship_init ~/.bashrc bash
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

# Function: remove_snap_from_gnome_arch
# Description: Completely remove snapd and all related integrations from GNOME on Arch Linux
remove_snap_from_gnome_arch() {
    echo "==> Removing snapd..."
    sudo pacman -Rns --noconfirm snapd

    echo "==> Deleting Snap data directories..."
    sudo rm -rf /var/lib/snapd
    rm -rf ~/snap

    # Remove GNOME integration package for Snap if installed via AUR
    if pacman -Qs gnome-software-snap >/dev/null 2>&1; then
        echo "==> Removing gnome-software-snap..."
        sudo pacman -Rns --noconfirm gnome-software-snap
    fi

    echo "==> Cleaning Snap .desktop files from GNOME menu..."
    rm -rf ~/.local/share/applications/snap-*
    update-desktop-database ~/.local/share/applications/ || true

    echo "==> Done! Please reboot or log out to apply all changes."
}

configure_gnome_environment() {
    # Define an array of GNOME-related apps to install
    local apps=("extension-manager" "gnome-tweaks")

    log_info "=== Configuring GNOME environment... ==="
    configure_bluetooth
    config_gnome_keyring
    remove_gnome_apps
    remove_snap_from_gnome_arch

    # Install necessary GNOME apps
    log_info "Installing GNOME apps: ${apps[*]}"
    install_package "${apps[@]}"

    if [ -f dump_extensions.txt ]; then
        log_info "Loading GNOME extension settings from dump_extensions.txt"
        dconf load /org/gnome/shell/extensions/ <dump_extensions.txt
    else
        log_warning "File dump_extensions.txt not found. Skipping GNOME extension load."
    fi
    log_success "=== GNOME environment configuration complete! ==="
}

# --------------------------------------
# AUTOSTART MAP-KEY TOOL ON LOGIN
# --------------------------------------
mapkey() {
    local desktop_file="$HOME/arch-linux/map-key.desktop"
    local xmodmap_file="$HOME/arch-linux/.xmodmap"
    local autostart_dir="$HOME/.config/autostart"

    # Kiểm tra file tồn tại
    if [[ ! -f "$desktop_file" ]]; then
        echo "File $desktop_file không tồn tại!"
        return 1
    fi
    if [[ ! -f "$xmodmap_file" ]]; then
        echo "File $xmodmap_file không tồn tại!"
        return 1
    fi

    chmod +x "$desktop_file"
    chmod +x "$xmodmap_file"

    # Apply xmodmap
    xmodmap "$xmodmap_file"

    # Tạo thư mục autostart nếu chưa có
    mkdir -p "$autostart_dir"
    cp "$desktop_file" "$autostart_dir/"

    echo "Đã setup mapkey autostart thành công!"
}

# --------------------------------------
# INSTALL VIRTUALIZATION SOFTWARE (QEMU, Virt-Manager, etc.)
# --------------------------------------
install_virt_manager() {
    sudo pacman -S --noconfirm qemu virt-manager virt-viewer dnsmasq vde2 bridge-utils openbsd-netcat ebtables iptables libguestfs
    sudo systemctl enable --now libvirtd
    sudo usermod -aG libvirt ${USER}
    sudo systemctl restart libvirtd
}

# Function to install ibus and ibus-bamboo on Arch Linux, and configure environment variables properly for .xprofile
install_ibus_bamboo() {
    echo "Installing ibus and ibus-bamboo..."
    local ibus_packages=(ibus ibus-bamboo)

    # Install packages if not already present
    for pkg in "${ibus_packages[@]}"; do
        install_package "$pkg"
    done

    # List of environment variables to set
    local env_vars=(
        'GTK_IM_MODULE=ibus'
        'QT_IM_MODULE=ibus'
        'XMODIFIERS="@im=ibus"'
    )

    # Helper function to add environment variable if not already present
    add_env_if_missing() {
        local file=$1
        local var_name
        for env in "${env_vars[@]}"; do
            var_name="${env%%=*}"
            # Remove any existing export of this variable before appending
            sed -i "/^\s*export\s\+$var_name=/d" "$file" 2>/dev/null
            echo "export $env" >>"$file"
            echo "Set export $env in $file"
        done
    }

    # Add to ~/.bashrc and source from ~/.bash_profile
    local BASH_FILE="$HOME/.bashrc"
    log_info "Checking Bash config: $BASH_FILE"
    add_env_if_missing "$BASH_FILE"
    local BASH_PROFILE="$HOME/.bash_profile"
    grep -q '[[ -f ~/.bashrc ]] && source ~/.bashrc' "$BASH_PROFILE" 2>/dev/null || echo '[[ -f ~/.bashrc ]] && source ~/.bashrc' >>"$BASH_PROFILE"

    # Add to ~/.zshrc and source from ~/.zprofile
    local ZSH_FILE="$HOME/.zshrc"
    log_info "Checking Zsh config: $ZSH_FILE"
    add_env_if_missing "$ZSH_FILE"
    local ZSH_PROFILE="$HOME/.zprofile"
    grep -q '[[ -f ~/.zshrc ]] && source ~/.zshrc' "$ZSH_PROFILE" 2>/dev/null || echo '[[ -f ~/.zshrc ]] && source ~/.zshrc' >>"$ZSH_PROFILE"

    echo "Installation and configuration complete!"
    echo "Please log out and log in again, then add 'Bamboo' in IBus Preferences if needed."
}

# --------------------------------------
# MAIN EXECUTION SECTION: The actual installation steps and user prompts
# --------------------------------------

# Install yay if not available (AUR helper)
if ! is_installed "yay"; then
    log_info "Installing yay..."
    sudo pacman -S --noconfirm --needed git base-devel
    git clone https://aur.archlinux.org/yay.git
    cd yay && makepkg -si --noconfirm && cd .. && rm -rf yay
fi

# Set timezone and update system packages
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

# Optional setups with yes/no prompt for user customization
if ask_yes_no "Configure map-key?"; then mapkey; fi
if ask_yes_no "Configure config_zoxide?"; then config_zoxide; fi
if ask_yes_no "Install ibus-bamboo?"; then install_ibus_bamboo; fi
if ask_yes_no "Configure fcitx5 environment?"; then configure_fcitx5; fi
if ask_yes_no "Clone wallpaper repository?"; then clone_wallpaper; fi
# if ask_yes_no "Configure full GNOME environment (Bluetooth, keyring, remove apps, GNOME extensions)?"; then
#     configure_gnome_environment
# fi
# if ask_yes_no "Load GNOME extension settings from file?"; then
#     dconf load /org/gnome/shell/extensions/ <dump_extensions.txt
# fi
# if ask_yes_no "Configure Hyprland and fcitx5?"; then setup_hyprland; fi
if ask_yes_no "Install recommended fonts?"; then install_fonts; fi
if ask_yes_no "Install warp client?"; then install_warp_client; fi
if ask_yes_no "Install virt_manager?"; then install_virt_manager; fi

log_success "Arch Linux setup script completed!"
