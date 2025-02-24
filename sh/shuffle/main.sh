#!/bin/bash

# This script shuffles the input words/numbers randomly

# Check if no input is given
if [[ "${#}" -eq 0 ]]; then
  echo "Please provide some words or numbers to shuffle."
  exit 1
fi

# Shuffle the input arguments and output them
echo "${*}" | tr ' ' '\n' | shuf | awk 'NR > 0 { printf "%s ", $0 } END { print "" }'
