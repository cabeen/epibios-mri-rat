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
    echo "Usage: ${name} <input> <output>"
    exit
fi

input=${1}
output=${2}

site=$(basename $(dirname $(dirname ${input})))

mkdir -p ${output}

echo "started ${name}"
echo "  using input: ${input}"
echo "  using site: ${site}"
echo "  using output: ${output}"

scanner=Bruker
if [ ${site} == "Einstein-P2" ]; then 
  scanner=Agilent
fi

bash ${root}/bin/EpibiosAux${scanner}Import.sh ${input} ${output}/convert
bash ${root}/bin/EpibiosAux${scanner}Common.sh ${output}/convert ${site} ${output}/common
echo ${site} > ${output}/common/site.txt
echo $(basename ${input}) > ${output}/common/sid.txt

echo "finished"

################################################################################
# END
################################################################################
