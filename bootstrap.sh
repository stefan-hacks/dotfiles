#!/usr/bin/env bash
set -euo pipefail
IFS=$'
	'

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

require_commands=(git stow curl gawk cmake sudo)
for cmd in "${require_commands[@]}"; do check_command "$cmd"; done

# Set default shell to bash for user and root
log "Setting default shell to bash for user and root..."
sudo chsh -s /bin/bash "$USER"
sudo chsh -s /bin/bash root

# Improve sudo password prompt
log "Customizing sudo password prompt..."
echo 'Defaults passprompt="[sudo] password for %u: 🔒 "' | sudo tee /etc/sudoers.d/00_prompt_lock > /dev/null

# Change default terminal to Kitty
log "Changing default terminal to Kitty..."
sudo update-alternatives --set x-terminal-emulator /usr/bin/kitty
if [ -f /usr/bin/gnome-terminal ]; then
  sudo mv /usr/bin/gnome-terminal /usr/bin/gnome-terminal.bak
fi
echo -e '#!/usr/bin/env bash
kitty "$@"' | sudo tee /usr/bin/gnome-terminal > /dev/null
sudo chmod 755 /usr/bin/gnome-terminal

# Configure and enable fail2ban
log "Setting up fail2ban..."
sudo apt install -y fail2ban python3-systemd
sudo cp /etc/fail2ban/fail2ban.conf /etc/fail2ban/fail2ban.local
sudo cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
sudo sed -i '/\[sshd\]/,/enabled/s/^enabled.*/enabled = true/;/\[sshd\]/,/enabled/s/^backend.*/backend = systemd/' /etc/fail2ban/jail.local
sudo systemctl enable fail2ban.service
sudo systemctl start fail2ban.service

# Set up Kanata keyboard remapper
log "Configuring Kanata..."
sudo groupadd -f uinput
sudo usermod -aG input "$USER"
sudo usermod -aG uinput "$USER"
echo 'KERNEL=="uinput", MODE="0660", GROUP="uinput", OPTIONS+="static_node=uinput"' | sudo tee /etc/udev/rules.d/99-input.rules > /dev/null
sudo udevadm control --reload-rules && sudo udevadm trigger
sudo modprobe uinput

mkdir -p ~/.config/systemd/user
cat <<EOF > ~/.config/systemd/user/kanata.service
[Unit]
Description=Kanata keyboard remapper
Documentation=https://github.com/jtroo/kanata

[Service]
Environment=PATH=/usr/local/bin:/usr/local/sbin:/usr/bin:/bin:$HOME/.cargo/bin
Environment=DISPLAY=:0
Type=simple
ExecStart=/usr/bin/sh -c 'exec \$(which kanata) --cfg \${HOME}/.config/kanata/kanata.kbd'
Restart=no

[Install]
WantedBy=default.target
EOF

systemctl --user daemon-reload
systemctl --user enable kanata.service
systemctl --user start kanata.service

log "Kanata service started. You may need to reboot or re-login for group changes to take effect."

# Further bootstrap steps would follow here...

# ==== Original Bootstrap Logic ====

#!/usr/bin/env bash

# Exit immediately if a command exits with a non-zero status
#set -e

# Initialize tracking arrays
failed_apt=()
failed_flatpak=()
failed_snap=()
failed_brew=()
excluded_apt_packages=()

# Function to log messages with a timestamp
log() {
  echo "[$(date +'%Y-%m-%dT%H:%M:%S%z')] $*"
}

# Section: Initial Setup
log "Starting initial setup..."
sudo sed -i '/^deb / s/$/ contrib non-free/' /etc/apt/sources.list
sudo apt update -y && sudo apt upgrade -y
sudo apt install -y stow git gh curl gawk cmake linux-headers-$(uname -r)

# Section: Remove Bloatware
log "Removing bloatware..."
sudo apt purge -y audacity gimp gnome-games libreoffice*

# Section: Git Projects and Dotfiles Setup
log "Setting up gitprojects and dotfiles..."
mkdir -p "$HOME/gitprojects"
rm -rf "$HOME/.bashrc"
git clone https://github.com/d4rkb4sh8/dotfiles_kali.git "$HOME/dotfiles"
cd "$HOME/dotfiles" && stow --adopt . && git restore .

# Remove specified packages from apt_list.bak
log "Filtering APT package list..."
file="$HOME/dotfiles/backups/apt_list.bak"

# Check if the file exists
if [[ ! -f "$file" ]]; then
  echo "Error: $file not found." >&2
  exit 1
fi

# Define the packages to remove (with regex patterns)
packages=(
  balena-etcher
  mullvad-vpn
  net\.downloadhelper\.coapp # Escape dots for literal matching
  popcorn-time
  ulauncher
  'virtualbox-*.*' # Match any VirtualBox version using regex wildcard
)

# Join packages into a regex pattern
pattern=$(
  IFS="|"
  echo "^(${packages[*]})$"
)

# Remove lines and overwrite the original file
grep -Ev "$pattern" "$file" >"$file.tmp" && mv "$file.tmp" "$file"

echo "Removed specified packages from $file successfully."

# Section: Install APT Packages
log "Installing APT packages..."
sudo apt install -y $(cat "$HOME/dotfiles/backups/apt_list.bak")

# Check for failed APT packages
while read -r pkg; do
  if ! dpkg -l | grep -q "^ii  $pkg "; then
    failed_apt+=("$pkg")
  fi
done <"$apt_list"

# Section: Flatpak and Snap Setup
log "Setting up Flatpak and Snap..."
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
flatpak install -y $(cat "$HOME/dotfiles/backups/flatpaks_list.bak")

# Check for failed Flatpak packages
while read -r pkg; do
  if ! flatpak list | grep -qi "$pkg"; then
    failed_flatpak+=("$pkg")
  fi
done <"$HOME/dotfiles/backups/flatpaks_list.bak"
sudo systemctl enable --now snapd apparmor
sudo snap install snapd snap-store
snap install $(cat "$HOME/dotfiles/backups/snap_list.bak")

# Check for failed Snap packages
while read -r pkg; do
  if ! snap list | grep -q "^$pkg "; then
    failed_snap+=("$pkg")
  fi
done <"$HOME/dotfiles/backups/snap_list.bak"

# Section: ble.sh Installation
log "Installing ble.sh..."
git clone --recursive --depth 1 --shallow-submodules https://github.com/akinomyoga/ble.sh.git "$HOME/ble.sh"
make -C "$HOME/ble.sh" install PREFIX=~/.local
echo 'source ~/.local/share/blesh/ble.sh' >>~/.bashrc

# Section: Font Installation
log "Installing Hack Nerd Font..."
mkdir -p ~/.local/share/fonts
wget -q https://github.com/ryanoasis/nerd-fonts/releases/download/v3.0.2/Hack.zip -O /tmp/Hack.zip
unzip -q /tmp/Hack.zip -d ~/.local/share/fonts
fc-cache -fv

# Section: UFW Setup
log "Setting up UFW..."
sudo ufw limit 22/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw enable

# Section: Homebrew Setup
log "Installing Homebrew..."
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >>~/.bashrc
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
ulimit -n 8192
brew install gcc $(cat "$HOME/dotfiles/backups/brew_list.bak")

# Check for failed Homebrew packages
while read -r pkg; do
  if ! brew list | grep -q "^$pkg$"; then
    failed_brew+=("$pkg")
  fi
done <"$HOME/dotfiles/backups/brew_list.bak"

# Section: Icon Theme Installation
log "Installing Tela-circle-icons..."
git clone https://github.com/vinceliuice/Tela-circle-icon-theme.git "$HOME/Downloads/Tela-circle-icon-theme"
"$HOME/Downloads/Tela-circle-icon-theme/install.sh"

# Section: GRUB Custom Theme Installation
log "Installing Grub theme..."
git clone https://github.com/vinceliuice/grub2-themes.git "$HOME/gitprojects/grub2-themes"
cp "$HOME/Pictures/wallpapers/wallpaper_001.jpg" "$HOME/gitprojects/grub2-themes/background.jpg"
sudo "$HOME/gitprojects/grub2-themes/install.sh" -s 1080p -b -t whitesur

# Section: GRUB Configuration
log "Configuring GRUB..."
sudo sed -i 's/^GRUB_TIMEOUT=.*/GRUB_TIMEOUT=2/' /etc/default/grub
sudo sed -i '/^GRUB_CMDLINE_LINUX_DEFAULT=/a GRUB_CMDLINE_LINUX="rhgb quiet mitigations=off"' /etc/default/grub
sudo update-grub
sudo update-initramfs -u -k all

# Section: AppArmor Enforcement
log "Enforcing AppArmor profiles..."
sudo aa-enforce /etc/apparmor.d/*

# alfa wireless adapter realtek
cd $HOME/gitprojects/
git clone https://github.com/aircrack-ng/rtl8812au.git
cd rtl8812au
sudo make dkms_install

# Section: Source .bashrc and Restore Gnome Settings
log "Sourcing .bashrc and restoring Gnome settings..."
source "$HOME/.bashrc"
dconf load / <"$HOME/dotfiles/backups/gnome_settings.bak"

# Section: Installation Summary
log "Installation Summary:"

print_failed() {
  local category=$1
  shift
  local packages=("$@")

  if [ ${#packages[@]} -gt 0 ]; then
    log "Failed $category packages:"
    printf ' - %s\n' "${packages[@]}"
    echo ""
  fi
}

print_failed "APT" "${failed_apt[@]}"
print_failed "Flatpak" "${failed_flatpak[@]}"
print_failed "Snap" "${failed_snap[@]}"
print_failed "Homebrew" "${failed_brew[@]}"

if [ ${#excluded_apt_packages[@]} -gt 0 ]; then
  log "The following packages were excluded and require manual installation:"
  printf ' - %s\n' "${excluded_apt_packages[@]}"
  echo "Install them manually"
  echo ""
fi

# Section: Display Completion Message and Reboot
log "Displaying completion message and rebooting..."
if command -v figlet &>/dev/null && command -v lolcat &>/dev/null; then
  figlet h4ck3r m4ch1n3 | lolcat
fi

#sudo reboot
