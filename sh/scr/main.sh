#!/usr/bin/env bash
# A CLI utility for all your display needs

source /usr/lib/geos/core.sh

# Perform operation
operation="${1}"
if [[ "${operation}" == 'toggle' ]]; then
    imp screen
    screens="${2}"
    case "${screens}" in
        '' | 'active') 
            connected_outputs=("$(get_scr active name)")
            ;;
        'other')
            mapfile -t connected_outputs < <(xrandr --listmonitors | awk '{if (NR > 1) {print $4}}' | grep -wv "$(get_scr active name)")
            ;;
        'all')
            mapfile -t connected_outputs < <(xrandr --listmonitors | awk '{if (NR > 1) {print $4}}')
            ;;
    esac

    # Loop through each connected output
    for output in "${connected_outputs[@]}"; do
        current_brightness="$(xrandr --verbose | grep -w "${output}" -A5 | grep -i brightness | awk '{print $2}')"
        
        if ! [[ "${current_brightness}" == '0.0' ]]; then
            new_brightness='0.0'
        else
            new_brightness='1.0'
        fi

        # Set the new brightness for the current output
        xrandr --output "${output}" --brightness "${new_brightness}"
    done
    exit
fi

imp arr args notifs

declare -A monitor_properties=(
    [eDP1]="1920x1080@60"
    [DP1]="1024x768@60"
    [DP3]="1280x1024@75"
)
default_resolution="1920x1080@60"

declare -A current_monitors
declare -A monitors_description

hist_file="${LOCAL_DIR}/history"

while IFS= read -r line; do
    if [[ "${line}" =~ ^([A-Za-z0-9]+)\ [connected|disconnected] ]]; then
        # When a new monitor is found, update current_monitor
        current_monitor="${BASH_REMATCH[1]}"
        monitors_description["${current_monitor}"]="${line}"
    elif [[ -n "${current_monitor}" ]]; then
        # Append the line to the current monitor's entry
        monitors_description["${current_monitor}"]+=$'\n'"${line}"
    fi
done <<< "$(xrandr)"


get_resolution() {
    local monitors=("${@}")
    local monitor resolution

    for monitor in "${monitors[@]}"; do
        resolution="${monitor_properties["${monitor}"]}"
        chk_var 'resolution' "${default_resolution}"
        echo "${resolution}"
    done
}

check_resolution() {
    local resolution="${1}"
    local monitor="${2}"

    grep -qw "${resolution}" <<< "${monitors_description["${monitor}"]}" && return 0 || return 1
}

set_screen() {
    local monitors=("${@}")
    local pos_x='0'
    local pos_y='0'
    local width height monitor resolution hz cvt_output

    for monitor in "${monitors[@]}"; do
        resolution="$(get_resolution "${monitor}")"
        IFS='@' read -r resolution hz <<< "${resolution}"
        IFS='x' read -r width height <<< "${resolution}"
        width="$(( (width + 4) / 8 * 8 ))"

        if ! check_resolution "${resolution}" "${monitor}"; then
            cvt_output="$(cvt "${width}" "${height}" "${hz}" | awk 'NR==2' | sed 's/Modeline //' | sed 's/"//g')" 
            read -r resolution cvt_output <<< "$(sed 's/^[ \t]*//' <<< "${cvt_output}")"
            resolution="$(sed 's/_[0-9.]*$//' <<< "${resolution}")"

            xrandr --newmode "${resolution}" ${cvt_output}
            xrandr --addmode "${monitor}" "${resolution}"
        fi

        current_monitors["${monitor}"]="${resolution}"
        xrandr --output "${monitor}" --mode "${resolution}" --pos "${pos_x}x${pos_y}" --rotate normal
        pos_x="$((pos_x+width))"
    done
}

mapfile -t monitors < <(xrandr | grep -w connected | awk '{print $1}')
monitors_number="${#monitors[@]}"

get_args

if ! chk_arr 'FILES'; then
    for idx in "${!monitors[@]}"; do
        monitor="${monitors["${idx}"]}"
        echo "$((idx+1)): ${monitor}: $(get_resolution "${monitor}")"
    done
    exit 0
fi

ordered_monitors=()
for file in "${FILES[@]}"; do
    if [[ "${file}" -eq '0' ]]; then
        break
    elif ! chk_rgx "${file}" 'positive_numbers' || ! ([[ "${file}" -gt '0' ]] && [[ "${file}" -le "${monitors_number}" ]]); then
        msg "Invalid monitor number: ${file}"
        continue
    fi

    ((file--))
    ordered_monitors+=("${monitors["${file}"]}")
done

set_screen "${ordered_monitors[@]}"

for monitor in "${monitors[@]}"; do
    if ! chk_el "${monitor}" 'ordered_monitors'; then
        xrandr --output "${monitor}" --off
    fi
done


ser_arr 'current_monitors' 'current_monitors_ser'

echo "${current_monitors_ser}" >> "${hist_file}"

nitrogen --restore &>/dev/null
