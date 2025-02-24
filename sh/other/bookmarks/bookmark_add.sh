#!/usr/bin/env bash

bookmark="$(xclip -o)"
dir="${HOME}/Documents/txt/Bookmarks/"
file=""$dir"/list"
backup=""$dir"Backup/Add/$(xprop -id $(xprop -root -f _NET_ACTIVE_WINDOW 0x " \$0\\n" _NET_ACTIVE_WINDOW | awk "{print \$2}") | awk '/WM_CLASS/{print $4}' | sed 's/\"//g') $(date '+%a %b %e %Y %R:%S [%Nns]') [$(pwgen -snc -1 9)].txt"

if [[ -z "$bookmark" ]]; then
	notify-send "Bookmarking failed" "String is empty, please try again."
elif grep -Fxq "$bookmark" "$file"; then
	notify-send "Bookmarking failed" "Bookmark already exists." 
else
	notify-send -u low "Bookmark added" "Bookmark has been saved ($bookmark)."
	cp "$file" "$backup"
	echo "$bookmark" >> "$file"
fi
