#!/bin/bash
# Mac Setup Script
# Installs Oh My Zsh, plugins, and all tools from Brewfile

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info()  { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ── Homebrew ──────────────────────────────────────────────────────────────────

install_homebrew() {
    if command -v brew &>/dev/null; then
        log_info "Homebrew already installed"
        return
    fi
    log_info "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    # Add to PATH for Apple Silicon
    if [ -f /opt/homebrew/bin/brew ]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
}

run_brewfile() {
    log_info "Installing packages from Brewfile..."
    brew bundle --file="$SCRIPT_DIR/Brewfile"
}

# ── Oh My Zsh ─────────────────────────────────────────────────────────────────

install_oh_my_zsh() {
    if [ -d "$HOME/.oh-my-zsh" ]; then
        log_info "Oh My Zsh already installed"
        return
    fi
    log_info "Installing Oh My Zsh..."
    # RUNZSH=no prevents it from switching shells mid-script
    RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
}

configure_zsh_plugins() {
    local zshrc="$HOME/.zshrc"

    # Powerlevel10k — instant prompt block must be near the top of .zshrc
    local p10k_theme
    p10k_theme="$(brew --prefix)/share/powerlevel10k/powerlevel10k.zsh-theme"
    if ! grep -q "powerlevel10k" "$zshrc" 2>/dev/null; then
        # Prepend the instant prompt block before everything else
        local tmp
        tmp=$(mktemp)
        cat > "$tmp" <<'EOF'
# Powerlevel10k instant prompt — keep near top of .zshrc
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

EOF
        cat "$zshrc" >> "$tmp"
        mv "$tmp" "$zshrc"
        # Append theme source and p10k config loader at the end
        echo "" >> "$zshrc"
        echo "# Powerlevel10k theme" >> "$zshrc"
        echo "source $p10k_theme" >> "$zshrc"
        echo "[[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh  # run 'p10k configure' to generate" >> "$zshrc"
        log_info "Added powerlevel10k to .zshrc"
    fi

    # Autosuggestions
    local autosuggest_src
    autosuggest_src="$(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
    if ! grep -q "zsh-autosuggestions" "$zshrc" 2>/dev/null; then
        echo "" >> "$zshrc"
        echo "# zsh-autosuggestions (installed via brew)" >> "$zshrc"
        echo "source $autosuggest_src" >> "$zshrc"
        log_info "Added zsh-autosuggestions to .zshrc"
    fi

    # Syntax highlighting (must come after autosuggestions)
    local syntax_src
    syntax_src="$(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
    if ! grep -q "zsh-syntax-highlighting" "$zshrc" 2>/dev/null; then
        echo "" >> "$zshrc"
        echo "# zsh-syntax-highlighting (installed via brew)" >> "$zshrc"
        echo "source $syntax_src" >> "$zshrc"
        log_info "Added zsh-syntax-highlighting to .zshrc"
    fi

    # fzf key bindings and completions (ctrl-r, ctrl-t, alt-c)
    if ! grep -q "fzf" "$zshrc" 2>/dev/null; then
        echo "" >> "$zshrc"
        echo "# fzf key bindings and fuzzy completion" >> "$zshrc"
        echo 'source <(fzf --zsh)' >> "$zshrc"
        log_info "Added fzf to .zshrc"
    fi

    # zoxide (replaces cd — use `z` to jump, `zi` for interactive)
    if ! grep -q "zoxide" "$zshrc" 2>/dev/null; then
        echo "" >> "$zshrc"
        echo "# zoxide — smarter cd" >> "$zshrc"
        echo 'eval "$(zoxide init zsh)"' >> "$zshrc"
        log_info "Added zoxide to .zshrc"
    fi

    # eza aliases (replaces ls)
    if ! grep -q "alias ls=.eza" "$zshrc" 2>/dev/null; then
        echo "" >> "$zshrc"
        echo "# eza aliases" >> "$zshrc"
        echo "alias ls='eza --icons'" >> "$zshrc"
        echo "alias ll='eza -lah --icons --git'" >> "$zshrc"
        echo "alias lt='eza --tree --icons'" >> "$zshrc"
        log_info "Added eza aliases to .zshrc"
    fi

    # fnm (Node version manager)
    if ! grep -q "fnm" "$zshrc" 2>/dev/null; then
        echo "" >> "$zshrc"
        echo "# fnm — Node.js version manager" >> "$zshrc"
        echo 'eval "$(fnm env --use-on-cd --shell zsh)"' >> "$zshrc"
        log_info "Added fnm to .zshrc"
    fi
}

# ── AeroSpace ────────────────────────────────────────────────────────────────

install_aerospace_config() {
    local src="$SCRIPT_DIR/aerospace.toml"
    local dest="$HOME/.aerospace.toml"
    if [ -f "$dest" ]; then
        log_warn "~/.aerospace.toml already exists — skipping (diff: diff $dest $src)"
        return
    fi
    cp "$src" "$dest"
    log_info "Copied aerospace.toml to ~/.aerospace.toml"
}

# ── Main ──────────────────────────────────────────────────────────────────────

main() {
    log_info "Starting Mac setup..."

    read -p "This will install software and modify your .zshrc. Continue? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Cancelled."
        exit 0
    fi

    install_homebrew
    run_brewfile
    install_oh_my_zsh
    configure_zsh_plugins
    install_aerospace_config

    log_info "Done! Open a new terminal (or run: source ~/.zshrc) to apply changes."
    log_warn "For icons to render correctly, set your terminal font to 'MesloLGS Nerd Font'."
    log_warn "AeroSpace: grant Accessibility permission in System Settings → Privacy & Security."
}

main "$@"
