#!/bin/sh
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
