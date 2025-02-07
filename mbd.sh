#!/bin/bash

SRC_DIR="$( dirname -- "${BASH_SOURCE[0]}" | xargs realpath)"

###################
# CUSTOM SETTINGS #
###################

# software.ini specifies software and level of theory for single-point calculations
[ "${SOFTWARE_INI_PATH}" == "" ] && SOFTWARE_INI_PATH="${SRC_DIR}/singlepoint.templates/by_software/orca/software.ini"

###################
# END OF SETTINGS #
###################

usage() {
    echo "Run Many-body Decomposition" >&2
    echo "Usage:" >&2
    echo "       natoms=<natomslist> [charges=<chargelist>] [multips=<multiplicitylist>] [SOFTWARE_INI_PATH=<path_to_software.ini>] $0 [options] <input.xyz>" >&2
    echo "   or  $0 [options] -S <setup.ini##must define natoms> <input.xyz>" >&2
    echo "     <natomslist>             String, number of atoms in each monomer, separated by space. (e.g. natoms='3 2 2')" >&2
    echo "     <chargelist>             String, charge of each monomer, separated by space. (default: '0' for all)" >&2
    echo "     <multiplicitylist>       String, multiplicity of each monomer, separated by space. (default: '1' for all)" >&2
    echo '     <path_to_software.ini>   String, path to <software.ini> for `singlepoint` executable.' >&2
    echo
    echo "Options:" >&2
    echo "  -h               help" >&2
    echo "  -c               clean      Removes unfinished outputs, reports finished results. No calculation performed." >&2
    echo "  -S <setup.ini>              Customize settings. The file provided as argument is sourced before running." >&2
    exit 1
}

# Parse options
while getopts "hcS:" opt; do
    case $opt in
        h) usage;;
        c) flag_clean="true" ;;
        S) MBD_INI_SRC_FILE="$OPTARG"
            if [ ! -f "$MBD_INI_SRC_FILE" ]; then
              echo "Error: Settings file '$MBD_INI_SRC_FILE' does not exist" >&2
              usage
            fi
            DO_SOURCE_MBD_INI="true"
            ;;
        *) echo "Invalid option: -${OPTARG}." >&2; usage;;
    esac
done

# Remaining arguments
shift $((OPTIND - 1))

# source settings file
[ -n "${DO_SOURCE_MBD_INI}" ] && source "$MBD_INI_SRC_FILE" "$@"

#-----------------#
# sanity checks
#-----------------#

# System setup
[ -n natoms ]        && natomslist=($natoms)
[ -n charges ]       && chargelist=($charges)
[ -n multips ]       && multiplicitylist=($multips)

# Check input xyz file is provided
[ $# -lt 1 ] && echo "cannot open ‘’ for reading: No such file or directory." && usage
input_xyz=$1
input=${input_xyz%.xyz}

echo "natoms=(${natomslist[@]})"

# Check if the xyz file has the correct number of atoms in the first frame
expected_atoms=$(IFS="+"; echo "$(( ${natomslist[*]} ))")
first_line_atoms=$(head -n 1 "$input_xyz")

if [[ $first_line_atoms -ne $expected_atoms ]]; then
  echo "Error: The first frame of the xyz file indicates $first_line_atoms atoms, but expected $expected_atoms based on natomslist."
  usage
fi

# Default chargelist to 0
[[ ${#chargelist[@]} -eq 0 ]] && chargelist=($(printf "0 %.0s" ${natomslist[@]}))

# Default multiplicitylist to 1
[[ ${#multiplicitylist[@]} -eq 0 ]] && multiplicitylist=($(printf "1 %.0s" ${natomslist[@]}))

echo "charges=(${chargelist[@]})"
echo "multips=(${multiplicitylist[@]})"

# Validate chargelist and multiplicitylist length
if [[ ${#chargelist[@]} -ne ${#natomslist[@]} || ${#multiplicitylist[@]} -ne ${#natomslist[@]} ]]; then
  echo "Error: chargelist and multiplicitylist must have the same length as natomslist."
  usage
fi

#-----------------#
# function defs
#-----------------#

# Perform generate_subclusters algorithm and store in array
generate_subclusters() {
  local bin="$1"
  local ones=()

  # Find indices of '1's
  for ((i = 0; i < ${#bin}; i++)); do
    if [[ ${bin:i:1} -eq 1 ]]; then
      ones+=("$i")
    fi
  done

  # Total number of subsets
  local num_ones=${#ones[@]}
  local max=$((2 ** num_ones - 1))

  # Generate subsets
  for ((mask = 1; mask < max; mask++)); do
    local temp="$bin"
    for ((j = 0; j < num_ones; j++)); do
      if (( (mask & (1 << j)) == 0 )); then
        temp="${temp:0:${ones[j]}}0${temp:$((ones[j] + 1))}"
      fi
    done
    echo "$temp"
  done
}

modskip() {

# modskip v 1.0

# Default values
chunk_size=0
print_indices=""
invert_selection=0

# Function to print usage
#usage() {
#    echo "Usage: $0 [-c <chunk_size>] [-p <print_indices>] [-v] [file]"
#    echo "  -c <chunk_size>        Specify the chunk size (default is ALL)"
#    echo "  -p <select_indices>    Specify indices (idx or min:max) to modify, separated by comma."
#    echo '  -F <format string>     AWK style format string (e.g. '"'"'print "STRINGSTART" $0 "STRINGEND"'"'"').'
#    echo "  -v                     Invert selection."
#    echo "  -h                     Print help message."
#    exit 1
#}

# Parse options
OPTIND=1
while getopts ":c:p:F:vh" opt; do
    case ${opt} in
        c )
            chunk_size="$OPTARG"
            ;;
        p )
            print_indices="$OPTARG"
            ;;
        F )
            format_string=" $OPTARG" # the space is important!
            ;;
        v )
            invert_selection=1
            ;;
        h )
#            usage
            ;;
        \? )
            echo "Invalid option: $OPTARG" 1>&2
#            usage
            ;;
        : )
            echo "Invalid option: $OPTARG requires an argument" 1>&2
#            usage
            ;;
    esac
done
shift $((OPTIND -1))

awk_command='{
    row_number++;
    if (chunk_size == "0") {
        mod_chunk = row_number;
    } else {
        mod_chunk = ((row_number - 1) % chunk_size) + 1;
    }
    print_line = invert_selection;

    if (print_indices != "") {
        split(print_indices, indices, ",");
        for (i in indices) {
            split(indices[i], range, ":");
            if (length(range) == 1) {
                if (mod_chunk == range[1]) {
                    print_line = !invert_selection;
                    break;
                }
            } else if (length(range) == 2) {
                if (mod_chunk >= range[1] && mod_chunk <= range[2]) {
                    print_line = !invert_selection;
                    break;
                }
            }
        }
    } else {
        print_line = !invert_selection;
    }

    if (format_string != "") {
        if (print_line) {
            '"${format_string}"';
        } else {
            printf "%s\n", $0;
        }
    } else {
        if (print_line) {
            print $0;
        }
    }
}'

awk \
    -v chunk_size="$chunk_size" \
    -v print_indices="$print_indices" \
    -v format_string="$format_string" \
    -v invert_selection="$invert_selection" \
    "$awk_command" "$1"

}

###################
# START OF SCRIPT #
###################

wd=$PWD

num_monomers=${#natomslist[@]}

# prepare calculation input
sdir="${input}.mbd.DIR/"
if [ ! -d "${sdir}" ]; then

  # create calculation folder
  rm -rf "${sdir}"
  mkdir -p "${sdir}"

  # Calculate monomer ranges
  ranges=()
  start=3
  for atoms in "${natomslist[@]}"; do
    end=$((start + atoms - 1))
    ranges+=("$start:$end")
    start=$((end + 1))
  done

  # Generate subsystems
  max_index=$((2 ** num_monomers - 1))

  for ((i = 1; i <= max_index; i++)); do
    # binary conversion
    binary=$(echo "obase=2; $i" | bc | xargs printf "%0${num_monomers}d")

    # Determine included monomers
    included_monomers=()
    charge=0
    multiplicity_sum=0
    num_included_atoms=0
    subsystem_ranges=()

    for ((j = 0; j < num_monomers; j++)); do
      if [[ ${binary:j:1} -eq 1 ]]; then
        included_monomers+=("$((j + 1))")
        charge=$((charge + chargelist[j]))
        num_included_atoms=$((num_included_atoms + natomslist[j]))
        multiplicity_sum=$((multiplicity_sum + multiplicitylist[j] - 1))
        subsystem_ranges+=("${ranges[j]}")
      fi
    done

    multiplicity=$((multiplicity_sum % 2 + 1))

    num_included_monomers="${#included_monomers[@]}"
    ranges_str=$(IFS=","; echo "${subsystem_ranges[*]}")

    # Output results for this subsystem using the stored variables
    echo "Subsystem: $binary"
    echo "  Number of monomers: $num_included_monomers"
    echo "  Number of atoms: $num_included_atoms"
    echo "  Charge: $charge"
    echo "  Multiplicity: $multiplicity"
    echo "  Ranges: $ranges_str"
    echo

    # Write Subsystem to file
    modskip -c $((expected_atoms+2)) -p "$ranges_str" "$input_xyz" | modskip -c "${num_included_atoms}" -p 1 -F 'print "'"${num_included_atoms}"'\nframe:" int(NR/'"${num_included_atoms}"') "  '"${charge} ${multiplicity}"'\n" $0' > "${sdir}/tmp.xyz" && mv "${sdir}/tmp.xyz" "${sdir}/${num_included_monomers}xx${binary}.xyz"
  done

fi

# run calculations
cd "${sdir}/"

for xyzfile in *xx*.xyz; do
  chg=$( head -n 2 "${xyzfile}" | tail -n 1 | awk '{print $2}')
  mult=$(head -n 2 "${xyzfile}" | tail -n 1 | awk '{print $3}')
  [ "$flag_clean" == "true" ] && ${SRC_DIR}/singlepoint -c -S "$SOFTWARE_INI_PATH" $xyzfile $chg $mult &> /dev/null
  [ "$flag_clean" != "true" ] && ${SRC_DIR}/singlepoint    -S "$SOFTWARE_INI_PATH" $xyzfile $chg $mult >&2
done

cd $wd

# calculate mbd
cd "${sdir}/"

for ((order = 1; order <= num_monomers; order++)); do
  for xyzfile in ${order}xx*.dat; do
    binary=${xyzfile#*xx}
    binary=${binary%.dat}

    subsubclusters_binaries="$(generate_subclusters "$binary")"

    awk '{print $1, $2}' ${order}xx${binary}.dat > ${order}MB${binary}.dat

    for subcluster in ${subsubclusters_binaries}; do
      echo "$(paste -d' ' ${order}MB${binary}.dat *MB${subcluster}.dat | awk '{if($4!="") {printf("%d %.16G\n", $1, $2-$4)} else {print $1}}')" > ${order}MB${binary}.dat
    done
  done
done

# summary report
cd $wd
more "${sdir}/"*MB*.dat | cat | sed 's@'"${sdir}/"'@\n@g' | tee "${input}.mbd.dat"
