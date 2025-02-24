#!/usr/bin/env bash

# for info about conditions
rofi_input=$(ls /home/geo/Documents/sh/conditions/ | rofi -p prompt -dmenu -mesg 'Choose condition to view state:')
output=$(cat /home/geo/Documents/sh/conditions/${rofi_input})

[[ -z ${rofi_input} ]] && exit
notify-send "${output}" || notify-send "No summary specified"
