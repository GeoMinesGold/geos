# Requires main_utils

# Function to parse arguments for notification and logging
parse_notification_args() {
    local num="${1}"
    shift
    local args='0'
    local urgency title details

    for ((i=1; i<=num; i++)); do
        if chk_val "${!i}"; then
            ((args++))
        fi
    done
    
    case "${args}" in
        '3')
            urgency="${1}"
            title="${2}"
            details="${3}"
            ;;
        '2')
            if chk_el "${1}" 'urgency_values'; then
                urgency="${1}"
                details="${2}"
            else
                title="${1}"
                details="${2}"
            fi
            ;;
        '1')
            details="${1}"
            ;;
        *)
            return 1
            ;;
    esac

    chk_el "${urgency}" 'urgency_values' || urgency='normal'
    chk_var 'title' "${SCRIPT_NAME^^}"
    echo "${urgency};${title};${details}"
}

# Function to echo
msg() {
    local urgency_values=('critical' 'low' 'warning' 'debug' 'normal')
    local seperator=':'
    local space=' '
    local urgency title details color_code
    IFS=";" read -r urgency title details < <(parse_notification_args "${#}" "${1}" "${2}" "${3}")

    urgency="${urgency^^}"
    case "${urgency}" in 
        'CRITICAL') color_code='\e[1;31m' ;; # Red
        'LOW') color_code='\e[1;36m' ;; # Cyan
        'WARNING') color_code='\e[1;33m' ;; # Yellow
        'DEBUG') color_code='\e[1;35m' ;; # Magenta
        'NORMAL') color_code='\e[1;37m' ;; # Bright White
    esac

    chk_var 'details' || seperator=
    chk_var 'seperator' || space=

    echo -e "${color_code}[${urgency}]\e[0m ${title}${seperator}${space}${details}" >&2
}

# Function to notify
script_notify() {
    local urgency_values=('low' 'normal' 'critical')
    local urgency title details

    IFS=";" read -r urgency title details < <(parse_notification_args "${#}" "${1}" "${2}" "${3}")
    notify-send -u "${urgency}" "${title}" "${details}" || notify-send -u 'critical' 'Unknown error occured' "Function ${FUNCNAME[0]} exited with error"
}

# Function to both notify and echo
ntf() {
    chk_val "${1}" || return 1
    msg "${1}" "${2}" "${3}"
    script_notify "${1}" "${2}" "${3}"
}
