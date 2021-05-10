#! /bin/bash

cd /ifs/loni/postdocs/rcabeen/collab/epibios/rat-project1
common=/ifs/loni/postdocs/rcabeen/collab/epibios/rat-common

for c in cases/staging/*/*; do

  logdir=$(echo ${c} | sed 's/staging/log/g')
  mkdir -p ${logdir} 

  qsubcmd --qlog ${logdir} bash \
   ${common}/repo/tools/bin/EpibiosMainProcess.sh \
   ${common}/stats \
   ${c} \
   $(echo ${c} | sed 's/staging/process/g')

done

