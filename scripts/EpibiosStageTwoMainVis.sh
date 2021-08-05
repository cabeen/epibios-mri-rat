#! /usr/bin/env bash 
################################################################################
# Author: Ryan Cabeen
################################################################################

echo "started"

cd $(dirname $0)
cd ../../../..

mkdir -p group/vis

for c in process/*/*/*; do
  echo ${c}
  sid=$(basename ${c})
  tp=$(basename $(dirname ${c}))
  site=$(basename $(dirname $(dirname ${c})))

  for vis in anatomy lesion; do 
    for param in small_{dti_S0,dti_FA,dti_MD,fwdti_FA,fwdti_MD,fwdti_FW,noddi_odi,noddi_ficvf,noddi_fiso}; do 
      in=${c}/atlas.dwi/vis/${param}_${vis}.png
      out=group/vis/${param}_${site}_${tp}_${sid}_${vis}.png; 
      if [ -e ${in} ] && [ ! -e ${out} ]; then
        ln ${in} ${out}
      fi
    done 

    for param in small_{mge_mean,mge_r2star,mge_t2star}; do 
      in=${c}/atlas.mge/vis/${param}_${vis}.png
      out=group/vis/${param}_${site}_${tp}_${sid}_${vis}.png; 
      if [ -e ${in} ] && [ ! -e ${out} ]; then
        ln ${in} ${out}
      fi
    done 
  done
done

echo "finished"

################################################################################
# END
################################################################################
