# Requires main_utils

# Function to check if a key exists within an array and print its value
chk_key() { 
    local element="${1}"
    shift
    local arrays=("${@}")
    local array_keys=()
    local array_name key value

    for array_name in "${arrays[@]}"; do 
        chk_arr "${array_name}" || continue

        eval "array_keys=(\"\${!${array_name}[@]}\")"
        for key in "${array_keys[@]}"; do
            if [[ "${key}" == "${element}" ]]; then
                if chk "${PRINT}"; then
                    eval "value=\${${array_name}[\${key}]}"
                    echo "${value}"
                fi
                return 0
            fi
        done
    done
    return 1
}

get_el() {
    local args=("${@}")
    PRINT=true chk_key "${args[@]}"
}

# Function to get the next or previous element in an array
get_arr_el() {
    if chk_val "${3}"; then
        local position="${1}"
        local current_element="${2}"
        local array_name="${3}"
    else
        local current_element="${1}"
        local array_name="${2}"
    fi

    local array_keys=()
    local key index value

    # Check if the array exists and is not empty
    chk_arr "${array_name}" || return 1
   
    # Check position value
    chk_var 'position' '1'
    chk_rgx "${position}" 'numbers' || return 1
    chk "${PREV}" && position="-${position}"

    # Get array keys
    eval "array_keys=(\"\${!${array_name}[@]}\")"

    # Iterate through the array keys to find the current element
    for key in "${array_keys[@]}"; do
        eval "value=\${${array_name}[\${key}]}"
        if [[ "${value}" == "${current_element}" ]]; then
            # Calculate index (with wrap-around)
            index="$(( (key + position) % ${#array_keys[@]} ))"
            eval "echo \${${array_name}[\${index}]}"
            return 0
        fi
    done
    # If the element is not found, return the first element
    eval "echo \${${array_name}[0]}"
    return 0
}
nxt_el() {
    local args=("${@}")
    get_arr_el "${args[@]}"
}

prev_el() {
    local args=("${@}")
    PREV=true get_arr_el "${args[@]}"
}

# Function to remove empty values from an array
rm_vals() {
    local non_empty_vals=()
    local arrays="${@}"
    local val array_name

    for array_name in "${arrays[@]}"; do
        # Check if the array exists and is not empty
        chk_arr "${array_name}" || return 1

        # Loop through all elements in the array
        eval "for val in \"\${${array_name}[@]}\"; do
            if chk_val \"\${val}\"; then
                non_empty_vals+=(\"\${val}\")
            fi
        done"

        # Reassign the array with non-empty values
        eval "${array_name}=(\"\${non_empty_vals[@]}\")"
    done
}

# Function to serialize an array into a string
ser_arr() {
    local array_name="${1}"
    local var_name="${2}"
    local seperator="${3}"
    local line_seperator="${4}"
    local -n array_ref="${array_name}"  # Use nameref to reference the array
    local serialized_string key

    chk_var 'array_name' || return 1
    chk_var 'seperator' '='
    chk_var 'line_seperator' ';'

    for key in "${!array_ref[@]}"; do
        serialized_string+="${key}${seperator}${array_ref["${key}"]}${line_seperator}"
    done
    serialized_string="${serialized_string%%${line_seperator}}"

    if chk_var 'var_name'; then
        eval "${var_name}='${serialized_string}'"
    else
        echo "${serialized_string}"
    fi
}

# Function to parse a serialized string into an array
prs_arr() {
    local serialized_string="${1}"
    local array_name="${2}"
    local seperator="${3}"
    local line_seperator="${4}"
    local -n array_ref="${array_name}"  # Use nameref to reference the array
    local key value entry entries=()

    chk_var 'array_name' || return 1
    chk_var 'seperator' '='
    chk_var 'line_seperator' ';'

    # Extract and parse the serialized string
    IFS="${line_seperator}" read -r -a entries <<< "${serialized_string}"

    for entry in "${entries[@]}"; do
        chk_var 'entry' || continue
        IFS="${seperator}" read -r key value <<< "${entry}"
        chk_var 'key' || continue
        chk_var 'value' || continue
        if ! chk_arr "${array_name}"; then
            if chk_rgx "${key}" 'positive_numbers'; then
                declare -ag "${array_name}"
            else
                declare -Ag "${array_name}"
            fi
        fi
        array_ref["${key}"]="${value}"
    done
}
