#!/usr/bin/env bash
# A custom password manager written in bash

source /usr/lib/geos/core.sh
imp date rand file

if [[ "${@}" =~ -o ]]; then
    pass otp .2fa/"$(ls -1 ~/.password-store/.2fa | cut -d'.' -f1 | rofi -dmenu)" | xclip -sel c 
else
    pass "$(ls -1 ~/.password-store | cut -d'.' -f1 | rofi -dmenu)" | xclip -sel c 
fi 

pass_dir="${LOCAL_DIR}/passwords"
mkdir -p "${pass_dir}"
