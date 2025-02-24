#!/usr/bin/env bash

# Declare an associative array to store devices by group
declare -A iommu_groups

# Loop through each device in the IOMMU groups directory
for dir in /sys/kernel/iommu_groups/*/devices/*; do
    # Extract the group number using parameter expansion
    group="${dir#/sys/kernel/iommu_groups/}"
    group="${group%%/devices*}"

    # Append device info to the appropriate group entry in the associative array
    iommu_groups["${group}"]+="${dir} "
done

# Output devices sorted by group
for group in $(echo "${!iommu_groups[@]}" | tr ' ' '\n' | sort -n); do
    echo -e "\nIOMMU Group ${group}"

    # For each device in the current group
    for dir in ${iommu_groups["${group}"]}; do
        # Extract the device address (e.g., 0000:00:02.0)
        device="${dir##*/}"

        # Check if the device has a PCI address by pattern matching
        if [[ "${device}" =~ ^[0-9a-fA-F]{4}:[0-9a-fA-F]{2}:[0-9a-fA-F]{2}\.[0-9a-fA-F]$ ]]; then
            # Print PCI device info with lspci using the correct device format
            echo -e "\t$(lspci -nn -s "${device}")"
        else
            # Print non-PCI devices (e.g., memory controllers, bridges)
            echo -e "\tNon-PCI device: ${device}"
        fi
    done
done
