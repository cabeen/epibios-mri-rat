#! /bin/bash

cd $(dirname $0)
cd ../../../../staging

for c in */*/*; do
  qsubcmd --qbase epibios --qlog ../process/${c}/log \
    EpibiosMainProcess.sh --source ${c} --case ../process/${c}
done
