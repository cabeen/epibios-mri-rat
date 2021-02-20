#! /bin/bash

workflow=$(cd $(dirname ${0}); cd ..; pwd -P)
cd ${workflow}/data/stats

data="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && cd ../../.. && pwd )/data/level5"

QIT_CMD="qit --verbose"

crop_full=":,:,25:81"
crop_small=":,:,47:2:71"

function visit
{
out=${3}
if [ ! -e ${out} ]; then
  ${QIT_CMD} VolumeRender \
    --bghigh threeup \
    --alpha 1.0 \
    --background ${1} \
    --bgmask ${workflow}/data/masks/brain.nii.gz \
    --output ${out}.nii.gz
  ${QIT_CMD} VolumeMosaic \
    --crop ${2} \
    --rgb --axis k \
    --input ${out}.nii.gz \
    --output ${out}
  rm ${out}.nii.gz
fi 
}

mkdir -p Vis

for site in Finland UCLA Melbourne; do
  for group in control tbi.{2d,9d,1mo,5mo} tbis; do 
    mkdir -p ${site}/${group}
    for measure in raw; do
		  for metric in dti_{S0,FA,MD,RD,AD} mge_{mean,r2star,t2star}; do
        visit ${site}/${group}/${metric}.${measure}.mean.nii.gz ${crop_full} \
          Vis/full_${site}_${group}_${metric}_${measure}.png
        visit ${site}/${group}/${metric}.${measure}.mean.nii.gz ${crop_small} \
          Vis/small_${site}_${group}_${metric}_${measure}.png
      done
    done
  done
done
