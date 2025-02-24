#!/usr/bin/env bash
# A CLI tool for all your past paper needs

source /usr/lib/geos/core.sh
src rand arr notifs args file

# Get files
mkdir -p "${LOCAL_DIR}"
paper_history="${LOCAL_DIR}/history"
boards_file="${LOCAL_DIR}/boards"
papers_dir="${HOME}/Documents/Past Papers"
display_tree='true'

# Define arguments
declare -A argument_keys=(
    ['paper_types']='next:0,type:typ,t,Specify the paper type(s)'
    ['paper_boards']='next:0,board:brd,b,Specify the board name(s)'
    ['paper_operation']='next:1,operation:opr,o,Specify the operation to be performed'
    ['paper_dirs']='next:0,dir,d,Specify directories'
    ['paper_indices']='next:0,index:idx,i,Specify the index range'
    ['content_viewer']='next:0,viewer:viw,v,Specify the content (typically PDF) viewer'
    ['paper_extension']='next:0,extension:ext,e,Specify the extension for the paper'
)

# Info for help
export ARGUMENT_DEFAULTS="${SCRIPT_NAME} -t qp -b cie -o query -d \$PWD -i all -v DEFAULT -e pdf"
export ARGUMENT_USAGE="${SCRIPT_NAME} [OPTIONS] [PAPER INDICES] [DIRS]"
export VERSION='1.1.1'
export SCRIPT_SOURCE="$(get_script)"

# Serialize array
ser_arr 'argument_keys' 'argument_keys_serialized'
ser_arr 'ARGUMENTS' 'arguments_serialized'

# Get arguments
get_args "${argument_keys_serialized}" "${arguments_serialized}"

# Kill if needed
if chk "${kill_state}"; then
    rm_lk
    cleanup
fi

# Define valid data
boards=('cie' 'oxford' 'edexcel')
operations=('query' 'increment' 'decrement' 'open' 'move')
paper_types=('qp' 'ms' 'ab' 'in' 'pm' 'sp' 'sm' 'gt' 'er' 'ab')

# Validate data
chk_el -d "${paper_types[@]}" 'valid_types'
chk_el -d "${paper_boards[@]}" 'valid_boards'
chk_el -d "${paper_extensions[@]}" 'valid_extensions'

# Find full extension data
paper_extensions_app=()
for paper_extension in "${paper_extensions[@]}"; do
    paper_extensions_app+="$(get_ext "${paper_extension}")"
done

# Get default viewer
default_content_viewer_desktop="$(xdg-mime query default "${paper_extension_full}")"
default_content_viewer="$(get_exec "${default_content_viewer_desktop}")"
