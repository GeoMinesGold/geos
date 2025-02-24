#!/usr/bin/env bash

if [[ "${1}" == "phone" ]]; then
    /home/geo/Documents/bin/camera virt
    scrcpy -e --v4l2-sink=/dev/video5 --video-source=camera --camera-id=0 --camera-fps 30 --camera-size 2576x1932 --no-audio --no-video-playback &
    ffplay /dev/video5 &
fi

if [[ "${1}" == "virt" ]]; then
    if [[ -z "${2}" ]] || [[ "${2}" == "add" ]]; then
        modprobe v4l2loopback video_nr=5 card_label='Virtual Camera' exclusive_caps=1
    elif [[ "${2}" == "remove" ]]; then
        modprobe -r v4l2loopback 
    elif [[ "${2}" == "img" ]]; then
        ffmpeg -re -stream_loop -1 -i ~/Pictures/geo.jpg -f v4l2 -vcodec rawvideo -pix_fmt yuv420p /dev/video5
    fi
fi
