#!/usr/bin/env bash

source /usr/lib/geos/core.sh
imp file notifs

disk_info="$(df /dev/sda2 -h | tail -1)"
disk_usage="$(echo ${disk_info} | awk '{print $5}' | tr -d '%')"

if [[ "${disk_usage}" -ge 85 ]]; then
    ntf 'critical' 'Free up space' "Over ${disk_usage}% of disk is in use"
elif [[ "${disk_usage}" -ge 80 ]]; then
    ntf 'Free up space' "Over ${disk_usage}% of disk is in use"
fi

if ! chk_rt; then
    ntf 'Run this script as sudo for maximum effectiveness'
    exit 0
fi

db_lck='/var/lib/pacman/db.lck'
if  [[ -f "${db_lck}" ]]; then
    if rm -f "${db_lck}"; then
        ntf 'Deleting db.lck'
    else
        ntf 'critical' 'Failed to delete db.lck'
    fi
fi

if pacman -Sy; then
    until [[ "$(pacman -Qu | wc -l)" = '0' ]]; do
        pacman -Syu --noconfirm
    done
else
    ntf 'critical' 'Update failed' 'Unable to lock database'
fi

# TEMPORARY FIX
sudo systemctl stop dnsmasq
sudo systemctl stop libvirtd
sudo virsh net-start default
sudo systemctl start libvirtd
