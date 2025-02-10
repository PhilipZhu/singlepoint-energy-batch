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

# TEST: software_ini_usage
echo
echo "TEST: software_ini_usage()"
declare -F software_ini_usage &>/dev/null && echo -e "  \033[32mfunction software_ini_usage() exist.\033[0m" || echo -e "  \033[33mfunction software_ini_usage() do not exist.\033[0m"
echo
echo "> software_ini_usage"
(software_ini_usage) && echo "exit 0" || echo "exit 1"

# TEST: split_input
echo
echo "TEST: split_input()"
declare -F split_input &>/dev/null && echo -e "  \033[32mfunction split_input() exist.\033[0m" || echo -e "  \033[33mfunction split_input() do not exist.\033[0m"
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
    [ "${folder}" != "c00001/" ] && $CALC_EXE "${CALC_INP_FILENAME}" > "${CALC_STDOUT_FILENAME}" || ( echo Timeout in 1.0 s.. && timeout 1 $CALC_EXE "${CALC_INP_FILENAME}" > "${CALC_STDOUT_FILENAME}" )
  )
  echo
done

# TEST: isfinished
echo "TEST: isfinished"
declare -F isfinished &>/dev/null && echo -e "  \033[32mfunction isfinished() exist.\033[0m" || echo -e "  \033[33mfunction isfinished() do not exist.\033[0m"
echo
for folder in c*/; do
  (cd "${folder}" && echo "> isfinished ${folder}" && (isfinished && echo "  true" || echo "  false") )
  echo
done

# TEST: lstmpfiles
echo "TEST: lstmpfiles"
declare -F lstmpfiles &>/dev/null && echo -e " \033[32m function lstmpfiles() exist.\033[0m" || echo -e "  \033[33mfunction lstmpfiles() do not exist.\033[0m"
echo
for folder in c*/; do
  (cd "${folder}" && echo "> ls ${folder}" && (ls | cat) && echo && echo "> lstmpfiles ${folder}" && lstmpfiles )
  echo
done

# TEST: getresult
echo "TEST: getresult"
declare -F getresult &>/dev/null && echo -e " \033[32m function getresult() exist.\033[0m" || echo -e "  \033[33mfunction getresult() do not exist.\033[0m"
echo
for folder in c*/; do
  (cd "${folder}" && echo "> getresult ${folder}" && getresult )
  echo
done
