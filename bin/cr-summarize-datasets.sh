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
# usage:

usage="usage: `basename $0` [cr:ALL | datasetIdentifier ...]

Run this from source/SSS/ (where dataset directories 9, 10, 32, ... reside)."

back_one=`cd .. 2>/dev/null && pwd`
ANCHOR_SHOULD_BE_SOURCE=`basename $back_one`
if [ $# -lt 1 -o $ANCHOR_SHOULD_BE_SOURCE != "source" ]; then
   echo "  Working directory does not appear to be a SOURCE directory."
   echo "  Run `basename $0` from a SOURCE directory (e.g. csv2rdf4lod/data/source/SOURCE/)"
   exit 1
fi

source=`basename \`pwd\` | sed 's/\./-/g'`

datasetIdentifiers=""
if [ "$1" == "cr:ALL" ]; then
   datasetIdentifiers=`find . -type d -depth 1 | sed 's/\.\///'`
   shift 1
else
   while [ $# -gt 0 ]; do
      datasetIdentifier="$1"
      datasetIdentifiers="$datasetIdentifiers $datasetIdentifier"
   done
fi

CSV2RDF4LOD_HOME=${CSV2RDF4LOD_HOME:?"must be set. source csv2rdf4lod/source-me.sh."}
CSV2RDF4LOD_BASE_URI=${CSV2RDF4LOD_BASE_URI:?"must be set. source csv2rdf4lod/source-me.sh."}
formats=${formats:?"must be set. source csv2rdf4lod/source-me.sh"}

function countDir {
   find $1 -type f 2> /dev/null | wc -l | awk '{print $1}'
}

function sumDir {
   find $1 -type f -exec stat -r '{}' \; 2> /dev/null | awk '{print $8}'| awk 'BEGIN{total=0}{total=total+$1}END{print total}'
}

echo "@prefix rdf:    <http://www.w3.org/1999/02/22-rdf-syntax-ns#> ."
echo "@prefix xsd:    <http://www.w3.org/2001/XMLSchema#> ."
echo "@prefix report: <http://purl.org/twc/vocab/conversion/> ."
echo "@prefix scovo:  <http://purl.org/NET/scovo#> ."
echo "@prefix nfo:    <http://www.semanticdesktop.org/ontologies/2007/03/22/nfo#> ."
echo "@prefix :       <http://blah.org/reports/report_blah/> ."

reportTime="\"`$CSV2RDF4LOD_HOME/bin/util/dateInXSDDateTime.sh`\"^^xsd:dateTime"
NLI="\n                  " # new line indent

for datasetIdentifier in $datasetIdentifiers; do
   versionDir=`find $datasetIdentifier -type d -depth 2 | head -1`
   sourceDir=$versionDir/source
   manualDir=$versionDir/manual
   automaticDir=$versionDir/automatic
   publishDir=$versionDir/publish
   lodmatDir=$versionDir/publish/lod-mat
   tdbDir=$versionDir/publish/tdb

   if [ ${#versionDir} ]; then
      version=`basename $versionDir`
      datasetURI=$CSV2RDF4LOD_BASE_URI/source/$source/dataset/$datasetIdentifier/version/$version
      echo ""
      echo "# $source     $datasetIdentifier     $version"

      let numConversions=0
      conversionIdentifiers=`find $versionDir -name "*.params.ttl" | sed -e 's/^.*\.\(.*\)\.params.ttl$/\1/'`
      for conversionIdentifier in $conversionIdentifiers; do
         let numConversions=$numConversions+1
         #echo "<$datasetURI> report:enhancement_identifier \"$conversionIdentifier\" ."
      done
         
      echo "[ rdf:value $numConversions; a scovo:Item; \n  scovo:dimension <$datasetURI>,$NLI report:layerForm,$NLI report:cardinality,$NLI $reportTime ] ."

      echo "[ rdf:value `countDir $sourceDir`; a scovo:Item; \n  scovo:dimension <$datasetURI>,$NLI report:sourceForm,$NLI report:cardinality,$NLI $reportTime ] ."
      echo "[ rdf:value `sumDir $sourceDir`; a scovo:Item; \n  scovo:dimension <$datasetURI>,$NLI report:sourceForm,$NLI report:bytes,$NLI $reportTime ] ."
      #find $sourceDir -type f | grep -v "pml.ttl" | grep -v "DS_Store" | sed 's/\.[^.]*$//g'

      echo "[ rdf:value `countDir $manualDir`; a scovo:Item; \n  scovo:dimension <$datasetURI>,$NLI report:manualForm,$NLI report:cardinality,$NLI $reportTime ] ."
      echo "[ rdf:value `sumDir $manualDir`; a scovo:Item; \n  scovo:dimension <$datasetURI>,$NLI report:manualForm,$NLI report:bytes,$NLI $reportTime ] ."

      echo "[ rdf:value `countDir $automaticDir`; a scovo:Item; \n  scovo:dimension <$datasetURI>,$NLI report:automaticForm,$NLI report:cardinality,$NLI $reportTime ] ."
      echo "[ rdf:value `sumDir $automaticDir`; a scovo:Item; \n  scovo:dimension <$datasetURI>,$NLI report:automaticForm,$NLI report:bytes,$NLI $reportTime ] ."

      nt_triples=`wc -l $publishDir/*.nt 2> /dev/null | awk 'BEGIN{total=0}{total=total+$1}END{print total}'`
      nt_size=`stat $publishDir/$source-$datasetIdentifier-$version.nt 2> /dev/null | awk '{print $8}'`
      echo "[ rdf:value $nt_triples; a scovo:Item; \n  scovo:dimension <$datasetURI>,$NLI report:ntriplesForm,$NLI report:cardinality,$NLI $reportTime ] ."
      echo "[ rdf:value ${nt_size:-"0"}; a scovo:Item; \n  scovo:dimension <$datasetURI>,$NLI report:ntriplesForm,$NLI report:bytes,$NLI $reportTime ] ."

      #ttl_triples=`rapper -g -c $publishDir/$source-$datasetIdentifier-$version.ttl 2>&1 | grep 'rapper: Parsing returned' | awk '{print $4}'`
      ttl_size=`stat $publishDir/$source-$datasetIdentifier-$version.ttl 2> /dev/null | awk '{print $8}'`
      echo "[ rdf:value $nt_triples; a scovo:Item; \n  scovo:dimension <$datasetURI>,$NLI report:turtleForm,$NLI report:cardinality,$NLI $reportTime ] ."
      echo "[ rdf:value ${ttl_size:-"0"}; a scovo:Item; \n  scovo:dimension <$datasetURI>,$NLI report:turtleForm,$NLI report:bytes,$NLI $reportTime ] ."

      #rdf_triples=`rapper -g -c $publishDir/$source-$datasetIdentifier-$version.rdf 2>&1 | grep 'rapper: Parsing returned' | awk '{print $4}'`
      rdf_size=`stat $publishDir/$source-$datasetIdentifier-$version.rdf 2> /dev/null | awk '{print $8}'`
      echo "[ rdf:value $nt_triples; a scovo:Item; \n  scovo:dimension <$datasetURI>,$NLI report:rdfxmlForm,$NLI report:cardinality,$NLI $reportTime ] ."
      echo "[ rdf:value ${rdf_size:-"0"}; a scovo:Item; \n  scovo:dimension <$datasetURI>,$NLI report:rdfxmlForm,$NLI report:bytes,$NLI $reportTime ] ."

      #tdb_size=`du -sm $tdbDir 2> /dev/null | awk '{print $1}'`
      echo "[ rdf:value `countDir $lodmatDir`; a scovo:Item; \n  scovo:dimension <$datasetURI>,$NLI report:lodmatForm,$NLI report:cardinality,$NLI $reportTime ] ."
      echo "[ rdf:value `sumDir $lodmatDir`; a scovo:Item; \n  scovo:dimension <$datasetURI>,$NLI report:lodmatForm,$NLI report:bytes,$NLI $reportTime ] ."

      #find $sourceDir -type f -name "*[Zz][Ii][Pp]" -exec ls -sk '{}' \;
     
      #pubFile="$publishDir/$source-$datasetIdentifier-$version.$con.nt"
      #echo "" > $pubFile
      #for rawFile in `find $automaticDir -name "*$con.ttl"`; do
      #   rapper -i turtle -o ntriples $rawFile >> $pubFile
      #   echo $rawFile
      #done
   else
      echo $datasetIdentifier: skipping b/c could not find directory 'automatic'
   fi

   shift
done
