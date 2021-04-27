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
cd "$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && cd ../../.. && pwd )/data"

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
mge=MGE
mtlow=FLASH_No_On
mthigh=FLASH_Yes_On

if [ ${site} == "Melbourne" ]; then
	mtlow=FLASH_Yes_On
	mthigh=FLASH_Yes_On.repeat
fi

params=${workflow}/params/${site}

mkdir -p ${output}

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
