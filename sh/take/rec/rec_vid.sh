#!/usr/bin/env bash

readonly sh_dir="/home/geo/Documents/sh/"
dir="/home/geo/Videos/Records/"
readonly initial_dir="${dir}"
ext=".mp4"
readonly manager_state="dir"


source "${sh_dir}common/header"
source "${sh_dir}common/find_active_screen"

cvlc /media/hdd/Files/Music/System/beep_1.mp3 --play-and-exit

ffmpeg -f x11grab -s "${resolution_x}x${resolution_y}" -i "${DISPLAY}+${offset_x},${offset_y}" -c:v libx264 -profile:v high -level 3.0 -pix_fmt yuv420p -brand mp42 "${file}"
