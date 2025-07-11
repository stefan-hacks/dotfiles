#!/usr/bin/env bash

# repro - Reproducible Environment Manager
# Version 2.0.1
# Supports apt, brew, cargo, flatpak, snap
# Automatic package tracking and system reproducibility

# Configuration
CONFIG_DIR="$HOME/.config/repro"
STATE_DIR="$CONFIG_DIR/state"
BACKUP_DIR="$CONFIG_DIR/backups"
LOG_FILE="$CONFIG_DIR/repro.log"
COLOR_ENABLED=true
HOSTNAME=$(hostname | tr '[:upper:]' '[:lower:]')
TIMESTAMP=$(date +%Y%m%d%H%M%S)

# Initialize colors
setup_colors() {
    if [[ -t 2 ]] && [[ -z "${NO_COLOR-}" ]] && [[ "${TERM-}" != "dumb" ]] && $COLOR_ENABLED; then
        RED=$(tput setaf 1)
        GREEN=$(tput setaf 2)
        YELLOW=$(tput setaf 3)
        BLUE=$(tput setaf 4)
        MAGENTA=$(tput setaf 5)
        CYAN=$(tput setaf 6)
        BOLD=$(tput bold)
        RESET=$(tput sgr0)
    else
        RED=""
        GREEN=""
        YELLOW=""
        BLUE=""
        MAGENTA=""
        CYAN=""
        BOLD=""
        RESET=""
    fi
}

# Logging functions
log() {
    echo -e "$(date '+%Y-%m-%d %H:%M:%S') - $*" | tee -a "$LOG_FILE"
}

success() {
    log "${GREEN}✓ SUCCESS:${RESET} $*"
}

info() {
    log "${CYAN}ℹ INFO:${RESET} $*"
}

warn() {
    log "${YELLOW}⚠ WARNING:${RESET} $*"
}

error() {
    log "${RED}✗ ERROR:${RESET} $*"
}

# Initialize directories
init_dirs() {
    mkdir -p "$STATE_DIR" "$BACKUP_DIR"
    touch "$LOG_FILE"
    
    # Create state files if missing
    for manager in apt brew cargo flatpak snap gnome; do
        touch "$STATE_DIR/$manager.txt"
    done
}

# Package detection functions
detect_apt() {
    apt-mark showmanual | sort -u > "$STATE_DIR/apt.txt"
}

detect_brew() {
    if command -v brew &> /dev/null; then
        brew leaves | sort -u > "$STATE_DIR/brew.txt"
    fi
}

detect_cargo() {
    if command -v cargo &> /dev/null; then
        cargo install --list | grep -E '^[a-zA-Z0-9_-]+ v[0-9]' | cut -d' ' -f1 | sort -u > "$STATE_DIR/cargo.txt"
    fi
}

detect_flatpak() {
    if command -v flatpak &> /dev/null; then
        flatpak list --app --columns=application | sort -u > "$STATE_DIR/flatpak.txt"
    fi
}

detect_snap() {
    if command -v snap &> /dev/null; then
        snap list | awk 'NR>1 {print $1}' | sort -u > "$STATE_DIR/snap.txt"
    fi
}

detect_gnome() {
    if command -v dconf &> /dev/null; then
        dconf dump / > "$STATE_DIR/gnome.txt"
    fi
}

detect_all() {
    info "Detecting installed packages and settings..."
    detect_apt
    detect_brew
    detect_cargo
    detect_flatpak
    detect_snap
    detect_gnome
    success "Detection completed"
}

# Installation functions
install_apt() {
    if [ -s "$STATE_DIR/apt.txt" ]; then
        info "Installing APT packages..."
        sudo apt update
        xargs -a "$STATE_DIR/apt.txt" sudo apt install -y
    fi
}

install_brew() {
    if [ -s "$STATE_DIR/brew.txt" ] && command -v brew &> /dev/null; then
        info "Installing Homebrew packages..."
        xargs -a "$STATE_DIR/brew.txt" brew install
    fi
}

install_cargo() {
    if [ -s "$STATE_DIR/cargo.txt" ] && command -v cargo &> /dev/null; then
        info "Installing Cargo packages..."
        xargs -a "$STATE_DIR/cargo.txt" cargo install
    fi
}

install_flatpak() {
    if [ -s "$STATE_DIR/flatpak.txt" ] && command -v flatpak &> /dev/null; then
        info "Installing Flatpak packages..."
        xargs -a "$STATE_DIR/flatpak.txt" flatpak install -y
    fi
}

install_snap() {
    if [ -s "$STATE_DIR/snap.txt" ] && command -v snap &> /dev/null; then
        info "Installing Snap packages..."
        xargs -a "$STATE_DIR/snap.txt" -I{} sudo snap install {}
    fi
}

install_gnome() {
    if [ -s "$STATE_DIR/gnome.txt" ] && command -v dconf &> /dev/null; then
        info "Applying GNOME settings..."
        dconf load / < "$STATE_DIR/gnome.txt"
    fi
}

install_all() {
    info "Beginning system provisioning..."
    install_apt
    install_brew
    install_cargo
    install_flatpak
    install_snap
    install_gnome
    success "Provisioning completed"
}

# Backup functions
create_backup() {
    local backup_name="${HOSTNAME}_${TIMESTAMP}"
    local backup_path="$BACKUP_DIR/$backup_name"
    
    mkdir -p "$backup_path"
    cp "$STATE_DIR"/*.txt "$backup_path"
    success "Backup created: $backup_name"
    echo "Backup location: $backup_path"
}

list_backups() {
    info "Available backups:"
    local count=1
    ls -1 "$BACKUP_DIR" | while read -r backup; do
        echo "  [$count] $backup"
        ((count++))
    done
}

restore_backup() {
    local backup_id=$1
    local backup_path=""
    
    if [[ "$backup_id" =~ ^[0-9]+$ ]]; then
        # Numeric ID selection
        backup_path=$(ls -1 "$BACKUP_DIR" | sed -n "${backup_id}p")
        if [ -z "$backup_path" ]; then
            error "Invalid backup number: $backup_id"
            return 1
        fi
        backup_path="$BACKUP_DIR/$backup_path"
    else
        # Direct name match
        backup_path="$BACKUP_DIR/$backup_id"
    fi
    
    if [ ! -d "$backup_path" ]; then
        error "Backup not found: $backup_id"
        return 1
    fi
    
    info "Restoring backup: $(basename "$backup_path")"
    cp "$backup_path"/*.txt "$STATE_DIR"
    success "Backup restored"
}

# Search functions
search_package() {
    local pkg=$1
    echo -e "${BOLD}${YELLOW}Search results for: $pkg${RESET}"
    echo "--------------------------------"
    
    # APT
    if apt-cache show "$pkg" &>/dev/null; then
        if dpkg -s "$pkg" &>/dev/null; then
            version=$(dpkg -s "$pkg" | grep '^Version:' | awk '{print $2}')
            echo -e "${GREEN}APT:${RESET} $pkg (${CYAN}$version${RESET})"
        else
            version=$(apt-cache show "$pkg" | grep -m1 '^Version:' | awk '{print $2}')
            echo -e "${YELLOW}APT:${RESET} $pkg (${version}) ${RED}[Not Installed]${RESET}"
        fi
    else
        echo -e "${RED}APT:${RESET} $pkg [Not Found]"
    fi
    
    # Homebrew
    if command -v brew &>/dev/null; then
        if brew info "$pkg" &>/dev/null; then
            version=$(brew info "$pkg" 2>/dev/null | grep -E '^[^/]+/brew' | awk '{print $3}')
            if brew list | grep -q "^$pkg\$"; then
                echo -e "${GREEN}Homebrew:${RESET} $pkg (${CYAN}$version${RESET})"
            else
                echo -e "${YELLOW}Homebrew:${RESET} $pkg (${version}) ${RED}[Not Installed]${RESET}"
            fi
        else
            echo -e "${RED}Homebrew:${RESET} $pkg [Not Found]"
        fi
    else
        echo -e "${RED}Homebrew:${RESET} brew not installed"
    fi
    
    # Cargo (fixed to suppress informational messages)
    if command -v cargo &>/dev/null; then
        # Use --quiet flag to suppress informational messages
        if cargo search --quiet --limit 1 "$pkg" 2>/dev/null | grep -q "^$pkg = "; then
            version=$(cargo search --quiet --limit 1 "$pkg" 2>/dev/null | awk -F'"' '{print $2}')
            if cargo install --list 2>/dev/null | grep -q "^$pkg v"; then
                installed_version=$(cargo install --list 2>/dev/null | grep "^$pkg v" | head -1 | awk '{print $2}')
                echo -e "${GREEN}Cargo:${RESET} $pkg (${CYAN}$installed_version${RESET})"
            else
                echo -e "${YELLOW}Cargo:${RESET} $pkg (${version}) ${RED}[Not Installed]${RESET}"
            fi
        else
            echo -e "${RED}Cargo:${RESET} $pkg [Not Found]"
        fi
    else
        echo -e "${RED}Cargo:${RESET} cargo not installed"
    fi
    
    # Flatpak
    if command -v flatpak &>/dev/null; then
        if flatpak search "$pkg" --columns=application 2>/dev/null | grep -q "$pkg"; then
            if flatpak info "$pkg" &>/dev/null; then
                version=$(flatpak info "$pkg" | grep -E '^Version:' | awk '{print $2}')
                echo -e "${GREEN}Flatpak:${RESET} $pkg (${CYAN}$version${RESET})"
            else
                echo -e "${YELLOW}Flatpak:${RESET} $pkg ${RED}[Not Installed]${RESET}"
            fi
        else
            echo -e "${RED}Flatpak:${RESET} $pkg [Not Found]"
        fi
    else
        echo -e "${RED}Flatpak:${RESET} flatpak not installed"
    fi
    
    # Snap
    if command -v snap &>/dev/null; then
        if snap info "$pkg" &>/dev/null; then
            version=$(snap info "$pkg" | awk '/^latest/{print $2; exit}')
            if snap list "$pkg" &>/dev/null; then
                installed_ver=$(snap list "$pkg" | awk -v p="$pkg" '$1 == p {print $2}')
                echo -e "${GREEN}Snap:${RESET} $pkg (${CYAN}$installed_ver${RESET})"
            else
                echo -e "${YELLOW}Snap:${RESET} $pkg (${version}) ${RED}[Not Installed]${RESET}"
            fi
        else
            echo -e "${RED}Snap:${RESET} $pkg [Not Found]"
        fi
    else
        echo -e "${RED}Snap:${RESET} snap not installed"
    fi
    
    echo "--------------------------------"
}

# Monitoring setup
setup_monitoring() {
    info "Setting up package monitoring..."
    
    # Create systemd service
    local service_file="/etc/systemd/system/repro-monitor.service"
    local timer_file="/etc/systemd/system/repro-monitor.timer"
    local script_path="/usr/local/bin/repro-monitor"
    
    # Create monitoring script
    sudo tee "$script_path" > /dev/null <<'EOF'
#!/bin/bash
CONFIG_DIR="$HOME/.config/repro"
export DISPLAY=:0
export DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$(id -u)/bus
/usr/local/bin/repro -d
EOF
    sudo chmod +x "$script_path"
    
    # Create service
    sudo tee "$service_file" > /dev/null <<EOF
[Unit]
Description=Repro Package Monitor

[Service]
Type=oneshot
User=$USER
Environment="DISPLAY=:0"
Environment="DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$(id -u)/bus"
ExecStart=$script_path
EOF

    # Create timer
    sudo tee "$timer_file" > /dev/null <<EOF
[Unit]
Description=Run Repro monitor hourly

[Timer]
OnCalendar=hourly
Persistent=true

[Install]
WantedBy=timers.target
EOF

    # Enable and start
    sudo systemctl daemon-reload
    sudo systemctl enable repro-monitor.timer
    sudo systemctl start repro-monitor.timer
    
    success "Monitoring enabled (runs hourly)"
}

# List functions
list_packages() {
    info "Current package state:"
    
    for manager in apt brew cargo flatpak snap; do
        local state_file="$STATE_DIR/$manager.txt"
        
        if [ -s "$state_file" ]; then
            echo -e "${BOLD}${MAGENTA}${manager^^} PACKAGES:${RESET}"
            cat "$state_file"
            echo
        fi
    done
}

# Help function
show_help() {
    echo -e "${BOLD}${GREEN}repro - Reproducible Environment Manager${RESET}"
    echo "Version 2.0.1 | Debian Package Management"
    echo
    echo "Usage: repro [OPTION] [ARGUMENTS]"
    echo
    echo "Options:"
    echo "  -d, --detect        Detect installed packages (update state)"
    echo "  -i, --install       Install packages from current state"
    echo "  -b, --backup        Create new backup"
    echo "  -r, --restore ID    Restore specific backup (by name or number)"
    echo "  -l, --list          List current package state"
    echo "  -s, --search PKG    Search for package across all managers"
    echo "  -m, --monitor       Enable automatic package monitoring"
    echo "  --list-backups      List available backups"
    echo "  -v, --version       Show version information"
    echo "  -h, --help          Show this help message"
    echo
    echo "Examples:"
    echo "  repro -d              # Update package state"
    echo "  repro -b              # Create new backup"
    echo "  repro -r mypc_20250101120000  # Restore specific backup"
    echo "  repro -r 2            # Restore backup #2 from list"
    echo "  repro -s firefox      # Search for firefox package"
    echo
}

# Main function
main() {
    setup_colors
    init_dirs
    
    if [[ $# -eq 0 ]]; then
        show_help
        exit 0
    fi

    while [[ $# -gt 0 ]]; do
        case $1 in
            -d|--detect)
                detect_all
                shift
                ;;
            -i|--install)
                install_all
                shift
                ;;
            -b|--backup)
                create_backup
                shift
                ;;
            -r|--restore)
                restore_backup "$2"
                shift 2
                ;;
            -l|--list)
                list_packages
                shift
                ;;
            -s|--search)
                search_package "$2"
                shift 2
                ;;
            -m|--monitor)
                setup_monitoring
                shift
                ;;
            --list-backups)
                list_backups
                shift
                ;;
            -v|--version)
                echo "repro 2.0.1"
                exit 0
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            *)
                error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
}

# Start main execution
main "$@"
