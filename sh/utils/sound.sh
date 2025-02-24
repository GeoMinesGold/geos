# Requires main_utils

chk_var 'MUSIC_DIR' "${HOME}/Music"
sounds_dir="${MUSIC_DIR}/Sound Effects"

# Function to play a sound using mpv
play_sound() {
    local files="${@}"
    local file

    for file in "${files[@]}"; do
        mpv "${file}" --vid=no --resume-playback=no --loop-file=no --idle=no
    done
}


# Function to play_sound given sound effect
sfx() {
    local app="${1}"
    local option="${2}"

    case "${app}" in
        'mute')
            app='discord'
            option='mute'
            ;;
        'unmute')
            app='discord'
            option='unmute'
            ;;
        'success')
            app='system'
            option='success'
            ;;
        'beep')
            app='system'
            option='beep'
            ;;
    esac

    case "${app}" in 
        'discord')
            case "${option}" in
                'mute') play_sound "${sounds_dir}/discord_mute.mp3" ;;
                'unmute') play_sound "${sounds_dir}/discord_unmute.mp3" ;;
            esac
            ;;
        'monitor')
            case "${option}" in 
                'mute') play_sound "${sounds_dir}/monitor_mute.mp3" ;;
                'unmute') play_sound "${sounds_dir}/monitor_unmute.mp3" ;;
            esac
            ;;
        'system')
            case "${option}" in
                'beep') play_sound "${sounds_dir}/beep_1.mp3" ;;
                'success') play_sound "${sounds_dir}/beep_2.mp3" ;;
            esac
            ;;
    esac
}
