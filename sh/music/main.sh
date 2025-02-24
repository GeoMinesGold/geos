#!/usr/bin/env bash

source /usr/lib/geos/core.sh
imp array args rand notifs
src functions

mkdir -p "${LOCAL_DIR}"

# Initialize variables
music_dir="${HOME}/Music"
history_file="${LOCAL_DIR}/history.txt"
options_file="${LOCAL_DIR}/options.txt"
socket="${CONFIG_DIR}/socket"
lock_file="${LOCK_DIR}/lock.lck"


operations=()
directories=()
files=()
queue=()

# Define arguments
declare -A argument_keys=(
    ['operations']='next:0,operations:opr,o,Specify the operations'
)

# Serialize arrays into variables
ser_arr 'argument_keys' 'argument_keys_serialized'
ser_arr 'ARGUMENTS' 'arguments_serialized'

# Get arguments
get_args "${argument_keys_serialized}" "${arguments_serialized}"

for file in "${FILES[@]}"; do
    if chk_rgx "${file}" 'numbers'; then
        queue+=("${file}")
        continue
    else
        if chk_dir "${file}"; then
            file="${file%/}"
        elif chk_var 'file' && chk_dir "${music_dir}/${file}"; then
            file="${music_dir}/${file%/}"
        elif [[ "${file}" == 'vid' ]] || [[ "${file}" == 'loop' ]] || [[ "${file}" == 'start_paused' ]] || [[ "${file}" == 'list' ]] || [[ "${file}" == 'ls' ]] || [[ "${file}" == 'next' ]] || [[ "${file}" == 'prev' ]] || [[ "${file}" == '+' ]] || [[ "${file}" == '-' ]] || [[ "${file}" == 'rand' ]] || [[ "${file}" == 'pause' ]]; then
            operations+=("${file}")
            continue
        else
            msg "Unknown argument: ${file}"
            continue
        fi
        directories+=("${file}")
    fi
done

last_line="$(tail -n 1 "${history_file}")"  # Get the last line from the file
IFS=: read -r -a last <<< "${last_line%:*}"  # Read all but the last field into an array
last_number="${last_line##*:}"  # Extract the last field (number)
chk_arr 'last' || last=("${music_dir}/Pop")
chk_arr 'directories' || directories=("${last[@]}")

# Add directories
for dir in "${directories[@]}"; do
    mapfile -O "${#files[@]}" -t files < <(find "${dir}" -mindepth 1 -type f)
done
files_length="${#files[@]}"

# Handle other music operations
if chk_arr 'directories' && ! chk_arr 'operations' && ! chk_arr 'options' && ! chk_arr 'queue'; then
    operations=('rand')
fi

for operation in "${operations[@]}"; do
    case "${operation}" in
        'vid')
            vid="$(echo '{ "command": ["get_property", "vid"] }' | socat - "${socket}" | awk -F ',' '{print $1}' | awk -F ':' '{print $2}')"
            if [[ "${vid}" == '1' ]]; then
                vid='no'
                sed -i 's/vid:true/vid:false/' "${options_file}"
            else
                vid='1'
                sed -i 's/vid:false/vid:true/' "${options_file}"
            fi
        socat - "${socket}" <<< "set vid ${vid}" &>/dev/null
            ;;
        'loop')
            loop="$(echo '{ "command": ["get_property", "loop"] }' | socat - "${socket}" | awk -F ',' '{print $1}' | awk -F ':' '{print $2}')"
            if [[ "${loop}" == '"inf"' ]]; then
                loop='no'
            else
                loop='inf'
            fi
            socat - "${socket}" <<< "set loop ${loop}" &>/dev/null
            ;;
        'start_paused')
            if grep -q 'pause:false' "${options_file}"; then
                sed -i 's/pause:false/pause:true/' "${options_file}"
            else
                sed -i 's/pause:true/pause:false/' "${options_file}"
            fi
            ;;
        'list' | 'ls') 
            for ((i=0; i<files_length; i++)); do
                echo "${i}: ${files[${i}]}"
            done
            ;;
        'pause')
            socat - "${socket}" <<< 'cycle pause' &>/dev/null
            ;;
        'next' | 'previous' | '+' | '-' | 'rand')
            queue=('rand')
            ;;
    esac
done

if chk_arr 'queue'; then
    kill -9 "$(cat "${lock_file}")" &>/dev/null
    play "${queue[@]}" &
    disown
    echo "${!}" > "${lock_file}"
    exit 0
fi

#                current_index="$(awk -F ':' 'END {print $1}' < "${history_file}" | grep -q "${music_directory}" && awk -F ':' 'END {print $2}' < "${history_file}")"
#                    ((current_index++))
#                    ((current_index--))
