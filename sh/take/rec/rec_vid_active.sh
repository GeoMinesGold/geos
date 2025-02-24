#!/usr/bin/env bash
cvlc /media/hdd/Files/Music/System/beep_1.mp3 --play-and-exit
day="$(date '+%a')"
date="$(date '+%b %e %Y')"
time="$(date '+%R:%S')"
dir="/home/geo/Videos/Records/"
full_dir="${dir}${day} ${date}/${active_window}/"
active_window="$(xprop -id "$(xprop -root -f _NET_ACTIVE_WINDOW 0x " \$0\n" _NET_ACTIVE_WINDOW | awk '{print $2}')" | awk '/WM_CLASS/{print $4}' | sed 's/\"//g')"
random="$(pwgen -snc -1 9)"
ext=".mp4"
file="${full_dir}${day} ${date} ${time} [${random}]${ext}"
geometry="$(xwininfo -id $(xprop -root 32x '\t$0' _NET_ACTIVE_WINDOW | cut -f 2) | grep 'geometry' | awk '{print $2     "+" $3 "+" $4 "+" $5}')"
active_window_id=$(xprop -root _NET_ACTIVE_WINDOW | awk '{print $NF}')
win_info="$(xdotool getactivewindow)"
x="$(echo "$win_info" | grep -i 'absolute upper-left x' | sed 's/^[^0-9]*\([0-9]\+\)$/\1/g' )"
y="$(echo "$win_info" | grep -i 'absolute upper-left y' | sed 's/^[^0-9]*\([0-9]\+\)$/\1/g' )"
width="$(echo "$win_info" | grep -Ei '^\W+width:' | sed 's/^[^0-9]*\([0-9]\+\)$/\1/g' )"
height="$(echo "$win_info" | grep -Ei '\W+height:' | sed 's/^[^0-9]*\([0-9]\+\)$/\1/g' )"

mkdir -p "$full_dir"
echo "$file"
echo "x: $x y: $y width: $width height: $height"
echo "geometry: $geometry"
echo "id: $active_window_id"

# ffmpeg -f x11grab -framerate 25  -video_size ${width}x${height} -i +${x},${y} -wid "$active_window_id" -c:v libx264 -profile:v high -level 3.0 -pix_fmt yuv420p -brand mp42 -vf scale=1280:720 "$file"

gst-launch-1.0 ximagesrc xid="$active_window_id" ! videoconvert ! x264enc pass=qual quantizer=20 tune=zerolatency ! matroskamux ! filesink location="$file"
/home/geo/Documents/sh/rec_aud &
/home/geo/Documents/sh/rec_mic &
