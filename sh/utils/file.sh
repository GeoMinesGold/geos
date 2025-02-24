# Requires main_utils, rand_utils, screen_utils and date_utils
imp date rand scr

# Function to remove extra slashes (two or more) and the trailing slash if any
rm_slash() {
    local path="${1}"
    path="$(sed -E 's:/+:/:g' <<< "${path}")"
    path="${path%/}"
    echo "${path}"
}

# Function to get full extension for any given file or filename extension
get_ext() {
    local files=("${@}")
    local file

    for file in "${files[@]}"; do
        if [[ "${file}" =~ '.' ]]; then
            chk_fl "${file}" && file -b --mime-type "${file}" || msg "File '${file}' does not exist"
        else
            grep -P "^\S+\s+\S*(\s|^)${file}(\s|$)" /etc/mime.types | head -n 1 | awk '{print $1}'
        fi
    done
}

# Function to get executable path from a desktop file
get_exec() {
    local files=("${@}")
    local file executable

    for file in "${files[@]}"; do
        chk_fl "${file}" || file="$(find /usr/share/applications/ ${HOME}/.local/share/applications/ -name "${file}" | head -n 1)"
        if ! [[ -e "${file}" ]]; then
            return 1
        fi
        executable="$(grep '^Exec=' "${file}" | sed 's/^Exec=//' | awk '{print $1}')"
        echo "${executable}"
    done
}

# Function to generate random filename for temporary directory and keep track of the temporary file
gen_tmp() {
    local vars=("${@}")
    local name name_seperator ext ext_seperator var result tmp_dir

    chk_var 'TMP' || local TMP='true'
    chk_var 'ECHO'  || local ECHO='false'
    chk_var 'SET' || local SET='true'
    chk_var 'NAME' && name="${NAME%%.*}" && ext="${NAME#*.}" && chk_val "${ext}" "${NAME}" && ext=
    chk_var 'EXT' && ext="${EXT}" 
    (! chk_var 'ext' && chk_var 'SCRIPT_NAME') && ext="${SCRIPT_NAME}"

    chk_var 'name' && name_seperator='_'
    chk_var 'ext' && ext_seperator='.'
    
    chk_var 'DIR' && tmp_dir="${DIR}"
    chk_var 'tmp_dir' "${TMP_DIR}"

    chk_arr 'vars' || { local ECHO='true'; local SET='false'; vars+='ECHO'; }

    for var in "${vars[@]}"; do
        result="$(rm_slash "${tmp_dir}/${name}${name_seperator}$(gen)${ext_seperator}${ext}")"
        chk "${ECHO}" && echo "${result}"
        chk "${SET}" && eval "${var}='${result}'"
        chk "${TMP}" && TMP_FILES+=("${result}")
    done

}

# Function to generate random filename for temporary lock file and keep track of the lock file
gen_lk() {
    local vars=("${@}")
    local lock_dir result var

    chk_var 'ECHO'  || local ECHO='false'
    chk_var 'SET' || local SET='true'
    chk_var 'LOCK' || local LOCK='true'
    chk_var 'DIR' && lock_dir="${DIR}"
    chk_var 'lock_dir' "${LOCK_DIR}"

    chk_arr 'vars' || { local ECHO='true'; local SET='false'; vars+='ECHO'; }
    for var in "${vars[@]}"; do
        result="$(ECHO='true' SET='false' TMP='false' DIR="${lock_dir}" NAME="${SCRIPT_NAME}.lck" gen_tmp "${var}")"
        chk "${ECHO}" && echo "${result}" || eval "${var}='${result}'"
        chk "${SET}" && eval "${var}='${result}'"
        chk "${LOCK}" && LOCK_FILES+=("${result}")
    done
}

# Function to check if a lock file generated by gen_lk exists for a given script name
chk_lk() {
    local scripts=("${@}")
    local script file lock_dir found
    local lock_files=()

    chk_arr 'scripts' || scripts=("${SCRIPT_NAME}")

    chk_var 'PRINT' 'false'
    chk "${PRINT}" && RETURN='false'
    chk_var 'RETURN' 'true'

    found='false'
    for script in "${scripts[@]}"; do
        script="$(get_fl "${script}")"
        lock_dir="${LOCK_DIR}"
        mapfile -t lock_files < <(find "${lock_dir}" -type f)
        for file in "${lock_files[@]}"; do
            file_name="$(get_fl "${file}")"
            if [[ "${file_name}" =~ ^"${script}"_[a-zA-Z0-9]+\.lck$ ]]; then
                found='true'
                chk "${PRINT}" && echo "${file}"
                chk "${RETURN}" && return 0
            fi
        done
    done
    chk "${found}" && return 0 || return 1
}

# Function to get all lock files generated by gen_lk for a given script name
get_lk() {
    local scripts=("${@}")
    PRINT='true' chk_lk "${scripts[@]}"
}

# Function to create a lock file with the current script's PID and the child proccess'
lk() {
    local file

    gen_lk file
    crt "${file}"
    ps -o 'pid:1=' --pid "${$}" --ppid "${$}" > "${file}"
}

# Function to remove lock file for given script
rm_lk() {
    local scripts=("${@}")
    local script
    local files=()
    chk_arr 'scripts' || scripts=("${SCRIPT_NAME}")

    for script in "${scripts[@]}"; do
        files=("$(get_lk "${script}")")
        cleanup "${files[@]}"
    done


}

# Function to generate directory structure using date and custom inputs
gen_dir() { 
    local result
    if chk_val "${1}" && (! chk_dirlike "${1}" || chk_val "${2}"); then
        local dir_name="${1}" 
        shift
    fi

    local dest_dir="$(get_abs "${1}")"
    chk_var 'dest_dir' "${HOME}"

    if chk "${SHORT}"; then
        result="$(rm_slash "${dest_dir}/${dir_name}/$(get_year)$(get_month)$(get_day)")"
    elif chk "${LONG}"; then
        result="$(rm_slash "${dest_dir}/${dir_name}/Year $(get_year)/$(get_month_name)/Week $(get_week)/Day $(get_day)")"
    elif chk "${TIME}"; then
        result="$(rm_slash "${dest_dir}/${dir_name}/$(get_date) $(get_hour):$(get_minute):$(get_second)")"
    else
        result="$(rm_slash "${dest_dir}/${dir_name}/$(get_date)")"
    fi

    echo "${result}"
} 

# Function to generate file using date and custom inputs
gen_fl() { 
    local name date ext name_seperator ext_seperator result i
    chk_var 'TMP' 'true'
    local win="$(get_win)"
    chk_var 'win' 'Desktop'

    if chk_val "${1}" && (! chk_dirlike "${1}" || chk_val "${2}"); then
        if [[ "${1}" == *.* ]]; then
            name="${1%%.*}"
            ext="${1#*.}"
        else
            ext="${1}" 
        fi
        shift
    fi

    chk_var 'name' && name_seperator=' '

    chk_var 'ext' && ext_seperator='.'

    local dir="${1}"
    chk_var 'dir' "$(gen_dir)"

    if chk "${SHORT}"; then
        date="$(get_year)$(get_month)$(get_day)T$(get_hour)$(get_minute)$(get_second)"
    elif chk "${LONG}"; then
        date="$(get_date) $(get_time)"
    else
        date="$(get_year)-$(get_month)-$(get_day) $(get_time)"
    fi
    local result="$(rm_slash "${dir}/${name^}${name_seperator}${win^} ${date} [$(gen '8')]${ext_seperator}${ext}")"

    echo "${result}"
}
