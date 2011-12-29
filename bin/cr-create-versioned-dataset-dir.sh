#!/bin/bash
#
# https://github.com/timrdf/csv2rdf4lod-automation/blob/master/bin/cr-create-versioned-dataset-dir.sh
#
# This script sets up a new version of a dataset when given a URL to a tabular file and some options
# describing its structure (comment character, header line, and delimter).
#
# If you have a non-tabular file, or custom software to retrieve data, then this script can be 
# used as a template for the retrieve.sh that is placed in the version directory.
#
# See:
# https://github.com/timrdf/csv2rdf4lod-automation/wiki/Automated-creation-of-a-new-Versioned-Dataset
#

CSV2RDF4LOD_HOME=${CSV2RDF4LOD_HOME:?"not set; source csv2rdf4lod/source-me.sh or see https://github.com/timrdf/csv2rdf4lod-automation/wiki/CSV2RDF4LOD-not-set"}

# cr:data-root cr:source cr:directory-of-datasets cr:dataset cr:directory-of-versions cr:conversion-cockpit
ACCEPTABLE_PWDs="cr:directory-of-versions"
if [ `${CSV2RDF4LOD_HOME}/bin/util/is-pwd-a.sh $ACCEPTABLE_PWDs` != "yes" ]; then
   ${CSV2RDF4LOD_HOME}/bin/util/pwd-not-a.sh $ACCEPTABLE_PWDs
   exit 1
fi

TEMP="_"`basename $0``date +%s`_$$.tmp


if [ $# -lt 2 ]; then
   echo "usage: `basename $0` version-identifier URL [--comment-character char]"
   echo "                                                                 [--header-line        row]"
   echo "                                                                 [--delimiter         char]"
   echo "   version-identifier: conversion:version_identifier for the VersionedDataset to create (use cr:auto for default)"
   echo "   URL               : URL to retrieve the data file."
   exit 1
fi


#-#-#-#-#-#-#-#-#
version="$1"
url="$2"
if [ "$1" == "cr:auto" ]; then
   version=`urldate.sh $url`
   echo "Attempting to use URL modification date to name version: $version"
fi
if [ ${#version} -ne 11 -a "$1" == "cr:auto" ]; then # 11!?
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

#
# This script is invoked from a cr:directory-of-versions, e.g. source/contactingthecongress/directory-for-the-112th-congress/version
#
if [ ! -d $version ]; then

   # Create the directory for the new version if it didn't exist already.
   mkdir -p $version/source

   # Go into the directory that stores the original data obtained from the source organization.
   pushd $version/source &> /dev/null
      touch .__CSV2RDF4LOD_retrieval # Make a timestamp so we know what files were created during retrieval.
      # - - - - - - - - - - - - - - - - - - - - Replace below for custom retrieval  - - - \
      pcurl.sh $url                                                                     # |
      if [ `ls *.gz *.zip 2> /dev/null | wc -l` -gt 0 ]; then                           # |
         # Uncompress anything that is compressed.                                      # |
         touch .__CSV2RDF4LOD_retrieval # Ignore the compressed file                    # |
         for zip in `ls *.gz *.zip 2> /dev/null`; do                                    # |
            punzip.sh $zip              # We are capturing provenance of decompression. # |
         done                                                                           # |
      fi                                                                                # |
      # - - - - - - - - - - - - - - - - - - - - Replace above for custom retrieval - - - -/
   popd &> /dev/null

   # Go into the conversion cockpit of the new version.
   pushd $version &> /dev/null

      if [ ! -e manual ]; then
         mkdir manual
      fi

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
         # Create a conversion trigger for the files obtained during retrieval.
         cr-create-convert-sh.sh -w --comment-character "$commentCharacter" --header-line $headerLine --delimiter ${delimiter:-","} $files
      fi

      ./*.sh # Run raw conversion
      for enhancementID in `cr-list-enhancement-identifiers.sh`; do
         flag=""
         if [ $enhancementID != "1" ]; then
            flag="-e $enhancementID"
         fi
         ./*.sh $flag # Run enhancement (flag not used for first enhancement)
      done

   popd &> /dev/null
else
   echo "Version exists; skipping."
fi
