#!/usr/bin/env bash

set -e

LOG_FILE="/var/log/system_setup.log"
PHASE_FILE="/tmp/install_phase"

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $*" | sudo tee -a "$LOG_FILE"
}

handle_phase() {
    if [ ! -f "$PHASE_FILE" ]; then
        # Phase 1 (pre-reboot)
        echo "phase1" > "$PHASE_FILE"
        
        log "Starting Phase 1 (pre-reboot)"
        
        # Enable Bluetooth
        log "Enabling Bluetooth"
        sudo systemctl enable --now bluetooth

        # Enable Wayland
        log "Enabling Wayland"
        sudo mkdir -p /etc/systemd/system/gdm.service.d
        sudo ln -sf /dev/null /etc/systemd/system/gdm.service.d/disable-wayland.conf

        # Install main packages
        log "Installing main packages"
        sudo apt update
        sudo apt install -y nala gnome-software-plugin-flatpak git gh stow build-essential dkms \
            linux-headers-$(uname -r) curl wget cmake gawk font-manager gnome-clocks \
            gnome-weather gnome-shell-extension-manager gpaste-2 fail2ban ufw snapd flatpak \
            gdebi tor torbrowser-launcher ffmpeg yt-dlp vlc mpv kitty figlet lolcat btop \
            gir1.2-gtop-2.0 lm-sensors hx nvim fzf ripgrep fd-find

        # Set default shell
        log "Setting default shell to bash"
        sudo chsh -s /bin/bash "$USER"
        sudo chsh -s /bin/bash root

        # Customize sudo prompt
        log "Customizing sudo prompt"
        echo 'Defaults passprompt="[sudo] password for %u:  "' | sudo tee /etc/sudoers.d/00_prompt_lock > /dev/null

        # Update GRUB
        log "Updating GRUB"
        sudo sed -i 's/^GRUB_TIMEOUT=.*/GRUB_TIMEOUT=2/' /etc/default/grub
        sudo update-grub
        sudo update-initramfs -u -k all

        log "Phase 1 complete. Rebooting..."
        # Schedule Phase 2 to run after reboot
        sudo cp "$0" /usr/local/bin/continue_install.sh
        sudo chmod +x /usr/local/bin/continue_install.sh
        echo "@reboot $USER /usr/local/bin/continue_install.sh" | sudo tee /etc/cron.d/continue_install
        sudo reboot
        
    else
        # Phase 2 (post-reboot)
        log "Starting Phase 2 (post-reboot)"
        
        # Remove cron job
        sudo rm -f /etc/cron.d/continue_install

        # Install Homebrew
        log "Installing Homebrew"
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> "$HOME/.bashrc"
        eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
        ulimit -n 8192
        brew install gcc $(cat "$HOME/dotfiles/backups/brew_list.bak")
        brew services start atuin

        # Setup dotfiles
        log "Setting up dotfiles"
        mkdir -p "$HOME/gitprojects"
        rm -rf "$HOME/.bashrc"
        git clone https://github.com/stefan-hacks/dotfiles.git "$HOME/dotfiles"
        cd "$HOME/dotfiles" && stow --adopt . && git restore .

        # Install wireless driver
        log "Installing wireless driver"
        cd "$HOME/gitprojects/"
        git clone https://github.com/aircrack-ng/rtl8812au.git
        cd rtl8812au
        sudo make dkms_install

        # Set Kitty as default terminal
        log "Setting Kitty as default terminal"
        sudo update-alternatives --set x-terminal-emulator /usr/bin/kitty
        if [ -f /usr/bin/gnome-terminal ]; then
            sudo mv /usr/bin/gnome-terminal /usr/bin/gnome-terminal.bak
        fi
        echo -e '#!/usr/bin/env bash\nkitty "$@"' | sudo tee /usr/bin/gnome-terminal > /dev/null
        sudo chmod 755 /usr/bin/gnome-terminal

        # Setup Flatpak
        log "Setting up Flatpak"
        flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
        flatpak install -y $(cat "$HOME/dotfiles/backups/flatpaks_list.bak")

        # Setup Snap
        log "Setting up Snap"
        sudo systemctl enable --now snapd apparmor
        sudo snap install snapd snap-store
        snap install $(cat "$HOME/dotfiles/backups/snap_list.bak")

        # Setup fail2ban
        log "Configuring fail2ban"
        sudo cp /etc/fail2ban/fail2ban.conf /etc/fail2ban/fail2ban.local
        sudo cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
        sudo sed -i '/\[sshd\]/,/enabled/s/^enabled.*/enabled = true/;/\[sshd\]/,/enabled/s/^backend.*/backend = systemd/' /etc/fail2ban/jail.local
        sudo systemctl enable fail2ban.service
        sudo systemctl start fail2ban.service

        # Setup UFW
        log "Configuring UFW"
        sudo ufw limit 22/tcp
        sudo ufw allow 80/tcp
        sudo ufw allow 443/tcp
        sudo ufw default deny incoming
        sudo ufw default allow outgoing
        sudo ufw enable

        # Install ble.sh
        log "Installing ble.sh"
        git clone --recursive --depth 1 --shallow-submodules https://github.com/akinomyoga/ble.sh.git "$HOME/ble.sh"
        make -C "$HOME/ble.sh" install PREFIX=~/.local
        echo 'source ~/.local/share/blesh/ble.sh' >>~/.bashrc

        # Install fonts
        log "Installing fonts"
        mkdir -p ~/.local/share/fonts
        wget -q https://github.com/ryanoasis/nerd-fonts/releases/download/v3.0.2/Hack.zip -O /tmp/Hack.zip
        unzip -q /tmp/Hack.zip -d ~/.local/share/fonts
        fc-cache -fv

        # Setup Kanata
        log "Setting up Kanata"
        sudo groupadd uinput || true
        sudo usermod -aG input "$USER"
        sudo usermod -aG uinput "$USER"
        echo 'KERNEL=="uinput", MODE="0660", GROUP="uinput", OPTIONS+="static_node=uinput"' | sudo tee /etc/udev/rules.d/99-input.rules > /dev/null
        sudo udevadm control --reload-rules && sudo udevadm trigger
        sudo modprobe uinput

        # Setup Kanata service
        mkdir -p ~/.config/systemd/user
        cat > ~/.config/systemd/user/kanata.service <<EOF
[Unit]
Description=Kanata keyboard remapper
Documentation=https://github.com/jtroo/kanata

[Service]
Environment=PATH=/home/linuxbrew/.linuxbrew/bin:/usr/local/bin:/usr/local/sbin:/usr/bin:/bin
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

        # Final setup
        log "Finalizing setup"
        source "$HOME/.bashrc"
        dconf load / <"$HOME/dotfiles/backups/gnome_settings.bak"

        log "All done! Cleaning up..."
        rm -f "$PHASE_FILE"
        sudo rm -f /usr/local/bin/continue_install.sh
    fi
}

# Main execution
handle_phase
