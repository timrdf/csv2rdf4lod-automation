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






# Deprecated, use:
# TODO: reconcile with bin/util/cr-create-eparams-template.sh







#
# Create a shell script to automate the conversion and publishing of the given csv filenames.
# Running the created script once will produce the raw conversion; 
# running it a second time will produce the enhanced conversion.                                                      
#
#        \/ source                                      
#        |        \/ dataset                         
#        |        |            version  
#        |        |         \/
# source/data-gov/9/version/2010-Jun-9
#
# source/nci-nih-gov/popscigrid-nhis-2000-2005/version/2010-Jun-9
#        ^           ^                                 ^
#        ^^ source   ^                                 ^
#                    ^^ dataset                        ^
#                                                      ^^ version  

back_one=`cd .. 2>/dev/null && pwd`
ANCHOR_SHOULD_BE_SOURCE=`basename $back_one`
if [ $ANCHOR_SHOULD_BE_SOURCE != "version" ]; then
   echo "  Working directory does not appear to be a SOURCE directory."
   echo "  Run `basename $0` from a SOURCE directory (e.g. csv2rdf4lod/data/source/SOURCE/)"
   exit 1
fi

usage="usage: `basename $0` .csv [-h headerRow] [-e enhancement_identifier]"
if [ $# -eq 2 ]; then
   echo $usage
   exit 1
fi
if [ $# -eq 4 ]; then
   echo $usage
   exit 1
fi
if [ $# -gt 5 ]; then
   echo $usage
   exit 1
fi

csvFile="$1"
shift 1
if [ ! -e "$csvFile" ]; then
   echo "`basename $0`: $csvFile does not exist"
   exit 1
fi

header=""
if [ "$1" == "-h" -a $# -ge 3 ]; then
   header="$2"
   shift 2
fi

eID="$2"
shift 1

back_three=`cd ../../.. 2>/dev/null && pwd`
sourceID=`basename $back_three` # Use the names from the canonical directory structure
if [ $sourceID == "data.gov" ]; then
   sourceID="data-gov"
fi

back_two=`cd ../.. 2>/dev/null && pwd`
datasetID=`basename $back_two` # Use the names from the canonical directory structure

datasetDir=`pwd`
versionID=`basename $datasetDir` # Use the names from the canonical directory structure

CSV2RDF4LOD_HOME=${CSV2RDF4LOD_HOME:?"not set; source csv2rdf4lod/source-me.sh or see https://github.com/timrdf/csv2rdf4lod-automation/wiki/CSV2RDF4LOD-not-set"}
CSV2RDF4LOD_BASE_URI=${CSV2RDF4LOD_BASE_URI:?"not set; source csv2rdf4lod/source-me.sh or see https://github.com/timrdf/csv2rdf4lod-automation/wiki/CSV2RDF4LOD-not-set"}

#echo "    base_uri           $CSV2RDF4LOD_BASE_URI"
#echo "    source_identifier  $sourceID"                                        
#echo "    dataset_identifier $datasetID"                                    
#echo "    dataset_version    $versionID"
#echo "$CSV2RDF4LOD_BASE_URI/source/$sourceID/dataset/$datasetID/version/$versionID"

params="-v surrogate=$CSV2RDF4LOD_BASE_URI -v sourceID=$sourceID -v datasetID=$datasetID -v datasetVersion=$versionID -v conversionID=$eID"

# NOTE: no variable values can be strings or have spaces. awk "bails out at line 1".
head -${header:-1} $csvFile | tail -1 | awk $params -f $CSV2RDF4LOD_HOME/bin/util/header2params.awk

# TODO: use edu.rpi.tw.data.csv.impl.CSVHeaders instead.
