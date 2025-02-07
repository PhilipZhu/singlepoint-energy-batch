#!/bin/bash

# split_input
#   Input  : <xyz file> <charge> <multiplicity> <HEAD file> <TAIL file>
#   Output : Generates input files for ${CALC_EXE} with name format xxNNNN. Each
#            file will be renamed as ${CALC_INP_FILENAME}. Each job will run as:
#
#            ${CALC_EXE} ${CALC_INP_FILENAME} > ${CALC_STDOUT_FILENAME}

fin="$1"
chg="$2"
mult="$3"
HEAD_FN="$4"
TAIL_FN="$5"

chgmult="${chg} ${mult}"
SHEAD="$(cat "${HEAD_FN}" | sed 's/XXXXX/'"${chgmult}"'/g' | awk -v ORS='\\n' '{gsub(/\r$/,"")}1' | sed 's/\\n$//g')"
STAIL="$(cat "${TAIL_FN}"                                  | awk -v ORS='\\n' '{gsub(/\r$/,"")}1' | sed 's/\\n$//g')"
CHARCOMMENT='!'
csplit -z -b "%05d" <(sed '\@^[[:space:]]*[0-9]*[[:space:]]*$@{N;s@^.*\n@'"${STAIL}"'\n'"${CHARCOMMENT}"'###CSPLIT####\n'"${SHEAD}"' '"${CHARCOMMENT}${CHARCOMMENT}${CHARCOMMENT}"' COMMENT FROM XYZ FILE : @g}' ${fin} | sed -n '\@^'"${CHARCOMMENT}"'###CSPLIT####@,$p' && echo -e "${STAIL}") '/^'"${CHARCOMMENT}"'###CSPLIT####$/' '{*}'
