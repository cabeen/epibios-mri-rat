#! /usr/bin/env bash 
##############################################################################
#
# EPIBIOS
#
#   A script for converting scanner data to nifti for the EPIBIOS project.
#
#     source: a Bruker MRI directory
#     subject: a destination nifti directory
#
# Author: Ryan Cabeen
#
##############################################################################

root="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && cd .. && pwd)"
name=$(basename $0)

if [ $# -ne "2" ]; then
    echo "Usage: ${name} <source> <subject>"
    exit
fi

source=${1}
subject=${2}

site=$(basename $(dirname ${source}))

mkdir -p ${subject}

echo "started ${name}"
echo "  using source: ${source}"
echo "  using site: ${site}"
echo "  using subject: ${subject}"

scanner=Bruker
if [ ${site} == "Einstein-P2" ]; then 
  scanner=Agilent
fi

bash ${root}/bin/EpibiosAux${scanner}Import.sh ${source} ${subject}/native.source/convert
bash ${root}/bin/EpibiosAux${scanner}Common.sh ${subject}/native.source/convert ${site} ${subject}/native.source/common

echo "finished"

################################################################################
# END
################################################################################
