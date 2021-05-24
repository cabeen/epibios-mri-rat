#! /bin/bash

cd /ifs/loni/postdocs/rcabeen/collab/epibios/rat-project2/process

for s in *; do
  echo; echo Site: ${s}

  for c in ${s}/*; do
    echo "total cases were found"
    if [ -e ${c}/native.source/common/dwi.nii.gz ]; then 
      echo "have a single-shell dwi scan in total";
      if [ -e ${c}/native.source/common/dwi.bvals.txt ]; then
        ng=$(wc -w ${c}/native.source/common/dwi.bvals.txt | awk '{print $1}')
        nc=$(fslhd ${c}/native.source/common/dwi.nii.gz | grep ^dim4 | awk '{print $2}')
        echo "have a single-shell dwi with ${ng} gradient directions and ${nc} dwi channels"
      else
        echo "have a single-shell dwi scan but no gradients"
      fi
    else
      echo "have no single-shell dwi scan in total";
    fi

    if [ -e ${c}/native.source/common/dwi.multi.nii.gz ]; then 
      echo "have a multi-shell dwi scan in total";
      if [ -e ${c}/native.source/common/dwi.multi.bvals.txt ]; then
        ng=$(wc -w ${c}/native.source/common/dwi.multi.bvals.txt | awk '{print $1}')
        nc=$(fslhd ${c}/native.source/common/dwi.multi.nii.gz | grep ^dim4 | awk '{print $2}')
        echo "have a multi-shell dwi with ${ng} gradient directions and ${nc} dwi channels"
      else
        echo "have a multi-shell dwi scan but no gradients"
      fi
    else
      echo "have no multi-shell dwi scan in total";
    fi
    if [ -e ${c}/native.source/common/rare.nii.gz ]; then echo "have a rare scan"; fi
    if [ -e ${c}/native.source/common/mge.nii.gz ]; then echo "have an mge scan"; fi
  done | sort | uniq -c
done
echo
