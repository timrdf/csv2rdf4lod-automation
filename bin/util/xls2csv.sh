#!/bin/bash
#
# https://github.com/timrdf/csv2rdf4lod-automation/blob/master/bin/util/xls2csv.sh

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

if [ $# -lt 1 ]; then
   echo "usage: `basename $0` xls [xls...]"
   if [ ${CSV2RDF4LOD_CONVERT_DEBUG_LEVEL:="."} == "fine" ]; then
      echo $CLASSPATH
   fi
   exit 1
fi

while [ $# -gt 0 ]; do
   xls="$1"
   echo $xls
   java edu.rpi.tw.data.excel.XLStoCSV $xls
   shift
done
