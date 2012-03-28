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
#
# https://github.com/timrdf/csv2rdf4lod-automation/blob/master/bin/util/cr-headers.sh
#
# Usage:
#
#    cr-headers.sh --number 2011-Nov-28/source/WhiteHouse-WAVES-Released-0611.csv 
#    1 NAMELAST
#    2 NAMEFIRST
#    3 NAMEMID
#    4 UIN
#    5 BDGNBR
#    6 ACCESS_TYPE


CSV2RDF4LOD_HOME=${CSV2RDF4LOD_HOME:?"not set; source csv2rdf4lod/source-me.sh or see https://github.com/timrdf/csv2rdf4lod-automation/wiki/CSV2RDF4LOD-not-set"}

# cr:data-root cr:source cr:directory-of-datasets cr:dataset cr:directory-of-versions cr:conversion-cockpit
ACCEPTABLE_PWDs="cr:directory-of-versions cr:conversion-cockpit"
if [ `${CSV2RDF4LOD_HOME}/bin/util/is-pwd-a.sh $ACCEPTABLE_PWDs` != "yes" ]; then
   ${CSV2RDF4LOD_HOME}/bin/util/pwd-not-a.sh $ACCEPTABLE_PWDs
   exit 1
fi

write="no"
if [[ "$1" == "-w" || "$1" == "--write" ]]; then
   write="yes"
   shift
fi

# If a file is given, print its headers
if [ $# -gt 0 ]; then

   number=""
   if [[ "$1" == "-N" || "$1" == "--number" ]]; then
      number="--number"
      shift
   fi

   while [ $# -gt 0 ]; do
      csv="$1"
      java edu.rpi.tw.data.csv.impl.CSVHeaders $csv $number
      shift
   done
   exit 0
fi

if [ `$CSV2RDF4LOD_HOME/bin/util/is-pwd-a.sh cr:conversion-cockpit` == "yes" ]; then
   echo TODO
elif [ `$CSV2RDF4LOD_HOME/bin/util/is-pwd-a.sh cr:directory-of-versions` == "yes" ]; then
   for version in `find . -depth 1 -type d | grep -v "...svn"`; do
      let count=0
      for csv in $version/source/*.csv; do
         let count=count+1
         if [ $count -eq 1 ]; then
            header_filename="$version/manual/headers.txt"
         else
            header_filename="$version/manual/headers.$count.txt"
         fi
         echo "$csv -> $header_filename"
         if [ "$write" == "yes" ]; then
            java edu.rpi.tw.data.csv.impl.CSVHeaders $csv --number | grep "^[^\s]" > $header_filename
         fi
      done
   done
else
   echo "huh"
fi

if [[ "$write" != "yes" ]]; then
   echo 
   echo "(use '`basename $0` -w' to write files.)"
fi

