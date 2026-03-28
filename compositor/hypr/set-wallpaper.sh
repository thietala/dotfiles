#!/bin/bash
# set-wallpaper.sh <path> [monitor]
IMG="$1"

# Get primary monitor name and resolution
read MONITOR MW MH < <(hyprctl monitors -j 2>/dev/null \
    | python3 -c "import json,sys; m=json.load(sys.stdin)[0]; print(m['name'], m['width'], m['height'])")
MONITOR=${MONITOR:-DP-1}; MW=${MW:-5120}; MH=${MH:-1440}

# Get image dimensions
DIMS=$(ffprobe -v quiet -select_streams v:0 \
    -show_entries stream=width,height -of csv=s=x:p=0 "$IMG" 2>/dev/null)
IW=${DIMS%x*}; IH=${DIMS#*x}

# If image aspect ratio >= monitor aspect ratio → crop, else → fit
if [ -n "$IW" ] && [ -n "$IH" ] && [ "$IW" -gt 0 ] && [ "$IH" -gt 0 ]; then
    [ $((IW * MH)) -ge $((IH * MW)) ] && RESIZE=crop || RESIZE=fit
else
    RESIZE=fit
fi

TRANSITIONS=(simple fade left right top bottom wipe wave grow center outer)
TRANSITION=${TRANSITIONS[$RANDOM % ${#TRANSITIONS[@]}]}

awww img \
    --resize "$RESIZE" \
    --fill-color 1a0e38ff \
    --transition-type "$TRANSITION" \
    --transition-duration 1 \
    "$IMG"
