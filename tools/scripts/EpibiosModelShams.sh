#! /bin/bash

repo=$(cd $(dirname $0) && cd .. && pwd)
cd $(dirname $0)
cd ../../../..

echo $PWD
echo ${repo}

output=group/Shams
mkdir -p ${output}

for c in $(cat ${repo}/params/Common/cond/sham.txt); do \
  echo process/*/*/${c}; \
done > ${output}/cases.txt

for p in FA MD RD AD S0; do
  qit -Xmx12G --verbose VolumeFuse \
    --skip \
    --input %s/atlas.dwi/param/harm/dti_${p}.nii.gz \
    --pattern ${output}/cases.txt \
    --output-mean ${output}/dti_${p}_mean.nii.gz \
    --output-std ${output}/dti_${p}_std.nii.gz 
done

for p in mean r2star t2star; do
  qit -Xmx12G --verbose VolumeFuse \
    --skip \
    --input %s/atlas.mge/param/harm/mge_${p}.nii.gz \
    --pattern ${output}/cases.txt \
    --output-mean ${output}/mge_${p}_mean.nii.gz \
    --output-std ${output}/mge_${p}_std.nii.gz 
done
