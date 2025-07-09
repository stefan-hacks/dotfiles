#!/usr/bin/env bash

# Configuration
BACKUP_DIR="$HOME/backups"
ERRORS=0

# Colors and symbols
RED=$(tput setaf 1 2>/dev/null || echo '')
GREEN=$(tput setaf 2 2>/dev/null || echo '')
YELLOW=$(tput setaf 3 2>/dev/null || echo '')
RESET=$(tput sgr0 2>/dev/null || echo '')
SUCCESS="${GREEN}✓${RESET}"
FAILURE="${RED}✗${RESET}"
WARNING="${YELLOW}⚠${RESET}"

# Help message
print_help() {
    cat <<EOF
Usage: $0 [OPTIONS]

Options:
  -i, --install         Create backup directory structure
  -o, --output-dir DIR  Specify custom backup directory (default: $BACKUP_DIR)
  -g, --gnome           Backup GNOME desktop settings
  -a, --apt             Backup APT packages list
  -f, --flatpak         Backup Flatpak applications
  -b, --brew            Backup Homebrew packages
  -s, --snap            Backup Snap packages
  -A, --all             Backup all systems (default if no options specified)
  -h, --help            Show this help message

If no backup options are specified, --all is assumed.
EOF
}

# Backup functions
backup_gnome() {
    if ! command -v dconf &>/dev/null; then
        echo "${WARNING} dconf not found - skipping GNOME settings backup"
        return 1
    fi
    
    if dconf dump / > "${BACKUP_DIR}/gnome_settings.bak" 2>/dev/null; then
        echo "${SUCCESS} GNOME settings backed up"
        return 0
    else
        echo "${FAILURE} Failed to backup GNOME settings"
        return 1
    fi
}

backup_apt() {
    if ! command -v dpkg-query &>/dev/null; then
        echo "${WARNING} dpkg-query not found - skipping APT packages backup"
        return 1
    fi
    
    if dpkg-query -f '${Package}\n' -W > "${BACKUP_DIR}/apt_list.bak" 2>/dev/null; then
        echo "${SUCCESS} APT packages backed up"
        return 0
    else
        echo "${FAILURE} Failed to backup APT packages"
        return 1
    fi
}

backup_flatpak() {
    if ! command -v flatpak &>/dev/null; then
        echo "${WARNING} flatpak not found - skipping Flatpak applications backup"
        return 1
    fi
    
    if flatpak list --app --columns=application > "${BACKUP_DIR}/flatpaks_list.bak" 2>/dev/null; then
        echo "${SUCCESS} Flatpak applications backed up"
        return 0
    else
        echo "${FAILURE} Failed to backup Flatpak applications"
        return 1
    fi
}

backup_brew() {
    if ! command -v brew &>/dev/null; then
        echo "${WARNING} brew not found - skipping Homebrew backup"
        return 1
    fi
    
    if brew list -1 > "${BACKUP_DIR}/brew_list.bak" 2>/dev/null; then
        echo "${SUCCESS} Homebrew packages backed up"
        return 0
    else
        echo "${FAILURE} Failed to backup Homebrew packages"
        return 1
    fi
}

backup_snap() {
    if ! command -v snap &>/dev/null; then
        echo "${WARNING} snap not found - skipping Snap packages backup"
        return 1
    fi
    
    if snap list | awk 'NR>1{print $1}' > "${BACKUP_DIR}/snap_list.bak" 2>/dev/null; then
        echo "${SUCCESS} Snap packages backed up"
        return 0
    else
        echo "${FAILURE} Failed to backup Snap packages"
        return 1
    fi
}

# Argument parsing
PARSED_ARGS=$(getopt -o "hi:o:gafbsA" --long help,install,output-dir:,gnome,apt,flatpak,brew,snap,all -- "$@") || exit 1
eval set -- "$PARSED_ARGS"

# Default backup flags
do_gnome=0
do_apt=0
do_flatpak=0
do_brew=0
do_snap=0
do_all=1

while true; do
    case "$1" in
        -i|--install)
            mkdir -p "$BACKUP_DIR"
            echo "${SUCCESS} Created backup directory: $BACKUP_DIR"
            exit 0
            ;;
        -o|--output-dir)
            BACKUP_DIR="$2"
            shift 2
            ;;
        -g|--gnome)    do_gnome=1; do_all=0; shift ;;
        -a|--apt)      do_apt=1; do_all=0; shift ;;
        -f|--flatpak)  do_flatpak=1; do_all=0; shift ;;
        -b|--brew)     do_brew=1; do_all=0; shift ;;
        -s|--snap)     do_snap=1; do_all=0; shift ;;
        -A|--all)      do_all=1; shift ;;
        -h|--help)     print_help; exit 0 ;;
        --)            shift; break ;;
        *)             echo "Invalid option"; exit 1 ;;
    esac
done

# Main backup process
echo "Starting backup process to: $BACKUP_DIR"
mkdir -p "$BACKUP_DIR"

if [[ $do_all -eq 1 ]]; then
    do_gnome=1
    do_apt=1
    do_flatpak=1
    do_brew=1
    do_snap=1
fi

(( do_gnome ))   && { backup_gnome   || ERRORS=$((ERRORS+1)); }
(( do_apt ))     && { backup_apt     || ERRORS=$((ERRORS+1)); }
(( do_flatpak )) && { backup_flatpak || ERRORS=$((ERRORS+1)); }
(( do_brew ))    && { backup_brew    || ERRORS=$((ERRORS+1)); }
(( do_snap ))    && { backup_snap    || ERRORS=$((ERRORS+1)); }

# Final status
if [[ $ERRORS -eq 0 ]]; then
    echo "${SUCCESS} All backups completed successfully"
    exit 0
else
    echo "${FAILURE} Backup completed with $ERRORS errors"
    exit 1
fi
