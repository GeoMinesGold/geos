#!/usr/bin/env bash

while true; do
    update="$(date '+%a %d/%m %T')"
    xsetroot -name "${update}"
    sleep '1'
done
