#! /usr/bin/env bash 
################################################################################
#
# EPIBIOS
#
#   Process data to level6
#
# Author: Ryan Cabeen
#
################################################################################

echo "started processing data level 6"

root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && cd ../.. && pwd)"

mkdir -p level4/tables/Combined
for map in $(cat ${root}/params/Common/maps.txt); do
  base=$(echo ${map} | sed 's/\//\./g')
  if [ ! -e level4/tables/Combined/${base} ]; then
    qsubcmd qit --verbose TablesCat \
      --input level4/tables/{UCLA,Melbourne,Finland}/${base} \
      --output level4/tables/Combined/${base}
  fi
done

echo "finished"

################################################################################
# END
################################################################################
