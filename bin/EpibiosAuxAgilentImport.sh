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
    echo "Usage: ${name} <input_agilent_dir> <output_nifti_dir>"
    exit
fi

input=${1}
output=${2}

echo "started ${name}"
echo "  using input: ${input}"
echo "  using output: ${output}"

tmp=${output}.tmp.${RANDOM}
mkdir -p ${tmp}

# Note: these are all the consistent directories:
# FSE-EPIBIOX_091620_01.dmc
# FSE-EPIBIOX_070820_01.dmc
# MGRE-EPIBIOS-072120_01.dmc
# MGRE-EPIBIOS-072120_03.dmc
# epidti3D_b1000_gauss_1nx_2sh_01.fid
# epidti3D_b1000_SGLgauss_1nx_2sh_01.fid
# epidti3D_b1000_SGLgauss_1nx_2sh_02.fid
# epidti3D_b2800_gauss_1nx_2sh_01.fid
# epidti3D_b2800_SGLgauss_1nx_2sh_01.fid

for d in MGRE-EPIBIOS-072120_01.dmc MGRE-EPIBIOS-072120_03.dmc \
         FSE-EPIBIOX_091620_01.dmc FSE-EPIBIOX_070820_01.dmc; do
  if [ -e ${input}/${d} ]; then
    dcm2niix -z y -o ${tmp} ${input}/${d}
  fi
done

if [ -e $(echo ${input}/epidti3D_b1000_* | awk '{print $1}') ]; then
  cp ${input}/epidti3D_b1000_*/image_mag.nii ${tmp}/dwi.low.nii
  gzip ${tmp}/dwi.low.nii
fi

if [ -e $(echo ${input}/epidti3D_b2800_* | awk '{print $1}') ]; then
  cp ${input}/epidti3D_b2800_*/image_mag.nii ${tmp}/dwi.high.nii
  gzip ${tmp}/dwi.high.nii
fi

chmod ug+rwx ${tmp}/*

for f in ${tmp}/FSE*.nii.gz; do
  qit --verbose --debug VolumeReorder \
    --swapjk \
    --input ${f} --output ${f}
done

for f in ${tmp}/MGRE*.nii.gz; do
  qit --verbose --debug VolumeReorder \
    --flipj --swapjk \
    --input ${f} --output ${f}
done

for f in ${tmp}/dwi*.nii.gz; do
  qit --verbose --debug VolumeReorder \
    --flipi --flipk --swapij \
    --input ${f} --output ${f}
done

for f in ${tmp}/*nii.gz; do
  qit --verbose --debug VolumeStandardize \
    --input ${f} --output ${f}

  # the Bruker conversion scales the voxel size
  # by a factor of ten, so let's do the same here
  qit --verbose --debug VolumeSetGrid \
    --df 10 --input ${f} --output ${f}
done

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
