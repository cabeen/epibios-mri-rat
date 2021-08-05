#! /usr/bin/env bash

levels=3,5,7,9  # the levels for perilesional analysis
erode=3         # erode the lesion brain mask by this much 
minvox=5        # the minimum num of contiguous lesion voxels
zcavity=3       # the cavity threshold 
zheme=-3        # the heme threshold

# to be specified
prior=
mask=
cavity=
heme=
output=

usage()
{
echo "
Name: $(basename $0)

Description:

  Segment lesions based on z-score maps
    
Usage: 

  $(basename $0) [opts] 

Input Parameters (must be include in the first run, but not afterwards):

   --mask mask.nii.gz:      a brain mask
   --cavity zscores.nii.gz: a z-score map for cavity segmentation
   --heme zscores.nii.gz:   a z-score map for heme segmentation (may be the same)
   --prior prior.nii.gz:    a lesion prior mask 
   --output output_dir:     the output directory

Optional Parameters (may be included in the first run, but not afterwards):

   --zcavity: the cavity threshold (default: ${zcavity})
   --zheme:   the heme threshold (default: ${zheme})
   --minvox:  the minimum lesion (default: ${minvox})
   --erode:   the number of outer erosions (default: ${erode})
   --levels:  the distances for perilesional levels (default: ${levels})

Author: Ryan Cabeen
"; exit 1
}

if [ $# -eq 0 ]; then usage; fi

posit=""
while [ "$1" != "" ]; do
    case $1 in
        --mask)     shift; mask=$1 ;;
        --cavity)   shift; cavity=$1 ;;
        --heme)     shift; heme=$1 ;;
        --prior)    shift; prior=$1 ;;
        --output)   shift; output=$1 ;;
        --zcavity)  shift; zcavity=$1 ;;
        --zheme)    shift; zheme=$1 ;;
        --minvox)   shift; minvox=$1 ;;
        --erode)    shift; erode=$1 ;;
        --levels)   shift; levels=$1 ;;
        --help )    usage ;;
        * )         posit="${posit} $1" ;;
    esac
    shift
done

if [ ${posit} ]; then usage; fi 

function runit
{
  echo "[info] running command: $@"
  $@
  if [ $? != 0 ]; then
    echo "[error] command failed: $@"
    exit;
  fi
}

tmp=${output}.tmp.${RANDOM}
mkdir -p ${tmp}

runit qit MaskErode \
  --input ${mask} \
  --num ${erode} \
  --output ${tmp}/mask.nii.gz

runit qit MaskFilterMode \
  --input ${tmp}/mask.nii.gz \
  --output ${tmp}/mask.nii.gz

runit qit MaskIntersection \
  --left ${prior} \
  --right ${tmp}/mask.nii.gz \
  --output ${tmp}/prior.nii.gz

runit qit VolumeThreshold \
  --input ${heme} \
  --mask ${tmp}/prior.nii.gz \
  --threshold ${zheme} \
  --invert \
  --output ${tmp}/heme.nii.gz

runit qit MaskComponents \
  --input ${tmp}/heme.nii.gz \
  --minvoxels ${minvox} \
  --output ${tmp}/heme.nii.gz

runit qit VolumeThreshold \
  --input ${cavity} \
  --mask ${tmp}/prior.nii.gz \
  --threshold ${zcavity} \
  --output ${tmp}/cavity.nii.gz

runit qit MaskComponents \
  --input ${tmp}/cavity.nii.gz \
  --minvoxels ${minvox} \
  --output ${tmp}/cavity.nii.gz

runit cp ${tmp}/mask.nii.gz ${tmp}/rois.nii.gz

runit qit MaskSet \
  --input ${tmp}/rois.nii.gz \
  --mask ${tmp}/cavity.nii.gz \
  --label 2 \
  --output ${tmp}/rois.nii.gz

runit qit MaskSet \
  --input ${tmp}/rois.nii.gz \
  --mask ${tmp}/heme.nii.gz \
  --label 3 \
  --output ${tmp}/rois.nii.gz

echo "index,name" > ${tmp}/rois.csv
echo "1,tissue" >> ${tmp}/rois.csv
echo "2,cavity" >> ${tmp}/rois.csv
echo "3,heme" >> ${tmp}/rois.csv

runit qit VolumeFuse \
  --input ${heme} ${cavity} \
  --mask ${tmp}/mask.nii.gz \
  --norm \
  --output-max ${tmp}/absz.nii.gz

runit qit MaskRegionsMeasure \
  --volume absz=${tmp}/absz.nii.gz \
  --regions ${tmp}/rois.nii.gz \
  --lookup ${tmp}/rois.csv \
  --output ${tmp}/stats

runit qit MaskMeasure \
  --fraction \
  --input ${tmp}/rois.nii.gz \
  --lookup ${tmp}/rois.csv \
  --output ${tmp}/stats.csv

runit qit MaskExtract \
  --input ${tmp}/rois.nii.gz \
  --label 1 \
  --output ${tmp}/tissue.nii.gz

runit qit MaskUnion \
  --distinct \
  --left ${tmp}/heme.nii.gz \
  --right ${tmp}/cavity.nii.gz \
  --output ${tmp}/lesion.nii.gz

runit qit MaskDistanceTransform \
  --input ${tmp}/lesion.nii.gz \
  --signed \
  --output ${tmp}/distance.nii.gz

runit qit MaskRings \
  --levels ${levels} \
  --input ${tmp}/lesion.nii.gz \
  --mask ${tmp}/tissue.nii.gz \
  --output ${tmp}/rings.nii.gz

runit mv ${tmp} ${output}

echo "[info] finished $(basename $0)"

##############################################################################
# End of file
##############################################################################
