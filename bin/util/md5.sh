#!/bin/bash
#
#   Copyright 2012 Timothy Lebo
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.

usage="usage: `basename $0` [-qs <string>] | [<file> [file]*]"

if [ $# -lt 1 ]; then
   echo $usage
   exit 1
fi

if [ "$1" == "-qs" ]; then
   shift
   if [ `which md5 2> /dev/null` ]; then
      md5 -qs "$*"
   elif [ `which md5sum 2> /dev/null` ]; then
      TEMP="_"`basename $0``date +%s`_$$.tmp
      echo $* > $TEMP
      md5.sh $TEMP
      rm $TEMP
   else
      echo "`basename $0`: can not find md5 to run."
   fi
   exit
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

      #echo hi | md5sum | awk '{print $1}'
   else
      echo "`basename $0`: can not find md5 to run."
   fi
   shift
done
