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
formats=${formats:?"must be set. source csv2rdf4lod/source-me.sh"}

source=`basename \`pwd\` | sed 's/\./-/g'`

while [ $# -gt 0 ]; do
   datasetIdentifier=$1

   osType=`sw_vers | grep "Mac OS X" | wc -l`
   if [ `which sw_vers` -a ${osType:-"0"} -gt 0 ]; then
      # For Mac OS X
      autoDir=`find $datasetIdentifier -type d -depth 3 -name automatic | head -1`
   else
      # For AIX unix
      autoDir=`find $datasetIdentifier -type d 3 -name automatic | head -1` 
   fi
   versionDir=`dirname $autoDir`
   version=`basename \`dirname $autoDir\``
   convertSH=`find $versionDir -name "convert*.sh"`
   if [ ${#convertSH} ]; then
      echo "$source     $datasetIdentifier     $version"
      pushd $versionDir; source `basename $convertSH`; popd;
   else
      echo $datasetIdentifier: skipping b/c could not find directory 'automatic'
   fi
   shift
done
