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

mkdir -p ${output}

echo "started ${name}"
echo "  using input: ${input}"
echo "  using site: ${site}"
echo "  using output: ${output}"

sid=$(basename ${input})

echo "... processing subject ${sid} from ${site}"

dwi=DWI_46
dwilow=DWI_23
mge=MGE
mtlow=FLASH_No_On
mthigh=FLASH_Yes_On
rare=RARE

if [ ${site} == "Melbourne" ]; then
	mtlow=FLASH_Yes_On
	mthigh=FLASH_Yes_On.repeat
fi

params=${workflow}/params/${site}

mkdir -p ${output}

if [ ! -e ${output}/rare ]; then
	if [ -e ${input}/${rare}/data.nii.gz ]; then
		ln ${input}/${rare}/data.nii.gz ${output}/rare.nii.gz
	else
		repeats=${input}/${rare}.repeat.*/data.nii.gz
		files=( $repeats )
		repeat=${files[0]}
		if [ -e ${repeat} ]; then
			ln ${files[0]} ${output}/rare.nii.gz
		else
			echo "rare missing for ${site} ${sid}"
			touch ${output}/rare.missing
		fi
	fi
fi

if [ ! -e ${output}/dwi.nii.gz ]; then
	if [ -e ${input}/${dwi}/data.nii.gz ]; then
		ln ${input}/${dwi}/data.nii.gz ${output}/dwi.nii.gz
	else
		repeats=${input}/${dwi}.repeat.*/data.nii.gz
		files=( $repeats )
		repeat=${files[0]}
		if [ -e ${repeat} ]; then
			ln ${files[0]} ${output}/dwi.nii.gz
		else
			echo "dwi missing for ${site} ${sid}"
			touch ${output}/dwi.missing
		fi
	fi

	ln ${params}/bvals.txt ${output}/dwi.bvals.txt 
	ln ${params}/bvecs.txt ${output}/dwi.bvecs.txt 
fi

if [ ! -e ${output}/dwi.multi.nii.gz ]; then
	if [ -e ${input}/${dwi}/data.nii.gz ] && [ -e ${input}/${dwilow}/data.nii.gz ]; then
    qit --verbose VolumeCat \
      --input ${input}/${dwilow}/data.nii.gz \
      --cat ${input}/${dwi}/data.nii.gz \
      --output ${output}/dwi.multi.nii.gz
	else
    echo "dwi missing for ${site} ${sid}"
    touch ${output}/dwi.multi.missing
	fi

	cp ${params}/multi.bvals.txt ${output}/dwi.multi.bvals.txt 
	cp ${params}/multi.bvecs.txt ${output}/dwi.multi.bvecs.txt 
fi

if [ ! -e ${output}/mge.nii.gz ]; then
	if [ -e ${input}/${mge}/data.nii.gz ]; then
		ln ${input}/${mge}/data.nii.gz ${output}/mge.nii.gz
	else
		repeats=${input}/${mge}.repeat.*/data.nii.gz
		files=( $repeats )
		repeat=${files[0]}
		if [ -e ${repeat} ]; then
			ln ${files[0]} ${output}/mge.nii.gz
		else
			echo "mge missing for ${site} ${sid}"
			touch ${output}/mge.missing
		fi
	fi

	ln ${params}/te.txt ${output}/mge.te.txt 
fi

if [ ! -e ${output}/mt.high.nii.gz ]; then
	if [ -e ${input}/${mtlow}/data.nii.gz ]; then
		ln ${input}/${mtlow}/data.nii.gz ${output}/mt.low.nii.gz
	else
		repeats=${input}/${mtlow}.repeat.*/data.nii.gz
		files=( $repeats )
		repeat=${files[0]}
		if [ -e ${repeat} ]; then
			ln ${files[0]} ${output}/mtlow.nii.gz
		else
			echo "mt low missing for ${site} ${sid}"
			touch ${output}/mt.low.missing
		fi
	fi

	if [ -e ${input}/${mthigh}/data.nii.gz ]; then
		ln ${input}/${mthigh}/data.nii.gz ${output}/mt.high.nii.gz
	else
		repeats=${input}/${mthigh}.repeat.*/data.nii.gz
		files=( $repeats )
		repeat=${files[0]}
		if [ -e ${repeat} ]; then
			ln ${files[0]} ${output}/mthigh.nii.gz
		else
			echo "mt high missing for ${site} ${sid}"
			touch ${output}/mt.high.missing
		fi
	fi
fi

echo "finished"

################################################################################
# END
################################################################################
