#!/bin/bash

EXE_DIR="$( dirname -- "${BASH_SOURCE[0]}" | xargs realpath)"
MBD_INI_PATH="$1"
XYZ_FILE="$2"

# wrapper

[ "$#" -eq 2 ] && "${EXE_DIR}/../../../mbd.sh" -c -s "$MBD_INI_PATH" "$XYZ_FILE" && exit
echo 'Do not see enough arguments. Did you run: ./singlepoint -S <mbd.ini> <input.xyz> <path_to_settings.ini>?' >&2
