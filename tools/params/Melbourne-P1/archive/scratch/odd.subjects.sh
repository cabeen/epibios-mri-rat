# /bin/bash

cd $(dirname $0)

echo "subject,tp,id" > odd.subjects.csv
for r in $(cat odd.subjects.txt | sed 's/.*Rat/Rat/g' | sed 's/_.*//g' | sort | uniq); do 
  grep ${r} odd.subjects.txt \
    | awk '{
  tp="NA"
  if (NR==1) { 
    tp="2d"
  } else if (NR==2) { 
    tp="9d"
  } else if(NR==3) {
    tp="1mo" 
  } else if (NR==4) {
    tp="5mo"
  } else if (NR==5) {
    tp="5mo2"
  }
  x=$0
  gsub(".*Rat","")
  gsub("_.*","")
  print(x","tp","$0)}' >> odd.subjects.csv 
done

qit TableMerge \
  --field id \
  --left odd.subjects.csv \
  --right P1A2-4.csv \
  --output odd.subjects.csv

