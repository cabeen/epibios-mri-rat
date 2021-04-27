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

if [ ${site} == "Einstein-P2" ]; then 
	bash ${root}/bin/EpibiosAuxAgilentImport.sh ${source} ${subject}/native.convert
	bash ${root}/bin/EpibiosAuxAgilentCommon.sh ${subject}/native.convert ${site} ${subject}/native.common
else
	bash ${root}/bin/EpibiosAuxBrukerImport.sh ${source} ${subject}/native.convert
	bash ${root}/bin/EpibiosAuxBrukerCommon.sh ${subject}/native.convert ${site} ${subject}/native.common
fi

echo "finished"

################################################################################
# END
################################################################################
