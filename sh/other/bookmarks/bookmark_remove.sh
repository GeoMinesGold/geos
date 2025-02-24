#!/usr/bin/env bash

bookmark="$(xclip -o)"
dir="${HOME}/Documents/txt/Bookmarks/"
file=""$dir"/list"
backup=""$dir"Bookmarks/Backup/Remove/$(xprop -id $(xprop -root -f _NET_ACTIVE_WINDOW 0x " \$0\\n" _NET_ACTIVE_WINDOW | awk "{print \$2}") | awk '/WM_CLASS/{print $4}' | sed 's/\"//g') $(date '+%a %b %e %Y %R:%S [%Nns]') [$(pwgen -snc -1 9)].txt"
temp="${HOME}/Documents/temp/temp_$(pwgen -snc -1 64)"

if [[ -z "$bookmark" ]]; then
	notify-send "Removal failed" "String is empty, please try again."
elif ! grep -Fxq "$bookmark" "$file"; then
	notify-send "Removal failed" "Bookmark does not exist." 
elif grep -Fxq "$bookmark" "$file"; then
	notify-send -u low "Bookmark removed" "Bookmark has been removed ($bookmark)."
	cp "$file" "$backup"
	grep -Fxv "$bookmark" "$file" > "$temp" && mv "$temp" "$file"
else
	notify-send "Removal failed" "An unknown error has occured."
fi
