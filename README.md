# dotfiles

> Work in progress! 

Personal Arch Linux configuration for a Hyprland-based desktop.

## Setup

```bash
git clone git@github.com:thietala/dotfiles.git ~/Documents/workspace/dotfiles
cd ~/Documents/workspace/dotfiles
./install.sh
```

Symlinks everything in this repo into `~/.config/`.

---

## What's included

| Config | Description |
|---|---|
| `hypr/` | Hyprland, hyprlock, hypridle — window manager, lock screen, idle daemon |
| `waybar/` | Status bar: network traffic, audio, battery, MPRIS |
| `kitty/` | Terminal emulator |
| `lf/` | Terminal file manager with image/video/PDF preview |
| `wlogout/` | Power menu (lock, logout, suspend, hibernate, reboot, shutdown) |
| `ly/` | Display manager config |
| `xdg-desktop-portal/` | Portal config for Hyprland |
| `mimeapps.list` | Default app associations (browser, video, audio, images) |

---

## Notes

### Screenshots

`Super + Shift + P` — region screenshot with `grim` + `slurp`, saved to `~/Pictures/screenshots/`.
