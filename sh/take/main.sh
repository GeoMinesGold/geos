#!/usr/bin/env bash
# Tool for taking screenshots, videos, notes and more with a variety of options
# Requires main_utils, rand_utils, date_utils, screen_utils, filename_utils and sound_utils

source /usr/lib/geos/core.sh
imp rand date scr file sound

# Check if root
if chk_rt; then
    ntf 'Do not run this command as the root user'
    exit 1
fi

# Initialize variables
take_type="${1}"
types=('screenshot' 'video' 'audio' 'note' 'script') 
primary_type='screenshot'
secondary_type='video'
tertiary_type='note'

# Process take_type
case "${take_type}" in
    '' | 'default' | 'def' | 'primary' | 'prim' | '1st' | 'first' | '1' | 'I')
        take_type="${primary_type}"
        ;;
    'alternative' | 'alt' | 'secondary' | 'sec' | '2nd' | 'second' | '2' | 'II')
        take_type="${secondary_type}"
        ;;
    'tertiary' | 'tert' | '3rd' | 'third' | '3' | 'III')
        take_type="${tertiary_type}"
        ;;
    'screenshot' | 'image' | 'img' | 'scr' | 'screen' | 'shot')
        take_type='screenshot'
        ;;
    'video' | 'vid' | 'rec' | 'record')
        take_type='video'
        ;;
    'note' | 'notes' | 'write' | 'diary' | 'type')
        take_type='note'
        ;;
    'script' | 'code')
        take_type='script'
        ;;
    *)
        msg "Type '${take_type}' is invalid"
        exit 1
esac

chk_var 'take_option' "${2}"

# Process options
case "${take_type}" in
    'screenshot' | 'video' | 'audio')
        types_options=('selection' 'screen' 'window' 'options' 'download' 'save')
        primary_option='selection'
        secondary_option='screen'
        tertiary_option='window'
        ;;
    'script') 
        types_options=('tex' 'dotnet' 'py')
        primary_option='tex'
        secondary_option='dotnet'
        tertiary_option='py'
        ;;
    'note')
        types_options=('text' 'drawing' 'image' 'video')
        primary_option='text'
        secondary_option='drawing'
        tertiary_option='image'
        ;;
esac

# Process take_option
case "${take_option}" in
    '' | 'default' | 'def' | 'primary' | 'prim' | '1st' | 'first' | '1' | 'I')
        take_option="${primary_option}"
        ;;
    'alternative' | 'alt' | 'secondary' | 'sec' | '2nd' | 'second' | '2' | 'II')
        take_option="${secondary_option}"
        ;;
    'tertiary' | 'tert' | '3rd' | 'third' | '3' | 'III')
        take_option="${tertiary_option}"
        ;;
    'opts' | 'opt' | 'more' | '-')
        take_option='options'
        ;;
    *)
        case "${take_type}" in
            'screenshot' | 'video' | 'audio')
                case "${take_option}" in
                    'sv' | 'write' | 'confirm' | '+')
                        take_option='save'
                        ;;
                    'sel' | 'choose')
                        take_option='selection'
                        ;;
                    'dow' | 'down')
                        take_option='download'
                        ;;
                    'scr' | 'display' | 'disp' | 'active_screen' | 'active_display')
                        take_option='screen'
                        ;;
                    'win' | 'active_window')
                        take_option='window'
                        ;;
                esac
                ;;
            'note')
                case "${take_option}" in
                    'text' | 'txt' | 'type') 
                        take_option='text'
                        ;;
                    'pen' | 'draw' | 'write' | 'paper')
                        take_option='drawing'
                        ;;
                    'camera' | 'photo' | 'image' | 'img' | 'capture' | 'shoot')
                        take_option='image'
                        ;;
                    'record' | 'video' | 'vid') 
                        take_option='video'
                        ;;
                esac
                ;;
            'script')
                case "${take_option}" in
                    'tx' | 'latex' | 'lat')
                        take_option='tex'
                        ;;
                    'python' | 'pyth' | 'pyt' | 'pytho')
                        take_option='py'
                        ;;
                    '.net' | 'dot' | 'net' | '.')
                        take_option='dotnet'
                        ;;
                esac
                ;;
        esac
esac

chk_arr 'types_options' || echo "Array 'types_options' does not exist"
chk_el "${take_option}" types_options || echo "Option '${take_option}' is invalid"

take_note_drawing() {
    local dir="$(gen_dir "${HOME}/Documents/xopp")"
    local file="$(gen_fl "${dir}")"

    crt_dir "${file}"
    xournalpp "${file}" &
    wait
    chk_dir "${dir}" || rm -r "${dir}"
}

take_note_text() {
    true
}

case "${take_type}" in
    'screenshot')
        case "${take_option}" in
            'selection')
                maim -s -u -m 10 | xclip -selection 'clipboard' -target 'image/png'
                ;;
            'screen')
                maim -g "$(get_scr)" -u -m 10 | xclip -selection 'clipboard' -target 'image/png'
                ;;
            'window')
                maim -i "$(get_win_id)" -u -m 10 | xclip -selection 'clipboard' -target 'image/png'
                ;;
            'all')
                maim -u -m 10 | xclip -selection 'clipboard' -target 'image/png'
                ;;
            'save')
                ;;
        esac
        ;;
   'video') 
        case "${take_option}" in
            'selection')
                take_vid_selection
                true
                ;;
            'download')
                ${SCRIPT_DIR}/vid_download.sh "${ARGUMENTS[@]:3}"
                ;;
        esac
        ;;
    'audio')
        case "${take_option}" in
            'selection')
                true
                ;;
        esac
        ;;
    'note')
        case "${take_option}" in
            'text')
                ${SCRIPT_DIR}/note_taker.sh "${ARGUMENTS[@]:3}"
                # take_note_text
                ;;
            'drawing')
                take_note_drawing
                ;;
        esac
        ;;
    'script')
        case "${take_option}" in
            'tex')
                true
                ;;
        esac
        ;;
esac
exit
