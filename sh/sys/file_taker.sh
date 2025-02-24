#!/usr/bin/env bash
source /usr/lib/geos/core.sh
imp notifs args file

file_taker_dir="${HOME}/Documents/file_taker"

if ! chk_val "${1}" || [[ "${1}" == "current" ]] || [[ "${1}" == "." ]]; then
    input_dir="${PWD}"
else
    if chk_dir "${1}"; then
        input_dir="${1}"
    else
        msg 'normal' 'Invalid input directory'
        exit 1
    fi
fi

if [[ -z "${2}" ]]; then
    output_dir="$(rm_slash "$(gen_dir "${file_taker_dir}")/$(gen 10)")"
else
    output_dir="${2}"
fi

mkdir -p "${output_dir}"

if ! chk_dir "${input_dir}"; then
    msg "Directory '${input_dir}' is empty or doesn't exist"
fi

# Move all files from the input directory (and subdirectories) to the output directory
if chk "${dry_run}"; then
    msg "Would move all files in directory '${input_dir}' recursively to '${output_dir}'"
else
    find "${input_dir}" -type f -exec mv -n -t "${output_dir}" {} +
    msg "Moved all files in directory '${input_dir}' recursively to '${output_dir}'"
fi
