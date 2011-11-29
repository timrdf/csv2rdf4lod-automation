#!/bin/bash

CSV2RDF4LOD_HOME=${CSV2RDF4LOD_HOME:?"not set; source csv2rdf4lod/source-me.sh or see https://github.com/timrdf/csv2rdf4lod-automation/wiki/CSV2RDF4LOD-not-set"}

# Java dependencies; relative to $CSV2RDF4LOD_HOME
for jar in                                              \
           lib/javacsv2.0/javacsv.jar                   \
           lib/poi-3.8-beta2-20110408.jar               \
           lib/poi-examples-3.8-beta2-20110408.jar      \
           lib/poi-excelant-3.8-beta2-20110408.jar      \
           lib/poi-ooxml-3.8-beta2-20110408.jar         \
           lib/poi-ooxml-schemas-3.8-beta2-20110408.jar \
           lib/poi-scratchpad-3.8-beta2-20110408.jar    \
           bin/dup/csv2rdf4lod.jar ; do
   if [[ $CLASSPATH != *`basename $jar`* ]]; then
      if [ ${CSV2RDF4LOD_CONVERT_DEBUG_LEVEL:="."} == "fine" ]; then
         echo "`basename $jar` not in classpath; adding $CSV2RDF4LOD_HOME/$jar"
      fi
      export CLASSPATH=$CLASSPATH:$CSV2RDF4LOD_HOME/$jar # TODO: export? : vs ; cygwin
   fi
done



