#! /bin/bash

cd $(dirname $0)
cd ../..

# todo: add stats

for c in process/*/*; do 
  qsubcmd \
    --qbase epibios-$(basename ${c}) \
    --qlog ${c}/log \
    EpibiosMainProcess.sh \
      --case ${c} \
      --multi
done
