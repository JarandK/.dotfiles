#!/usr/bin/env bash
set -e

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
info() { echo -e "${GREEN}==> $1${NC}"; }
warn() { echo -e "${YELLOW}==> $1${NC}"; }
err()  { echo -e "${RED}==> $1${NC}"; }

DOTFILES="$HOME/.dotfiles"

latest_github_release() {
    curl -s "https://api.github.com/repos/$1/releases/latest" \
        | grep '"tag_name"' \
        | sed 's/.*"tag_name": "v\([^"]*\)".*/\1/'
}

# ── Submodules ────────────────────────────────────────────────────────────────
info "Initialising submodules..."
git -C "$DOTFILES" submodule update --init --recursive

# ── APT packages ──────────────────────────────────────────────────────────────
info "Updating apt..."
sudo apt-get update -qq

info "Installing packages via apt..."
sudo apt-get install -y \
    curl wget git unzip \
    fish tmux \
    zoxide \
    ripgrep fd-find bat \
    build-essential \
    xclip wl-clipboard \
    nodejs npm \
    btop \
    gh

# ── Neovim ───────────────────────────────────────────────────────────────────
# Ubuntu 26.04+ ships a recent neovim in apt; older releases need the PPA.
if ! command -v nvim &>/dev/null; then
    info "Installing Neovim..."
    if sudo apt-get install -y neovim 2>/dev/null && nvim --version | grep -q "^NVIM v0\.[1-9][0-9]"; then
        info "Neovim installed from apt ($(nvim --version | head -1))"
    else
        info "apt neovim too old, adding PPA..."
        sudo add-apt-repository -y ppa:neovim-ppa/unstable
        sudo apt-get update -qq
        sudo apt-get install -y neovim
    fi
else
    info "Neovim already installed ($(nvim --version | head -1))"
fi

# ── eza ───────────────────────────────────────────────────────────────────────
# Ubuntu 26.04+ includes eza in the official repos; older releases need the
# gierens.de third-party repo.
if ! command -v eza &>/dev/null; then
    info "Installing eza..."
    if ! sudo apt-get install -y eza 2>/dev/null; then
        sudo mkdir -p /etc/apt/keyrings
        wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc \
            | sudo gpg --dearmor -o /etc/apt/keyrings/gierens.gpg
        echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" \
            | sudo tee /etc/apt/sources.list.d/gierens.list > /dev/null
        sudo chmod 644 /etc/apt/keyrings/gierens.gpg /etc/apt/sources.list.d/gierens.list
        sudo apt-get update -qq
        sudo apt-get install -y eza
    fi
else
    info "eza already installed"
fi

# ── AnyDesk ──────────────────────────────────────────────────────────────────
if ! command -v anydesk &>/dev/null; then
    info "Installing AnyDesk..."
    sudo mkdir -p /etc/apt/keyrings
    wget -qO- https://keys.anydesk.com/repos/DEB-GPG-KEY \
        | sudo gpg --dearmor -o /etc/apt/keyrings/anydesk.gpg
    echo "deb [signed-by=/etc/apt/keyrings/anydesk.gpg] http://deb.anydesk.com/ all main" \
        | sudo tee /etc/apt/sources.list.d/anydesk-stable.list > /dev/null
    sudo apt-get update -qq
    sudo apt-get install -y anydesk
else
    info "AnyDesk already installed"
fi

# AnyDesk remote desktop doesn't work on Wayland (screen capture is blocked
# by Wayland's security model). Disable Wayland in GDM so the session uses
# Xorg, which AnyDesk fully supports. Safe on X11-only machines too.
if [ -f /etc/gdm3/custom.conf ]; then
    sudo sed -i 's/#WaylandEnable=false/WaylandEnable=false/' /etc/gdm3/custom.conf
    # If the line wasn't there at all, add it under [daemon]
    if ! grep -q "WaylandEnable=false" /etc/gdm3/custom.conf; then
        sudo sed -i '/\[daemon\]/a WaylandEnable=false' /etc/gdm3/custom.conf
    fi
    info "Wayland disabled in GDM — log out and back in for AnyDesk to work"
fi

# ── Ghostty (via Snap) ────────────────────────────────────────────────────────
if ! command -v ghostty &>/dev/null; then
    info "Installing Ghostty via Snap..."
    sudo snap install ghostty --classic
else
    info "Ghostty already installed ($(ghostty --version 2>&1 | head -1))"
fi

# ── Lazygit ───────────────────────────────────────────────────────────────────
if ! command -v lazygit &>/dev/null; then
    info "Installing Lazygit..."
    VER=$(latest_github_release jesseduffield/lazygit)
    curl -Lo /tmp/lazygit.tar.gz \
        "https://github.com/jesseduffield/lazygit/releases/download/v${VER}/lazygit_${VER}_Linux_x86_64.tar.gz"
    tar xf /tmp/lazygit.tar.gz -C /tmp lazygit
    sudo install /tmp/lazygit -D -t /usr/local/bin/
    rm /tmp/lazygit.tar.gz /tmp/lazygit
else
    info "Lazygit already installed"
fi

# ── Lazydocker ────────────────────────────────────────────────────────────────
if ! command -v lazydocker &>/dev/null; then
    info "Installing Lazydocker..."
    VER=$(latest_github_release jesseduffield/lazydocker)
    curl -Lo /tmp/lazydocker.tar.gz \
        "https://github.com/jesseduffield/lazydocker/releases/download/v${VER}/lazydocker_${VER}_Linux_x86_64.tar.gz"
    tar xf /tmp/lazydocker.tar.gz -C /tmp lazydocker
    sudo install /tmp/lazydocker -D -t /usr/local/bin/
    rm /tmp/lazydocker.tar.gz /tmp/lazydocker
else
    info "Lazydocker already installed"
fi

# ── Yazi ─────────────────────────────────────────────────────────────────────
if ! command -v yazi &>/dev/null; then
    info "Installing Yazi..."
    VER=$(latest_github_release sxyazi/yazi)
    curl -Lo /tmp/yazi.zip \
        "https://github.com/sxyazi/yazi/releases/download/v${VER}/yazi-x86_64-unknown-linux-gnu.zip"
    unzip -o /tmp/yazi.zip -d /tmp/yazi-extract
    sudo install /tmp/yazi-extract/yazi-x86_64-unknown-linux-gnu/yazi -D -t /usr/local/bin/
    sudo install /tmp/yazi-extract/yazi-x86_64-unknown-linux-gnu/ya -D -t /usr/local/bin/
    rm -rf /tmp/yazi.zip /tmp/yazi-extract
else
    info "Yazi already installed"
fi

# ── Starship ──────────────────────────────────────────────────────────────────
if ! command -v starship &>/dev/null; then
    info "Installing Starship..."
    curl -sS https://starship.rs/install.sh | sh -s -- --yes
else
    info "Starship already installed"
fi

# ── uv ───────────────────────────────────────────────────────────────────────
if ! command -v uv &>/dev/null; then
    info "Installing uv..."
    curl -LsSf https://astral.sh/uv/install.sh | sh
else
    info "uv already installed"
fi

# ── fzf ──────────────────────────────────────────────────────────────────────
if [ ! -f "$HOME/.local/bin/fzf" ] && [ ! -f "/usr/local/bin/fzf" ]; then
    info "Installing fzf..."
    "$DOTFILES/fzf/install" --bin --no-update-rc
    mkdir -p "$HOME/.local/bin"
    cp "$DOTFILES/fzf/bin/fzf" "$HOME/.local/bin/"
else
    info "fzf already installed"
fi

# ── Fonts ─────────────────────────────────────────────────────────────────────
# JetBrains Mono — main terminal font (available in apt)
sudo apt-get install -y fonts-jetbrains-mono

# Symbols Nerd Font — provides powerline arrows and icons as a fallback font.
# Ghostty (and most terminals) automatically use it for glyphs not in the main
# font, so the Starship prompt arrows render correctly without switching fonts.
if ! fc-list | grep -qi "Symbols Nerd Font"; then
    info "Installing Symbols Nerd Font..."
    VER=$(latest_github_release ryanoasis/nerd-fonts)
    wget -q "https://github.com/ryanoasis/nerd-fonts/releases/download/v${VER}/NerdFontsSymbolsOnly.zip" \
        -O /tmp/nerd-symbols.zip
    unzip -q /tmp/nerd-symbols.zip -d /tmp/nerd-symbols
    mkdir -p "$HOME/.local/share/fonts"
    cp /tmp/nerd-symbols/*.ttf "$HOME/.local/share/fonts/"
    fc-cache -f
    rm -rf /tmp/nerd-symbols.zip /tmp/nerd-symbols
else
    info "Symbols Nerd Font already installed"
fi

# ── TPM (tmux plugin manager) ─────────────────────────────────────────────────
if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
    info "Installing TPM (tmux plugin manager)..."
    git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
else
    info "TPM already installed"
fi

# ── Symlink configs ───────────────────────────────────────────────────────────
info "Linking up configs..."
cd "$DOTFILES"
python3 setup.py --linkup

# ── Ghostty as default terminal (ctrl+alt+t) ─────────────────────────────────
GHOSTTY_BIN=$(command -v ghostty || true)
if [ -n "$GHOSTTY_BIN" ]; then
    info "Setting Ghostty as default terminal emulator..."

    # Works for GNOME and as a generic fallback
    sudo update-alternatives --install /usr/bin/x-terminal-emulator x-terminal-emulator "$GHOSTTY_BIN" 50
    sudo update-alternatives --set x-terminal-emulator "$GHOSTTY_BIN"

    DE="${XDG_CURRENT_DESKTOP:-}"
    case "$DE" in
        *GNOME*|*gnome*|*ubuntu*|*Ubuntu*)
            # Clear the built-in terminal shortcut and use a custom one instead.
            # Modern GNOME ignores x-terminal-emulator for ctrl+alt+t, so we
            # wire it directly to ghostty via the custom keybindings API.
            KPATH="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom-ghostty/"
            gsettings set org.gnome.settings-daemon.plugins.media-keys terminal "[]"
            # Merge ghostty into the custom-keybindings list (preserve any existing entries)
            EXISTING=$(gsettings get org.gnome.settings-daemon.plugins.media-keys custom-keybindings)
            if ! echo "$EXISTING" | grep -q "custom-ghostty"; then
                if [ "$EXISTING" = "@as []" ] || [ "$EXISTING" = "[]" ]; then
                    NEW="['$KPATH']"
                else
                    NEW=$(echo "$EXISTING" | sed "s|]$|, '$KPATH']|")
                fi
                gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "$NEW"
            fi
            gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:"$KPATH" name    'Ghostty'
            gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:"$KPATH" command 'ghostty'
            gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:"$KPATH" binding '<Primary><Alt>t'
            ;;
        *KDE*|*kde*|*Plasma*|*plasma*)
            kwriteconfig5 --file kglobalshortcutsrc \
                --group "ghostty.desktop" \
                --key "_launch" "Ctrl+Alt+T,none,Launch Ghostty" 2>/dev/null || \
            warn "KDE detected — set ctrl+alt+t manually in System Settings → Shortcuts"
            ;;
        *XFCE*|*xfce*)
            xfconf-query -c xfce4-keyboard-shortcuts \
                -p "/commands/custom/<Primary><Alt>t" \
                -s "ghostty" -n -t string 2>/dev/null || \
            warn "XFCE detected — set ctrl+alt+t manually in Keyboard → Application Shortcuts"
            ;;
        *)
            warn "Desktop '$DE' — ctrl+alt+t may need to be set manually in your keyboard shortcuts settings"
            ;;
    esac
fi

# ── Fish as default shell ─────────────────────────────────────────────────────
FISH_PATH=$(command -v fish || true)
if [ -n "$FISH_PATH" ] && [ "$SHELL" != "$FISH_PATH" ]; then
    info "Setting fish as default shell..."
    if ! grep -qxF "$FISH_PATH" /etc/shells; then
        echo "$FISH_PATH" | sudo tee -a /etc/shells > /dev/null
    fi
    chsh -s "$FISH_PATH"
else
    info "Fish is already the default shell"
fi

# ── Done ──────────────────────────────────────────────────────────────────────
echo ""
info "Installation complete!"
echo ""
echo "  Next steps:"
echo "  1. Log out and back in (or reboot) for the shell change to take effect"
echo "  2. Open tmux and press  prefix + I  to install tmux plugins"
echo "  3. Open nvim — lazy.nvim will bootstrap and install plugins automatically"
echo "  4. Update config/gitconfig with your name and email"
echo ""
