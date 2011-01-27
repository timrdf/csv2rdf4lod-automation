#!/bin/bash

usage="usage: `basename $0` file [file] ..."

if [ $# -lt 1 ]; then
   echo $usage
   exit 1
fi

while [ $# -gt 0 ]; do
   file="$1"
   if [ `which md5 2> /dev/null` ]; then
      # md5 outputs:
      # MD5 (pcurl.sh) = ecc71834c2b7d73f9616fb00adade0a4
      md5 $file | perl -pe 's/^.* = //'
   elif [ `which md5sum 2> /dev/null` ]; then
      md5sum $file | perl -pe 's/\s.*//'
      # md5sum 1008/urls.txt 
      # 06c63f2da8419e3791531cbabaaccc9c  1008/urls.txt
   else
      echo "`basename $0`: can not find md5 to run."
   fi
   shift
done
