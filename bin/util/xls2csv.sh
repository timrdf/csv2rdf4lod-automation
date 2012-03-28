#!/bin/bash
#
# https://github.com/timrdf/csv2rdf4lod-automation/blob/master/bin/util/xls2csv.sh
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

CSV2RDF4LOD_HOME=${CSV2RDF4LOD_HOME:?"not set; source csv2rdf4lod/source-me.sh or see https://github.com/timrdf/csv2rdf4lod-automation/wiki/CSV2RDF4LOD-not-set"}

# Java dependencies; relative to $CSV2RDF4LOD_HOME
for jar in                                              \
           lib/javacsv2.0/javacsv.jar                   \
           lib/poi/poi-3.8-beta2-20110408.jar               \
           lib/poi/poi-examples-3.8-beta2-20110408.jar      \
           lib/poi/poi-excelant-3.8-beta2-20110408.jar      \
           lib/poi/poi-ooxml-3.8-beta2-20110408.jar         \
           lib/poi/poi-ooxml-schemas-3.8-beta2-20110408.jar \
           lib/poi/poi-scratchpad-3.8-beta2-20110408.jar    \
           bin/dup/csv2rdf4lod.jar ; do
   if [[ $CLASSPATH != *`basename $jar`* ]]; then
      if [ ${CSV2RDF4LOD_CONVERT_DEBUG_LEVEL:="."} == "fine" ]; then
         echo "`basename $jar` not in classpath; adding $CSV2RDF4LOD_HOME/$jar"
      fi
      export CLASSPATH=$CLASSPATH:$CSV2RDF4LOD_HOME/$jar # TODO: export? : vs ; cygwin
   fi
done

if [[ $# -lt 1 || "$1" == "--help" ]]; then
   echo "usage: `basename $0` xls [xls...]"
   if [ ${CSV2RDF4LOD_CONVERT_DEBUG_LEVEL:="."} == "fine" ]; then
      echo $CLASSPATH
   fi
   exit 1
fi

memory="-Xmx3060m"
#while [ $# -gt 0 ]; do
#   xls="$1"
   java $memory -cp $CLASSPATH edu.rpi.tw.data.excel.XLStoCSV $*
#   shift
#done
