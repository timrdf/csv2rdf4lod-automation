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

usage="usage: `basename $0` [-con {raw,e1}] [cr:ALL] datasetIdentifier ...\n\
\n\
combine automatic/*.raw.ttl into publish/SSS-DDD-VVV.raw.nt for the requested datasets.\n\
\n\
-con: conversion identifier to publish (raw, e1, e2, ...) (default: raw)\n\
\n\
Run this from source/SSS/ (where dataset directories 9, 10, 32, ... reside)."

if [ $# -lt 1 ]; then
   echo $usage
   exit 1
fi

see="https://github.com/timrdf/csv2rdf4lod-automation/wiki/CSV2RDF4LOD-not-set"
CSV2RDF4LOD_HOME=${CSV2RDF4LOD_HOME:?"not set; source csv2rdf4lod/source-me.sh or see $set"}

# cr:data-root cr:source cr:directory-of-datasets cr:dataset cr:directory-of-versions cr:conversion-cockpit
ACCEPTABLE_PWDs="cr:source"
if [ `${CSV2RDF4LOD_HOME}/bin/util/is-pwd-a.sh $ACCEPTABLE_PWDs` != "yes" ]; then
   ${CSV2RDF4LOD_HOME}/bin/util/pwd-not-a.sh $ACCEPTABLE_PWDs
   exit 1
fi

source=`basename \`pwd\` | sed 's/\./-/g'`

con=raw
if [ "$1" == "-con" ]; then
   con="$2"
   shift 2
fi

datasetIdentifiers=""
if [ "$1" == "cr:ALL" ]; then
   datasetIdentifiers=`find . -type d -depth 1 | sed 's/\.\///'`
   shift 1
else
   while [ $# -gt 0 ]; do
      datasetIdentifier="$1"
      datasetIdentifiers="$datasetIdentifiers $datasetIdentifier"
      shift 1
   done
fi

CSV2RDF4LOD_HOME=${CSV2RDF4LOD_HOME:?"must be set. source csv2rdf4lod/source-me.sh."}
CSV2RDF4LOD_BASE_URI=${CSV2RDF4LOD_BASE_URI:?"must be set. source csv2rdf4lod/source-me.sh."}
formats=${formats:?"must be set. source csv2rdf4lod/source-me.sh"}

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

      conversionIdentifiers=`find $versionDir -name "*.params.ttl" | sed -e 's/^.*\.\(.*\)\.params.ttl$/\1/'`
      for conversionIdentifier in $conversionIdentifiers; do
         echo "  $conversionIdentifier"
      done
   else
      echo $datasetIdentifier: skipping b/c could not find directory 'automatic'
   fi
   shift
done
