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

if [ $# -lt 1 ]; then
   echo "usage: `basename $0` [-a] [-field dateField] [-format {'simple','dateTime'}] url [url ...]"
   exit 1
fi

printAll="no"
if [ $1 == "-a" ]; then
   printAll="yes"
   shift
fi

FIELD="Date:"
FIELD="Last-Modified:"
if [ $1 == "-field" ]; then
   FIELD=$2
   shift 2
fi

FORMAT="simple"
if [ $1 == "-format" ]; then
   FORMAT=$2
   shift 2
fi

if [ $# -gt 1 ]; then
   printBoth=1
fi

while [ $# -gt 0 ]; do
   url="$1"
   
   #dateFromHTTP=`curl -s -I -L $url | grep $FIELD` # Follow redirects
   dateFromHTTP=`curl -s -I -L $url | grep $FIELD | tail -1`
   dateInSimple=`echo $dateFromHTTP | awk '{printf("%s-%s-%s\n",$5,$4,$3)}' 2> /dev/null`
   dateInXSD=`echo $dateFromHTTP | awk -f $CSV2RDF4LOD_HOME/bin/util/http2xsddatetime.awk 2> /dev/null`

   if [ $printBoth ]; then
      echo $1 $dateInSimple
   else
      if [ $FORMAT == "dateTime" ]; then
         echo $dateInXSD 
      else
         echo $dateInSimple
      fi
   fi 
   if [ $printAll == "yes" ]; then
      echo $dateInXSD 
   fi
   shift 
done
