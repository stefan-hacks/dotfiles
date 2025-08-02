#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# Initialize tracking arrays
failed_apt=()
failed_flatpak=()
failed_snap=()
failed_brew=()
excluded_apt_packages=()

log() {
  echo "[$(date +'%Y-%m-%dT%H:%M:%S%z')] $*"
}

check_command() {
  command -v "$1" &>/dev/null || { log "Missing required command: $1"; exit 1; }
}

# Dependency Installation Functions
install_essentials() {
  log "Installing essential dependencies..."
  sudo apt update -y
  sudo apt install -y git stow curl gawk cmake build-essential \
    linux-headers-$(uname -r) unzip
}

setup_system() {
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

remove_bloatware() {
  log "Removing unnecessary packages..."
  sudo apt purge -y audacity gimp gnome-games libreoffice*
}

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

setup_flatpak() {
  log "Configuring Flatpak..."
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

setup_fail2ban() {
  log "Configuring fail2ban..."
  sudo apt install -y fail2ban python3-systemd
  sudo cp /etc/fail2ban/{fail2ban,jail}.conf /etc/fail2ban/{fail2ban,jail}.local
  sudo sed -i '/\[sshd\]/,/enabled/s/^enabled.*/enabled = true/;
               /\[sshd\]/,/enabled/s/^backend.*/backend = systemd/' \
               /etc/fail2ban/jail.local
  sudo systemctl enable --now fail2ban.service
}

setup_kanata() {
  log "Configuring Kanata..."
  [[ ! $(command -v kanata) ]] && return

  sudo groupadd -f uinput
  sudo usermod -aG input,uinput "$USER"
  echo 'KERNEL=="uinput", MODE="0660", GROUP="uinput", OPTIONS+="static_node=uinput"' \
    | sudo tee /etc/udev/rules.d/99-input.rules > /dev/null
  sudo udevadm control --reload-rules && sudo udevadm trigger
  sudo modprobe uinput

  mkdir -p ~/.config/systemd/user
  cat <<EOF > ~/.config/systemd/user/kanata.service
[Unit]
Description=Kanata keyboard remapper

[Service]
Environment=PATH=/usr/local/bin:/usr/bin:/bin:$HOME/.cargo/bin
ExecStart=$(which kanata) --cfg \${HOME}/.config/kanata/kanata.kbd
Restart=always
RestartSec=3

[Install]
WantedBy=default.target
EOF

  systemctl --user daemon-reload
  systemctl --user enable --now kanata.service
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

setup_icons() {
  log "Installing Tela-circle-icons..."
  git clone https://github.com/vinceliuice/Tela-circle-icon-theme.git \
    "$HOME/Downloads/Tela-circle-icon-theme"
  "$HOME/Downloads/Tela-circle-icon-theme/install.sh"
}

setup_grub() {
  log "Configuring GRUB..."
  sudo apt install -y grub2-themes
  local grub_repo="$HOME/gitprojects/grub2-themes"
  git clone https://github.com/vinceliuice/grub2-themes.git "$grub_repo"
  cp "$HOME/Pictures/wallpapers/wallpaper_023.jpg" "$grub_repo/background.jpg"
  sudo "$grub_repo/install.sh" -s 1080p -b -t whitesur

  sudo sed -i 's/^GRUB_TIMEOUT=.*/GRUB_TIMEOUT=2/' /etc/default/grub
  sudo sed -i '/^GRUB_CMDLINE_LINUX_DEFAULT=/a GRUB_CMDLINE_LINUX="rhgb quiet mitigations=off"' /etc/default/grub
  sudo update-grub
  sudo update-initramfs -u -k all
}

setup_apparmor() {
  log "Enforcing AppArmor..."
  sudo aa-enforce /etc/apparmor.d/*
}

install_drivers() {
  log "Installing rtl8812au driver..."
  local driver_repo="$HOME/gitprojects/rtl8812au"
  git clone https://github.com/aircrack-ng/rtl8812au.git "$driver_repo"
  cd "$driver_repo" && sudo make dkms_install
}

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

# Main Execution Flow
install_essentials
setup_system
remove_bloatware
setup_dotfiles
filter_package_lists
install_apt_packages
setup_flatpak
setup_snap
setup_kitty
setup_fail2ban
setup_kanata
install_blesh
install_fonts
setup_ufw
setup_homebrew
setup_icons
setup_grub
setup_apparmor
install_drivers
finalize

log "Bootstrap complete! Some changes require reboot to take effect."
# sudo reboot
