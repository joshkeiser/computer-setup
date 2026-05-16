# CLAUDE.md

This file provides guidance to Claude Code when working with code in this repository.

## Repository Purpose

Cross-platform machine setup automation. Each platform has its own folder with a declarative package manifest and an installer script.

## Structure

```
mac/
  install.sh        — installs Homebrew packages, Oh My Zsh, Zsh plugins, copies configs
  Brewfile          — declarative manifest (brew, cask)
  aerospace.toml    — AeroSpace tiling WM config (installed to ~/.aerospace.toml)

linux/
  install.sh        — installs dnf/apt/pacman packages, Flatpak, Snap
  packages.yml      — declarative manifest
  detect-packages.sh — scans a live system and regenerates packages.yml
```

## Mac

### Design

- **Homebrew** is the single package manager for everything (CLI tools and GUI apps via casks)
- **Brewfile** is the source of truth — `brew bundle --file=mac/Brewfile` is idempotent
- **Oh My Zsh** plugins (autosuggestions, syntax highlighting, fzf, zoxide, powerlevel10k) are installed via Homebrew and sourced in `~/.zshrc` by the installer
- **AeroSpace** (i3-style tiling WM) uses `mac/aerospace.toml` as a versioned starter config

### Common commands

```bash
# Run full setup
./mac/install.sh

# Install/update packages only
brew bundle --file=mac/Brewfile

# Reconfigure Zsh prompt
p10k configure
```

## Linux

### Design

- **packages.yml** is the declarative manifest organized by package manager (dnf, flatpak, snap)
- **install.sh** does simple awk-based YAML parsing — no external dependencies
- **detect-packages.sh** auto-generates packages.yml from a live system; it filters out core OS packages to focus on user-installed software
- Multi-distro: Fedora (dnf), Debian/Ubuntu (apt), Arch (pacman) — package names may differ

### Common commands

```bash
# Capture current system state
./linux/detect-packages.sh

# Run installer on a fresh system
./linux/install.sh

# Review manifest
cat linux/packages.yml
```

## Design Principles

- **Declarative over imperative**: track what should be installed, not how
- **Idempotent**: safe to run installers multiple times
- **Minimal dependencies**: bash + awk + platform package manager only
- **No overwrites**: installers skip config files that already exist (show a diff hint instead)
