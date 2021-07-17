# /bin/bash

cd $(dirname $0)

echo "subject,tp,id" > subjects.a.csv
cat subjects.a.txt | awk '{
  tp="tp"
  if (match($0, /D02/)) { 
    tp="2d"
  } else if (match($0, /D09/)) { 
    tp="9d"
  } else if (match($0, /W04/)) { 
    tp="1mo"
  } else if (match($0, /D28/)) { 
    tp="1mo"
  } else if (match($0, /M01/)) { 
    tp="1mo"
  } else if (match($0, /M05/)) { 
    tp="5mo"
  } else if (match($0, /W04/)) { 
    tp="5mo"
  }
  x=$0
  gsub("_M_.*","")
  id=substr($0, length($0)-3, length($0))
  print(x","tp","id)}' >> subjects.a.csv

qit TableMerge \
  --field id \
  --left subjects.a.csv \
  --right group.csv \
  --output subjects.a.csv

echo "subject,tp,id" > subjects.b.csv
for r in $(cat subjects.b.txt | sed 's/.*Rat/Rat/g' | sed 's/_.*//g' | sort | uniq); do 
  grep ${r} subjects.b.txt \
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
  print(x","tp","$0)}' >> subjects.b.csv
done

qit TableMerge \
  --field id \
  --left subjects.b.csv \
  --right group.csv \
  --output subjects.b.csv

qit TableCat \
  --x subjects.a.csv \
  --y subjects.b.csv \
  --output meta.csv
