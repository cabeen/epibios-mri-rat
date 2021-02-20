#! /usr/bin/env bash 
##############################################################################
#
# EPIBIOS
#
#   A script for converting scanner data to nifti for the EPIBIOS project.
#
#     input: a Bruker MRI directory
#     output: a destination nifti directory
#
# Author: Ryan Cabeen
#
##############################################################################

root="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && cd .. && pwd)"
name=$(basename $0)

if [ $# -ne "2" ]; then
    echo "Usage: ${name} <input_dir> <output_dir>"
    exit
fi

input=${1}
output=${2}

site=$(basename $(dirname ${input}))

mkdir -p ${output}

echo "started ${name}"
echo "  using input: ${input}"
echo "  using site: ${site}"
echo "  using output: ${output}"

# TODO: add support for Agilent data

bash ${root}/bin/EpibiosBrukerImport.sh ${input} ${output}/raw
bash ${root}/bin/EpibiosBrukerRename.sh ${output}/raw ${site} ${output}/common

echo "finished"

################################################################################
# END
################################################################################
