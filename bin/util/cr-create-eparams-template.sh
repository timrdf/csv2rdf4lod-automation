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









# TODO: reconcile with bin/cr-create-enhancement-template.sh











if [ $# -eq 0 ]; then
   echo "usage: `basename $0` [-h headerRow] -s <source> -d <dataset> -v <version> [-e <enhancement>] <csv> [csv...]"
   echo "  -h[eader]"
   echo "  -s[ource]"
   echo "  -d[ataset]"
   echo "  -v[ersion]"
   exit 1
fi

header=""
if [ "$1" == "-h" ]; then
   header="$2"
   shift 2
fi

source="SSS"
if [ "$1" == "-s" ]; then
   source="$2"
   shift 2
else
   echo "need -s"
   exit 1
fi

dataset="DDD"
if [ "$1" == "-d" ]; then
   dataset="$2"
   shift 2
else
   echo "need -d"
   exit 1
fi

version="VVV"
if [ "$1" == "-v" ]; then
   version="$2"
   shift 2
else
   echo "need -v"
   exit 1
fi

enhancement="1"
if [ "$1" == "-e" ]; then
   enhancement="$2"
   shift 2
fi

CSV2RDF4LOD_HOME=${CSV2RDF4LOD_HOME:?"must be set. source csv2rdf4lod/source-me.sh."}
CSV2RDF4LOD_BASE_URI=${CSV2RDF4LOD_BASE_URI:?"must be set. source csv2rdf4lod/source-me.sh."}

csvHeadersPath="edu.rpi.tw.data.csv.impl.CSVHeaders"                                                  # is in csv2rdf4lod.jar

h2p=$CSV2RDF4LOD_HOME/bin/util/header2params2.awk                                                     # process by line, not parse the first

cellDelimiter=""
dataStart=""
onlyIfCol=""
repeatIfEmptyCol=""
interpretAsNull=""
dataEnd=""
subjectDiscriminator=""
while [ $# -gt 0 ]; do
   data="$1"

   paramsParams="-v surrogate=$CSV2RDF4LOD_BASE_URI -v sourceID=$source -v datasetID=$dataset"                             # NOTE: no variable values 
   paramsParams="$paramsParams -v header=$header -v dataStart=$dataStart -v onlyIfCol=$onlyIfCol"                   # can be strings or have spaces. 
   paramsParams="$paramsParams -v repeatAboveIfEmptyCol=$repeatAboveIfEmptyCol -v interpretAsNull=$interpretAsNull" # awk "bails out at line 1".
   paramsParams="$paramsParams -v dataEnd=$dataEnd"
   paramsParams="$paramsParams -v subjectDiscriminator=$subjectDiscriminator -v datasetVersion=$version"

   # NOTE: command done below, too.
   java $csvHeadersPath $data --header-line ${header:-"1"} | awk -v conversionID="$enhancement" $paramsParams -f $h2p
   shift
done
