#!/bin/bash

ANCHOR_SHOULD_BE_VERSION=`basename \`pwd\``
if [ $ANCHOR_SHOULD_BE_VERSION != "version" ]; then
   echo "  Working directory does not appear to be a directory 'version'."
   echo "  Run `basename $0` from a 'version/' directory (e.g. csv2rdf4lod/data/source/SOURCE/DDD/version/)"
   exit 1
fi


if [ $# -ne 2 ]; then
   echo "usage: `basename $0` google-key local-name"
   exit 1
fi

GOOGLE_SPREADSHEET_ID="$1"
LOCAL="$2"

CSV2RDF4LOD_HOME=${CSV2RDF4LOD_HOME:?"must be set. source csv2rdf4lod/source-me.sh."}

dryRun="true"
if [ "$1" == "-w" ]; then
  dryRun="false"
else
   echo ""
   echo "       (NOTE: only performing dry run; add -w parameter to actually fetch."
   echo ""
fi

versionID=`$CSV2RDF4LOD_HOME/bin/util/date.sh | sed 's/_.*$//'`
if [ ${1:-"."} == "-f" ]; then
   shift
   versionID=`$CSV2RDF4LOD_HOME/bin/util/date.sh`
fi

if [ -d $versionID ]; then
   echo "version/$versionID already exists. Wait until tomorrow or use -f"
   exit 1
fi

mkdir -p $versionID/source

pushd $versionID/source &> /dev/null
   if [ ${dryRun-"."} == "true" ]; then
      echo "(in $versionID/source)"
      echo pcurl.sh `$CSV2RDF4LOD_HOME/bin/util/google-spreadsheet-url.sh $GOOGLE_SPREADSHEET_ID` -n $LOCAL -e csv
   else
      pcurl.sh `$CSV2RDF4LOD_HOME/bin/util/google-spreadsheet-url.sh $GOOGLE_SPREADSHEET_ID` -n $LOCAL -e csv
   fi
popd &> /dev/null

pushd $versionID &> /dev/null
   if [ ${dryRun-"."} == "true" ]; then
      echo "(in $versionID)"
      echo $CSV2RDF4LOD_HOME/bin/cr-create-convert-sh.sh -w source/$LOCAL.csv
      echo ./*.sh
   else
      $CSV2RDF4LOD_HOME/bin/cr-create-convert-sh.sh -w source/$LOCAL.csv
      ./*.sh
   fi
popd &> /dev/null
