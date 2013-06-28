#!/bin/bash
#
#3> <> prov:specializationOf <https://github.com/timrdf/csv2rdf4lod-automation/blob/master/bin/util/install-csv2rdf4lod-dependencies.sh> .

HOME=$(cd ${0%/*/*} && echo ${PWD%/*})
export PATH=$PATH`$HOME/bin/util/cr-situate-paths.sh`
export CLASSPATH=$CLASSPATH`$HOME/bin/util/cr-situate-classpaths.sh`
CSV2RDF4LOD_HOME=${CSV2RDF4LOD_HOME:?$HOME}

while [ $# -gt 0 ]; do
   eparams="$1"
   shift
   if [ -e $eparams ]; then
      java edu.rpi.tw.data.csv.impl.UsefulEnhancements $eparams 2> /dev/null
   fi
done
