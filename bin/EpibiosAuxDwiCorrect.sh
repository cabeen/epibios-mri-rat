#! /bin/bash
################################################################################
#
# Run FSL EDDY
#
################################################################################

if [ $# -ne "4" ]; then
  echo "Usage: ${name} <dwi> <bvecs> <bvals> <output>"; exit
fi

dwi=$1
bvecs=$2
bvals=$3
output=$4

tmp=${output}.tmp.${RANDOM}
mkdir -p ${tmp}

echo "starting dwi eddy correction"
echo "using: ${tmp}"
echo "using dwi: ${dwi}"
echo "using bvecs: ${bvecs}"
echo "using bvals: ${bvals}"
echo "using output: ${output}"

num=$(fslhd ${dwi} | grep ^dim4 | awk '{print $2}')
echo "number of gradients: ${num}"

echo "cropping dwi"
qit VolumeCrop \
  --even \
  --input ${dwi} \
  --output ${tmp}/dwi.nii.gz

echo "extracting baselines"
qit VolumeDwiBaseline \
  --input ${tmp}/dwi.nii.gz \
  --gradients ${bvecs} \
  --cat ${tmp}/baselines.nii.gz \
  --mean ${tmp}/baseline.nii.gz

echo "running bet"
bet ${tmp}/baseline.nii.gz ${tmp}/brain -m -f 0.3

echo "formatting gradients"
qit VectsTransform --rows --input ${bvecs} --output ${tmp}/bvecs
qit VectsTransform --rows --input ${bvals} --output ${tmp}/bvals

echo "defining parameters"
idx=""
for i in $(seq ${num}); do
  idx="${idx} 1"
done

echo ${idx} > ${tmp}/index.txt
echo "1 0 0 0.108420" > ${tmp}/acqparams.txt

echo "running eddy"
eddycmd="eddy"
 if [ ! $(which eddy) ]; then eddycmd=eddy_openmp; fi

${eddycmd} --verbose \
  --data_is_shelled \
	--imain=${tmp}/dwi.nii.gz \
	--mask=${tmp}/brain_mask.nii.gz \
	--acqp=${tmp}/acqparams.txt \
	--index=${tmp}/index.txt \
	--bvecs=${tmp}/bvecs \
	--bvals=${tmp}/bvals \
	--out=${tmp}/out

if [ -e ${tmp}/out.nii.gz ]; then
	echo "cleaning up"
	if [ -e ${output} ]; then
		backup=${output}.bck.${RANDOM}
		echo "backing up previous results to ${backup}"
		mv ${output} ${backup}
	fi

	mv ${tmp} ${output}
else
  echo "error encountered, results are saved to ${tmp}"
  exit 1
fi

echo "finished"

################################################################################
# End
################################################################################
