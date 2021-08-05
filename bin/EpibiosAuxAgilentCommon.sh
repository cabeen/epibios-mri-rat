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

params=${workflow}/params/${site}/pipe

tmp=${output}.tmp.${RANDOM}
mkdir -p ${tmp}

qit --verbose VolumeFuse --skip \
  --input ${input}/MGRE-*e{1,2,3,4,5,6,7,8,9,10,11,12,13}.nii.gz \
  --output-cat ${tmp}/mge.nii.gz

cp $(echo ${input}/FSE*.nii.gz | awk '{print $1}') ${tmp}/rare.nii.gz

qit --verbose VolumeCat \
  --input ${input}/dwi.low.nii.gz \
  --cat ${input}/dwi.high.nii.gz \
  --output ${tmp}/dwi.nii.gz

cp ${params}/multi.bvals.txt ${tmp}/dwi.bvals.txt
cp ${params}/multi.bvecs.txt ${tmp}/dwi.bvecs.txt 
cp ${params}/te.txt ${tmp}/mge.te.txt 

touch ${tmp}/mt.high.missing
touch ${tmp}/mt.low.missing

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