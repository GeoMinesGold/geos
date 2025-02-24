#!/usr/bin/env bash
# A CLI tool for all your past paper needs

# Source custom core utils
source /usr/lib/geos/core.sh

# Import necessary libraries (complement to core)
imp rand arr notifs args file

# Source project files
src functions

# Get files
mkdir -p "${LOCAL_DIR}"
paper_history="${LOCAL_DIR}/history"
boards_file="${LOCAL_DIR}/boards"
papers_dir="${HOME}/Documents/Past Papers"
display_tree='true'

# Script information
export ARGUMENT_DEFAULTS="${SCRIPT_NAME} -t qp -b cie -o query -d \$PWD -i all -v DEFAULT -e pdf"
export ARGUMENT_USAGE="${SCRIPT_NAME} [OPTIONS] [PAPER INDICES] [DIRS]"
export VERSION='1.1.1'
export SCRIPT_SOURCE="$(get_script)"

# Define arguments
declare -A argument_keys=(
    ['paper_type']='next:0,type:typ,t,Specify the paper type'
    ['paper_board']='next:0,board:brd,b,Specify the board name'
    ['paper_operation']='next:1,operation:opr,o,Specify the operation to be performed'
    ['paper_dir']='next:0,dir,d,Specify directory'
    ['paper_index']='next:0,index:idx,i,Specify the index range'
    ['content_viewer']='next:0,viewer:viw,v,Specify the content (typically PDF) viewer'
    ['paper_extension']='next:0,extension:ext,e,Specify the extension for the paper'
)

# Serialize arrays into variables
ser_arr 'argument_keys' 'argument_keys_serialized'
ser_arr 'ARGUMENTS' 'arguments_serialized'

# Get arguments
get_args "${argument_keys_serialized}" "${arguments_serialized}"

# Kill script if needed
if chk "${kill_state}"; then
    rm_lk
    cleanup
fi

# Define valid data
boards=('cie' 'oxford' 'edexcel')
operations=('query' 'increment' 'decrement' 'open' 'move')
paper_types=('qp' 'ms' 'ab' 'in' 'pm' 'sp' 'sm' 'gt' 'er' 'ab')

# Define default data
default_board='cie'
default_operation='query'
default_paper_type='qp'

# Validate paper_type
paper_type="${paper_type,,}"
chk_el "${paper_type}" 'paper_types' || { chk_var 'paper_type' && msg "Unexpected value for paper_type: ${paper_type}, defaulting to ${default_paper_type}"; paper_type="${default_paper_type}"; }

# Validate paper_board
paper_board="${paper_board,,}"
chk_el "${paper_board}" 'boards' || { chk_var 'paper_board' && msg "Unexpected value for paper_board: ${paper_board}, defaulting to ${default_board}"; paper_board="${default_board}"; }

# Validate extension
chk_var 'paper_extension' 'pdf'
paper_extension_full="$(get_ext "${paper_extension}")"

# Get default viewer
default_content_viewer_desktop="$(xdg-mime query default "${paper_extension_full}")"
default_content_viewer="$(get_exec "${default_content_viewer_desktop}")"

# Validate paper_operation
paper_operation="${paper_operation,,}"
chk_el "${paper_operation}" 'operations' || { chk_var 'paper_operation' && msg "Unexpected value for paper_operation: ${paper_operation}, defaulting to ${default_operation}"; paper_operation="${default_operation}"; }

input_dirs=()
# Check if input was given as an argument
for file in "${FILES[@]}"; do
    if chk_rgx "${file}" 'numbers' 'range' || chk_val "${file}" 'all' '-'; then
        paper_index+=("${file}")
        paper_operation='open'
    else
        input_dirs+=("${file}")
    fi
done

# Get input_dirs
if chk_val "${paper_operation}" 'open' 'query'; then
    for input_dir in "${input_dirs[@]}"; do
        mapfile -O "${#all_papers[@]}" -t all_papers < <(find "${input_dir}" -mindepth 1 -type f -name "*.${paper_extension}" | sort)
    done
fi

# Check if paper_dir exists
if ! chk_arr 'paper_dir' && ! chk_arr 'input_dirs'; then
    paper_dir=("${PWD}")
fi

# Get paper_dir
if chk_val "${paper_operation}" 'open' 'query'; then
    for dir in "${paper_dir[@]}"; do
        case "${dir}" in
            'current' | 'pwd') 
                dir="${PWD}" ;;
            'last' | 'latest')
                if chk_fl "${paper_history}"; then
                    dir="${papers_dir}/$(awk -F ':' 'END {print $3}' "${paper_history}")"
                else
                    msg 'History file is empty'
                    continue
                fi
                ;;
        esac
        mapfile -O "${#all_papers[@]}" -t all_papers < <(find "${dir}" -mindepth 1 -type f -name "*.${paper_extension}" | sort)
    done
fi

temp_papers=()
for paper in "${all_papers[@]}"; do
    details="$(get_paper "${paper}")"
    IFS=':' read -r file name board level code day month year type number variant <<< "${details}"
    type="$(get_paper_type short "${type}")"

    if [[ "${type}" == "${paper_type}" ]]; then
        temp_papers+=("${paper}")
    fi
done
all_papers=("${temp_papers[@]}")
papers_count="${#all_papers[@]}"
temp_papers=()

new_paper_index=()
chk_arr 'paper_index' || paper_index=('all')
for idx in "${paper_index[@]}"; do
    case "${idx}" in
        'last' | 'latest')
            new_paper_index+=("$(awk -F ':' 'END {print $2}' "${paper_history}")")
            ;;
        '' | 'all' | '-') 
            new_paper_index+=("0-$((papers_count-1))")
            ;;
        'get' | 'find')
            compare_file="$(awk -F ':' 'END {print $4}' "${paper_history}")"
            dir="$(get_dir "$(get_dir "${compare_file}")")"

            type="$(get_paper_type "${paper_type}")"

            file="$(find "${dir}/${type}" -type f | head -n 1)"
            papers+=("${file}")
            idx="$(get_key "${file}" 'all_papers')"
            new_paper_index+=("${idx}")
            ;;
        *)
            new_paper_index+=("${idx}")
            ;;
    esac
done
paper_index=("${new_paper_index[@]}")

# Validate paper_index
for idx in "${paper_index[@]}"; do
    if chk_rgx "${idx}" 'range'; then
        read -r start_index end_index <<< "$(awk -F '-' '{print $1, $2}' <<< "${idx}")"
    elif chk_rgx "${idx}" 'positive_numbers'; then
        start_index="${idx}"
        end_index="${idx}"
    elif chk_rgx "${idx}" 'negative_numbers'; then
        start_index="$((papers_count-1-paper_index))"
    else
        msg "Unexpected value for paper_index: ${idx}, must be an integer or a range of integers"
        exit 1
    fi

    # Check if range is reversed
    if [[ "${start_index}" -gt "${end_index}" ]]; then
        temp_end_index="${end_index}"
        end_index="${start_index}"
        start_index="${temp_end_index}"
    fi

    # Check if start and end indexes exist
    chk_var 'start_index' '0'
    chk_var 'end_index' "$((papers_count-1))"

    for ((i=start_index; i<=end_index; i++)); do
        papers+=("${all_papers["${i}"]}")
    done
done

# Validate content_viewer
if ! chk_var 'content_viewer'; then
    case "${paper_type}" in
        'qp' | 'sp')
            content_viewer="${default_content_viewer}"
            ;;
        *)
            content_viewer='zathura'
            ;;
    esac
fi

# Perform operation on paper from papers array
case "${paper_operation}" in
    'open')
        chk_lk && chk_val "${paper_type}" 'qp' && exit
        lk
        for paper in "${papers[@]}"; do
            idx="$(get_key "${paper}" 'papers')"
            view_file "${paper}" &
            pid="${!}"
            echo "${idx}:${paper}" >> "${paper_history}"
            wait "${pid}"
        done
        ;;
    'query')
        i='0'
        for paper in "${papers[@]}"; do 
            short_paper="${paper#${paper_dir}/}"
            echo "$(get_key "${paper}" 'all_papers'): ${short_paper}"
            ((i++))
        done
        ;;
    'move') 
        chk_lk && exit
        lk
        ! chk_fl "${boards_file}" && ntf 'Boards file is empty' && exit 1
        gen_tmp treedir_file results_file

        files=()
        for input_dir in "${input_dirs[@]}"; do
            mapfile -t dir_files < <(find "${input_dir}" -type f)
            files+=("${dir_files[@]}")
        done
        files_number="${#files[@]}"

        if ! chk_arr 'files'; then
           ntf 'All directories are empty' && exit 1
        fi

        for file in "${files[@]}"; do
            file_type="$(file -b --mime-type "${file}")"
            if ! chk_val "${file_type}" 'application/pdf' && [[ "${file}" =~ ^.*\.pdf$ ]]; then 
                echo 'Files that are not valid PDF documents' >> "${results_file}"
                msg "File '${file}' is not a valid PDF document"
                continue
            fi

            details="$(get_paper "${file}")"

            if ! chk_var 'details'; then
                msg "File '${file}' doesn't match any naming convention"
                echo "Files that don't match the naming convention" >> "${results_file}"
                continue
            fi

            IFS=':' read -r file name board level code day month year type number variant <<< "${details}"
            chk "${verbose_output}" && msg "File details: ${details}"

            if ! chk_var 'board'; then
                msg "No board found for file '${file}'"
                echo "Files with no board" >> "${results_file}"
                continue
            fi

            if ! chk_var 'name'; then
                msg "No subject name found for file '${file}'"
                echo "Files with no subject name" >> "${results_file}"
                continue
            fi

            if ! chk_var 'level'; then
                msg "No level found for file '${file}'"
                echo "Files with no level" >> "${results_file}"
                continue
            fi

            if ! chk_var 'month'; then
                msg "No month found for file '${file}'"
                echo "Files with no month" >> "${results_file}"
                continue
            fi

            if ! chk_var 'year'; then
                msg "No year found for file '${file}'"
                echo "Files with no year" >> "${results_file}"
                continue

            fi

            if ! chk_var 'type'; then
                msg "No paper type found for file '${file}'"
                echo "Files with no paper type" >> "${results_file}"
                continue

            fi

            if ! chk_var 'number'; then 
                if chk_var 'variant'; then
                    number="${variant}"
                    variant=
                else
                    number='01'
                    variant='01'
                fi
            fi

            if ! chk_var 'variant'; then
                variant='1'
            fi

            if chk_rgx "${month}" 'numbers' && ! [[ "${month}" == 0* ]]; then
                month="$(printf "%02d" "${month}")"
            fi

            month="$(get_paper_month "${month}")"
            type="$(get_paper_type "${type}")"

            if [[ "${year}" =~ ^[0-9]{2}$ ]]; then
                year="20${year}"
            fi

            if chk_rgx "${number}" 'numbers' && ! [[ "${number}" == 0* ]]; then
                number="$(printf "%02d" "${number}")"
            fi

            if chk_rgx "${variant}" 'numbers' && ! [[ "${variant}" == 0* ]]; then
                variant="$(printf "%02d" "${variant}")"
            fi

            dir="$(rm_slash "${papers_dir}/${board}/${level}/${name}/Code ${code}/Paper ${number}/${year}/${month}/Variant ${variant}/${type}")"

            if chk "${dry_run}"; then
                msg "Dry run: Would move file '${file}' to '${dir}'"
                echo "${dir}/${file}" >> "${treedir_file}"
                echo 'Successful dry-run' >> "${results_file}"
            else
                mkdir -p "${dir}"
                if ! chk_nm "${file}" "${dir}" || chk "${force_state}"; then
                    mv -f "${file}" "${dir}"
                    msg "Moved file '${file}' to '${dir}'"
                    echo "${dir}/${file}" >> "${treedir_file}"
                    echo 'Files moved successfully' >> "${results_file}"
                else
                    msg "File '${file}' already exists in '${dir}'"
                    echo 'Files that already exist' >> "${results_file}"
                fi
            fi
        done

        # Evaluate results
        declare -A counts
        while IFS= read -r line; do
        ((counts["${line}"]++))
        done < "${results_file}"

        # Display tree if enabled
        chk "${display_tree}" && echo -e '\n' && display_tree

        # Output results
        echo -e '\nResults:'
        for key in "${!counts[@]}"; do
            echo "${key}: ${counts[${key}]}"
        done
esac

# reverse_count=$((end_index-i-1))
