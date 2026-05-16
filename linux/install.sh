#!/bin/bash
# Automated Computer Setup Script for Fedora 43
# This script installs and configures software based on packages.yml

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running on supported system
check_system() {
    if [ -f /etc/fedora-release ]; then
        log_info "Detected Fedora Linux"
        PKG_MANAGER="dnf"
    elif [ -f /etc/debian_version ]; then
        log_info "Detected Debian/Ubuntu Linux"
        PKG_MANAGER="apt"
    elif [ -f /etc/arch-release ]; then
        log_info "Detected Arch Linux"
        PKG_MANAGER="pacman"
    else
        log_warn "Unknown distribution - defaulting to dnf"
        PKG_MANAGER="dnf"
    fi
}

# Update system
update_system() {
    log_info "Updating system packages..."
    case $PKG_MANAGER in
        dnf)
            sudo dnf update -y
            ;;
        apt)
            sudo apt update && sudo apt upgrade -y
            ;;
        pacman)
            sudo pacman -Syu --noconfirm
            ;;
    esac
}

# Install packages from YAML file
install_dnf_packages() {
    log_info "Installing DNF packages..."

    # Extract package list from YAML (simple grep-based parsing)
    packages=$(awk '/^dnf_packages:/,/^[a-z_]*:/ {if ($0 ~ /^  - /) print $2}' packages.yml)

    if [ -z "$packages" ]; then
        log_warn "No DNF packages found in packages.yml"
        return
    fi

    for package in $packages; do
        log_info "Installing $package..."
        case $PKG_MANAGER in
            dnf)
                sudo dnf install -y "$package"
                ;;
            apt)
                sudo apt install -y "$package"
                ;;
            pacman)
                sudo pacman -S --noconfirm "$package"
                ;;
        esac
    done
}

# Install Flatpak packages
install_flatpak_packages() {
    # Check if flatpak is installed
    if ! command -v flatpak &> /dev/null; then
        log_info "Flatpak not found. Installing..."
        sudo dnf install -y flatpak
        flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    fi

    log_info "Installing Flatpak packages..."
    packages=$(awk '/^flatpak_packages:/,/^[a-z_]*:/ {if ($0 ~ /^  - /) print $2}' packages.yml)

    if [ -z "$packages" ]; then
        log_warn "No Flatpak packages found in packages.yml"
        return
    fi

    for package in $packages; do
        log_info "Installing $package..."
        flatpak install -y flathub "$package"
    done
}

# Enable RPM Fusion
enable_rpmfusion() {
    local enabled=$(grep "enable_rpmfusion: true" packages.yml)
    if [ -n "$enabled" ]; then
        log_info "Enabling RPM Fusion repositories..."
        sudo dnf install -y \
            https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
            https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
    fi
}

# Main installation flow
main() {
    log_info "Starting automated computer setup..."

    # Check for packages.yml
    if [ ! -f "packages.yml" ]; then
        log_error "packages.yml not found. Please create it first."
        exit 1
    fi

    check_system

    # Ask for confirmation
    read -p "This will install packages and modify your system. Continue? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Installation cancelled."
        exit 0
    fi

    update_system
    enable_rpmfusion
    install_dnf_packages
    install_flatpak_packages

    log_info "Installation complete!"
    log_info "You may need to reboot for all changes to take effect."
}

main "$@"
