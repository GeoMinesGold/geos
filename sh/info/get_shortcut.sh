#!/usr/bin/env bash

## for info about keybinds
rofi_input="$(rofi -dmenu -p "Enter key")"
output="$(cat /home/geo/Documents/flexipatch/config.h | grep "${rofi_input}")"

[[ -z ${rofi_input} ]] && exit
notify-send -t 0 "${output}" || notify-send "No summary specified"
