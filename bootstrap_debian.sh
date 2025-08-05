#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# --- Initial Checks ---
if [[ "$(id -u)" -eq 0 ]]; then
    echo "ERROR: This script must NOT be run as root. Run as regular user with sudo privileges."
    exit 1
fi

if ! command -v sudo &> /dev/null; then
    echo "ERROR: sudo is not installed. Run as root: apt install sudo"
    exit 1
fi

# --- System Information ---
CURRENT_USER=$(whoami)
CURRENT_UID=$(id -u)
KERNEL_VERSION=$(uname -r)

# --- Tracking Arrays ---
failed_apt=()
failed_flatpak=()
failed_snap=()
failed_brew=()

log() {
    echo "[$(date +'%Y-%m-%dT%H:%M:%S%z')] $*"
}

clean_package_list() {
    # Remove comments and empty lines from package lists
    sed -e 's/#.*$//' -e '/^$/d' "$1"
}

# --- System Setup Functions ---
install_essentials() {
    log "Installing essential dependencies..."
    sudo apt update -y
    sudo apt install -y git stow curl gawk nala wget cmake build-essential \
        linux-headers-$KERNEL_VERSION unzip gdebi-core dkms
}

configure_system() {
    log "Configuring system fundamentals..."
    
    # Customize sudo prompt
    echo 'Defaults passprompt="[sudo] password for %u:  "' | sudo tee /etc/sudoers.d/00_prompt_lock > /dev/null
    
    # Update sources
    sudo sed -i '/^deb / s/$/ contrib non-free/' /etc/apt/sources.list
    sudo apt update -y && sudo apt full-upgrade -y
}

remove_bloatware() {
    log "Removing unnecessary packages..."
    sudo apt purge -y audacity gimp gnome-games
}

# --- Dotfiles and Package Management ---
setup_dotfiles() {
    log "Configuring dotfiles..."
    mkdir -p "$HOME/gitprojects"
    [[ -f "$HOME/.bashrc" ]] && mv "$HOME/.bashrc" "$HOME/.bashrc.bak"
    
    if ! git clone https://github.com/stefan-hacks/dotfiles.git "$HOME/dotfiles"; then
        log "ERROR: Failed to clone dotfiles repository"
        return 1
    fi
    
    cd "$HOME/dotfiles" && stow --adopt . && git restore .
}

install_apt_packages() {
    log "Installing APT packages..."
    local apt_list="$HOME/dotfiles/backups/apt_list_debian.bak"
    [[ ! -f "$apt_list" ]] && { log "APT list missing"; return 1; }
    
    local pkg_list
    mapfile -t pkg_list < <(clean_package_list "$apt_list")
    
    sudo apt install -y "${pkg_list[@]}"

    # Verify installations
    for pkg in "${pkg_list[@]}"; do
        if ! dpkg -l | grep -q "^ii  $pkg "; then
            failed_apt+=("$pkg")
        fi
    done
}

# --- Security Services ---
setup_fail2ban() {
    log "Configuring fail2ban..."
    sudo apt install -y fail2ban python3-systemd
    sudo cp /etc/fail2ban/{fail2ban,jail}.conf /etc/fail2ban/{fail2ban,jail}.local
    sudo sed -i '/\[sshd\]/,/enabled/s/^enabled.*/enabled = true/;
                /\[sshd\]/,/enabled/s/^backend.*/backend = systemd/' \
                /etc/fail2ban/jail.local
    sudo systemctl enable --now fail2ban.service
}

setup_ufw() {
    log "Configuring UFW..."
    sudo apt install -y ufw
    sudo ufw limit 22/tcp
    sudo ufw allow 80/tcp
    sudo ufw allow 443/tcp
    sudo ufw default deny incoming
    sudo ufw default allow outgoing
    sudo ufw --force enable
}

setup_apparmor() {
    log "Enforcing AppArmor..."
    sudo apt install -y apparmor-utils apparmor-profiles
    sudo aa-enforce /etc/apparmor.d/*
    sudo systemctl enable apparmor.service
    sudo systemctl start apparmor.service
}

# --- Application Installations ---
setup_flatpak() {
    log "Configuring Flatpak..."
    sudo apt install -y flatpak
    flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
    
    local flatpak_list="$HOME/dotfiles/backups/flatpaks_list.bak"
    [[ ! -f "$flatpak_list" ]] && { log "Flatpak list missing"; return 1; }
    
    local pkg_list
    mapfile -t pkg_list < <(clean_package_list "$flatpak_list")
    
    flatpak install -y "${pkg_list[@]}"

    # Verify installations
    for pkg in "${pkg_list[@]}"; do
        if ! flatpak list | grep -qi "$pkg"; then
            failed_flatpak+=("$pkg")
        fi
    done
}

setup_snap() {
    log "Configuring Snap..."
    sudo apt install -y snapd
    sudo systemctl enable --now snapd.socket
    
    local snap_list="$HOME/dotfiles/backups/snap_list.bak"
    [[ ! -f "$snap_list" ]] && { log "Snap list missing"; return 1; }
    
    local pkg_list
    mapfile -t pkg_list < <(clean_package_list "$snap_list")
    
    for pkg in "${pkg_list[@]}"; do
        sudo snap install "$pkg"
    done

    # Verify installations
    for pkg in "${pkg_list[@]}"; do
        if ! snap list | grep -q "^$pkg "; then
            failed_snap+=("$pkg")
        fi
    done
}

setup_homebrew() {
    log "Installing Homebrew..."
    # Install Homebrew without prompting
    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> ~/.bashrc
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
    ulimit -n 8192

    local brew_list="$HOME/dotfiles/backups/brew_list.bak"
    [[ ! -f "$brew_list" ]] && { log "Brew list missing"; return 1; }
    
    local pkg_list
    mapfile -t pkg_list < <(clean_package_list "$brew_list")
    
    brew install "${pkg_list[@]}"

    # Verify installations
    for pkg in "${pkg_list[@]}"; do
        if ! brew list | grep -q "^$pkg$"; then
            failed_brew+=("$pkg")
        fi
    done
}

install_blesh() {
    log "Installing ble.sh..."
    git clone --recursive --depth 1 --shallow-submodules \
        https://github.com/akinomyoga/ble.sh.git "$HOME/ble.sh"
    make -C "$HOME/ble.sh" install PREFIX=~/.local
}

install_fonts() {
    log "Installing Hack Nerd Font..."
    mkdir -p ~/.local/share/fonts
    wget -q https://github.com/ryanoasis/nerd-fonts/releases/download/v3.0.2/Hack.zip -O /tmp/Hack.zip
    unzip -q /tmp/Hack.zip -d ~/.local/share/fonts
    fc-cache -fv
}

# install_drivers() {
#     log "Installing rtl8812au driver..."
#     local driver_repo="$HOME/gitprojects/rtl8812au"
#     git clone https://github.com/aircrack-ng/rtl8812au.git "$driver_repo"
#     cd "$driver_repo"
#     sudo make dkms_install
# }

install_grub() {
    log "Installing Grub theme..."
    git clone https://github.com/vinceliuice/grub2-themes.git "$HOME/gitprojects/grub2-themes"
    
    local wallpaper_src="$HOME/Pictures/wallpapers/wallpaper_023.jpg"
    if [[ -f "$wallpaper_src" ]]; then
        cp "$wallpaper_src" "$HOME/gitprojects/grub2-themes/background.jpg"
    else
        log "Wallpaper not found, using default GRUB background"
    fi
    
    sudo "$HOME/gitprojects/grub2-themes/install.sh" -s 1080p -b -t whitesur

    log "Configuring GRUB..."
    sudo sed -i 's/^GRUB_TIMEOUT=.*/GRUB_TIMEOUT=2/' /etc/default/grub
    sudo sed -i '/^GRUB_CMDLINE_LINUX_DEFAULT=/a GRUB_CMDLINE_LINUX="rhgb quiet mitigations=off"' /etc/default/grub
    sudo update-grub
    sudo update-initramfs -u -k all
}


# --- Finalization ---
finalize() {
    log "Finalizing configuration..."
    source "$HOME/.bashrc"
    [[ -f "$HOME/dotfiles/backups/gnome_settings.bak" ]] && \
        dconf load / < "$HOME/dotfiles/backups/gnome_settings.bak"

    log "Installation Summary:"
    print_failed "APT" "${failed_apt[@]}"
    print_failed "Flatpak" "${failed_flatpak[@]}"
    print_failed "Snap" "${failed_snap[@]}"
    print_failed "Homebrew" "${failed_brew[@]}"
}

print_failed() {
    local category=$1
    shift
    local packages=("$@")
    [[ ${#packages[@]} -eq 0 ]] && return

    log "Failed $category packages:"
    printf ' - %s\n' "${packages[@]}"
    echo ""
}

# --- Main Execution Flow ---
main() {
    install_essentials
    configure_system
    remove_bloatware
    setup_dotfiles
    install_apt_packages
    setup_flatpak
    setup_snap
    setup_fail2ban
    install_blesh
    install_fonts
    setup_ufw
    setup_homebrew
    setup_apparmor
    # install_drivers
    install_grub
    finalize

    log "Bootstrap complete! Rebooting to activate changes..."
    sudo reboot
}

# Execute main function
main
