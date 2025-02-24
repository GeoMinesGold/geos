#!/usr/bin/env bash

# Get the active audio sink name
active_sink=$(pactl info | grep "Default Sink" | awk '{print $3}')

date="$(date '+%a %b %e %Y')/"
dir="/home/geo/Music/Records/"
mkdir -p "$dir$date"
ffmpeg -f pulse -i "$monitor" "$dir$date$(xprop -id $(xprop -root -f _NET_ACTIVE_WINDOW 0x " \$0\n" _NET_ACTIVE_WINDOW | awk '{print $2}') | awk '/WM_CLASS/{print $4}' | sed 's/\"//g') $(date '+%a %b %e %Y %R:%S [%Nns]') [$(pwgen -snc -1 9)]".mp3
