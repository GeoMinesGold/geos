#!/usr/bin/env bash

# Define the priority order of microphones
priority_mics=("alsa_input.usb-GeneralPlus_USB_Audio_Device-00.mono-fallback" "alsa_input.usb-Logitech_G935_Gaming_Headset-00.mono-fallback" "alsa_input.usb-C-Media_Electronics_Inc._USB_PnP_Sound_Device-00.mono-fallback" "alsa_input.usb-C-Media_Electronics_Inc._USB_PnP_Sound_Device-00.mono-fallback.2")

# Specify the microphone to control
chosen_mic=""
for mic in "${priority_mics[@]}"; do
    if pactl list sources | grep -q "$mic"; then
        chosen_mic="$mic"
        break
    fi
done

if [ -z "$chosen_mic" ]; then
    echo "None of the specified microphones are found."
else
	date="$(date '+%a %b %e %Y')/"
	dir="/home/geo/Music/Microphone/"
	mkdir -p "$dir$date"
	ffmpeg -f pulse -i "$chosen_mic" "$dir$date$(xprop -id $(xprop -root -f _NET_ACTIVE_WINDOW 0x " \$0\\n" _NET_ACTIVE_WINDOW | awk "{print \$2}") | awk '/WM_CLASS/{print $4}' | sed 's/\"//g') $(date '+%a %b %e %Y %R:%S [%Nns]') [$(pwgen -snc -1 9)]".mp3
fi
