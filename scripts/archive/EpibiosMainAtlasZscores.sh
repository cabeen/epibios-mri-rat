#! /bin/bash

workflow=$(cd $(dirname ${0}); cd ..; pwd -P)
cd ${workflow}/data/stats

data="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && cd ../../.. && pwd )/data/level5"

QIT_CMD="qsubcmd qit --verbose"

function fuseit
{
if [ ! -e ${3}.mean.nii.gz ]; then
  ${QIT_CMD} VolumeFuse \
    --input $1 \
    --skip \
    --pattern $2 \
    --mask ${workflow}/data/masks/brain.edit.nii.gz \
    --output-mean ${3}.mean.nii.gz \
    --output-std ${3}.std.nii.gz \
    --output-cv ${3}.cv.nii.gz
fi 
}

for site in Finland UCLA Melbourne; do
  for group in control tbi.{2d,9d,1mo,5mo} tbis; do 
  #for group in control tbis; do 
    mkdir -p ${site}/${group}
    for measure in raw.zscore harm.zscore; do
		  for metric in dti_{S0,FA,MD,RD,AD}; do
        fuseit ${data}/${site}/%s/atlas.dwi.param/${measure}/${metric}.nii.gz \
         ../../params/${site}/${group}.txt \
         ${site}/${group}/${metric}.${measure}
      done

		  for metric in mge_{mean,r2star,t2star}; do
        fuseit ${data}/${site}/%s/atlas.mge.param/${measure}/${metric}.nii.gz \
         ../../params/${site}/${group}.txt \
         ${site}/${group}/${metric}.${measure}
      done
    done
  done
done
