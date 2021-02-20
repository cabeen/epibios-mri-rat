#! /bin/bash

workflow=$(cd $(dirname ${0}); cd ..; pwd -P)
cd ${workflow}/data/stats

data="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && cd ../../.. && pwd )/data/level5"

# QIT_CMD="qit --verbose"
QIT_CMD="qsubcmd qit --verbose"

for group in control tbi.{2d,9d,1mo,5mo} tbis; do 
#for group in control tbis; do 
  mkdir -p Combined/${group}
  for measure in raw harm; do
    for metric in dti_{S0,FA,MD,RD,AD} mge_{mean,r2star,t2star}; do
      for stat in mean std cv; do
        out=Combined/${group}/${metric}.${measure}.${stat}.nii.gz
        if [ ! -e ${out} ]; then
          ${QIT_CMD} VolumeFuse \
            --input {Melbourne,UCLA,Finland}/${group}/${metric}.${measure}.${stat}.nii.gz \
            --skip --output-mean ${out}
        fi
      done
    done
  done
done

