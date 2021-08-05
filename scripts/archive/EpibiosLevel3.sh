#! /usr/bin/env bash 
################################################################################
#
# Author: Ryan Cabeen
#
################################################################################

echo "started processing data"

root="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd ../.. && pwd )"
stats=/ifs/loni/postdocs/rcabeen/collab/epibios/rat-common/stats

for input in level2/*/*; do
  output=$(echo ${input} | sed 's/level2/level3/g')
  qsubcmd --qlog .qlog --qbase epibios_${site}_$(basename ${input}) \
    bash ${root}/bin/EpibiosProcess.sh ${stats} ${input}/common ${output} $@
done

echo "finished"

################################################################################
# END
################################################################################
