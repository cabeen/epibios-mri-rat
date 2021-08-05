#! /bin/bash

cd $(dirname $0)
cd ../..

echo UCLA-P2 9d 09d 9D 5m Melbourne-P2 9d D9 5M M5 Finland-P2 9d d9 5mo Einstein-P2 9Day 5Month

cmd="qsubcmd --qbigmem qit -Xmx8G VolumeFuse --verbose --debug --skip"

mkdir -p group/fuse

for t in fit harm; do
  #for p in dti_FA dti_RD dti_AD  dti_MD dti_S0 \
  #         fwdti_FA fwdti_MD fwdti_S0 fwdti_AD fwdti_FW fwdti_RD \
  #         noddi_fiso noddi_ficvf  noddi_odi \
  #         mge_mean mge_r2star mge_t2star; do

  for p in mge_mean mge_r2star mge_t2star; do

    ${cmd} \
      --input process/UCLA-P2/*_{9d,09d,9D}*/atlas.*/param/${t}/${p}.nii.gz \
      --output-mean group/fuse/UCLA-P2-${t}-${p}-early-mean.nii.gz \
      --output-std group/fuse/UCLA-P2-${t}-${p}-early-std.nii.gz

    ${cmd} \
      --input process/UCLA-P2/*_5m*/atlas.*/param/${t}/${p}.nii.gz \
      --output-mean group/fuse/UCLA-P2-${t}-${p}-late-mean.nii.gz \
      --output-std group/fuse/UCLA-P2-${t}-${p}-late-std.nii.gz

    ${cmd} \
      --input process/Melbourne-P2/*_{9d,D9}*/atlas.*/param/${t}/${p}.nii.gz \
      --output-mean group/fuse/Melbourne-P2-${t}-${p}-early-mean.nii.gz \
      --output-std group/fuse/Melbourne-P2-${t}-${p}-early-std.nii.gz

    ${cmd} \
      --input process/Melbourne-P2/*_{5M,M5}*/atlas.*/param/${t}/${p}.nii.gz \
      --output-mean group/fuse/Melbourne-P2-${t}-${p}-late-mean.nii.gz \
      --output-std group/fuse/Melbourne-P2-${t}-${p}-late-std.nii.gz

    ${cmd} \
      --input process/Finland-P2/*_{9d,d9}*/atlas.*/param/${t}/${p}.nii.gz \
      --output-mean group/fuse/Finland-P2-${t}-${p}-early-mean.nii.gz \
      --output-std group/fuse/Finland-P2-${t}-${p}-early-std.nii.gz

    ${cmd} \
      --input process/Finland-P2/*_5mo*/atlas.*/param/${t}/${p}.nii.gz \
      --output-mean group/fuse/Finland-P2-${t}-${p}-late-mean.nii.gz \
      --output-std group/fuse/Finland-P2-${t}-${p}-late-std.nii.gz

    ${cmd} \
      --input process/Einstein-P2/*_9Day*/atlas.*/param/${t}/${p}.nii.gz \
      --output-mean group/fuse/Einstein-P2-${t}-${p}-early-mean.nii.gz \
      --output-std group/fuse/Einstein-P2-${t}-${p}-early-std.nii.gz

    ${cmd} \
      --input process/Einstein-P2/*_5Month*/atlas.*/param/${t}/${p}.nii.gz \
      --output-mean group/fuse/Einstein-P2-${t}-${p}-late-mean.nii.gz \
      --output-std group/fuse/Einstein-P2-${t}-${p}-late-std.nii.gz
  done
done
