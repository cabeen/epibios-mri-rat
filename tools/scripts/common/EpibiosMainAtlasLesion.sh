#! /bin/bash

workflow=$(cd $(dirname ${0}); cd ..; pwd -P)
cd ${workflow}/data/stats

mkdir -p Lesion

qit --verbose VolumeFuse --norm \
  --input Combined/tbis/dti_{S0,FA,MD}.harm.zscore.mean.nii.gz \
          Combined/tbis/mge_mean.harm.zscore.mean.nii.gz\
  --output-max Lesion/zscore.nii.gz

qit --verbose VolumeThreshold \
  --input Lesion/zscore.nii.gz \
  --threshold 1 \
  --output Lesion/thresh.nii.gz

qit --verbose MaskDilate \
  --input Lesion/thresh.nii.gz \
  --num 2 \
  --output Lesion/mask.nii.gz

qit --verbose MaskFilterMode \
  --input Lesion/mask.nii.gz \
  --output Lesion/mask.nii.gz

qit --verbose MaskLargest \
  --input Lesion/mask.nii.gz \
  --output Lesion/mask.nii.gz

qit --verbose MaskComponents \
  --minvoxels 10 --keep \
  --input Lesion/mask.nii.gz \
  --output Lesion/mask.nii.gz

qit --verbose MaskErode \
  --input ../masks/brain.edit.nii.gz \
  --num 1 \
  --output Lesion/brain.nii.gz

qit --verbose MaskIntersection \
  --left Lesion/mask.nii.gz \
  --right Lesion/brain.nii.gz \
  --output Lesion/mask.nii.gz

echo "index,name" > Lesion/rois.csv
echo "1,tissue" >> Lesion/rois.csv
echo "2,cavity" >> Lesion/rois.csv
echo "3,heme" >> Lesion/rois.csv
