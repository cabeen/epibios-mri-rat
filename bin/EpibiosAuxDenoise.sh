#! /usr/bin/env bash 
##############################################################################
#
# EPIBIOS
#
#   A script for denoising volumetric image data 
#
#     input: a multi-channel nifti volume
#     output: the denoised result
#
# Author: Ryan Cabeen
#
##############################################################################

root="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && cd .. && pwd)"
name=$(basename $0)

if [ $# -ne "2" ]; then
    echo "Usage: ${name} <input_dir> <output_dir>"
    exit
fi

input=${1}
output=${2}

echo "started ${name}"
echo "  using input: ${input}"
echo "  using output: ${output}"

# I found that the default settings tended to oversmooth and to run very slowly
# So use a patch and radius that do not include the fourth channel
DenoiseImage -v 1 -d 4 -p 1x1x1x0 -r 2x2x2x0 -i ${input} -o ${output}

echo "finished"

################################################################################
# END
################################################################################
