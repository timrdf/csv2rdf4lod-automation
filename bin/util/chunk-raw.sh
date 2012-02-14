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

usage="usage: `basename $0` [-con {raw,e1}] datasetIdentifier ...\n\
\n\
combine automatic/*.raw.ttl into publish/SSS-DDD-VVV.raw.nt for the requested datasets.\n\
\n\
-con: conversion identifier to publish (raw, e1, e2, ...) (default: raw)\n\
\n\
This is run from data.gov/ (where directories 9, 10, 32, ... reside)."

if [ $# -lt 1 ]; then
   echo $usage
   exit 1
fi

con=raw
if [ "$1" == "-con" ]; then
   con="$2"
   shift 2
fi

CSV2RDF4LOD_HOME=${CSV2RDF4LOD_HOME:?"must be set. source csv2rdf4lod/source-me.sh."}
formats=${formats:?"must be set. source csv2rdf4lod/source-me.sh"}

source=`basename \`pwd\` | sed 's/\./-/g'`

while [ $# -gt 0 ]; do
   datasetIdentifier=$1

   autoDir=`find $datasetIdentifier -type d -depth 3 -name automatic | head -1`
   if [ ${#autoDir} ]; then

      version=`basename \`dirname $autoDir\``
      echo "$source     $datasetIdentifier     $version"

      pubFile=`dirname $autoDir`/publish/"$source-$datasetIdentifier-$version.$con.nt"

      echo $autoDir
      echo $pubFile
      echo "" > $pubFile
      for rawFile in `find $autoDir -name "*$con.ttl"`; do
         echo $rawFile
      done
   else
      echo $datasetIdentifier: skipping b/c could not find directory 'automatic'
   fi

   shift
done
