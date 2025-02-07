#!/bin/bash

# split_input
#   Input  : <xyz file> <HEAD file> <TAIL file> <charge> <spin=2*S> <frozen> <dummy>
#   Output : Generates input files for ${CALC_EXE} with name format xxNNNN. Each
#            file will be renamed as ${CALC_INP_FILENAME}. Each job will run as:
#
#            ${CALC_EXE} ${CALC_INP_FILENAME} > ${CALC_STDOUT_FILENAME}

fin="$1"
HEAD_FN="$2"
TAIL_FN="$3"
chg="$4"
spin="$5"
frozen="$6"
dummy="$7"

SHEAD="$(cat "${HEAD_FN}" | sed 's/XXXXXX/'"${chg}"'/g' | sed 's/SSSSSS/'"${spin}"'/g' | sed 's/ZZZZZZ/'"${frozen}"'/g' | sed 's/DDDummyDDD/'"${dummy}"'/g' | dos2unix | awk -v ORS='\\n' '1' | sed 's/\\n$//g')"
STAIL="$(cat "${TAIL_FN}" | sed 's/XXXXXX/'"${chg}"'/g' | sed 's/SSSSSS/'"${spin}"'/g' | sed 's/ZZZZZZ/'"${frozen}"'/g' | sed 's/DDDummyDDD/'"${dummy}"'/g' | dos2unix | awk -v ORS='\\n' '1' | sed 's/\\n$//g')"
CHARCOMMENT='!'
csplit -z <(sed 's@[[:space:]]*: @1 @g' "${fin}" | sed '\@^[[:space:]]*[0-9]*[[:space:]]*$@{N;s@^.*\n@'"${STAIL}"'\n'"${CHARCOMMENT}"'###CSPLIT####\n'"${SHEAD}"'\n'"${CHARCOMMENT}${CHARCOMMENT}${CHARCOMMENT}"' COMMENT FROM XYZ FILE : @g}' | sed -n '\@^'"${CHARCOMMENT}"'###CSPLIT####@,$p' && echo -e "${STAIL}") '/^'"${CHARCOMMENT}"'###CSPLIT####$/' '{*}'
