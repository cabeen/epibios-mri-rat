#! /usr/bin/env bash 
################################################################################
# Author: Ryan Cabeen
################################################################################

echo "started processing data level 4"

workflow=$(cd $(dirname "${BASH_SOURCE[0]}"); cd ../..; pwd -P)

function catit
{
  site=$1
  input=level3/${site}/%{subject}/$2
  output=level4/tables/${site}/$(echo $2 | sed 's/\//\./g')

  if [ ! -e ${output} ]; then
    mkdir -p $(dirname ${output})

    qsubcmd "qit --verbose MapCat \
        --pattern ${input} \
        --vars subject=${workflow}/params/${site}/sids.txt \
        --skip --rows \
        --output ${output} && \
      qit --verbose TableMerge \
        --field subject \
        --left ${workflow}/params/${site}/meta.csv \
        --right ${output} \
        --output ${output} && \
      qit --verbose TableSelect \
        --constant site=${site} \
        --input ${output} \
        --output ${output} && \
      cat ${output} | sed 's/null/NA/g' > ${output}.tmp && \
      mv ${output}.tmp ${output}"
  fi
}

for site in {Finland,UCLA,Melbourne}-P1; do
  mkdir -p level4/tables/${site}

  cp ${workflow}/params/${site}/pte.csv level4/tables/${site}/pte.csv
  cp ${workflow}/params/${site}/meta.csv level4/tables/${site}/meta.csv
  for map in $(cat ${workflow}/params/Common/maps.txt); do
    catit ${site} ${map}
  done
done

echo "finished"

################################################################################
# END
################################################################################
