#!/usr/bin/env bash
# A VoiceMeeter/PulseMeeter alternative for Linux
# Includes utilities for managing PulseAudio, ALSA and PipeWire
# Requires main_utils, sound_utils, input_utils, notification_utils and array_utils

source /usr/lib/geos/core.sh
imp sound input arr notifs

# Get active sink and source
active_sink="$(pactl info | grep 'Default Sink' | awk '{print $3}')"
active_source="$(pactl info | grep 'Default Source' | awk '{print $3}')"

mapfile -t sinks < <(pactl list sinks short | awk '{print $2}')
mapfile -t sources < <(pactl list sources short | awk '{print $2}' | grep -v '\.monitor$')
mapfile -t monitors < <(pactl list sources short | awk '{print $2}' | grep '\.monitor$')

# Get info about a particular object (sink, source or otherwise)
get_object_info() {
  local list_type="${1}"
  local name="${2}"

  # Define headers and name prefixes based on the type
  case "${list_type}" in
    'sink')
      list_command='pactl list sinks'
      header_prefix='Sink #'
      name_prefix='Name: '
      ;;
    'source')
      list_command='pactl list sources'
      header_prefix='Source #'
      name_prefix='Name: '
      ;;
    'source-output')
      list_command='pactl list source-outputs'
      header_prefix='Source Output #'
      name_prefix='Name: '
      ;;
    'sink-input')
      list_command='pactl list sink-inputs'
      header_prefix='Sink Input #'
      name_prefix='Name: '
      ;;
    'source-input')
      list_command='pactl list source-inputs'
      header_prefix='Source Input #'
      name_prefix='Name: '
      ;;
    'module')
      list_command='pactl list modules'
      header_prefix='Module #'
      name_prefix='Name: '
      ;;
    'card')
      list_command='pactl list cards'
      header_prefix='Card #'
      name_prefix='Name: '
      ;;
    'client')
      list_command='pactl list clients'
      header_prefix='Client #'
      name_prefix='Name: '
      ;;
    'sample')
      list_command='pactl list samples'
      header_prefix='Sample #'
      name_prefix='Name: '
      ;;
    *)
      echo "Unsupported type: ${list_type}"
      return 1
      ;;
  esac

  ${list_command} | awk -v name="${name}" -v header_prefix="${header_prefix}" -v name_prefix="${name_prefix}" '
    BEGIN {
      # Initialize variables
      in_block = 0
      block = ""
      target_block_started = 0
    }

    # Mark the start of a new block
    $0 ~ header_prefix {
      if (in_block && target_block_started) {
        # Print the block without trailing new line
        print block
      }
      # Start a new block
      current_header = $0
      in_block = 1
      target_block_started = 0
      block = current_header
      next
    }

    # Append non-empty lines to the current block
    in_block && $0 != "" {
      block = block "\n" $0
    }

    # Match the name and start target block
    $0 ~ name_prefix && $0 ~ name {
      target_block_started = 1
    }

    # At the end, print the block if it matches the target
    END {
      if (in_block && target_block_started) {
        print block
      }
    }
  '
}

# Get corresponding monitor for sink
get_monitor() {
    local sink="${1}"

    chk_var 'sink' "${active_sink}"

    local monitor="$(get_object_info 'sink' "${sink}" | grep "Monitor Source" | awk '{print $3}')"
    echo "${monitor}"
}

active_monitor="$(get_monitor "${active_sink}")"

# Function to set or modify sink volume
set_sink_volume() {
    local sink="${1}"
    local value="${2}"

    chk_var 'sink' "${active_sink}"
    chk_var 'value' "100"

    pactl set-sink-volume "${sink}" "${value}%"
}

# Check sink mute status
check_sink_mute() {
    local sink="${1}"
    chk_var 'sink' "${active_sink}"

    local mute_state="$(pactl get-sink-mute "${sink}" | awk '{print $2}')"
    chk "${mute_state}" && echo 'true' || echo 'false'
}

# Check source mute status
check_source_mute() {
    local src="${1}"
    chk_var 'src' "${active_source}"

    local mute_state="$(pactl get-source-mute "${src}" | awk '{print $2}')"
    chk "${mute_state}" && echo 'true' || echo 'false'
}

# Check monitor mute status
check_monitor_mute() {
    local monitor="${1}"
    chk_var 'monitor' "${active_monitor}"

    local mute_state="$(pactl get-source-mute "${monitor}" | awk '{print $2}')"
    chk "${mute_state}" && echo 'true' || echo 'false'
}

# Function to mute sink
mute_sink() {
    local sink="${1}"
    chk_var 'sink' "${active_sink}"

    pactl set-sink-mute "${sink}" toggle
    chk "${mute_state}" && sfx unmute || sfx mute
}

# Function to mute source
mute_source() {
    local src="${1}"
    chk_var 'src' "${active_source}"
    local mute_state="$(pactl list sources | grep -A 9 "${src}" | grep "Mute:" | awk '{print $2}')"

    pactl set-source-mute "${src}" toggle

    chk "${mute_state}" && sfx unmute || sfx mute
}

# Function to get volume for a sink
get_sink_volume() {
    local sink="${1}"

    chk_var 'sink' "${active_sink}"

    pactl get-sink-volume "${sink}" | awk '{print $5}'
}

# Function to get volume for a sink
get_source_volume() {
    local src="${1}"

    chk_var 'src' "${active_source}"

    pactl get-source-volume "${src}" | awk '{print $5}'
}

# Function to set default sink
set_default_sink() {
    local sink="${1}"

    case "${sink}" in
        'cycle' | 'next' | 'nxt' | '')
            sink="$(nxt_el "${active_sink}" 'sinks')"
            ;;
        'previous' | 'prev')
            sink="$(prev_el "${active_sink}" 'sinks')"
            ;;
    esac

    chk_var 'sink' || return 1

    pactl set-default-sink "${sink}" && active_sink="${sink}"
}

# Function to set default source
set_default_source() {
    local src="${1}"

    case "${src}" in
        'cycle' | 'next' | 'nxt' | '')
            src="$(nxt_el "${active_source}" 'sources')"
            ;;
        'previous' | 'prev')
            src="$(prev_el "${active_source}" 'sources')"
            ;;
    esac

    chk_var 'src' || return 1

    pactl set-default-source "${src}" && active_source="${src}"
}

# Handle options
sound_type="${1}"
sound_option="${2}"

case "${sound_type}" in
    'sound' | 'volume' | 'vol' | 'sink' | '')
        case "${sound_option}" in
            'get' | '')
                volume="$(pactl -- get-sink-volume "${active_sink}" | awk '{print $5}')" 
                ntf 'low' "${volume}"
                ;;
            'increase' | 'incr' | 'inc' | '+')
                value="${3}"
                chk_rgx "${value}" 'numbers' || value='5'
                set_sink_volume "${active_sink}" "+${value}"
                ;;
            'decrease' | 'decr' | 'dec' | '-')
                value="${3}"
                chk_rgx "${value}" 'numbers' || value='5'
                set_sink_volume "${active_sink}" "-${value}"
                ;;
            'set')
                current_volume="$(get_sink_volume "${active_sink}")"
                value="${3}"
                chk_var 'value' || value="$(get_input "Enter new volume" "Current volume: ${current_volume}")" 
                value="${value//\%/}"
                chk_rgx "${value}" 'numbers' || value='100'
                set_sink_volume "${active_sink}" "${value}"
                ;;
            'mute')
                sink="${3}"
                mute_sink "${sink}"
                ;;
            'switch')
                sink="${3}"
                set_default_sink "${sink}"
                ;;
        esac
        ;;
        'microphone' | 'mic' | 'src' | 'source')
            case "${sound_option}" in
                'mute')
                    src="${3}"
                    mute_source "${src}"
                    ;;
                'switch')
                    src="${3}"
                    set_default_source "${src}"
                    ;;
            esac
            ;;
        'monitor')
            case "${sound_option}" in
                'mute')
                    src="${3}"
                    monitor="$(get_monitor "${src}")"
                    mute_source "${monitor}"
                    ;;
            esac
            ;;
        'info')
            ntf "Audio: $(check_sink_mute)\nMic: $(check_source_mute)\nMonitor: $(check_monitor_mute)"
            ;;
    *)
        ntf "Unknown option: ${sound_option}"
        exit 1
        ;;
esac
