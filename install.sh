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
    [[ "$name" == "ly" ]] && continue
    link "$dir" "$CONFIG/$name"
done

# ── Standalone files ───────────────────────────────────────────────────────────

shopt -s nullglob
for file in "$DOTFILES"/*.conf "$DOTFILES"/*.list "$DOTFILES"/*.ini; do
    [[ -f "$file" ]] || continue
    name="$(basename "$file")"
    link "$file" "$CONFIG/$name"
done

echo ""
echo -e "${GREEN}Done.${RESET}"

# ── Manual steps (require sudo) ────────────────────────────────────────────────
echo ""
echo -e "${YELLOW}Manual steps required:${RESET}"
echo -e "  sudo cp $DOTFILES/ly/config.ini /etc/ly/config.ini"
