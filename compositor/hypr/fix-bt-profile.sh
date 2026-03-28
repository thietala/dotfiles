#!/bin/bash
# Fix Bluetooth cards stuck on profile "off" at login.
# Runs after a short delay to let WirePlumber finish enumerating devices.
# Only touches devices that are actually stuck — doesn't interfere with
# normal WirePlumber profile switching (including mic auto-switch).

sleep 6

for card in $(pactl list cards short 2>/dev/null | awk '/bluez/{print $2}'); do
    active=$(pactl list cards 2>/dev/null \
        | awk "/Name: $card/,0" \
        | grep "Active Profile:" \
        | head -1 \
        | awk '{print $NF}')

    if [ "$active" = "off" ]; then
        pactl set-card-profile "$card" a2dp-sink 2>/dev/null \
            || pactl set-card-profile "$card" headset-head-unit 2>/dev/null
    fi
done
