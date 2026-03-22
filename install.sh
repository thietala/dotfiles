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

# ── Directories ────────────────────────────────────────────────────────────────

for dir in "$DOTFILES"/*/; do
    name="$(basename "$dir")"
[[ "$name" == "sddm"           ]] && continue
    [[ "$name" == "vscodium-theme" ]] && continue
    [[ "$name" == "firefox"        ]] && continue
    [[ "$name" == "kdeglobals"     ]] && continue
    [[ "$name" == "Kvantum"        ]] && continue
    [[ "$name" == "color-schemes"  ]] && continue
    link "$dir" "$CONFIG/$name"
done

# kdeglobals is a single file, not a directory
link "$DOTFILES/kdeglobals/kdeglobals" "$CONFIG/kdeglobals"

# KDE color scheme
mkdir -p "$HOME/.local/share/color-schemes"
link "$DOTFILES/color-schemes/PurpleGlass.colors" "$HOME/.local/share/color-schemes/PurpleGlass.colors"

# Kvantum theme + config
mkdir -p "$CONFIG/Kvantum"
link "$DOTFILES/Kvantum/PurpleGlass" "$CONFIG/Kvantum/PurpleGlass"
cat > "$CONFIG/Kvantum/kvantum.kvconfig" << 'EOF'
[General]
theme=PurpleGlass
EOF
info "Kvantum theme set to PurpleGlass"

# ── Standalone files ───────────────────────────────────────────────────────────

shopt -s nullglob
for file in "$DOTFILES"/*.conf "$DOTFILES"/*.list "$DOTFILES"/*.ini; do
    [[ -f "$file" ]] || continue
    name="$(basename "$file")"
    link "$file" "$CONFIG/$name"
done

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

# ── Firefox theme ──────────────────────────────────────────────────────────────

FIREFOX_PROFILES="$HOME/.config/mozilla/firefox"
if [[ -f "$FIREFOX_PROFILES/profiles.ini" ]]; then
    # Find the default-release profile path
    FF_PROFILE=$(grep -A3 '\[Profile0\]' "$FIREFOX_PROFILES/profiles.ini" | grep '^Path=' | cut -d= -f2)
    if [[ -n "$FF_PROFILE" ]]; then
        FF_CHROME="$FIREFOX_PROFILES/$FF_PROFILE/chrome"
        mkdir -p "$FF_CHROME"
        cp "$DOTFILES/firefox/chrome/userChrome.css" "$FF_CHROME/userChrome.css"
        cp "$DOTFILES/firefox/chrome/userContent.css" "$FF_CHROME/userContent.css"
        info "Firefox theme deployed → $FF_CHROME"
        info "Enable in about:config: toolkit.legacyUserProfileCustomizations.stylesheets = true"
    fi
fi

# ── VSCodium theme ─────────────────────────────────────────────────────────────

if command -v codium &>/dev/null; then
    EXTENSIONS_DIR="$HOME/.vscode-oss/extensions"
    mkdir -p "$EXTENSIONS_DIR/purple-glass"
    cp -r "$DOTFILES/vscodium-theme/." "$EXTENSIONS_DIR/purple-glass/"
    info "VSCodium theme deployed → $EXTENSIONS_DIR/purple-glass"
    info "Activate via: File → Preferences → Color Theme → Purple Glass"
elif command -v code &>/dev/null; then
    EXTENSIONS_DIR="$HOME/.vscode/extensions"
    mkdir -p "$EXTENSIONS_DIR/purple-glass"
    cp -r "$DOTFILES/vscodium-theme/." "$EXTENSIONS_DIR/purple-glass/"
    info "VSCode theme deployed → $EXTENSIONS_DIR/purple-glass"
    info "Activate via: File → Preferences → Color Theme → Purple Glass"
fi

echo ""
echo -e "${GREEN}System config (sudo required):${RESET}"

# ── SDDM ───────────────────────────────────────────────────────────────────────
if command -v sddm &>/dev/null; then
    sudo mkdir -p /usr/share/sddm/themes/purple-glass
    sudo cp -r "$DOTFILES/sddm/theme/." /usr/share/sddm/themes/purple-glass/
    info "/usr/share/sddm/themes/purple-glass → deployed"

    sudo mkdir -p /etc/sddm.conf.d
    syslink "$DOTFILES/sddm/sddm.conf" /etc/sddm.conf.d/purple-glass.conf

    if ! systemctl is-enabled sddm &>/dev/null 2>&1; then
        sudo systemctl enable sddm
        info "sddm enabled"
    fi
else
    warning "sddm not installed — skipping (install with: sudo pacman -S sddm)"
fi

echo ""
echo -e "${GREEN}Done.${RESET}"
