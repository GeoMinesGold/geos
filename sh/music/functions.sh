# Function to play music
play() {
    local numbers=("${@}")
    local number video

    declare -A options
    while IFS=: read -r key value; do
        options["${key}"]="${value}"
    done < "${options_file}"

    # Kill existing mpv instances using the socket
    kill -9 "$(lsof -t "${socket}")" &>/dev/null

    chk_arr 'numbers' || numbers=("$(gen_num "${files_length}")")

    for number in "${numbers[@]}"; do
        if [[ "${number}" == 'rand' ]]; then
            number=("$(gen_num "${files_length}")")
        fi

        if chk_rgx "${number}" 'numbers'; then
            if [[ "${options['pause']}" == 'true' ]]; then
                pause='yes'
            else
                pause='no'
            fi

            if [[ "${options['vid']}" == 'true' ]]; then
                vid='1'
            else
                vid='no'
            fi

            video="${files[${number}]}"
            
            # Save to history file
            (IFS=':'; echo "${directories[*]}:${number}" >> "${history_file}")

            # Launch mpv with specified options
            mpv "${video}" --pause="${pause}" --vid="${vid}" --input-ipc-server="${socket}" &>/dev/null
        fi
    done
    play rand
}
