#! /usr/bin/env bash 
################################################################################
# Author: Ryan Cabeen
################################################################################

echo "started processing data"
root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && cd ../.. && pwd)"

mkdir -p level4/vis
for site in Finland-P1 UCLA-P1 Melbourne-P1; do 
  for group in shams tbi.{2d,9d,1mo,5mo}; do
    for sid in $(cat ${root}/params/${site}/${group}.txt); do 
      for vis in anatomy lesion; do 
        for param in small_{dti_S0,dti_FA,dti_MD}; do 
          in=level3/${site}/${sid}/atlas.dwi/vis/${param}_${vis}.png
          out=level4/vis/${param}_${site}_${group}_${sid}_${vis}.png; 
          if [ -e ${in} ] && [ ! -e ${out} ]; then
            ln ${in} ${out}
          fi
        done 

        for param in small_{mge_mean,mge_r2star,mge_t2star}; do 
          in=level3/${site}/${sid}/atlas.mge/vis/${param}_${vis}.png
          out=level4/vis/${param}_${site}_${group}_${sid}_${vis}.png; 
          if [ -e ${in} ] && [ ! -e ${out} ]; then
            ln ${in} ${out}
          fi
        done 
      done
    done 
  done
done

echo "finished"

################################################################################
# END
################################################################################
