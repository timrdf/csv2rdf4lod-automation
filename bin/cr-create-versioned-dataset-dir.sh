#!/bin/bash
#
# cr-create-versioned-dataset-dir.sh
#
# See:
# https://github.com/timrdf/csv2rdf4lod-automation/wiki/Automated-creation-of-a-new-Versioned-Dataset
#

if [ $# -lt 2 ]; then
   echo "usage: `basename $0` version-identifier URL [--comment-character char]"
   echo "                                                                 [--header-line        row]"
   echo "                                                                 [--delimiter         char]"
   echo "   version-identifier: conversion:version_identifier for the VersionedDataset to create (use cr:auto for default)"
   echo "   URL               : URL to retrieve the data file."
   exit 1
fi

CSV2RDF4LOD_HOME=${CSV2RDF4LOD_HOME:?"not set; source csv2rdf4lod/source-me.sh or see https://github.com/timrdf/csv2rdf4lod-automation/wiki/CSV2RDF4LOD-not-set"}

#-#-#-#-#-#-#-#-#
version="$1"
url="$2"
if [ "$1" == "cr:auto" ]; then
   version=`urldate.sh $url`
   echo "Attempting to use URL modification date to name version: $version"
fi
if [ ${#version} -ne 11 -a "$1" == "cr:auto" ]; then
   version=`cr-make-today-version.sh 2>&1 | head -1`
   echo "Using today's date to name version: $version"
fi
if [ "$1" == "cr:today" ]; then
   version=`cr-make-today-version.sh 2>&1 | head -1`
   echo "Using today's date to name version: $version"
fi
if [ ${#version} -gt 0 -a `echo $version | grep ":" | wc -l | awk '{print $1}'` -gt 0 ]; then
   echo "Version identifier invalid."
   exit 1
fi
shift 2

#-#-#-#-#-#-#-#-#
commentCharacter="#"
if [ "$1" == "--comment-character" -a $# -ge 2 ]; then
   commentCharacter="$2"
   shift 2
fi

#-#-#-#-#-#-#-#-#
headerLine=0
if [ "$1" == "--header-line" -a $# -ge 2 ]; then
   headerLine="$2"
   shift 2
fi

#-#-#-#-#-#-#-#-#
delimiter='\t'
if [ "$1" == "--delimiter" -a $# -ge 2 ]; then
   delimiter="$2"
   shift 2
fi

echo "version   : $version"
echo "url       : $url"
echo "header    : $headerLine"
echo "comment   : $commentCharacter"
echo "delimiter : $delimiter"

if [ ! -d $version ]; then

   mkdir -p $version/source

   pushd $version/source &> /dev/null
      touch .__CSV2RDF4LOD_retrieval
      pcurl.sh $url
      if [ `ls *.gz *.zip 2> /dev/null | wc -l` -gt 0 ]; then
         touch .__CSV2RDF4LOD_retrieval
         for zip in `ls *.gz *.zip 2> /dev/null`; do
            punzip.sh $zip
         done
      fi
   popd &> /dev/null

   pushd $version &> /dev/null

      if [ -e ../2manual.sh ]; then
         # Leave it up to the global 2manual.sh to populate manual/ from any of the source/
         # 2manual.sh should also create the cr-create-convert.sh.
         chmod +x ../2manual.sh
         ../2manual.sh
      else
         # Take a best guess as to what data files should be converted.
         # Include source/* that is newer than source/.__CSV2RDF4LOD_retrieval and NOT *.pml.ttl

         files=`find source -newer source/.__CSV2RDF4LOD_retrieval -type f | grep -v "pml.ttl$"`

         echo files: $files
         cr-create-convert-sh.sh -w --comment-character "$commentCharacter" --header-line $headerLine --delimiter ${delimiter:-","} $files
      fi

      ./*.sh # produce raw layer 
      ./*.sh # produce e1 layer (if global params are at ../*e1..params.ttl)
      # TODO: handle more than just e1; for each $eparams in ../*.params.ttl

   popd &> /dev/null
else
   echo "Version exists; skipping."
fi
