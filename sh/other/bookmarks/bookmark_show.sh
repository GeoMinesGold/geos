#!/usr/bin/env bash
grep -v '^#' ~/Documents/txt/Bookmarks/list | rofi -dmenu -i -1 50 | cut -d' ' -f1 | xclip -sel c
