#!/usr/bin/env bash
# Requires main_utils, filename_utils and input_utils

source /usr/lib/geos/core.sh
imp file input notifs

# Get input
if chk_val "${1}"; then 
    link="${1}"
else
    # Get input buffers
    get_buffers 'selection' 'clipboard'

    # Get priority buffer
    priority="$(get_buffer selection clipboard)"

    if ! chk_var 'priority'; then
        ntf 'Download failed: No buffer selected'
        exit 1
    fi
    link="${buffers["${priority}"]}"

    # Check if link exists
    if ! chk_var 'link'; then
        ntf 'Download failed: No link provided'
        exit 1
    fi
fi

# Generate directory
dir="$(gen_dir "${HOME}/Videos/Downloads")"
mkdir -p "${dir}"

# Download video of select url
down_vid() {
    local links=("${@}")
    local link
    for link in "${links[@]}"; do
        chk_var 'link' || return 1
        video_title="$(yt-dlp --get-title --no-playlist "${link}")"
        chk_var 'video_title' || return 1
        ntf 'low' 'Video is being downloaded' "Title: ${video_title}"

    #    yt-dlp -f 'bestvideo[height<=720][width<=1280]+bestaudio/best[height<=720][width<=1280]' --merge-output-format 'mp4' --no-playlist --embed-thumbnail --embed-chapters --embed-metadata --embed-info-json -o "${dir}/%(title)s.%(ext)s" "${link}" 

        yt-dlp -f 'bestvideo[height<=480][width<=854]+bestaudio/best[height<=480][width<=854]' --merge-output-format 'mp4' --no-playlist --embed-thumbnail --embed-chapters --embed-metadata --embed-info-json -o "${dir}/%(title)s.%(ext)s" "${link}"

    #    yt-dlp --extract-audio --audio-format mp3 --merge-output-format 'mp4' --no-playlist --embed-thumbnail --embed-chapters --embed-metadata --embed-info-json -o "${dir}/%(title)s.%(ext)s" "${link}"

    # --embed-sub --write-sub --write-auto-sub --sub-lang 'en.*' --sub-format 'best' --convert-subs vtt - currently does not work/ floppy at best
    done
}

if down_vid "${link}"; then
    ntf 'low' 'Download successful' "Title: ${video_title}"
    exit 0
else
    ntf 'Unknown error occured'
    exit 1
fi
