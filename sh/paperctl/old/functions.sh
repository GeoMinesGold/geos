#!/usr/bin/env bash

# Get details about each past paper
get_paper() {
    local files=("${@}")
    local file s

    chk_var 's' ':'

    for file in "${files[@]}"; do
    local name board level code day month year type number variant

        file="$(get_fl "${file}")"
        if [[ "${file,,}" =~ ^([0-9]{4})_(m|s|w|y)([0-9]{2})_([a-z]{2})_?([0-9])?([0-9])?.*\.pdf$ ]]; then
            board='CIE'
            code="${BASH_REMATCH[1]}"
            month="${BASH_REMATCH[2]}"
            year="${BASH_REMATCH[3]}"
            type="${BASH_REMATCH[4]}"
            number="${BASH_REMATCH[5]}"
            variant="${BASH_REMATCH[6]}"
        elif [[ "${file,,}" =~ ^(mark.*|question.*|examiner.*)-(paper|unit)([a-z0-9]+)\(([a-z0-9]+)\)(\(legacy\)|-?paper[a-z0-9]+)?-([a-z]+)([0-9]{4}).*\.pdf$ ]]; then
            board='Edexcel'
            type="${BASH_REMATCH[1]}"
            number="${BASH_REMATCH[3]^^}"
            code="${BASH_REMATCH[4]^^}"
            month="${BASH_REMATCH[6]}"
            year="${BASH_REMATCH[7]}"
        elif [[ "${file,,}" =~ ^([a-z0-9]+)_([a-z0-9]+)_(que|msc|rms|pef)_([0-9]+).*\.pdf$ ]]; then
            board='Edexcel'
            code="${BASH_REMATCH[1]^^}"
            number="${BASH_REMATCH[2]^^}"
            type="${BASH_REMATCH[3]}"
            IFS='-' read -r year month day <<< "$(awk '{print substr($0,1,4) "-" substr($0,5,2) "-" substr($0,7,2)}' <<< "${BASH_REMATCH[4]}")"
        elif [[ "${file,,}" =~ ^([0-9]{2}[a-z])-igcse-maths-([a-z0-9]+)-([a-z0-9]+)-(may|november|june|january)-([0-9]{4})-(mark-scheme|examination-paper).*\.pdf$ ]]; then
            board='Edexcel'
            code="${BASH_REMATCH[2]^^}"
            number="${BASH_REMATCH[3]^^}"
            month="${BASH_REMATCH[4]}"
            year="${BASH_REMATCH[5]}"
            type="${BASH_REMATCH[6]}"
        else
            return 1
        fi
        chk_var 'code' && IFS=':' read level name <<< "$(grep "${code}" "${boards_file}" | grep "${board}" | head -n 1 | cut -d ':' -f 2-3)"

        if chk "${human}"; then
            echo -e "File name: ${file}\nName: ${name}\nBoard: ${board}\nLevel: ${level}\nCode: ${code}\nDay: ${day}\nMonth: ${month}\nYear: ${year}\nType: ${type}\nNumber: ${number}\nVariant: ${variant}"
        else
            echo "${file}${s}${name}${s}${board}${s}${level}${s}${code}${s}${day}${s}${month}${s}${year}${s}${type}${s}${number}${s}${variant}"
        fi
    done
}

get_paper_type() {
    if [[ "${1}" == 'short' ]]; then
        local short='true'
        shift
    fi
    local types=("${@}")
    local type

    for type in "${types[@]}"; do
        case "${type,,}" in
            'qp' | 'que' | 'questionpaper' | 'question paper' | 'examiner-paper' | 'examination-paper' | 'sp' | 'specimen' | 'specimen question paper' | 'specimen paper') chk "${short}" && type='qp' || type='Question Paper' ;;
            'ms' | 'msc' | 'rms' | 'markscheme' | 'mark scheme' | 'mark-scheme' | 'sm' | 'specimen mark scheme') chk "${short}" && type='ms' || type='Mark Scheme' ;;
            'in' | 'insert' | 'inserts') chk "${short}" && type='in' || type='Inserts' ;;
            'pm' | 'pre-release' | 'prerelease') chk "${short}" && type='pm' || type='Pre-release Materials' ;;
            'gt' | 'grade threshold' | 'grade thresholds') chk "${short}" && type='gt' || type='Grade Thresholds' ;;
            'er' | 'pef' | 'examinerreport' | 'examinerreports' | 'examiner report' | 'examiner reports') chk "${short}" && type='er' || type='Examiner Report' ;;
            'ab' | 'answer' | 'answers' | 'booklet' | 'formula' | 'formula sheet' | 'sheet') chk "${short}" && type='ab' || type='Answer Booklet' ;;
        esac
        echo "${type}"
    done
}

get_paper_month() {
    case "${1}" in
        'num' | 'digits' | 'numerical' | '0' | '1') local num='true' && shift ;;
        'short' | '-') local short='true' && shift ;;
    esac

    local months=("${@}")
    local month


    for month in "${months[@]}"; do
        case "${month,,}" in
            '01' | '1' | 'jan' | 'january') chk "${num}" && month='01' || chk "${short}" && month='Jan' || month='January' ;;
            '02' | '2' | 'feb' | 'february') chk "${num}" && month='02' || chk "${short}" && month='Feb' || month='February' ;;
            '03' | '3' | 'mar' | 'march') chk "${num}" && month='03' || chk "${short}" && month='Mar' || month='March' ;;
            '04' | '4' | 'apr' | 'april') chk "${num}" && month='04' || chk "${short}" && month='Apr' || month='April' ;;
            '05' | '5' | 'may') chk "${num}" && month='05' || month='May' ;;
            '06' | '6' | 'jun' | 'june') chk "${num}" && month='06' || chk "${short}" && month='Jun' || month='June' ;;
            '07' | '7' | 'jul' | 'july') chk "${num}" && month='07' || chk "${short}" && month='Jul' || month='July' ;;
            '08' | '8' | 'aug' | 'august') chk "${num}" && month='08' || chk "${short}" && month='Aug' || month='August' ;;
            '09' | '9' | 'sep' | 'sept' | 'september') chk "${num}" && month='09' || chk "${short}" && month='Sep' || month='September' ;;
            '10' | 'oct' | 'october') chk "${num}" && month='10' || chk "${short}" && month='Oct' || month='October' ;;
            '11' | 'nov' | 'november') chk "${num}" && month='11' || chk "${short}" && month='Nov' || month='November' ;;
            '12' | 'dec' | 'december') chk "${num}" && month='12' || chk "${short}" && month='Dec' || month='December' ;;
            *)
                case "${paper_board,,}" in
                    'cie' | *)
                        case "${month,,}" in
                            'm' | 'y') month='Feb-March' ;;
                            's') month='May-June' ;;
                            'w') month='Oct-Nov' ;;
                        esac
                esac
                ;;
        esac
        echo "${month}"
    done
}

# Open file using default viewer
view_file() {
    local args=("${@}")
    "${content_viewer}" "${args[@]}" &>/dev/null
}

# Function to display directory tree structure based on moved files
display_tree() {
    if chk_fl "${treedir_file}"; then
        echo "Tree structure:"
        create_tree "${treedir_file}"
    else
        msg 'critical' "Temporary directory file doesn't exist"
        return 1
    fi
}
