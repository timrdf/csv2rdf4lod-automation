#!/bin/bash
#
# grep-head.awk
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
#   bash-3.2$ cr-list-sources-datasets.sh | grep-head.sh -p ^epa- -
#      epa-thermal-emissions
#      stack-heights
#      transfer-coefficents

usage="usage: `basename $0` [-p <end-head-pattern>] csv2rdf4lod-output.ttl [csv2rdf4lod-output.ttl]..."

if [ $# -lt 1 ]; then
   echo $usage
   exit 1
fi

endHeadRegex='^# CSV2RDF4LOD DATASET METADATA.*$'
if [ "$1" == "-p" ]; then
   endHeadRegex="$2"
   shift 2
fi

while [ $# -gt 0 ]; do
   file=$1
   if [ $file == "-" ]; then
      file=/dev/stdin
   fi
   #cat $file | awk '                               BEGIN { stillPrint="false"; }
   #                 /^# CSV2RDF4LOD DATASET METADATA.*$/ { stillPrint="true"; }
   #                                                      { if(stillPrint == "true") print }'
   cat $file | awk "          BEGIN { stillPrint=\"true\"; }
                                    { if(stillPrint == \"true\") print }
                    /$endHeadRegex/ { stillPrint=\"false\"; exit 0 }"
   shift
done
