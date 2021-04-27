#! /usr/bin/env bash 
##############################################################################
#
# EPIBIOS
#
#   A script for renaming Brucker nifti data for the EPIBIOS project.
#
# Author: Ryan Cabeen
#
##############################################################################

workflow=$(cd $(dirname ${0}); cd ..; pwd -P)
cd "$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && cd ../../.. && pwd )/data"

name=$(basename $0)

if [ $# -ne "3" ]; then
    echo "Usage: ${name} <input_dir> <site> <output_dir>"
    exit
fi

input=${1}
site=${2}
output=${3}

echo "started ${name}"
echo "  using input: ${input}"
echo "  using site: ${site}"
echo "  using output: ${output}"

sid=$(basename ${input})

echo "... processing subject ${sid} from ${site}"

params=${workflow}/params/${site}

tmp=${output}.tmp.${RANDOM}
mkdir -p ${tmp}

qit --verbose VolumeFuse --skip \
  --input ${input}/MGRE-EPIBIOS-*e{1,2,3,4,5,6,7,8,9,10,11,12,13}.nii.gz \
  --output-cat ${tmp}/mge.nii.gz

cp ${input}/FSE*.nii.gz ${tmp}/rare.nii.gz

qit --verbose VolumeCat \
  --input ${input}/dwi.b1000.nii.gz \
  --cat ${input}/dwi.b2800.nii.gz \
  --output ${tmp}/dwi.nii.gz

qit --verbose VolumeReorder \
  --flipi --swapij \
  --input ${tmp}/dwi.nii.gz \
  --output ${tmp}/dwi.nii.gz

for v in dwi rare mge; do
  qit --verbose VolumeStandardize \
    --input ${tmp}/${v}.nii.gz \
    --input ${tmp}/${v}.nii.gz
done

cp ${params}/bvals.txt ${tmp}/dwi.bvals.txt 
cp ${params}/bvecs.txt ${tmp}/dwi.bvecs.txt 
cp ${params}/te.txt ${tmp}/mge.te.txt 

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
