#!/bin/bash

# wrapper

EXE_DIR="$( dirname -- "${BASH_SOURCE[0]}" | xargs realpath)"
[ "$#" -eq 2 ] && "${EXE_DIR}/../../../mbd.sh" -S $1 $2 && exit
echo 'Do not see enough arguments. Did you run: ./singlepoint -S <mbd.ini> <input.xyz> <path_to_settings.ini>?' >&2
