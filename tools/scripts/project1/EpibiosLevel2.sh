#! /usr/bin/env bash 
################################################################################
# conversion to nifti
################################################################################

echo "started"

workflow="$(cd "$(dirname "${BASH_SOURCE[0]}")" && cd ../.. && pwd)"

for input in level1/*/*; do
  site=$(basename $(dirname ${input}))
	output=$(echo ${input} | sed 's/level1/level2/')
	if [ ! -e ${output} ]; then
		qsubcmd bash ${workflow}/bin/EpibiosConvert.sh ${input} ${site} ${output}
	fi
done

echo "finished"

################################################################################
# END
################################################################################
