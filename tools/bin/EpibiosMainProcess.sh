#! /usr/bin/env bash 

usage()
{
    echo "
Name: $(basename $0)

Description:

  Process an EPIBIOS case.
    
Usage: 

  $(basename $0) [opts] --case case [targets]

Required Input Data:

   --case <dn>: the case directory 

Optional Input Data:

   --input <dn>: the path to the raw imaging data (Bruker or Agilent directory).
                 this is only required the first time you run the script.

   --multi: enable multi-shell dwi processing

   --stats <dn>: the site-specific population statistical atlas

Author: Ryan Cabeen
"

exit 1
}

if [ $# -eq 0 ]; then usage; fi

root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
makefile=${root}/EpibiosAuxProcess.makefile
name=$(basename $0)

case=$(pwd)
input=
stats=
multi=""
posit=""

while [ "$1" != "" ]; do
    case $1 in
        --input)        shift; input=$1 ;;
        --stats)        shift; stats=$1 ;;
        --case)         shift; case=$1 ;;
        --multi)        multi='MULTI=1' ;;
        --help )        usage ;;
        * )             posit="${posit} $1" ;;
    esac
    shift
done

if [ "${input}" != "" ]; then
  input=$(cd ${input} && pwd -P)
fi

if [ "${stats}" != "" ]; then
  stats=$(cd ${stats} && pwd -P)
else
  stats=$(pwd)
fi


targets=${posit}

if [ ! ${targets} ]; then
  targets=all
fi

echo "started ${name}"
echo "  using makefile: ${makefile}"
echo "  using stats: ${stats}"
echo "  using input: ${input}"
echo "  using case: ${case}"
echo "  using targets: ${targets}"

if [ ! -e ${case}/native.source ]; then
  if [ ! -e ${input} ]; then
    echo "error, invalid input: ${input}"; exit 1
  fi

  bash ${root}/EpibiosAuxConvert.sh ${input} ${case}/native.source
fi

args="-k -C ${case} -f ${makefile} ${multi} STATS=${stats} ${posit}"

mkdir -p ${case}
echo "running: make ${args}"
make ${args}

 
echo "finished"

################################################################################
# END
################################################################################

