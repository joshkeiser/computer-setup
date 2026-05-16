# computer-setup

Automated setup scripts for new machines. Each platform lives in its own folder.

```
mac/     — macOS setup (Homebrew, Oh My Zsh, CLI tools, apps)
linux/   — Fedora/Debian/Arch setup (dnf/apt/pacman, Flatpak, Snap)
```

---

## Mac

### First-time setup

```bash
cd mac
./install.sh
```

This will:
1. Install all packages from `Brewfile` via `brew bundle`
2. Install Oh My Zsh
3. Configure Zsh plugins (autosuggestions, syntax highlighting, fzf, zoxide, powerlevel10k)
4. Copy `aerospace.toml` to `~/.aerospace.toml`

After install, open a new terminal and run `p10k configure` to set up your prompt style.

> **Note:** Set your terminal font to `MesloLGS Nerd Font` for icons to render correctly.
> AeroSpace requires Accessibility permission — grant it in System Settings → Privacy & Security.

### Adding packages

Edit `mac/Brewfile` and add a line under the appropriate section:

```ruby
brew "tool-name"          # CLI tool
cask "app-name"           # GUI app
```

Then run `brew bundle --file=mac/Brewfile` to apply.

### Files

| File | Purpose |
|---|---|
| `mac/install.sh` | Main installer |
| `mac/Brewfile` | Declarative package manifest |
| `mac/aerospace.toml` | AeroSpace tiling WM config (copied to `~/.aerospace.toml`) |

---

## Linux

Targets Fedora 43, with best-effort support for Debian/Ubuntu and Arch.

### Detect currently installed packages

Run this on an existing system to capture what's installed:

```bash
linux/detect-packages.sh
```

Generates `linux/packages.yml`. Review and trim anything you don't want to track.

### Fresh installation

```bash
linux/install.sh
```

### Adding packages

Edit `linux/packages.yml` under the appropriate section:

```yaml
dnf_packages:
  - htop

flatpak_packages:
  - org.mozilla.firefox
```

### Files

| File | Purpose |
|---|---|
| `linux/install.sh` | Main installer |
| `linux/packages.yml` | Declarative package manifest |
| `linux/detect-packages.sh` | Scans system and regenerates packages.yml |
