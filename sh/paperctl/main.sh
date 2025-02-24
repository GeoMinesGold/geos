#!/usr/bin/env bash
# A CLI tool for all your past paper needs

# Source custom core utils
source /usr/lib/geos/core.sh

# Import necessary libraries (complement to core)
imp rand arr notifs args file

# Source project files
src functions

# Get files
mkdir -p "${LOCAL_DIR}"
paper_history="${LOCAL_DIR}/history"
boards_file="${LOCAL_DIR}/boards"
papers_dir="${HOME}/Documents/Past Papers"
display_tree='true'
