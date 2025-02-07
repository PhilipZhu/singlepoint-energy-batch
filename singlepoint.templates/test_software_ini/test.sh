#!/bin/bash

INI_FILE=$(realpath $1)

cd -- "$( dirname -- "${BASH_SOURCE[0]}")"
rm -rf tmp

if [ "$#" -lt 1 ]; then
    echo "Run $0 <software.ini>"
    exit 1
fi

mkdir -p tmp && cd tmp && cp ../input.xyz .

echo "TEST: ${INI_FILE}"
source "${INI_FILE}"
echo
echo "  CALC_EXE=${CALC_EXE}"
echo "  CALC_INP_FILENAME=${CALC_INP_FILENAME}"
echo "  CALC_STDOUT_FILENAME=${CALC_STDOUT_FILENAME}"

# TEST: split_input
echo
echo "TEST: split_input()"
declare -F split_input &>/dev/null && echo "  function split_input() exist." || echo "  function split_input() do not exist."
echo
echo "> split_input"
split_input ./input.xyz 0 1
echo
echo "> ls"
ls xx*
echo

for file in xx*; do
  folder=${file#xx}
  mkdir "c${folder}/" && cp "${file}" "c${folder}/${CALC_INP_FILENAME}"
done

echo "TEST: prepare input files"
echo
for folder in c*/; do
  (cd "${folder}" && echo "> ls ${folder}" && ls)
  echo
done

for folder in c*/; do
  (cd "${folder}" && echo "> cat ${folder}${CALC_INP_FILENAME}" && cat "${CALC_INP_FILENAME}")
  echo
done

# TEST: run CALC_EXE
echo "TEST: CALC_EXE"
echo
for folder in c*/; do
  (
    cd "${folder}"
    echo '> $CALC_EXE "${CALC_INP_FILENAME}" > "${CALC_STDOUT_FILENAME}"'
    echo "> $CALC_EXE ${CALC_INP_FILENAME} > ${CALC_STDOUT_FILENAME}"
    [ "${folder}" != "c01/" ] && $CALC_EXE "${CALC_INP_FILENAME}" > "${CALC_STDOUT_FILENAME}" || ( echo Timeout in 1.0 s.. && timeout 1 $CALC_EXE "${CALC_INP_FILENAME}" > "${CALC_STDOUT_FILENAME}" )
  )
  echo
done

# TEST: isfinished
echo "TEST: isfinished"
declare -F isfinished &>/dev/null && echo "  function isfinished() exist." || echo "  function isfinished() do not exist."
echo
for folder in c*/; do
  (cd "${folder}" && echo "> isfinished ${folder}" && (isfinished && echo "  true" || echo "  false") )
  echo
done

# TEST: lstmpfiles
echo "TEST: lstmpfiles"
declare -F lstmpfiles &>/dev/null && echo "  function lstmpfiles() exist." || echo "  function lstmpfiles() do not exist."
echo
for folder in c*/; do
  (cd "${folder}" && echo "> ls ${folder}" && (ls | cat) && echo && echo "> lstmpfiles ${folder}" && lstmpfiles )
  echo
done

# TEST: getresult
echo "TEST: getresult"
declare -F getresult &>/dev/null && echo "  function getresult() exist." || echo "  function getresult() do not exist."
echo
for folder in c*/; do
  (cd "${folder}" && echo "> getresult ${folder}" && getresult )
  echo
done
