#!/usr/bin/env bash

cvlc /media/hdd/Files/Music/System/beep_1.mp3 --play-and-exit &
date="$(date '+%a %b %e %Y')/"
dir="/home/geo/Videos/Records/"
mkdir -p "${dir}${date}"

read -r resolution offset < <(slop -f '%wx%h %x+%y') 
ffmpeg -f x11grab -draw_mouse 0 -video_size "${resolution}" -i "${DISPLAY}+${offset}" -vf "crop=trunc(iw/2)*2:trunc(ih/2)*2" -c:v libx264 -profile:v high -level 3.0 -pix_fmt yuv420p -brand mp42 "${dir}${date}$(xprop -id $(xprop -root -f _NET_ACTIVE_WINDOW 0x " \$0\\n" _NET_ACTIVE_WINDOW | awk "{print \$2}") | awk '/WM_CLASS/{print $4}' | sed 's/\"//g') $(date '+%a %b %e %Y %R:%S [%Nns]') [$(pwgen -snc -1 9)]".mp4
/home/geo/Documents/sh/rec_aud & 
/home/geo/Documents/sh/rec_mic &
