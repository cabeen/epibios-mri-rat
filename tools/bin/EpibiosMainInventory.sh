#! /bin/bash

cd /ifs/loni/postdocs/rcabeen/collab/epibios/rat-project2/process

for s in *; do
  echo; echo Site: ${s}

  for c in ${s}/*; do
    echo "cases were found"
    if [ -e ${c}/native.source/common/dwi.nii.gz ]; then echo "have a dwi scan"; fi
    if [ -e ${c}/native.source/common/rare.nii.gz ]; then echo "have a rare scan"; fi
    if [ -e ${c}/native.source/common/mge.nii.gz ]; then echo "have an mge scan"; fi
  done | sort | uniq -c
done
echo
