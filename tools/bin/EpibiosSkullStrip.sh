#! /bin/bash

usage()
{
    echo "
Name: $(basename $0)

Description:

  Skull strip a rodent brain using ANTs 

Usage:

  $(basename $0) input.nii.gz output.nii.gz

Author: Ryan Cabeen
"

exit 1
}

if [ $# -ne 2 ]; then usage; fi

echo "started skull stripping"

input=$1
output=$2

# You may need this if you don't have ANTs installed
# export ANTSPATH=/usr/local/ANTs/bin/
# export PATH=${ANTSPATH}:${PATH}

temp=$(dirname $0)/../data
base=${input%.nii.gz}.tmp.${RANDOM}.ants

antsBrainExtraction.sh \
  -d 3 -a ${input} \
  -e ${temp}/reference/head.nii.gz \
  -m ${temp}/masks/brain.nii.gz \
  -o ${base}

if [ -e ${output} ]; then
  bck=${output}.bck.${RANDOM}
  echo "backing up previous results to ${bck}"
  mv ${output} ${bck}
fi

if [ $? -eq "0" ]; then
  mkdir -p $(dirname ${output})
  cp ${base}BrainExtractionMask.nii.gz ${output}
  rm -rf ${base}*
  echo "finished skull stripping"
else
  echo "error: skull stripping failed"
  rm -rf ${base}*
  exit 1
fi

