#!/bin/sh

if [ $# -lt 1 ]; then
   echo "usage: `basename $0` [-a] dataset-id [dataset-id ...]"
fi

printAll="no"
if [ $1 == "-a" ]; then
   printAll="yes"
   shift
fi

if [ $# -gt 1 ]; then
   printBoth=1
fi

while [ $# -gt 0 ]; do
   
   # TODO: use $rutil/bin/urlmoddate.sh to get dates. NOTE: urlmoddate.sh does NOT follow redirects anymore.

   modDate=`curl -s -I -L http://www.data.gov/download/$1/csv | grep "Last-Modified:" | awk '{printf("%s-%s-%s\n",$5,$4,$3)}' 2> /dev/null`
   if [ $printBoth ]; then
      echo $1 $modDate
   else
      echo $modDate
   fi 
   if [ $printAll == "yes" ]; then
      # TODO: use $rutil/bin/urlmoddate.sh to get dates
      curl -s -I -L http://www.data.gov/download/$1/csv
      curl -s -I -L http://www.data.gov/download/$1/csv | grep "Last-Modified:" | awk '{num["Jan"]="01";num["Feb"]="02";num["Mar"]="03";num["Apr"]="04";num["May"]="05";num["Jun"]="06";num["Jul"]="07";num["Aug"]="08";num["Sep"]="09";num["Oct"]="10";num["Nov"]="11";num["Dec"]="12";printf("%s-%s-%sT%s\n",$5,num[$4],$3,$6)}' 2> /dev/null
   fi
   shift 
done
