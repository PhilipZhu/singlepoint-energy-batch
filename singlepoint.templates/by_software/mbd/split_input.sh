#!/bin/bash

# split_input
#   Input  : <xyz file>
#   Output : Generates input files for ${CALC_EXE} with name format xxNNNN. Each
#            file will be renamed as ${CALC_INP_FILENAME}. Each job will run as:
#
#            ${CALC_EXE} ${CALC_INP_FILENAME} > ${CALC_STDOUT_FILENAME}

input_xyz_file="$1"

CHARCOMMENT='#'
csplit --prefix=zxx -z -b "%05d" <(sed '\@^[[:space:]]*[0-9]*[[:space:]]*$@{N;s@\n@\n'"${CHARCOMMENT}"'@g;s@^@'"${CHARCOMMENT}"'###CSPLIT####\n@g}' ${input_xyz_file} | sed -n '\@^'"${CHARCOMMENT}"'###CSPLIT####@,$p') '/^'"${CHARCOMMENT}"'###CSPLIT####$/' '{*}'
sed -i '\@^'"${CHARCOMMENT}"'###CSPLIT####@d' zxx*
for file in zxx*; do
  mv "$file" "${file/zxx/xx}"
done
