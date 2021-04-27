#! /usr/bin/env bash 
##############################################################################
#
# EPIBIOS
#
#   A script for importing Agilent data for the EPIBIOS project.
#
# Author: Ryan Cabeen
#
##############################################################################

ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

name=$(basename $0)

if [ $# -ne "2" ]; then
    echo "Usage: ${name} <input_dir> <output_dir>"
    exit
fi

input=${1}
output=${2}

echo "started ${name}"
echo "  using input: ${input}"
echo "  using output: ${output}"

tmp=${output}.tmp.${RANDOM}
mkdir -p ${tmp}

dcm2niix -z y -o ${tmp} raw/MGRE-*dmc
dcm2niix -z y -o ${tmp} raw/FSE-*dmc

cp raw/epidti3D_b1000_*/image_mag.nii ${tmp}/dwi.b1000.nii
gzip ${tmp}/dwi.b1000.nii

cp raw/epidti3D_b2800_*/image_mag.nii ${tmp}/dwi.b2800.nii
gzip ${tmp}/dwi.b2800.nii

log=${tmp}/log.txt
echo "EPIBIOS import log" > ${log}
echo "  date: $(date)" >> ${log}
echo "  input: ${input}" >> ${log}
echo "  output: ${output}" >> ${log}

if [ -e ${output} ]; then
  bck=${output}.bck.${RANDOM}
  echo "backing up results to ${bck}"
  mv ${output} ${bck}
fi

mv ${tmp} ${output}

echo "finished"

################################################################################
# END
################################################################################
