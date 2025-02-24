# A collection of bash utilities for generating random data
# Requires main_utils

# Function to generate random string based on input
gen() {
    local random_length="${1}"
    local random_characters="${2}"
    local random_number="${3}"

    chk_var 'random_length' '8'
    chk_var 'random_number' '1'
    chk_var 'random_characters' 'a-zA-Z0-9'

    tr -dc "${random_characters}" < /dev/urandom | fold -w "${random_length}" | head -n "${random_number}" | paste -sd ' '
}

# Function to generate a random password based on gen function
gen_pw() {
    local length="${1}"
    local chars="${2}"
    local number="${3}"
    local char

    chk_var 'length' '16'
    chk_var 'chars' 'complex'
    chk_var 'number' '1'

    case "${chars}" in
        'alphanumeric') chars='a-zA-Z0-9' ;;
        'simple' | 'small' | 'lowercase' | 'a' | 'z') chars='a-z' ;;
        'capitals' | 'capital' | 'cap' | 'caps' | 'code' | 'uppercase' | 'A' | 'Z') chars='A-Z' ;;
        'numbers' | 'number' | 'num' | 'nums' | '0' | '1') chars='0-9' ;;
        'letters' | 'letter' | 'Aa' | 'aA' | 'Zz' | 'zZ') chars='a-zA-Z' ;;
        'complex') chars='[:graph:]' ;;
        *) msg "Unknown option: ${chars}" 'Defaulting to random alphanumeric'; chars='a-zA-Z0-9' ;;
    esac

    gen "${length}" "${chars}" "${number}"
}

# Function to generate a random passphrase using dictionary or by generating multiple passwords
gen_phr() {
    local dict="${1}"
    local number="${2}"
    local length="${3}"
    local files=()
    local chars

    chk_var 'number' '4'

    if chk_rgx "${1}" 'numbers'; then
        dict=
        number="${1}"
        length="${2}"
    fi

    local dicts=(${dict})
    chk_arr 'dicts' || dicts=('us' 'uk' 'fr' 'la' 'de')

    for dict in "${dicts[@]}"; do
        case "${dict}" in
            'dict' | 'dictionary' | 'words' | 'default' | '')
                files+=("${DICT_DIR}/words")
                ;;
            'us' | 'usa' | 'american' | 'american-english' | 'en')
                files+=("${DICT_DIR}/american-english")
                ;;
            'uk' | 'gb' | 'british' | 'british-english')
                files+=("${DICT_DIR}/british-english")
                ;;
            'fr' | 'french')
                files+=("${DICT_DIR}/french")
                ;;
            'la' | 'latin')
                files+=("${DICT_DIR}/latin")
                ;;
            'de' | 'german')
                files+=("${DICT_DIR}/german")
                ;;
            'random' | 'rand')
                if [[ "${dict}" == 'random' ]] || [[ "${dict}" == 'rand' ]]; then
                    dict=
                fi
                chk_var 'length' '8'
                chk_var 'dict' 'simple'

                gen_pw "${length}" "${dict}" "${number}"
                ;;
            *)
                local dict_file="${DICT_DIR}/${dict}"
                chk_fl "${dict_file}" && files+=("${dict_file}")
                ;;
        esac
    done

    # Set maximum length of a word to default value if no valid input is supplied
    if ! (chk_var 'length' && chk_rgx "${length}" 'numbers'); then
       length='15'
    fi

    cat "${files[@]}" | \
    shuf --random-source=/dev/urandom | \
    awk '{print tolower($0)}' | \
    sed 's/ä/a/g; s/ö/o/g; s/ü/u/g; s/ß/ss/g; s/â/a/g; s/ê/e/g; s/î/i/g; s/ô/o/g; s/û/u/g; s/ç/c/g; s/é/e/g; s/è/e/g' | \
    cut -c 1-"${length}" | \
    head -n "${number}" | \
    awk '{print $1}' | \
    paste -sd ' '
}

# Function to generate a random number between given range, inclusive
gen_num() {
    local min="${1}"
    local max="${2}"

    if [[ -z "${max}" ]]; then
        if [[ -n "${min}" ]]; then
            max="${min}"
            min='0'
        else
            min='0'
            max='1'
        fi
    fi

    if ! chk_rgx "${min}" 'numbers'; then
        msg "Invalid min value '${min}'"
        return 1
    fi

    if ! chk_rgx "${max}" 'numbers'; then
        msg "Invalid max value '${max}'"
        return 1
    fi

    if [[ "${min}" -gt "${max}" ]]; then
        local temp_max="${max}"
        max="${min}"
        min="${temp_max}"
    fi

    local range="$(( max - min + 1 ))"
    local number="$(( RANDOM % range + min ))"
    echo "${number}"
}
