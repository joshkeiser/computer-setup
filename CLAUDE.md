# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Purpose

This repository automates Linux computer setup, primarily targeting Fedora 43. It provides a declarative way to track installed software and automate fresh installations.

## Architecture

### Core Components

1. **packages.yml** - Declarative software manifest
   - Organized by installation method (dnf, flatpak, snap)
   - Simple YAML format for easy editing
   - Supports repository configuration

2. **detect-packages.sh** - Package detection script
   - Scans the current system for installed packages
   - Generates packages.yml automatically
   - Detects DNF, Flatpak, and Snap packages
   - Filters out core system packages

3. **install.sh** - Installation automation script
   - Multi-distro support (Fedora/Debian/Arch detection)
   - Simple YAML parsing using awk
   - Idempotent operations with error handling
   - Color-coded logging output

### Design Principles

- **Declarative over imperative**: Track what should be installed, not how
- **Portability**: Support multiple package managers for cross-distro compatibility
- **Safety**: Requires user confirmation before system modifications
- **Simplicity**: Minimal dependencies (bash, awk, package manager)

## Common Commands

### Detecting currently installed packages
```bash
./detect-packages.sh
```

### Running the installer
```bash
./install.sh
```

### Reviewing what will be installed
```bash
cat packages.yml
```

### Making scripts executable (if needed)
```bash
chmod +x detect-packages.sh install.sh
```

## Workflow

### Initial Setup
1. Run `./detect-packages.sh` to capture current system state
2. Review and edit `packages.yml` to remove unwanted packages
3. Commit the manifest to git

### Adding New Software
1. Install it manually first
2. Run `./detect-packages.sh` to regenerate packages.yml, or
3. Manually add the package name to the appropriate section in `packages.yml`
4. Test the installation on a fresh VM/container if possible

## Extension Points

- Additional package managers can be added to `install_*_packages()` functions
- Post-install hooks can be implemented by parsing the `post_install` section
- Dotfiles management could be added as a separate script
