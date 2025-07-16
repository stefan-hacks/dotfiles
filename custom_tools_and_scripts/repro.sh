#!/usr/bin/env bash

# repro - Reproducible Environment Manager
# Version 3.0.0
# Supports apt, brew, cargo, flatpak, snap
# Automatic package tracking and system reproducibility

# Configuration
CONFIG_DIR="${REPRO_CONFIG:-$HOME/.config/repro}"
STATE_DIR="$CONFIG_DIR/state"
BACKUP_DIR="$CONFIG_DIR/backups"
LOG_FILE="$CONFIG_DIR/repro.log"
COLOR_ENABLED=true
HOSTNAME=$(hostname | tr '[:upper:]' '[:lower:]')
TIMESTAMP=$(date +%Y%m%d%H%M%S)
NONINTERACTIVE=false

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
        DIM=$(tput dim)
        RESET=$(tput sgr0)
    else
        RED=""; GREEN=""; YELLOW=""; BLUE=""
        MAGENTA=""; CYAN=""; BOLD=""; RESET=""; DIM=""
    fi
}

# Enhanced logging
log() {
    local type="$1"
    local msg="$2"
    local color=""
    local symbol=""
    
    case $type in
        success) color="$GREEN"; symbol="✓" ;;
        info) color="$CYAN"; symbol="ℹ" ;;
        warn) color="$YELLOW"; symbol="⚠" ;;
        error) color="$RED"; symbol="✗" ;;
        *) color="$BLUE"; symbol="•" ;;
    esac
    
    local log_entry="$(date '+%Y-%m-%d %H:%M:%S') - ${type^^}: $msg"
    echo -e "${color}${BOLD}${symbol} ${type^^}:${RESET} $msg" >&2
    echo "$log_entry" >> "$LOG_FILE"
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
    command -v brew &>/dev/null && brew leaves | sort -u > "$STATE_DIR/brew.txt"
}

detect_cargo() {
    command -v cargo &>/dev/null && cargo install --list | awk '/^[a-z0-9_-]+ v[0-9]/{print $1}' | sort -u > "$STATE_DIR/cargo.txt"
}

detect_flatpak() {
    command -v flatpak &>/dev/null && flatpak list --app --columns=application | sort -u > "$STATE_DIR/flatpak.txt"
}

detect_snap() {
    command -v snap &>/dev/null && snap list | awk 'NR>1 {print $1}' | sort -u > "$STATE_DIR/snap.txt"
}

detect_gnome() {
    command -v dconf &>/dev/null && dconf dump / > "$STATE_DIR/gnome.txt"
}

detect_all() {
    log info "Detecting installed packages and settings..."
    detect_apt; detect_brew; detect_cargo
    detect_flatpak; detect_snap; detect_gnome
    log success "Detection completed"
}

# Installation functions
install_apt() {
    if [[ -s "$STATE_DIR/apt.txt" ]]; then
        log info "Installing APT packages..."
        sudo apt-get update
        xargs -a "$STATE_DIR/apt.txt" sudo apt-get install -y
    fi
}

install_brew() {
    [[ -s "$STATE_DIR/brew.txt" ]] && command -v brew &>/dev/null && {
        log info "Installing Homebrew packages..."
        xargs -a "$STATE_DIR/brew.txt" brew install
    }
}

install_cargo() {
    [[ -s "$STATE_DIR/cargo.txt" ]] && command -v cargo &>/dev/null && {
        log info "Installing Cargo packages..."
        xargs -a "$STATE_DIR/cargo.txt" cargo install
    }
}

install_flatpak() {
    [[ -s "$STATE_DIR/flatpak.txt" ]] && command -v flatpak &>/dev/null && {
        log info "Installing Flatpak packages..."
        xargs -a "$STATE_DIR/flatpak.txt" flatpak install -y
    }
}

install_snap() {
    [[ -s "$STATE_DIR/snap.txt" ]] && command -v snap &>/dev/null && {
        log info "Installing Snap packages..."
        xargs -a "$STATE_DIR/snap.txt" -I{} sudo snap install {}
    }
}

install_gnome() {
    [[ -s "$STATE_DIR/gnome.txt" ]] && command -v dconf &>/dev/null && {
        log info "Applying GNOME settings..."
        dconf load / < "$STATE_DIR/gnome.txt"
    }
}

install_all() {
    log info "Beginning system provisioning..."
    install_apt; install_brew; install_cargo
    install_flatpak; install_snap; install_gnome
    log success "Provisioning completed"
}

# Backup functions
create_backup() {
    local backup_name="${HOSTNAME}_${TIMESTAMP}"
    local backup_path="$BACKUP_DIR/$backup_name"
    
    mkdir -p "$backup_path"
    cp -p "$STATE_DIR"/*.txt "$backup_path" 2>/dev/null
    log success "Backup created: $backup_name"
    echo "${BOLD}Backup location:${RESET} $backup_path"
}

list_backups() {
    log info "Available backups:"
    local count=1
    ls -1t "$BACKUP_DIR" | while read -r backup; do
        echo "  ${BOLD}[$count]${RESET} $backup"
        ((count++))
    done
}

restore_backup() {
    local backup_id=$1
    local backup_path=""
    
    # Numeric ID selection
    if [[ "$backup_id" =~ ^[0-9]+$ ]]; then
        backup_path=$(ls -1t "$BACKUP_DIR" | sed -n "${backup_id}p")
        [[ -z "$backup_path" ]] && {
            log error "Invalid backup number: $backup_id"
            return 1
        }
        backup_path="$BACKUP_DIR/$backup_path"
    else
        backup_path="$BACKUP_DIR/$backup_id"
    fi
    
    [[ ! -d "$backup_path" ]] && {
        log error "Backup not found: $backup_id"
        return 1
    }
    
    log info "Restoring backup: $(basename "$backup_path")"
    cp -f "$backup_path"/*.txt "$STATE_DIR"
    log success "Backup restored"
}

# Package installation from specific manager
install_package() {
    local manager="$1"
    local pkg="$2"
    
    case "$manager" in
        apt)
            sudo apt-get install -y "$pkg"
            detect_apt
            ;;
        brew)
            brew install "$pkg"
            detect_brew
            ;;
        cargo)
            cargo install "$pkg"
            detect_cargo
            ;;
        flatpak)
            flatpak install -y "$pkg"
            detect_flatpak
            ;;
        snap)
            sudo snap install "$pkg"
            detect_snap
            ;;
        *)
            log error "Unsupported manager: $manager"
            return 1
            ;;
    esac
}

# Enhanced search function
search_package() {
    local pkg="$1"
    local found=false
    
    echo -e "${BOLD}${YELLOW}Search results for: $pkg${RESET}"
    echo "${BOLD}--------------------------------${RESET}"
    
    # APT
    if apt-cache show "$pkg" &>/dev/null; then
        local installed_version=$(dpkg-query -W -f='${Version}' "$pkg" 2>/dev/null)
        if [[ -n "$installed_version" ]]; then
            echo -e "${GREEN}APT:${RESET} $pkg ${CYAN}($installed_version)${RESET} [Installed]"
        else
            local available_version=$(apt-cache policy "$pkg" | grep -m1 'Candidate:' | awk '{print $2}')
            echo -e "${YELLOW}APT:${RESET} $pkg ${CYAN}($available_version)${RESET} [Available]"
        fi
        found=true
    fi
    
    # Homebrew
    if command -v brew &>/dev/null; then
        if brew info "$pkg" &>/dev/null; then
            local brew_version=$(brew info "$pkg" | head -1 | awk '{print $3}' | tr -d ',')
            if brew list | grep -q "^$pkg\$"; then
                echo -e "${GREEN}Homebrew:${RESET} $pkg ${CYAN}($brew_version)${RESET} [Installed]"
            else
                echo -e "${YELLOW}Homebrew:${RESET} $pkg ${CYAN}($brew_version)${RESET} [Available]"
            fi
            found=true
        fi
    fi

    # Cargo
    if command -v cargo &>/dev/null; then
        if cargo search --quiet --limit 1 "$pkg" 2>/dev/null | grep -q "^$pkg = "; then
            local cargo_version=$(cargo search --quiet --limit 1 "$pkg" | awk -F'"' '{print $2}')
            if cargo install --list | grep -q "^$pkg v"; then
                echo -e "${GREEN}Cargo:${RESET} $pkg ${CYAN}($cargo_version)${RESET} [Installed]"
            else
                echo -e "${YELLOW}Cargo:${RESET} $pkg ${CYAN}($cargo_version)${RESET} [Available]"
            fi
            found=true
        fi
    fi

    # Flatpak
    if command -v flatpak &>/dev/null; then
        if flatpak search "$pkg" --columns=application 2>/dev/null | grep -q "$pkg"; then
            local flatpak_version=$(flatpak info "$pkg" 2>/dev/null | awk -F': ' '/^Version:/ {print $2}')
            if flatpak list | grep -q "$pkg"; then
                echo -e "${GREEN}Flatpak:${RESET} $pkg ${CYAN}($flatpak_version)${RESET} [Installed]"
            else
                echo -e "${YELLOW}Flatpak:${RESET} $pkg ${CYAN}($flatpak_version)${RESET} [Available]"
            fi
            found=true
        fi
    fi

    # Snap
    if command -v snap &>/dev/null; then
        if snap info "$pkg" &>/dev/null; then
            local snap_version=$(snap info "$pkg" | awk '/^latest/ {print $2}')
            if snap list "$pkg" &>/dev/null; then
                echo -e "${GREEN}Snap:${RESET} $pkg ${CYAN}($snap_version)${RESET} [Installed]"
            else
                echo -e "${YELLOW}Snap:${RESET} $pkg ${CYAN}($snap_version)${RESET} [Available]"
            fi
            found=true
        fi
    fi

    [[ "$found" == false ]] && 
        echo -e "${RED}No package found in any manager:${RESET} $pkg"
    
    echo "${BOLD}--------------------------------${RESET}"
}

# Monitoring setup
setup_monitoring() {
    log info "Setting up package monitoring..."
    
    # Create systemd service
    local service_file="/etc/systemd/system/repro-monitor.service"
    local timer_file="/etc/systemd/system/repro-monitor.timer"
    local script_path="/usr/local/bin/repro-monitor"
    
    # Create monitoring script
    sudo tee "$script_path" > /dev/null <<'EOF'
#!/bin/bash
export DISPLAY=:0
export DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$(id -u)/bus
/usr/local/bin/repro --detect
EOF
    sudo chmod +x "$script_path"
    
    # Create service
    sudo tee "$service_file" > /dev/null <<EOF
[Unit]
Description=Repro Package Monitor

[Service]
Type=oneshot
User=$USER
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

    sudo systemctl daemon-reload
    sudo systemctl enable repro-monitor.timer
    sudo systemctl start repro-monitor.timer
    
    log success "Monitoring enabled (runs hourly)"
}

# Clean old backups
clean_backups() {
    local keep=${1:-5}
    local total=$(ls -1t "$BACKUP_DIR" | wc -l)
    
    if (( total <= keep )); then
        log info "No backups to clean (keeping all $total backups)"
        return
    fi
    
    local to_remove=$((total - keep))
    log info "Removing $to_remove old backups (keeping $keep)"
    
    ls -1t "$BACKUP_DIR" | tail -n $to_remove | while read -r backup; do
        log info "Removing backup: $backup"
        rm -rf "$BACKUP_DIR/$backup"
    done
    
    log success "Backup cleanup completed"
}

# Show diff between states
show_diff() {
    local backup_id="$1"
    local backup_path=""
    
    if [[ -z "$backup_id" ]]; then
        backup_path=$(ls -dt "$BACKUP_DIR"/*/ | head -1)
    elif [[ "$backup_id" =~ ^[0-9]+$ ]]; then
        backup_path=$(ls -1t "$BACKUP_DIR" | sed -n "${backup_id}p")
        [[ -z "$backup_path" ]] && {
            log error "Invalid backup number: $backup_id"
            return 1
        }
        backup_path="$BACKUP_DIR/$backup_path"
    else
        backup_path="$BACKUP_DIR/$backup_id"
    fi
    
    [[ ! -d "$backup_path" ]] && {
        log error "Backup not found: $backup_id"
        return 1
    }
    
    log info "Comparing current state with: $(basename "$backup_path")"
    
    for manager in apt brew cargo flatpak snap gnome; do
        local current="$STATE_DIR/$manager.txt"
        local backup="$backup_path/$manager.txt"
        
        [[ ! -f "$backup" ]] && continue
        
        echo -e "\n${BOLD}${MAGENTA}${manager^^} CHANGES:${RESET}"
        diff --color=always -U0 "$backup" "$current" | grep -v '^@@'
    done
}

# Enhanced help with Nala-like styling
show_help() {
    echo -e "${BOLD}${GREEN}repro - Reproducible Environment Manager${RESET} ${DIM}v3.0.0${RESET}"
    echo "Cross-platform package management and system reproducibility"
    echo
    echo -e "${BOLD}${MAGENTA}USAGE:${RESET}"
    echo "  repro [OPTIONS] [ARGUMENTS]"
    echo
    echo -e "${BOLD}${MAGENTA}OPTIONS:${RESET}"
    echo -e "  ${GREEN}-d, --detect${RESET}        Detect installed packages"
    echo -e "  ${GREEN}-i, --install${RESET}       Install packages from current state"
    echo -e "  ${GREEN}-a, --add PKG${RESET}       Install package and update state"
    echo -e "  ${GREEN}-b, --backup${RESET}        Create new backup"
    echo -e "  ${GREEN}-r, --restore ID${RESET}    Restore specific backup"
    echo -e "  ${GREEN}-l, --list${RESET}          List current package state"
    echo -e "  ${GREEN}-s, --search PKG${RESET}    Search for package across managers"
    echo -e "  ${GREEN}-m, --monitor${RESET}       Enable automatic monitoring"
    echo -e "  ${GREEN}--list-backups${RESET}      List available backups"
    echo -e "  ${GREEN}--clean-backups [N]${RESET} Clean old backups (keep last N)"
    echo -e "  ${GREEN}--diff [ID]${RESET}         Compare current state with backup"
    echo -e "  ${GREEN}-v, --version${RESET}       Show version"
    echo -e "  ${GREEN}-h, --help${RESET}          Show this help"
    echo
    echo -e "${BOLD}${MAGENTA}EXAMPLES:${RESET}"
    echo -e "  ${DIM}# Create new backup${RESET}"
    echo -e "  repro -b\n"
    echo -e "  ${DIM}# Install package from specific manager${RESET}"
    echo -e "  repro --add apt:neovim\n"
    echo -e "  ${DIM}# Restore backup #2${RESET}"
    echo -e "  repro -r 2\n"
    echo -e "  ${DIM}# Compare with latest backup${RESET}"
    echo -e "  repro --diff\n"
}

# Main function
main() {
    setup_colors
    init_dirs
    
    [[ $# -eq 0 ]] && { show_help; exit 0; }

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
            -a|--add)
                if [[ "$2" == *:* ]]; then
                    manager="${2%%:*}"
                    pkg="${2#*:}"
                    shift
                    log info "Installing $pkg via $manager"
                    install_package "$manager" "$pkg"
                else
                    log error "Specify manager: package (e.g., apt:neovim)"
                    exit 1
                fi
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
                log info "Current package state:"
                for manager in apt brew cargo flatpak snap; do
                    [[ -s "$STATE_DIR/$manager.txt" ]] && {
                        echo -e "\n${BOLD}${MAGENTA}${manager^^} PACKAGES:${RESET}"
                        cat "$STATE_DIR/$manager.txt"
                    }
                done
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
            --clean-backups)
                clean_backups "$2"
                [[ -n "$2" && "$2" =~ ^[0-9]+$ ]] && shift
                shift
                ;;
            --diff)
                show_diff "$2"
                [[ -n "$2" ]] && shift
                shift
                ;;
            -v|--version)
                echo "repro 3.0.0"
                exit 0
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            *)
                log error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
}

# Start main execution
main "$@"
