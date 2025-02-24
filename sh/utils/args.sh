# Requires main_utils and array_utils

imp arr

# Help function
show_help() {
    help_status="${1}"

    if [[ -z "${help_status}" ]] || [[ "${help_status}" = 'type' ]]; then
        echo "Type '${SCRIPT_NAME} -h' for help"
        exit "${2:-1}"
    fi

    if chk_var 'SCRIPT_NAME' && chk_var 'VERSION'; then
        echo "\$ ${SCRIPT_NAME} v${VERSION}"
    elif chk_var 'SCRIPT_NAME'; then
        echo "\$ ${SCRIPT_NAME}" 
    fi
    chk_var 'ARGUMENT_USAGE' && echo "Usage: ${ARGUMENT_USAGE}"
    chk_var 'ARGUMENT_DEFAULTS' && echo "Default options: ${ARGUMENT_DEFAULTS}"
    chk_var 'SCRIPT_SOURCE' && echo "\$BASH_SOURCE hierarchy: ${SCRIPT_SOURCE}"
    echo -e "\nAvailable Options:"
    for argument_key in "${ordered_argument_keys[@]}"; do
        awk -F ',' '{
            split($2, a, ":");
            split($3, b, ":");
            if (a[1] && b[1]) {
                printf "--%s, -%s: %s\n", a[1], b[1], $4;
            } else if (a[1]) {
                printf "--%s: %s\n", a[1], $4;
            } else if (b[1]) {
                printf "-%s: %s\n", b[1], $4;
            }
        }' <<< "${argument_keys[${argument_key}]}"
    done
    chk "${help_state}" && help_state=
    chk_val "${help_status}" '-' || exit "${help_status}"
}

# Function to process an argument
process_argument() {
    local argument_position="${1}"
    local argument_name="${2}"
    local argument_type="${3}"
    local found empty argument_key argument argument_type_field k

    chk_var 'argument_position' || return 1
    chk_var 'argument_name' || return 1
    chk_var 'argument_type' || return 1

    if [[ "${argument_type}" == 'string' ]]; then
        argument_type_field='2' # Field for long options
        argument="--${argument_name}"
    elif [[ "${argument_type}" == 'char' ]]; then
        argument_type_field='3' # Field for short options
        argument="-${argument_name}"
    else
        echo "Unrecognized argument_type '${argument_type}' for argument '${argument_name}'" 
        exit 1
    fi

    found='false'
    for argument_key in "${!argument_keys[@]}"; do
        if grep -E "(^|:)${argument_name}($|:)" <<< "$(awk -v field="${argument_type_field}" -F ',' '{print $field}' <<< "${argument_keys["${argument_key}"]}" )" &>/dev/null; then
            IFS=':' read -r argument_action argument_option <<< "$(awk -F ',' '{print $1}' <<< "${argument_keys["${argument_key}"]}")"
            found='true'
            break
        fi
    done

    if [[ "${found}" == 'false' ]]; then
        echo "Argument '${argument}' is unknown"
        show_help
    fi
    case "${argument_action}" in
        'next')
            k="$((argument_position+1))"
            empty='true'

            if [[ "${argument_option}" == '1' ]]; then
                until ! [[ "${arguments[${k}]}" == '--' ]]; do
                    ((k++))
                done
                if [[ -n "${arguments[${k}]}" ]]; then
                    eval "${argument_key}=${arguments[${k}]}"
                    argument_values+=("${k}")
                    empty='false'
                fi
            elif [[ "${argument_option}" == '0' ]]; then
                until [[ "${arguments[${k}]}" == -* ]] || [[ -z "${arguments[${k}]}" ]]; do
                    until ! [[ "${arguments[${k}]}" == '--' ]]; do
                        ((k++))
                    done
                if [[ -n "${arguments[${k}]}" ]]; then
                    eval "${argument_key}+=("${arguments[${k}]}")"
                    argument_values+=("${k}")
                    ((k++))
                    empty='false'
                fi
                done
            else
                for ((i=0; i<argument_option; i++)); do
                    until ! [[ "${arguments[${k}]}" == '--' ]]; do
                        ((k++))
                    done
                if [[ -n "${arguments[${k}]}" ]]; then
                    eval "${argument_key}+=("${arguments[${k}]}")"
                    argument_values+=("${k}")
                    ((k++))
                    empty='false'
                fi
                done
            fi
            ;;
        'prev')
            k="$((argument_position-1))"
            empty='true'

            if [[ "${argument_option}" == '1' ]]; then
                until ! [[ "${arguments[${k}]}" == '--' ]]; do
                    ((k--))
                done
                if [[ -n "${arguments[${k}]}" ]]; then
                    eval "export ${argument_key}=${arguments[${k}]}"
                    argument_values+=("${k}")
                    empty='false'
                fi
            elif [[ "${argument_option}" == '0' ]]; then
                until [[ "${arguments[${k}]}" == -* ]] || [[ -z "${arguments[${k}]}" ]]; do
                    until ! [[ "${arguments[${k}]}" == '--' ]]; do
                        ((k--))
                    done
                if [[ -n "${arguments[${k}]}" ]]; then
                    eval "${argument_key}+=("${arguments[${k}]}")"
                    argument_values+=("${k}")
                    ((k--))
                    empty='false'
                fi
                done
            else
                for ((i=0; i<argument_option; i++)); do
                    until [[ "${arguments[${k}]}" == -* ]] || [[ -z "${arguments[${k}]}" ]]; do
                        ((k--))
                    done
                if [[ -n "${arguments[${k}]}" ]]; then
                    eval "${argument_key}+=("${arguments[${k}]}")"
                    argument_values+=("${k}")
                    ((k--))
                    empty='false'
                fi
                done
            fi
            ;;
        'bool')
            case "${argument_option}" in
                'true')
                    eval "export ${argument_key}=true"
                    ;;
                'false')
                    eval "export ${argument_key}=false"
                    ;;
                'toggle')
                    if [[ "${!argument_key}" == 'true' ]]; then
                        eval "export ${argument_key}=false"
                    else
                        eval "export ${argument_key}=true"
                    fi
                    ;;
            esac
            ;;
        *)  # Handle any additional actions here if needed
            if [[ -n "${argument_action}" ]]; then
                echo "Unknown action '${argument_action}' for argument '${argument}'"
            else
                echo "Argument '${argument}' requires an action"
            fi
            show_help
            ;;
    esac

    if [[ "${empty}" == 'true' ]]; then
        echo "No values were found for '${argument}'"
        exit '1'
    fi
}

# Function to process all given arguments
get_args() {
    local -A argument_keys
    local argument_keys_serialized="${1}"
    local arguments_serialized="${2}"
    local potential_file i h argument prev_argument argument_position prev_argument_position argument_name argument_char key prompt word 
    local ordered_argument_keys=() argument_values=() potential_files=() arguments=()
    declare -ga FILES

    chk_var 'argument_keys_serialized' && prs_arr "${argument_keys_serialized}" 'argument_keys'
    chk_var 'arguments_serialized' && prs_arr "${arguments_serialized}" 'arguments'

    if ! chk_arr 'arguments'; then
        ser_arr 'ARGUMENTS' 'arguments_serialized'
        prs_arr "${arguments_serialized}" 'arguments'
    fi

    local arguments_number="${#arguments[@]}"

    argument_keys['help_state']='bool:true,help:info:help?:usage:what:huh:explain,h:?,View this help command'
    argument_keys['license_state']='bool:true,license:copyright:copyleft,,View license information'
    argument_keys['interactive_mode']='bool:true,interactive:intr,,Enter interactive mode'
    argument_keys['verbose_output']='bool:true,verbose:vrb,,Enable verbose output'
    argument_keys['kill_state']='bool:true,kill,k,Kill all running processes of this script'
    argument_keys['dry_run']='bool:true,dry-run,n,Dry-run without modifying files'
    argument_keys['force_state']='bool:true,force,f,Force operation without prompting'


    while IFS= read -r key; do
        ordered_argument_keys+=("${key}")
    done < <(printf '%s\n' "${!argument_keys[@]}" | sort -t ',' -k 2,2 -k 3,3 | cut -d ',' -f 1 | uniq)

    # Check if ordered list for display in help exists
    chk_arr 'ordered_argument_keys' || { msg 'Error occured while ordering arguments'; return 1; }

    # Initialize variables
    local argument_allow_options='true'
    chk_var 'interactive_mode' 'false'
    chk_var 'arguments_number' "${ARGUMENTS_NUMBER}"

# Process each argument, not starting from zero as $0 is script name
for ((i=1; i<=arguments_number; i++)); do
    chk_val "${arguments["${i}"]}" || continue

    if chk_val "${arguments["${i}"]}" '--'; then
        chk "${argument_allow_options}" && argument_allow_options='false' || argument_allow_options='true'
        continue
    fi

    argument_position="${i}"
    argument="${arguments["${argument_position}"]}"

    chk_el "${argument_position}" 'argument_values' && continue

    if [[ "${argument_position}" -gt '1' ]]; then
        prev_argument_position="$((argument_position-1))"
        prev_argument="${arguments["${prev_argument_position}"]}"
    fi

    if chk "${argument_allow_options}"; then
        if [[ "${argument}" == --* ]]; then
            argument_name="${argument##--}"  # Remove starting '--' from argument to match array values
            process_argument "${argument_position}" "${argument_name}" 'string'

        elif [[ "${argument}" == -* ]]; then
                argument_name="${argument##-}"  # Remove starting '-' from argument to match array values
            if [[ "${#argument_name}" -gt '1' ]]; then
                for ((h=0; h<"${#argument_name}"; h++)); do
                    argument_char="${argument_name:${h}:1}"
                    process_argument "${argument_position}" "${argument_char}" 'char'
                done
            else
                process_argument "${argument_position}" "${argument_name}" 'char'
            fi
        else
            if chk "${interactive_mode}" && ([[ "${argument_position}" == '1' ]] || chk_val "${prev_argument}" '&&' '&' ';'); then
                process_argument "${argument_position}" "${argument}" 'string'
            else
                potential_files+=("${argument_position}")
            fi
        fi

    else
        potential_files+=("${argument_position}")
    fi
done

# Add files
for potential_file in "${potential_files[@]}"; do
    if (! chk_el "${potential_file}" 'argument_values' && ! chk_val "${potential_file}" '-' '--' ';' '&&' '&'); then
        FILES+=("${arguments["${potential_file}"]}")

    fi
done
local files_number="${#FILES[@]}"

# Show help if needed
if chk "${help_state}"; then
    if chk "${interactive_mode}"; then
        show_help -
    else
        show_help 0
    fi
fi

    if chk "${interactive_mode}"; then
        while true; do
            echo -n "[${SCRIPT_NAME^^}] ${PWD} >>> "
            read -r -a prompt || cleanup

            case "${prompt[*]}" in
            'exit' | 'break')
                cleanup
                ;;
            '')
                ;;
            *)
                prompt=("${SCRIPT_NAME}" "${prompt[@]}")
                ser_arr 'prompt' 'arguments_serialized'
                get_args "${argument_keys_serialized}" "${arguments_serialized}"
                ;;
            esac
        done
    fi
}
