#!/usr/bin/env bash

readonly sh_dir="/home/geo/Documents/sh/"
dir="/home/geo/Music/Downloads/"
readonly initial_dir="/home/geo/Music/Downloads/"
ext=".mp3"
readonly manager_state="disable"

clipboard="$1"
source ${sh_dir}common/sounds
source ${sh_dir}common/header

lang="$2" 
[[ -z $lang ]] && lang=en
link="https://translate.google.com/translate_tts?ie=UTF-8&q=${clipboard}&tl=${lang}&total=1&idx=0&textlen=15&tk=350535.255567&client=webapp&prev=input"

yt-dlp --extract-audio --audio-format mp3 -o "${file}" "$link"
