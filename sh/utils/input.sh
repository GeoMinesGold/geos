# A collection of bash utilities to store input
# Requires main_utils

declare -gA buffers

# Get user input using rofi
get_input() {
    local prompt="${1}"
    local msg="${2}"

    chk_var 'prompt' 'Enter your input'

    rofi -dmenu -p "${prompt}" -mesg "${msg}" -theme '/usr/share/rofi/themes/Arc-Dark.rasi'
}

# Get clipboard
get_clipboard() {
    xclip -o -sel clipboard 2>/dev/null | tr -d "\n"
}

# Get mouse selection
get_selection() {
    xclip -o -sel primary 2>/dev/null | tr -d "\n"
}

# Get specified buffers
get_buffers() {
    local selected_buffers=("${@}")

    chk_el 'input' 'selected_buffers' && buffers['input']="$(get_input)"
    chk_el 'selection' 'selected_buffers' && buffers['selection']="$(get_selection)"
    chk_el 'clipboard' 'selected_buffers' && buffers['clipboard']="$(get_clipboard)"
}

# Loop through buffers to prioritize the foremost non-empty variable
get_buffer() {
    local buffer_names=("${@}")

    for buffer_name in "${buffer_names[@]}"; do
        if chk_val "${buffers["${buffer_name}"]}"; then
            echo "${buffer_name}" 
            return 0 
        fi
    done
}
