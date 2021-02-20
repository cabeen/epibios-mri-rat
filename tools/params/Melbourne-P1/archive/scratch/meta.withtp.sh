# /bin/bash

cd $(dirname $0)

cat meta.withtp.csv | awk '{
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
  print($0","tp)}' > meta.withtp.col.csv

