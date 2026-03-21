# dotfiles

Personal Arch Linux configuration for a Hyprland-based desktop, themed with **Purple Glass** — a deep desaturated royal purple liquid glass aesthetic with heavy blur, semi-transparent panels, and specular edge highlights.

## Setup

```bash
git clone git@github.com:thietala/dotfiles.git ~/Documents/workspace/dotfiles
cd ~/Documents/workspace/dotfiles
./install.sh
```

Symlinks configs into `~/.config/`, deploys the SDDM theme to `/usr/share/sddm/themes/purple-glass/`, and installs the VSCodium theme into the extensions directory.

---

## Requirements

### Core

| Package | Purpose |
|---|---|
| `hyprland` | Wayland compositor |
| `hyprlock` | Lock screen |
| `hypridle` | Idle daemon |
| `hyprpaper` | Wallpaper daemon |
| `quickshell` | Top bar (workspaces, clock, MPRIS, system tray) |
| `kitty` | Terminal emulator |
| `rofi-wayland` | App launcher (compact + sidebar modes) |
| `wlogout` | Power menu |
| `swaync` | Notification center |
| `sddm` | Display manager |

### Fonts

| Package | Purpose |
|---|---|
| `ttf-jetbrains-mono-nerd` | Primary font — used everywhere |

### System tray / background services

| Package | Purpose |
|---|---|
| `udiskie` | Auto-mount removable drives |
| `gnome-keyring` | Secret storage (for apps that need it) |
| `hyprpolkitagent` | Polkit agent for privilege escalation |
| `xdg-desktop-portal-hyprland` | Portal backend for screen sharing etc. |

### Theming

| Package | Purpose |
|---|---|
| `adw-gtk-theme` | GTK3 base theme (`adw-gtk3-dark`) |
| `kvantum` | Qt style engine for KDE/Qt apps |
| `qt6ct` | Qt6 color/font configuration |
| `papirus-icon-theme` | Icon theme |

### Optional

| Package | Purpose |
|---|---|
| `lf` | Terminal file manager |
| `grim` + `slurp` | Screenshots |
| `playerctl` | MPRIS media control |
| `blueman` | Bluetooth manager |
| `nm-connection-editor` | Network configuration |
| `pavucontrol` | Audio control |

---

## What's included

| Config | Description |
|---|---|
| `hypr/` | Hyprland, hyprlock, hypridle, hyprpaper |
| `quickshell/` | Top bar — workspace dots, clock, MPRIS player, network traffic, audio, bluetooth, tray, power |
| `kitty/` | Terminal — purple glass theme, 50% opacity |
| `rofi/` | App launchers — compact center modal (`Super+R`) and sidebar grid (`Super+Shift+R`) |
| `swaync/` | Notification center — purple glass CSS theme |
| `sddm/` | Login screen — custom QML theme with clock, animations, purple glass card |
| `wlogout/` | Power menu — lock, logout, suspend, hibernate, reboot, shutdown |
| `gtk-3.0/` | GTK3 theme overrides — purple glass colors on top of adw-gtk3-dark |
| `gtk-4.0/` | GTK4 theme overrides |
| `kdeglobals/` | KDE/Qt app color scheme (Gwenview, Okular, etc.) |
| `qt6ct/` | Qt6 font, style and color palette |
| `Kvantum/` | Kvantum purple glass theme for Qt/KDE apps |
| `firefox/` | userChrome.css — purple glass browser UI |
| `vscodium-theme/` | VSCodium/VSCode extension — Purple Glass color theme |
| `lf/` | Terminal file manager with image/video/PDF preview |
| `xdg-desktop-portal/` | Portal config for Hyprland |
| `mimeapps.list` | Default app associations |

---

## Purple Glass theme

A consistent visual language applied across every layer of the stack:

| Token | Value | Used for |
|---|---|---|
| Background | `#1a0e38` | Base dark purple |
| Surface | `#231248` | Panels, cards |
| Primary | `#9b7bc4` | Accents, active elements |
| Secondary | `#8a6aae` | Borders, inactive |
| Text | `#e8e0f0` | Primary text |
| Muted | `#8878a8` | Secondary text, icons |

Blur is applied to the bar and rofi via Hyprland `layerrule`. Window transparency is set per-app via `windowrule` in `hypr/conf/windowrules.conf`.

---

## Keybinds (notable)

| Keybind | Action |
|---|---|
| `Super + R` | App launcher (compact) |
| `Super + Shift + R` | App launcher (sidebar grid) |
| `Super + E` | File manager (`lf` in kitty) |
| `Super + Shift + P` | Region screenshot → `~/Pictures/screenshots/` |
| `Super + L` | Lock screen |

---

## Notes

### After install

1. Enable `toolkit.legacyUserProfileCustomizations.stylesheets` in Firefox `about:config` for userChrome.css to apply
2. In VSCodium: **File → Preferences → Color Theme → Purple Glass**
