#!/usr/bin/env bash
# Symlinks all dotfiles into ~/.config/
# Re-running is safe — existing symlinks are updated, files are never overwritten.

set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG="$HOME/.config"

# ── Helpers ────────────────────────────────────────────────────────────────────

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
RESET='\033[0m'

info()    { echo -e "${GREEN}  [link]${RESET} $1"; }
skip()    { echo -e "${YELLOW}  [skip]${RESET} $1"; }
warning() { echo -e "${RED}   [!]  ${RESET} $1"; }

link() {
    local src="$1"
    local dst="$2"

    # Already the correct symlink — nothing to do
    if [[ -L "$dst" && "$(readlink "$dst")" == "$src" ]]; then
        skip "$dst → already linked"
        return
    fi

    # Destination exists and is a real file/dir — back it up
    if [[ -e "$dst" && ! -L "$dst" ]]; then
        local backup="${dst}.bak"
        warning "$dst exists — backing up to $backup"
        mv "$dst" "$backup"
    fi

    # Remove a stale symlink pointing elsewhere
    [[ -L "$dst" ]] && rm "$dst"

    mkdir -p "$(dirname "$dst")"
    ln -s "$src" "$dst"
    info "$dst → $src"
}

# ── Compositor ─────────────────────────────────────────────────────────────────

link "$DOTFILES/compositor/hypr"        "$CONFIG/hypr"
link "$DOTFILES/compositor/quickshell"  "$CONFIG/quickshell"
link "$DOTFILES/compositor/rofi"        "$CONFIG/rofi"
link "$DOTFILES/compositor/wlogout"     "$CONFIG/wlogout"

# ── Apps ───────────────────────────────────────────────────────────────────────

link "$DOTFILES/apps/btop"    "$CONFIG/btop"
link "$DOTFILES/apps/kitty"   "$CONFIG/kitty"
link "$DOTFILES/apps/lf"      "$CONFIG/lf"
link "$DOTFILES/apps/swaync"  "$CONFIG/swaync"

# ── Theme ──────────────────────────────────────────────────────────────────────

link "$DOTFILES/theme/gtk-3.0" "$CONFIG/gtk-3.0"
link "$DOTFILES/theme/gtk-4.0" "$CONFIG/gtk-4.0"

# kdeglobals is a single file, not a directory
link "$DOTFILES/theme/kdeglobals/kdeglobals" "$CONFIG/kdeglobals"

# KDE color scheme
mkdir -p "$HOME/.local/share/color-schemes"
link "$DOTFILES/theme/color-schemes/PurpleGlass.colors" "$HOME/.local/share/color-schemes/PurpleGlass.colors"

# Kvantum theme + config
mkdir -p "$CONFIG/Kvantum"
link "$DOTFILES/theme/Kvantum/PurpleGlass" "$CONFIG/Kvantum/PurpleGlass"
cat > "$CONFIG/Kvantum/kvantum.kvconfig" << 'EOF'
[General]
theme=PurpleGlass
EOF
info "Kvantum theme set to PurpleGlass"

# qt6ct — symlink subdirs, generate qt6ct.conf with real HOME path
[[ -L "$CONFIG/qt6ct" ]] && rm "$CONFIG/qt6ct"
mkdir -p "$CONFIG/qt6ct"
link "$DOTFILES/theme/qt6ct/colors" "$CONFIG/qt6ct/colors"
link "$DOTFILES/theme/qt6ct/qss"    "$CONFIG/qt6ct/qss"
qt6ct_conf="$(sed "s|__HOME__|$HOME|g" "$DOTFILES/theme/qt6ct/qt6ct.conf")"
echo "$qt6ct_conf" > "$CONFIG/qt6ct/qt6ct.conf"
info "$CONFIG/qt6ct/qt6ct.conf → generated with HOME=$HOME"

# ── System ─────────────────────────────────────────────────────────────────────

link "$DOTFILES/system/xdg-desktop-portal" "$CONFIG/xdg-desktop-portal"
link "$DOTFILES/system/mimeapps.list"      "$CONFIG/mimeapps.list"
link "$DOTFILES/system/starship.toml"      "$CONFIG/starship.toml"

# Starship — add init to .bashrc if not already there
if command -v starship &>/dev/null; then
    if ! grep -q "starship init bash" "$HOME/.bashrc" 2>/dev/null; then
        echo 'eval "$(starship init bash)"' >> "$HOME/.bashrc"
        info "Starship init added to ~/.bashrc"
    else
        skip "Starship already in ~/.bashrc"
    fi
fi

# ── Firefox theme ──────────────────────────────────────────────────────────────

FIREFOX_PROFILES="$HOME/.config/mozilla/firefox"
if [[ -f "$FIREFOX_PROFILES/profiles.ini" ]]; then
    FF_PROFILE=$(grep -A3 '\[Profile0\]' "$FIREFOX_PROFILES/profiles.ini" | grep '^Path=' | cut -d= -f2)
    if [[ -n "$FF_PROFILE" ]]; then
        FF_CHROME="$FIREFOX_PROFILES/$FF_PROFILE/chrome"
        mkdir -p "$FF_CHROME"
        cp "$DOTFILES/apps/firefox/chrome/userChrome.css" "$FF_CHROME/userChrome.css"
        cp "$DOTFILES/apps/firefox/chrome/userContent.css" "$FF_CHROME/userContent.css"
        info "Firefox theme deployed → $FF_CHROME"
        info "Enable in about:config: toolkit.legacyUserProfileCustomizations.stylesheets = true"
    fi
fi

# ── VSCodium theme ─────────────────────────────────────────────────────────────

if command -v codium &>/dev/null; then
    EXTENSIONS_DIR="$HOME/.vscode-oss/extensions"
    mkdir -p "$EXTENSIONS_DIR/purple-glass"
    cp -r "$DOTFILES/theme/vscodium-theme/." "$EXTENSIONS_DIR/purple-glass/"
    info "VSCodium theme deployed → $EXTENSIONS_DIR/purple-glass"
    info "Activate via: File → Preferences → Color Theme → Purple Glass"
elif command -v code &>/dev/null; then
    EXTENSIONS_DIR="$HOME/.vscode/extensions"
    mkdir -p "$EXTENSIONS_DIR/purple-glass"
    cp -r "$DOTFILES/theme/vscodium-theme/." "$EXTENSIONS_DIR/purple-glass/"
    info "VSCode theme deployed → $EXTENSIONS_DIR/purple-glass"
    info "Activate via: File → Preferences → Color Theme → Purple Glass"
fi

# ── System files (require sudo) ────────────────────────────────────────────────

syslink() {
    local src="$1"
    local dst="$2"
    if [[ -L "$dst" && "$(readlink "$dst")" == "$src" ]]; then
        skip "$dst → already linked"
        return
    fi
    if [[ -e "$dst" && ! -L "$dst" ]]; then
        warning "$dst exists — backing up to ${dst}.bak"
        sudo mv "$dst" "${dst}.bak"
    fi
    [[ -L "$dst" ]] && sudo rm "$dst"
    sudo mkdir -p "$(dirname "$dst")"
    sudo ln -s "$src" "$dst"
    info "$dst → $src"
}

echo ""
echo -e "${GREEN}System config (sudo required):${RESET}"

if command -v sddm &>/dev/null; then
    sudo mkdir -p /usr/share/sddm/themes/purple-glass
    sudo cp -r "$DOTFILES/system/sddm/theme/." /usr/share/sddm/themes/purple-glass/
    sudo sed -i "s|__HOME__|$HOME|g" /usr/share/sddm/themes/purple-glass/theme.conf
    info "/usr/share/sddm/themes/purple-glass → deployed"

    sudo mkdir -p /etc/sddm.conf.d
    syslink "$DOTFILES/system/sddm/sddm.conf" /etc/sddm.conf.d/purple-glass.conf

    if ! systemctl is-enabled sddm &>/dev/null 2>&1; then
        sudo systemctl enable sddm
        info "sddm enabled"
    fi
else
    warning "sddm not installed — skipping (install with: sudo pacman -S sddm)"
fi

echo ""
echo -e "${GREEN}Done.${RESET}"
