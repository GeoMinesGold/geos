# A collection of bash utilities for finding current date or time
# Requires main_utils

# Function to get current date
get_date() {
    date '+%b %d %Y'
}

# Function to get current time
get_time() {
    date '+%T'
}

# Function to get current second
get_second() {
    date '+%S'
}

# Function to get current minute
get_minute() {
    date '+%M'
}

# Function to get current hour
get_hour() {
    date '+%H'
}

# Function to get current day of month
get_day() {
    date '+%d'
}

# Function to get current weekday
get_weekday() {
    date '+%A'
}

# Function to get short current weekday
get_short_weekday() {
    date '+%a'
}

# Function to get current month
get_month() {
    date '+%m'
}

# Function to get name of current month
get_month_name() {
    date '+%B'
}

# Function to get short name of current month
get_short_month_name() {
    date '+%b'
}

# Function to get current year
get_year() {
    date '+%Y'
}

# Function to check if a year is a leap year
lp_yr() {
    local year="${1}"
    chk_rgx "${year}" 'numbers' || return 1
    if (( (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0) )); then
        return 0  # Leap year
    else
        return 1  # Not a leap year
    fi
}

# Function to get the number of days in a month
get_days_in_month() {
    local month="${1,,}"
    local year="${2}"
    chk_rgx "${year}" 'numbers' || return 1

    case "${month}" in
        'january' | 'jan' | '1' | 'march' | 'mar' | '3' | 'may' | '5' | 'july' | 'jul' | '7' | 'august' | 'aug' | '8' | 'october' | 'oct' | '10' | 'december' | 'dec' | '12') echo '31' ;;
        'april' | 'apr' | '4' | 'june' | 'jun' | '6' | 'september' | 'sep' | '9' | 'november' | 'nov' | '11') echo '30' ;;
        'february' | 'feb' | '2')
            if is_leap_year "${year}"; then
                echo '29'
            else
                echo '28'
            fi
            ;;
        *) return 1 ;;
    esac
}

# Function to get the day of month given day of year
get_day_of_month() {
    local day_of_year="${1}"
    local year="${2}"
    local month_days=()
    local month days_in_month cumulative_days

    chk_rgx "${day_of_year}" 'numbers' || return 1
    chk_rgx "${year}" 'numbers' || return 1

    for month in {1..12}; do
        month_days+=("$(get_days_in_month "${month}" "${year}")")
    done

    month='0'
    cumulative_days='0'
    for days_in_month in "${month_days[@]}"; do
       ((month++)) 
       ((cumulative_days+=days_in_month))
       if [[ "${day_of_year}" -le "${cumulative_days}" ]]; then
            local day_of_month="$((day_of_year - (cumulative_days - days_in_month)))"
            break
        fi
    done
    echo -e "Day: ${day_of_month}\nMonth: ${month}"
}


# Function to map the day of the week to its corresponding day number
map_day_to_number() {
  local day="${1}"
  chk_var 'FIRST_DAY' 'Monday'
  chk_var 'day' "${FIRST_DAY}"
  day="${day,,}"
  case "${day}" in
    'sun' | 'sunday') echo 0 ;;
    'mon' | 'monday') echo 1 ;;
    'tue' | 'tuesday') echo 2 ;;
    'wed' | 'wednesday') echo 3 ;;
    'thu' | 'thursday') echo 4 ;;
    'fri' | 'friday') echo 5 ;;
    'sat'  | 'saturday') echo 6 ;;
    *)
      echo "Error: Invalid day of the week." >&2
      exit 1
      ;;
  esac
}

# Function to get the day of the week
get_day_of_week() {
    local relative_day
    chk_val "${1}" && relative_day="${1}" || relative_day="$((10#"$(get_day)"))"
    local modulus='7'
    local remainder="$((relative_day % modulus))"
    local day_of_week="${remainder}"

    if [[ "${day_of_week}" -eq '0' ]]; then
    day_of_week="${modulus}"
    fi

    echo "${day_of_week}"
}

# Function to get the week in the year
get_week_in_year() {
  local first_day_of_week="${1}"
  local first_day_num="$(map_day_to_number "${first_day_of_week}")"
  local days_since_start_of_year="$(date +%j)"
  local week_in_year="$(( (days_since_start_of_year - (first_day_num - 1) + 6) / 7 ))"
  echo "${week_in_year}"
}

# Function to get the week in the month
get_week() {
    local first_day_of_week="${1}"
    local first_day_num="$(map_day_to_number "${first_day_of_week}")"
    local today="$(date '+%Y-%m-%d')"
    local day="$(date '+%d')"
    local start_of_month_day_num="$(date -d "$(date +%Y-%m-01)" +%w)"
    local first_week_offset="$((8 - first_day_num))"

    if [[ "${day}" -le "${first_week_offset}" ]]; then
        local week='1'
    else
        local days_since_start_of_month="$((day - first_week_offset))"
        local week="$(( (days_since_start_of_month / 7) + 2 ))"
    fi

    echo "${week}"
}
