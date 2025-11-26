# computer-setup

Automated setup for new Linux installations, with a focus on Fedora 43. This repository helps you track and automate software installation to easily reproduce your preferred setup on new machines.

## Quick Start

### Detect Current System Packages

On your current system, automatically detect and catalog installed software:

```bash
./detect-packages.sh
```

This will generate `packages.yml` with all your currently installed DNF packages, Flatpaks, and Snaps. Review and edit the file to remove any packages you don't want to track.

### Fresh Installation

1. Clone this repository:
   ```bash
   git clone <your-repo-url>
   cd computer-setup
   ```

2. Edit `packages.yml` to add your desired software packages (or use `detect-packages.sh` as above)

3. Run the installation script:
   ```bash
   ./install.sh
   ```

## File Structure

- `packages.yml` - Software manifest tracking all packages to install
- `detect-packages.sh` - Scans your system and generates packages.yml
- `install.sh` - Automated installation script
- `CLAUDE.md` - Guide for Claude Code when working in this repository

## Tracking New Software

When you install new software manually, add it to `packages.yml` under the appropriate section:

- `dnf_packages` - System packages installed via dnf/apt/pacman
- `flatpak_packages` - Flatpak applications (use full app IDs)
- `snap_packages` - Snap packages
- `enable_rpmfusion` - Set to `true` to enable RPM Fusion repos (Fedora)

### Example

```yaml
dnf_packages:
  - git
  - vim
  - htop

flatpak_packages:
  - org.mozilla.firefox
  - org.gnome.Builder
```

## Portability

The installation script detects your Linux distribution and uses the appropriate package manager:
- Fedora/RHEL: `dnf`
- Debian/Ubuntu: `apt`
- Arch Linux: `pacman`

Package names may differ between distributions - you may need to adjust `packages.yml` when switching distros.

## Manual Installation Steps

For software or configurations that can't be automated, document them here:

- [ ] Configure GNOME settings
- [ ] Import browser bookmarks
- [ ] Set up SSH keys
- [ ] Configure git user info

## Future Enhancements

- [ ] Add dotfiles management
- [ ] System configuration automation (shell settings, desktop environment)
- [ ] Post-install configuration scripts
- [ ] Backup and restore user data
