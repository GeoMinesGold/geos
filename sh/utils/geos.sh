#!/usr/bin/env bash
# A collection of custom and opinionated bash utilities
# Includes utilities for dependency management, data checking, file handling and regular expression comparisons
# Requires a modern version of bash (preferably v5.0 or later)
# Author: Geo

# Store global arguments in an array for retrieval inside functions (including $0)
export ARGUMENTS_NUMBER="${#}"
declare -g ARGUMENTS=()
for ((i=0; i<=ARGUMENTS_NUMBER; i++)); do
    ARGUMENTS+=("${!i}")
done

# Function to check if any given value exists, or if two values are the same
chk_val() {
    local val="${1}"
    local array_val
    
    if [[ -z "${2}" ]]; then
        if [[ -n "${val}" ]]; then
            return 0
        else
            return 1
        fi
    fi

    shift
    local vals=("${@}")

    for array_val in "${vals[@]}"; do
        if [[ -n "${array_val}" ]]; then
            if [[ "${array_val}" == "${val}" ]]; then
                return 0
            fi
        fi
    done
    return 1
}

# Function to check if any given variable exists and is not empty
chk_var() {
    if ! chk_val "${3}"; then
        local vars=("${1}")
        local default="${2}"
    else
        local vars=("${@}")
    fi

    for var in "${vars[@]}"; do
        chk_val "${var}" || continue
        local content="${!var}"

        if [[ "${var}" =~ ^[-+]?[0-9]+$ ]]; then
            echo "check_variable: Unable to check a positional variable" >&2
            continue 
        else
            if [[ -v "${var}" ]] && chk_val "${content}"; then
                return 0
            else
                if chk_val "${default}"; then
                    eval "${var}='${default}'"
                    return 0
                fi
            fi
        fi
    done
    return 1
}

# Function to check if any given array exists and is not empty
chk_arr() {
    local arrays=("${@}")
    local array_name

    for array_name in "${arrays[@]}"; do
        local array_size="$(eval "echo \${#${array_name}[@]}")"
        if [[ "${array_size}" -gt '0' ]]; then
            return 0
        fi
    done
    return 1
}

# Function to check if an element matches any given regex 
chk_rgx() {
    local val="${1}"
    shift
    local regexes=("${@}")
    local regex 

    chk_var 'val' || return 1

    for regex in "${regexes[@]}"; do
        chk_var 'regex' || continue

        case "${regex}" in
            'letters' | 'letter' | 'lets' | 'let' | 'Aa' | 'aA' | 'Zz' | 'zZ') regex='^[a-zA-Z]+$' ;;
            'simple' | 'small' | 'lowercase' | 'a' | 'z') regex='^[a-z]+$' ;;
            'capitals' | 'capital' | 'caps' | 'cap' | 'code' | 'uppercase' | 'A' | 'Z') regex='^[A-Z]+$' ;;
            'numbers' | 'number' | 'nums' | 'num' | '0' | '1') regex='^[-+]?[0-9]+$' ;;
            'positive_numbers' | 'positives' | 'positive' | 'pos' | '+' | '+1') regex='^[+]?[0-9]+$' ;;
            'negative_numbers' | 'negatives' | 'negative' | 'neg' | '-' | '-1') regex='^-[0-9]+$' ;;
            'range' | '0-1' | '1-0' | '0-') regex='^[-+]?[0-9]+-[-+]?[0-9]+$' ;;
            '' | 'default' | 'alphanumeric') regex='^[a-zA-Z0-9]+$' ;;
        esac

        if [[ "${val}" =~ ${regex} ]]; then # Do not use double quotes to match as regex
            return 0
        fi
    done
    return 1
}

# Function to check if any given value is set to true
chk() {
    local vals=("${@}")
    local val

    for val in "${vals[@]}"; do
        case "${val,,}" in
            'true' | 't' | 'yes' | 'ye' | 'y' | 'aight' | 'oui' | 'positive' | 'on' | 'enable' | 'enabled' | 'affirmative' | 'sure' | 'surely' | 'certain' | 'certainly' | 'active' | 'allow' | 'allowed' | 'agree' | 'agreed' | 'yessir' | 'yes sir' | 'permit' | 'permitted' | 'grant' | 'granted' | 'valid' | 'validate' | 'consent' | 'verify' | 'verified' | 'absolutely' | '+' | '1' | 'ok' | 'okay' | 'why not' | 'sure why not' | 'sure why not?' | 'sure, why not' | 'sure, why not?') return 0 ;; # for the memes
        esac
    done
    return 1
}

# Function to check if current user is root
chk_rt() {
    local id="$(id -u)"
    if [[ "${id}" -eq '0' ]]; then
        return 0
    else
        return 1
    fi
}


# Function to check if current session is being sourced or being run directly
chk_intr() {
    if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
        return 0  # Script is being sourced
    else
        return 1  # Script is being run directly
    fi
}

# Function to send current proccess to background automatically 
script_bg() {
    chk "${BG}" && return 1
    export BG='true'
    "${ARGUMENTS[@]}" &
    disown
    exit 0
}

# Function to check if any given regular file exists and is not empty
chk_fl() {
    local files=("${@}")
    local file

    for file in "${files[@]}"; do
        if chk_var 'file'; then
            if [[ -f "${file}" ]]; then
                if [[ -s "${file}" ]]; then
                    return 0
                fi
            fi
        fi
    done
    return 1
}

# Function to check if an element (value) exists within any given array
chk_el() { 
    local element="${1}"
    shift
    local arrays=("${@}")
    local array_keys=()
    local array_name key value

    for array_name in "${arrays[@]}"; do
        chk_arr "${array_name}" || continue

        eval "array_keys=(\"\${!${array_name}[@]}\")"
        for key in "${array_keys[@]}"; do
            eval "value=\${${array_name}[\${key}]}"
            if [[ "${value}" == "${element}" ]]; then
                chk "${PRINT}" && echo "${key}"
                return 0
            fi
        done
    done
    return 1
}

# Print the key of the element
get_key() {
    local args=("${@}")
    PRINT=true chk_el "${args[@]}"
}

# Function to check if any given path is absolute
is_abs() {
    local paths=("${@}")
    local path

    for path in "${paths[@]}"; do
        if [[ "${path}" == /* ]]; then
            return 0
        fi
    done
    return 1
}

# Function to get absolute path of a file or directory
get_abs() {
    local paths=("${@}")
    local path

    for path in "${paths[@]}"; do
        chk_var 'path' || return 1
        readlink -f "${path}"
    done
}

# Function to get file from file path
get_fl() {
    local paths=("${@}")
    local path

    for path in "${paths[@]}"; do
        chk_var 'path' || return 1
        basename "${path}"
    done
}

# Function to get directory from file path
get_dir() {
    local files=("${@}")
    local file

    for file in "${files[@]}"; do
        chk_var 'file' || return 1
        dirname "${file}"
    done
}

# Function to check if any given directory exists and is not empty
chk_dir() {
    local directories=("${@}")
    local dir files=()

    for dir in "${directories[@]}"; do
        dir="$(get_abs "${dir}")"
        if chk_var 'dir'; then
            if [[ -d "${dir}" ]]; then
                mapfile -t files < <(find "${dir}" -mindepth 1 -print -quit)
                if chk_arr 'files'; then
                    return 0
                fi
            fi
        fi
    done
    return 1
}

# Function to check if any given path contains /
chk_dirlike() {
    local paths=("${@}")
    local path

    for path in "${paths[@]}"; do
        if chk_var 'path'; then
            if [[ "${path}" =~ '/' ]]; then
                return 0
            fi
        fi
    done
    return 1
}

# Global BASH_SOURCE for use in functions and to avoid repeatedly sourcing the same files
declare -g FILE_SOURCES=()
declare -g SOURCED_FILES=()
for src in "${BASH_SOURCE[@]}"; do
    FILE_SOURCES+=("$(get_abs "${src}")")
done

# Function to check if a filename matches any array of extensions, or if the filename has an extension
chk_ext() {
    local file="${1}"
    shift
    local extensions=("${@}")

    if ! chk_arr 'extensions'; then
        if [[ "${file}" == *.* ]]; then
            return 0
        else
            return 1
        fi
    fi

    local extension
    for extension in "${extensions[@]}"; do
        if [[ "${extension}" == .* ]]; then
            extension="${extension##.}"
        fi

        if [[ "${file}" == *."${extension}" ]]; then
            return 0
        fi
    done
    return 1
}

# Function to check if filename belongs in $FILE_SOURCES or $SOURCED_FILES
chk_src() {
    local files=("${@}")
    local file

    for file in "${files[@]}"; do
        if ! is_abs "${file}"; then
            original="$(get_fl "${file}")"
            file="${SRC_DIR}/utils/${original}"
            ! chk_fl "${file}" && file="${file}.sh"
            ! chk_fl "${file}" && file="${SRC_DIR}/utils/$(get_fl "${original}")"
            ! chk_fl "${file}" && file="${file}.sh"
        fi

        if chk_fl "${file}" && chk_el "${file}" 'FILE_SOURCES' 'SOURCED_FILES'; then
            return 0
        fi
    done
    return 1
}

# Function to check if name of a file exists in any given directory
chk_nm() {
    local name="${1}"
    shift
    local directories=("${@}")
    local dir dir_file
    local -a dir_files

    chk_var 'name' || return 1
    name="$(get_fl "${name}")"

    for dir in "${directories[@]}"; do
        chk_dir "${dir}" || continue
        
        # Store all files in the current directory in an array
        mapfile -t dir_files < <(find "${dir}" -type f)

        for dir_file in "${dir_files[@]}"; do
            dir_file="$(get_fl "${dir_file}")"
            if chk_val "${name}" "${dir_file}"; then
                return 0
            fi
        done
    done
    return 1
}

# Function to check if a duplicate of a file exists in any given directory
chk_ex() {
    local file="${1}"
    shift
    local directories=("${@}")
    local dir dir_file

    chk_fl "${file}" || return 1

    for dir in "${directories[@]}"; do
        chk_dir "${dir}" || continue
        while IFS= read -r dir_file; do
            if diff -q "${file}" "${dir_file}" &>/dev/null; then
                return 0
            fi
        done < <(find "${dir}" -type f)
    done
    return 1
}

# Function to check if given content already exists in any given directory
chk_ct() {
    imp file || return 1
    local content="${1}"
    shift
    local directories=("${@}")
    local file dir
    gen_tmp file

    echo "${content}" > "${file}"
    for dir in "${directories[@]}"; do
        chk_ex "${file}" "${dir}" && return 0
    done
    return 1
}

# Function to import custom libraries if not already imported
imp() {
    local files=("${@}")
    local file original

    for file in "${files[@]}"; do
        if ! is_abs "${file}"; then
            original="$(get_fl "${file}")"
            file="${SRC_DIR}/utils/${original}"
            ! chk_fl "${file}" && file="${file}.sh"
            ! chk_fl "${file}" && file="${SRC_DIR}/utils/$(get_fl "${original}")"
            ! chk_fl "${file}" && file="${file}.sh"
        fi

        if chk_fl "${file}"; then
            if ! chk_src "${file}"; then
                SOURCED_FILES+=("${file}")
                source "${file}" "${ARGUMENTS[@]:1}"
            fi
        fi
    done
}

# Function to source files if not already sourced
src() {
    local files=("${@}")
    local file

    for file in "${files[@]}"; do
        file="${SCRIPT_DIR}/${file}"
        ! chk_fl "${file}" && file="${file}.sh"
        if chk_fl "${file}"; then
            imp "${file}"
        fi
    done
}

# Function to get full script source hierarchy from FILE_SOURCES
get_script() {
    local scripts_number="${#FILE_SOURCES[@]}"
    local file base_file script_path

    for file in "${FILE_SOURCES[@]}"; do
        base_file="$(get_fl "${file}" | sed 's/\..*//')"
        script_path+="${base_file}"
        if ! [[ "${file}" == "${FILE_SOURCES[-1]}" ]]; then
            if [[ "${scripts_number}" -ge '5' ]]; then
                script_path+='-'
            else
                script_path+='/'
            fi
        fi
    done
    echo "${script_path}"
}

# Function to get base name of current script
get_bn() {
    local paths=("${@}")
    local path

    for path in "${paths}"; do
        get_fl "${path}" | sed 's/\..*//'
    done
}

# Function to create directories recursively given file paths
crt_dir() {
    local files=("${@}")
    local file dir

    for file in "${files[@]}"; do
        chk_var 'file' || continue
        dir="$(get_dir "${file}")"
        mkdir -p "${dir}"
    done
}

# Function to create files and directories recursively given file paths
crt() {
    local files=("${@}")
    local file

    for file in "${files[@]}"; do
        chk_var 'file' || continue
        crt_dir "${file}"

        if ! [[ -e "${file}" ]]; then
            touch "${file}"
        fi
    done
}

# Function to remove temporary files
rm_tmp() {
    local file 
    local files=()

    if chk_val "${@}"; then
        files=("${@}")
    else
        if chk_arr 'TMP_FILES'; then
            files=("${TMP_FILES[@]}")
        else
            return 1
        fi
    fi

    for file in "${files[@]}"; do
        chk_fl "${file}" && rm -f -- "${file}"
    done
}

# Function to perform cleanup such as removing temporary files
cleanup() {
    imp file
    local args=("${@}")
    local arg file pid
    local files=()

    if chk_arr 'args'; then
        for arg in "${args[@]}"; do
            if chk_rgx "${arg}" 'numbers'; then
                if kill -0 "${arg}" &>/dev/null; then
                    kill "${arg}" &>/dev/null || kill -9 "${arg}" &>/dev/null
                fi
            elif chk_fl "${arg}" || files=("$(get_lk "${arg}")"); then
            chk_arr 'files' || files=("${arg}")
                for file in "${files[@]}"; do
                    if chk_fl "${file}"; then
                        while IFS= read -r pid; do
                            if kill -0 "${pid}" &>/dev/null; then
                                kill "${pid}" &>/dev/null || kill -9 "${pid}" &>/dev/null
                            fi
                        done < "${file}"
                        rm -f -- "${file}"
                    fi
                done
            else
                continue
            fi
        done
        return 0
    else
        rm_tmp
        chk_arr 'LOCK_FILES' && rm_tmp "${LOCK_FILES[@]}"

        # Attempt to gracefully kill background jobs with a timeout of 3 seconds, then forcibly killing it
        if jobs -p &>/dev/null; then
            timeout 3s bash -c 'kill "$(jobs -p)"' &>/dev/null || kill -9 "$(jobs -p)" &>/dev/null
        fi
        exit 0
    fi
}

# Function to output log to a generated file
log() {
    imp file
    local file="${1}"
    local dir="$(gen_dir "${LOG_DIR}")"

    chk_var 'file' "$(gen_fl "${SCRIPT_NAME}" "${dir}")"

    crt "${file}"
    exec > >(tee "${file}") 2>&1
}

# Fetches a list of all users who have a /home folder
get_users() {
    # Array of line numbers to fetch
    local lines=("${@}")
    local users line

    # Get the list of all users with a /home directory
    users=("$(awk -F: '$6 ~ /^\/home\// {print $1}' /etc/passwd)")

    # If no specific lines are provided, output all users
    if ! chk_arr 'lines'; then
        for user in "${users[@]}"; do
            echo "${user}"
        done
        return
    fi

    # Loop through the provided line numbers and fetch the corresponding users
    for line in "${lines[@]}"; do
        # Ensure the line number is valid
        if ((line > 0 && line <= "${#users[@]}")); then
            echo "${users[line-1]}"
        fi
    done
}

run_user() {
    local args=("${@}")
    sudo -E -u "${user}" "${args[@]}"
}

# Check if script is being run as root
if chk_var 'SUDO_USER'; then
    user="${SUDO_USER}"
    home="/home/${user}"
else
    user="${USER}"
    home="${HOME}"
fi

if ! [[ -d "${home}" ]]; then
    imp notifs
    ntf 'critical' 'Home folder does not exist'
    exit 1
fi

readonly BIN_DIR="${home}/Documents/bin"
readonly SRC_DIR="${home}/Documents/src/sh"
readonly DWN_DIR="${home}/Downloads"
readonly LOG_DIR="${home}/Documents/logs"
readonly DICT_DIR='/usr/share/dict'
readonly TMP_DIR='/tmp'
readonly FIRST_DAY='Monday' # To maintain compability with ISO 8601
readonly SCRIPT_NAME="$(get_bn "${ARGUMENTS[0]}")"
readonly SCRIPT_DIR="$(get_dir "$(get_abs "${ARGUMENTS[0]}")")"
readonly LOCAL_DIR="${home}/.local/share/${SCRIPT_NAME}"
readonly CONFIG_DIR="${home}/.config/${SCRIPT_NAME}"
readonly LOCK_DIR="${LOCAL_DIR}/lock"

export BIN_DIR SRC_DIR DWN_DIR LOG_DIR DICT_DIR TMP_DIR FIRST_DAY SCRIPT_NAME SCRIPT_DIR LOCAL_DIR CONFIG_DIR LOCK_DIR
declare -ga TMP_FILES
declare -ga LOCK_FILES

# Cleanup before exiting
trap 'cleanup' SIGINT SIGTERM SIGQUIT SIGHUP SIGPIPE EXIT

# Start logging
log

if chk_intr; then
    imp arr rand date scr file input sound notifs

    if chk_val "${1}"; then
        eval "${@}"
        exit
    fi

    while true; do
        echo -n "[GeOS] ${PWD} >>> "
        read -r prompt || cleanup

        case "${prompt}" in
        'help')
            echo 'Help has arrived'
            ;;
        'exit' | 'break')
            cleanup
            ;;
        '')
            ;;
        *)
            eval "${prompt}"
            ;;
        esac
    done
fi
