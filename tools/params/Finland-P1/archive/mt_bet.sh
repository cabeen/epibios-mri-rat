#! /bin/bash
################################################################################
#
# A custom script for skull stripping MT rodent data.
# The input should be the MT scan, not the MT0 
#
# Author: Ryan Cabeen
#
################################################################################

input=$1
output=$2
tmp=${output}.tmp.${RANDOM}.nii.gz

qit VolumeBrainExtract --input ${input} --output ${output} --frac 0.4
qit VolumeThreshold --threshold 3000 --input ${input} --output ${tmp}
qit MaskIntersection --left ${output} --right ${tmp} --output ${output}
rm ${tmp}

qit MaskErode --num 3 --input ${output} --output ${output}
qit MaskLargest --input ${output} --output ${output}
qit MaskDilate --num 3 --input ${output} --output ${output}
qit MaskClose --input ${output} --output ${output}
