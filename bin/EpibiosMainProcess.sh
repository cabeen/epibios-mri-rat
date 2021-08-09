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

   --source <dn>: the path to the raw imaging data (Bruker or Agilent 
                  directory).  this is only required the first time 
                  you run the script.

   --multi: enable multi-shell dwi processing

Author: Ryan Cabeen
"

exit 1
}

if [ $# -eq 0 ]; then usage; fi

root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
makefile=${root}/EpibiosAuxProcess.makefile
name=$(basename $0)

case=$(pwd)
source=
multi=""
site=""
time=""
stats=""
posit=""

while [ "$1" != "" ]; do
    case $1 in
        --source)       shift; source=$1 ;;
        --case)         shift; case=$1 ;;
        --time)         shift; time=$1 ;;
        --site)         shift; site=$1 ;;
        --stats)        shift; stats=$1 ;;
        --multi)        multi='MULTI=1' ;;
        --help )        usage ;;
        * )             posit="${posit} $1" ;;
    esac
    shift
done

if [ "${source}" != "" ]; then
  source=$(cd ${source} && pwd -P)
fi

targets=${posit}

if [ ! ${targets} ]; then
  targets=all
fi

echo "started ${name}"
echo "  using makefile: ${makefile}"
echo "  using source: ${source}"
echo "  using case: ${case}"
echo "  using site: ${site}"
echo "  using time: ${time}"
echo "  using stats: ${stats}"
echo "  using targets: ${targets}"

if [ ! -e ${case}/native.source ]; then
  if [ ! -e ${source} ]; then
    echo "error, invalid source: ${source}"; exit 1
  fi

  bash ${root}/EpibiosAuxConvert.sh ${source} ${case}/native.source
fi

args="-k -C ${case} -f ${makefile} ${multi} ${posit}"

if [ "${time}" != "" ]; then args="${args} TIME=${time}"; fi
if [ "${site}" != "" ]; then args="${args} SITE=${site}"; fi
if [ "${stats}" != "" ]; then args="${args} STATS=${stats}"; fi

mkdir -p ${case}
echo "running: make ${args}"
make ${args}
 
echo "finished"

################################################################################
# END
################################################################################

