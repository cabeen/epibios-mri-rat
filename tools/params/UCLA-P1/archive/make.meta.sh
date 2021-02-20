#! /bin/bash

fn=subjects.csv; 

echo subject,id,tp > ${fn}
for s in ../../level1/UCLA/UCLA_*/*; do 
  b=$(basename $s); 
  t=$(echo $(basename $(dirname ${s})) | sed 's/UCLA_//g' | sed 's/_.*//g' | sed 's/day/d/g' | sed 's/mon/mo/g')
  i=$(echo ${b} | sed 's/.*_//g' | sed 's/\..*//g')
  echo ${b},${i},${t} >> ${fn}
done 

cat subjects.csv | awk 'BEGIN{FS=",";OFS=","}{print $1,$2,$3,$2"_"$3}' > left.csv
cat groups.csv | awk 'BEGIN{FS=",";OFS=","}{print $1,$2,$3,$1"_"$3}' > right.csv

qit TableMerge --left left.csv --right right.csv --rightField id_tp --leftField id_tp --output meta.csv
qit TableSelect --exclude name --input meta.csv --output meta.csv 
