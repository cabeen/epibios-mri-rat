#! /bin/bash

cd /ifs/loni/postdocs/rcabeen/collab/epibios/rat-project1
common=/ifs/loni/postdocs/rcabeen/collab/epibios/rat-common

for c in cases/sources/*/*; do

  logdir=$(echo ${c} | sed 's/sources/log/g')
  mkdir -p ${logdir} 

  qsubcmd --qlog ${logdir} bash \
   ${common}/tools/repo/tools/bin/EpibiosMainProcess.sh \
   ${common}/stats \
   ${c} \
   $(echo ${c} | sed 's/sources/process/g')

done

