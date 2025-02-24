#!/usr/bin/env bash

source /usr/lib/geos/core.sh
imp rand file arr notifs

# Get operation
operation="${1}"

# Define network-related variables and arrays
network_conditions=('wireless' 'wifi')
test_urls=('www.google.com' 'www.bing.com' 'www.facebook.com' 'www.github.com' 'www.amazon.com')

# Create the condition regex from the network_conditions array
network_condition_regex="$(IFS='|'; echo "${network_conditions[*]}")"

# Function to get network information
get_networks() {
    current_network="$(nmcli -t -f NAME connection show --active | awk 'NR==1')"
    mapfile -t networks < <(nmcli -t -f SSID device wifi)
    mapfile -t saved_networks < <(nmcli -t -f NAME,TYPE connection show)
    preferred_networks=()
    active_networks=()
}

# Function to ping a URL and output the result to a temporary file
ping_url() {
    local url="${1}"
    local file="${2}"

    chk_var url || return 1
    chk_var file || return 1

    if timeout 1s ping -c 1 -s 1 -w 1 -W 1 "${url}" &> /dev/null; then
        echo 'success' >> "${file}"
        
    else
        echo 'fail' >> "${file}"
    fi
}

# Function to switch to next network
switch_networks() {
    local network filtered_network
    get_networks

    # Process saved networks
    for network in "${saved_networks[@]}"; do
        if chk_var 'network'; then
            if ! chk_el "${network}" 'preferred_networks'; then
                filtered_network="$(grep -E "${network_condition_regex}" <<< "${network}" | awk -F ':' '{print $1}')"
                chk_var 'filtered_network' && preferred_networks+=("${filtered_network}")
            fi
        fi
    done

    # Get active networks
    for network in "${networks[@]}"; do
        if chk_el "${network}" 'preferred_networks'; then
            if ! chk_el "${network}" 'active_networks'; then
                active_networks+=("${network}")
            fi
        fi
    done

    # Check if there are any active networks
    if ! chk_arr 'active_networks'; then
        ntf 'Network switch error' 'No active networks found'
        exit 1
    fi

    local next_network="$(nxt_el "${current_network}" 'active_networks')"

    if [[ "${next_network}" == "${current_network}" ]]; then
        ntf 'Already on the only network available'
        exit 0
    fi

    # Connect to the next network
    nmcli device wifi connect "${next_network}" && ntf 'low' 'Network switched' "Current network: ${next_network}" || ntf 'Unable to switch networks'
}

# Function to get status of current network
get_network_status() {
    # Initialize counters
    local success_counter='0'
    local fail_counter='0'
    local result results_file url pid pids=()
    gen_tmp results_file

    get_networks

    # Loop through each URL and ping it in parallel
    for url in "${test_urls[@]}"; do
        ping_url "${url}" "${results_file}" &
        pids+=("${!}")
    done

    # Wait for all ping background processes to finish
    for pid in "${pids[@]}"; do
        wait "${pid}"
    done

    # Process the results
    while read -r result; do
        if [[ "${result}" == "success" ]]; then
            ((success_counter++))
        else
            ((fail_counter++))
        fi
    done < "${results_file}"

    # Calculate the total number of sites tested
    local total_sites="$((success_counter + fail_counter))"

    # Check if any sites were tested
    if [[ "${total_sites}" -eq 0 ]]; then
        ntf 'Ping failure' 'No sites were tested'
        exit 1
    fi

    # Calculate the success percentage
    local success_percentage="$((success_counter * 100 / total_sites))"

    # Send appropriate notifications based on success percentage
    if [[ "${success_percentage}" -eq 100 ]]; then
        ntf 'low' 'Ping success' "All sites worked, current network: ${current_network}"
    elif [[ "${success_percentage}" -eq 0 ]]; then
        ntf 'Ping failure' "No sites worked, current network: ${current_network}"
    elif [[ "${success_percentage}" -gt 0 ]] && [[ "${success_percentage}" -lt 100 ]]; then
        ntf 'low' 'Ping success' "${success_percentage}% of sites worked, current network: ${current_network}"
    else
        ntf 'Ping failure' "Unexpected success percentage: ${success_percentage}"
    fi
}

# Main function
case "${operation}" in
    '' | 'status') get_network_status ;;
    'switch') switch_networks ;;
    *) ntf "Unknown operation: ${operation}" ; exit 1 ;;
esac
