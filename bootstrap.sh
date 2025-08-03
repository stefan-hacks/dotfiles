#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# Initialize tracking arrays
failed_apt=()
failed_flatpak=()
failed_snap=()
failed_brew=()

log() {
    echo "[$(date +'%Y-%m-%dT%H:%M:%S%z')] $*"
}

# --- System Setup Functions ---
install_essentials() {
    log "Installing essential dependencies..."
    sudo apt update -y
    sudo apt install -y git stow curl gawk cmake build-essential \
        linux-headers-$(uname -r) unzip gdebi-core
}

configure_system() {
    log "Configuring system fundamentals..."
    # Set bash as default shell
    sudo chsh -s /bin/bash "$USER"
    sudo chsh -s /bin/bash root
    
    # Customize sudo prompt
    echo 'Defaults passprompt="[sudo] password for %u:  "' | sudo tee /etc/sudoers.d/00_prompt_lock > /dev/null
    
    # Update sources
    sudo sed -i '/^deb / s/$/ contrib non-free/' /etc/apt/sources.list
    sudo apt update -y && sudo apt full-upgrade -y
}

enable_wayland() {
    log "Enabling Wayland session..."
    # Create directory and symlink to disable Wayland block
    sudo mkdir -p /etc/systemd/system/gdm.service.d
    sudo tee /etc/systemd/system/gdm.service.d/disable-wayland.conf > /dev/null <<EOL
[Service]
Environment=GDM_BACKEND=wayland
EOL
    sudo systemctl daemon-reload
}

harden_kernel() {
    log "Applying kernel hardening..."
    # Create sysctl hardening config
    cat <<EOF | sudo tee /etc/sysctl.d/99-kali-hardening.conf >/dev/null
# Kernel security parameters 
kernel.kptr_restrict=2
kernel.dmesg_restrict=1
kernel.perf_event_paranoid=3
kernel.unprivileged_bpf_disabled=1
net.core.bpf_jit_harden=2
dev.tty.ldisc_autoload=0
vm.unprivileged_userfaultfd=0
kernel.kexec_load_disabled=1
kernel.sysrq=4
net.ipv4.tcp_syncookies=1
net.ipv4.tcp_rfc1337=1
net.ipv4.conf.all.rp_filter=1
net.ipv4.conf.default.rp_filter=1
net.ipv4.conf.all.accept_redirects=0
net.ipv4.conf.default.accept_redirects=0
net.ipv4.conf.all.send_redirects=0
net.ipv4.conf.default.send_redirects=0
net.ipv6.conf.all.accept_redirects=0
net.ipv6.conf.default.accept_redirects=0
EOF

    # Apply settings immediately
    sudo sysctl -p /etc/sysctl.d/99-kali-hardening.conf

    # Security-focused GRUB configuration
    sudo sed -i 's/^GRUB_CMDLINE_LINUX_DEFAULT=.*/GRUB_CMDLINE_LINUX_DEFAULT="quiet slub_debug=P page_poison=1"/' /etc/default/grub
    sudo update-grub
    sudo update-initramfs -u -k all
}

remove_bloatware() {
    log "Removing unnecessary packages..."
    # Removed libreoffice per user request 
    sudo apt purge -y audacity gimp gnome-games
}

# --- Dotfiles and Package Management ---
setup_dotfiles() {
    log "Configuring dotfiles..."
    mkdir -p "$HOME/gitprojects"
    rm -rf "$HOME/.bashrc"
    git clone https://github.com/stefan-hacks/dotfiles.git "$HOME/dotfiles"
    cd "$HOME/dotfiles" && stow --adopt . && git restore .
}

filter_package_lists() {
    log "Filtering package lists..."
    local file="$HOME/dotfiles/backups/apt_list.bak"
    [[ ! -f "$file" ]] && { log "APT list not found"; return; }

    local packages=(
        balena-etcher
        mullvad-vpn
        net\.downloadhelper\.coapp
        popcorn-time
        ulauncher
        'virtualbox-*.*'
        wikiman  # Added to exclusion list as requested
    )
    local pattern=$(IFS="|"; echo "^(${packages[*]})$")
    grep -Ev "$pattern" "$file" > "$file.tmp" && mv "$file.tmp" "$file"
}

install_apt_packages() {
    log "Installing APT packages..."
    local apt_list="$HOME/dotfiles/backups/apt_list.bak"
    [[ ! -f "$apt_list" ]] && { log "APT list missing"; return; }
    
    sudo apt install -y $(cat "$apt_list")

    # Verify installations
    while read -r pkg; do
        if ! dpkg -l | grep -q "^ii  $pkg "; then
            failed_apt+=("$pkg")
        fi
    done < "$apt_list"
}

install_wikiman() {
    log "Installing wikiman from GitHub release..."
    local temp_dir=$(mktemp -d)
    wget -q -O "$temp_dir/wikiman.deb" \
        "https://github.com/filiparag/wikiman/releases/latest/download/wikiman_$(curl -s https://api.github.com/repos/filiparag/wikiman/releases/latest | grep tag_name | cut -d '"' -f 4)_all.deb"
    sudo gdebi -n "$temp_dir/wikiman.deb"
    rm -rf "$temp_dir"
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
    [[ ! -f "$flatpak_list" ]] && { log "Flatpak list missing"; return; }
    
    flatpak install -y $(cat "$flatpak_list")

    # Verify installations
    while read -r pkg; do
        if ! flatpak list | grep -qi "$pkg"; then
            failed_flatpak+=("$pkg")
        fi
    done < "$flatpak_list"
}

setup_snap() {
    log "Configuring Snap..."
    sudo apt install -y snapd apparmor
    sudo systemctl enable --now snapd apparmor
    local snap_list="$HOME/dotfiles/backups/snap_list.bak"
    [[ ! -f "$snap_list" ]] && { log "Snap list missing"; return; }
    
    sudo snap install $(cat "$snap_list")

    # Verify installations
    while read -r pkg; do
        if ! snap list | grep -q "^$pkg "; then
            failed_snap+=("$pkg")
        fi
    done < "$snap_list"
}

setup_homebrew() {
    log "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> ~/.bashrc
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
    ulimit -n 8192

    local brew_list="$HOME/dotfiles/backups/brew_list.bak"
    [[ ! -f "$brew_list" ]] && { log "Brew list missing"; return; }
    
    brew install gcc $(cat "$brew_list")

    # Verify installations
    while read -r pkg; do
        if ! brew list | grep -q "^$pkg$"; then
            failed_brew+=("$pkg")
        fi
    done < "$brew_list"
}

# --- Utilities and Drivers ---
setup_kitty() {
    log "Setting Kitty as default terminal..."
    [[ ! $(command -v kitty) ]] && return
    
    sudo update-alternatives --set x-terminal-emulator /usr/bin/kitty
    if [ -f /usr/bin/gnome-terminal ]; then
        sudo mv /usr/bin/gnome-terminal /usr/bin/gnome-terminal.bak
    fi
    echo -e '#!/usr/bin/env bash\nkitty "$@"' | sudo tee /usr/bin/gnome-terminal > /dev/null
    sudo chmod 755 /usr/bin/gnome-terminal
}

install_blesh() {
    log "Installing ble.sh..."
    git clone --recursive --depth 1 --shallow-submodules \
        https://github.com/akinomyoga/ble.sh.git "$HOME/ble.sh"
    make -C "$HOME/ble.sh" install PREFIX=~/.local
    echo 'source ~/.local/share/blesh/ble.sh' >> ~/.bashrc
}

install_fonts() {
    log "Installing Hack Nerd Font..."
    mkdir -p ~/.local/share/fonts
    wget -q https://github.com/ryanoasis/nerd-fonts/releases/download/v3.0.2/Hack.zip -O /tmp/Hack.zip
    unzip -q /tmp/Hack.zip -d ~/.local/share/fonts
    fc-cache -fv
}

install_drivers() {
    log "Installing rtl8812au driver..."
    local driver_repo="$HOME/gitprojects/rtl8812au"
    git clone https://github.com/aircrack-ng/rtl8812au.git "$driver_repo"
    cd "$driver_repo" && sudo make dkms_install
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
install_essentials
configure_system
enable_wayland
harden_kernel
remove_bloatware
setup_dotfiles
filter_package_lists
install_apt_packages
install_wikiman  # Install wikiman separately after APT packages
setup_flatpak
setup_snap
setup_kitty
setup_fail2ban
install_blesh
install_fonts
setup_ufw
setup_homebrew
setup_apparmor
install_drivers
finalize

log "Bootstrap complete! Rebooting to activate Wayland and kernel hardening..."
sudo reboot
