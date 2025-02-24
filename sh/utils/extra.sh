# Requires main_utils

# Function to check if any given function exists
chk_func() {
    local funcs=("${@}")
    local func

    for func in "${funcs[@]}"; do
        if declare -F "${func}" &>/dev/null; then
            return 0
        fi
    done
    return 1
}

# Function to check if a file is a symlink and the original file is not empty
chk_sym() {
    local links=("${@}")
    local link

    for link in "${links[@]}"; do
        if chk_var 'link'; then
            if [[ -L "${link}" ]]; then
                local target="$(get_abs "${link}")"
                chk_fl "${target}" && return 0
            fi
        fi
    done
    return 1
}

# Function to check if an alias exists
chk_al() {
    local aliases=("${@}")
    local alias_name

    for alias_name in "${aliases[@]}"; do
        if alias "${alias_name}" &> /dev/null; then
            return 0
        fi
    done
    return 1
}

# Function to approximate a number
rnd() {
    local number="${1}"
    local decimal_places="${2}"
    
    # Check if decimal_places exists
    chk_var 'decimal_places' '3'

    # Check if decimal_places is a positive integer
    chk_rgx "${decimal_places}" 'positive_numbers' || return 1

    # Perform the rounding
    local rounded="$(echo "scale=$((decimal_places + 1)); ${number}" | bc)"
    local formatted="$(echo "${rounded}" | awk -v dp="${decimal_places}" '{printf "%.*f", dp, $0}')"

    # Output the rounded number
    echo "${formatted}"
}
