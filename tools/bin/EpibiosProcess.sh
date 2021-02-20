#! /usr/bin/env bash 
##############################################################################
#
# EPIBIOS
#
#   A script for running level five of the analysis on a single subject
#
# Author: Ryan Cabeen
#
##############################################################################

root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
makefile=${root}/EpibiosProcess.makefile

name=$(basename $0)

if [ $# -lt "3" ]; then
  echo "Usage: ${name} <stats> <input> <output> [optional_targets]"; exit
fi

stats=${1}
input=${2}
output=${3}
targets=${@:4}

input=$(cd ${input} && pwd -P)

if [ ! ${targets} ]; then
  targets=all
fi

echo "started ${name}"
echo "  using makefile: ${makefile}"
echo "  using stats: ${stats}"
echo "  using input: ${input}"
echo "  using output: ${output}"
echo "  using targets: ${targets}"

mkdir -p ${output}
make -k -C ${output} -f ${makefile} INPUT=${input} STATS=${stats} ${targets}

echo "finished"

################################################################################
# END
################################################################################
