#! /usr/bin/env bash 
##############################################################################
#
# EPIBIOS
#
#   A script for importing data for the EPIBIOS project. This will convert
#   all of the data from a given subject directory from the Bruker format to
#   nifti. 
#
# Author: Ryan Cabeen
#
##############################################################################

ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

name=$(basename $0)

if [ $# -ne "2" ]; then
    echo "Usage: ${name} <input_dir> <output_dir>"
    exit
fi

input=${1}
output=${2}

mkdir -p ${output}

echo "started ${name}"
echo "  using input: ${input}"
echo "  using output: ${output}"

for dir in ${input}/*; do
  if [ -e ${dir}/method ]; then
    echo "  ... processing case: ${dir}"
    tmp=${output}.tmp.${RANDOM}
    log=${tmp}/log.txt

    mkdir -p ${tmp}
    python3 ${ROOT}/EpibiosAuxBrukerParse.py \
      ${dir}/method \
      --write-header ${tmp}/header.json \
      --write-param ${tmp}/param.json
    scan=$(python3 ${ROOT}/EpibiosAuxBrukerIdentify.py ${tmp}/param.json)
    outdir=${output}/${scan}
      
    echo "EPIBIOS import log" > ${log}
    echo "  date: $(date)" >> ${log}
    echo "  input: ${input}" >> ${log}
    echo "  output: ${output}" >> ${log}
    echo "  exp id: $(basename ${dir})" >> ${log}
    echo "  exp name: ${scan}" >> ${log}
    echo "" >> ${log}
    echo "  bru2nii output: " >> ${log}

    Bru2 -v -z -o ${tmp}/data ${dir} >> ${log} 
    echo "   ...... creating scan ${scan} from subdirectory $(basename ${dir})"

    if [ ! -e ${tmp}/data.nii.gz ]; then
      nout=${outdir}-missing-${RANDOM}
      echo "   ...... [warning] found no image data, moving to ${nout}"
      mv ${tmp} ${nout}
    else
      if [[ ! -e ${outdir} ]] ; then
        echo "   ...... saving result to ${outdir}"
        mv ${tmp} ${outdir}
      elif [[ $(diff ${outdir}/header.json ${tmp}/header.json) ]]; then
        nout=${outdir}-extra-${RANDOM}
        echo "   ...... [warning] found extra image data, moving to ${nout}"
        mv ${tmp} ${nout}
      else
        echo "   ...... [warning] found duplicate data, skipping it"
        rm -rf ${tmp}
      fi
    fi
  fi
done

echo "finished"

################################################################################
# END
################################################################################
