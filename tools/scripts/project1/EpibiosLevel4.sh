#! /usr/bin/env bash 
################################################################################
# Author: Ryan Cabeen
###############################################################################

echo "started processing data level 6"

root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && cd .. && pwd)"

function catit
{
  site=$1
  input=level3/${site}/%{subject}/$2
  output=level4/${site}/tables/$(echo $2 | sed 's/\//\./g')

  if [ ! -e ${output} ]; then
    mkdir -p level4/${site}/tables

    qit --verbose MapCat \
      --pattern ${input} \
      --vars subject=${root}/params/${site}/subjects.txt \
      --skip --rows \
      --output ${output}

    if [ -e ${output} ]; then
      qit --verbose TableMerge \
        --field subject \
        --left ${root}/params/${site}/meta.csv \
        --right ${output} \
        --output ${output}
    fi
  fi
}

for site in Finland UCLA Melbourne; do
  mkdir -p level4/${site}

#  catit ${site} native.tract/bundles.map/volume.csv
#  catit ${site} native.tract/bundles.map/num_curves.csv

  catit ${site} atlas.lesion/stats.csv
  catit ${site} atlas.lesion/stats/absz_volume.csv
  catit ${site} atlas.lesion/stats/absz_mean.csv
  catit ${site} atlas.lesion/stats/absz_std.csv
  catit ${site} atlas.lesion/stats/absz_median.csv
  catit ${site} atlas.lesion/stats/absz_iqr.csv
  catit ${site} atlas.lesion/stats/absz_std.csv
  catit ${site} atlas.lesion/stats/absz_qhigh.csv
  catit ${site} atlas.lesion/stats/absz_max.csv
  catit ${site} atlas.lesion/stats/absz_sum.csv

  for p in S0 FA MD; do
    catit ${site} atlas.region/tissue.hemi.dtiz.map/z${p}_mean.csv
  done

  # for space in atlas native; do
  #   for p in S0 FA MD RD AD CS CL CP; do
  #     catit ${site} ${space}.region/perilesion.dtiz.map/z${p}_mean.csv
  #   done
  # done
done

for site in Finland UCLA Melbourne; do
  mkdir -p level4/${site}/plots
  for p in atlas.lesion.stats.absz_{volume,mean,sum,qhigh,max}; do 
    for v in cavity heme; do 
      out=level4/${site}/plots/${p}.${v}.pdf
      if [ ! -e ${out} ]; then
        echo "... plotting ${site} ${p} ${v}"
        Rscript ${root}/bin/EpibiosSummarize.R ${site} ${p} ${v} ${out}
      fi
    done
  done

  for p in atlas.region.tissue.hemi.dtiz.map.z{S0,FA,MD}_mean; do
    for v in {left,right}_{white,gray}; do 
      out=level4/${site}/plots/${p}.${v}.pdf
      if [ ! -e ${out} ]; then
        echo "... plotting ${site} ${p} ${v}"
        Rscript ${root}/bin/EpibiosSummarize.R ${site} ${p} ${v} ${out}
      fi
    done
  done
done

for site in Melbourne Finland UCLA; do
  if [ ! -e level4/site/vis ]; then
    echo "creating visualizations for site: ${site}"
    for sid in $(cat ${root}/params/${site}/subjects.txt); do 
      srcd=level3/${site}/${sid}/atlas.vis
      if [ -e ${srcd} ]; then
        for p in {large,small}_{FA,MD,S0}; do
          outd=level4/${site}/vis/${p}
          mkdir -p ${outd}
          ln ${srcd}/${p}.png ${outd}/${sid}.brain.png
          ln ${srcd}/${p}_lesion.png ${outd}/${sid}.lesion.png
        done
      fi
    done
  fi
done

echo "finished"

################################################################################
# END
################################################################################
