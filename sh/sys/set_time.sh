#!/usr/bin/env bash
auto_time='true'
auto_timezone='true'

# To maintain compatibility with Windows, use local time instead of UTC
timedatectl set-local-rtc 1

# Fetch time info from worldtimeapi.org
if ! response="$(curl -s http://worldtimeapi.org/api/ip)"; then
     echo 'Failed to fetch time'
     exit '1'
 fi

# Fetch timezone automatically or manually
if [[ "${auto_timezone}" == 'true' ]]; then
    timezone="$(grep -oP '"timezone":"\K[^"]+' <<< "${response}")"

    # Check if timezone was extracted 
    if [[ -z "${timezone}" ]]; then
        echo 'Failed to parse timezone'
        exit '1'
    fi
else
   echo -e 'Enter timezone here (Ex: America/New_York):\nTimezones are available at /usr/share/zoneinfo by default'
    if ! read -r timezone; then
        echo 'Failed to read timezone'
        exit '1'
    fi
fi

# Set the system timezone using timedatectl
if ! sudo timedatectl set-timezone "${timezone}"; then
    echo "Failed to set timezone ${timezone}"
    exit '1'
fi

 
# Set date and time manually
if [[ "${auto_time}" == 'false' ]]; then
    datetime="$(grep -oP '"datetime":"\K[^"]+' <<< "${response}")"

    # Check if datetime was extracted
    if [[ -z "${datetime}" ]]; then
        echo 'Failed to parse date and time'
        exit '1'
    fi

    # Convert the datetime to the format required by the timedatectl command
    formatted_datetime="$(date -d "${datetime}" +'%Y-%m-%d %H:%M:%S')"

    # Set the system time using timedatectl
    sudo timedatectl set-time "${formatted_datetime}"
fi

# Enable NTP (Network Time Protocol)
if ! sudo timedatectl set-ntp true; then
    echo 'Failed to set NTP'
    exit '1'
fi

# Wait for NTP synchronization to complete
while true; do
    if timedatectl status | grep -q 'System clock synchronized: yes'; then
        break
    fi
    sleep '0.1'
done

# Set the hardware clock (CMOS Battery) from the system time
if ! sudo hwclock -w; then
    echo 'Failed to set the hardware clock'
    exit '1'
fi
