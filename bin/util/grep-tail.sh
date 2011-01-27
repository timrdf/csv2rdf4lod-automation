#!/bin/bash
#
# grep-tail.awk
#
# Print the end of a file, starting from the line that matches a given pattern.
# If no pattern is provided, defaults to /^# CSV2RDF4LOD DATASET METADATA.*$/ 
# (what edu.rpi.tw.data.csv.CSVtoRDF.java outputs to indicate VoID subset).
#
# Example usage:
#   bash-3.2$ cr-list-sources-datasets.sh 
#      dan-project
#      eia
#      energy-visuals
#      epa-thermal-emissions
#      stack-heights
#      transfer-coefficents
#   bash-3.2$ cr-list-sources-datasets.sh | grep-tail.sh -p ^epa- -
#      epa-thermal-emissions
#      stack-heights
#      transfer-coefficents

usage="usage: `basename $0` [-p <begin-tail-pattern>] csv2rdf4lod-output.ttl [csv2rdf4lod-output.ttl]..."

if [ $# -lt 1 ]; then
   echo $usage
   exit 1
fi

beginTailRegex='^# CSV2RDF4LOD DATASET METADATA.*$'
if [ "$1" == "-p" ]; then
   beginTailRegex="$2" 
   shift 2
fi

while [ $# -gt 0 ]; do
   file=$1
   if [ $file == "-" ]; then
      file=/dev/stdin
   fi
   #cat $file | awk '                               BEGIN { printYet="false"; }
   #                 /^# CSV2RDF4LOD DATASET METADATA.*$/ { printYet="true"; }
   #                                                      { if(printYet == "true") print }'
   cat $file | awk "            BEGIN { printYet=\"false\"; }
                    /$beginTailRegex/ { printYet=\"true\"; }
                                      { if(printYet == \"true\") print }"
   shift
done
