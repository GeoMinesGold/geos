#!/usr/bin/env bash
# Requires main_utils, filename_utils, input_utils and sound_utils

source /usr/lib/geos/core.sh
imp file input sound notifs

# Get input
if chk_val "${1}"; then 
    note="${1}"
else
    # Get input buffers
    get_buffers 'input' 'clipboard' 'selection'

    # Get priority buffer
    priority="$(get_buffer 'input' 'clipboard' 'selection')"

    if ! chk_var 'priority'; then
        ntf 'No buffer selected'
        exit 1
    fi
    note="${buffers["${priority}"]}"

    # Check if note exists
    if ! chk_var 'note'; then
        ntf 'No input provided'
        exit 1
    fi
fi

# Get file structure for note
chk_var 'notes_dir' "${HOME}/Documents/Notes"
dir="$(gen_dir $(get_input) "${notes_dir}")"
file="$(gen_fl txt "${dir}")"

# Check if note already exists in directory
if chk_ct "${note}" "${notes_dir}"; then
    ntf 'Note already exists'
    exit 0 # Because note already exists so no error occured
else
    crt "${file}"
    chk_var 'note' && echo "${note}" > "${file}"
    ntf 'low' 'Note has been saved'
    exit 0
fi
