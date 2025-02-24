# Requires main_utils

# Function to get active display manager
get_disp() {
    local display_manager

    if [[ -n "${WAYLAND_DISPLAY}" ]] || ([[ -n "${XDG_SESSION_TYPE}" ]] && grep -q 'wayland' <<< "${XDG_SESSION_TYPE}"); then
        display_manager="wayland"
    elif [[ -n "${XDG_SESSION_TYPE}" ]] && ! grep -q 'wayland' <<< "${XDG_SESSION_TYPE}"; then
        display_manager="xorg"
    fi
    echo "${display_manager}"
}

# Function to find given screen
get_scr() {
    local monitors primary_monitor monitors_number operation mouse_x_offset monitor_x_offset monitor_name resolution_x resolution_y offset_x offset_y monitor_resolution
    # Get monitors and order them based on offset X value in ascending order
    monitors="$(xrandr --listmonitors | awk '/Monitors/{flag=1; next} flag' | awk '{gsub(/[+\/]/," "); split($4, offset, "x"); print $8" "$3" "offset[2]" "$6" "$7}' | sort -n -k4)"
    primary_monitor="$(xrandr | grep "connected primary" | awk '{print $1}')"
    monitors_number="$(wc -l <<< "${monitors}")"

    # Perform operation
    operation="${1}"
    if ! chk_var 'operation' || [[ "${operation}"  == 'active' ]] || [[ "${operation}" == 'name' ]]; then
        # Find mouse location
        mouse_x_offset="$(xdotool getmouselocation --shell | grep -oP 'X=\K\d+')"
        while read -r line; do
            monitor_x_offset="$(cut -d ' ' -f 4 <<< "${line}")"
            if [[ "${mouse_x_offset}" -ge "${monitor_x_offset}" ]]; then
                monitor="${line}"
            fi
        done <<< "${monitors}"
    elif chk_rgx "${operation}" 'numbers' && [[ "${operation}" -le "${monitors_number}" ]] && ! [[ "${operation}" -eq '0' ]]; then
        monitor="$(awk "NR==${operation}" <<< "${monitors}")"
    else
        return 1
    fi

    # Print results
    operation="${2}"
    read monitor_name resolution_x resolution_y offset_x offset_y <<< "${monitor}"
    monitor_resolution="${resolution_x}x${resolution_y}+${offset_x}+${offset_y}"
    case "${operation}" in
        '' | 'res' | 'resolution') echo "${monitor_resolution}" ;;
        'name') echo "${monitor_name}" ;;
        *) return 1 ;;
    esac
}

# Function to get PID of active window
get_win_id() {
    local win_type="${1}"
    local win_id

    case "${win_type}" in
        'hexadecimal' | 'hex' | '') win_id="$(xprop -root -f _NET_ACTIVE_WINDOW 0x " \$0\n" _NET_ACTIVE_WINDOW | awk '{print $2}')" ;;
        'denary') win_id="$(xdotool getactivewindow)" ;;
    esac
    echo "${win_id}"
}

# Function to get geometry of active window
get_win_geo() {
    local win_id="$(get_win_id)"
    xwininfo -id "${win_id}" | grep 'geometry' | awk '{print $2}'
}

# Function to get name of active window
get_win() { 
    local win_id="$(get_win_id)"
    xprop -id "${win_id}" | awk '/WM_CLASS/{print $4}' | sed 's/\"//g'
}
