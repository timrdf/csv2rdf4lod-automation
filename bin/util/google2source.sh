#!/bin/bash

ANCHOR_SHOULD_BE_VERSION=`basename \`pwd\``
if [ $ANCHOR_SHOULD_BE_VERSION != "version" ]; then
   echo "  Working directory does not appear to be a directory 'version'."
   echo "  Run `basename $0` from a 'version/' directory (e.g. csv2rdf4lod/data/source/SOURCE/DDD/version/)"
   exit 1
fi

if [ $# -lt 2 ]; then
   echo "usage: `basename $0` [-{w,f}] google-key local-name [google-key]*"
   echo "    -w            - write instead of doing a dry run (dry run is default)."
   echo "    -f            - force another version, even though there is already one for today."
   echo "    google-key    - key from google spreadsheet URL"
   echo "    local-name    - local name within source/ (use 'cr:auto' to default to dataset identifier)"
   echo "    [google-key]* - more keys from google spreadsheet URLs"
   exit 1
fi

CSV2RDF4LOD_HOME=${CSV2RDF4LOD_HOME:?"must be set. source csv2rdf4lod/source-me.sh."}

dryRun="true"
versionID=`$CSV2RDF4LOD_HOME/bin/util/date.sh | sed 's/_.*$//'`
if [ "$1" == "-w" ]; then
   dryRun="false"
   shift
elif [ "$1" == "-f" ]; then
   dryRun="false"
   versionID=`$CSV2RDF4LOD_HOME/bin/util/date.sh`
   shift
else
   echo ""
   echo "       (NOTE: only performing dry run; add -w parameter to actually fetch."
   echo ""
fi

if [ $# -lt 2 ]; then
   echo "usage: `basename $0` [-{w,f}] google-key local-name [google-key]*"
   echo "    -w            - write instead of doing a dry run (dry run is default)."
   echo "    -f            - force another version, even though there is already one for today."
   echo "    google-key    - key from google spreadsheet URL"
   echo "    local-name    - local name within source/ (use 'cr:auto' to default to dataset identifier)"
   echo "    [google-key]* - more keys from google spreadsheet URLs"
   echo "."
   exit 1
fi

if [ -d $versionID ]; then
   echo "version/$versionID already exists. Wait until tomorrow or use -f"
   exit 1
fi

LOCAL="$2"
if [ $LOCAL == "auto" -o $LOCAL == "cr:auto" ]; then
   LOCAL=`basename \`cd .. 2>/dev/null && pwd\``
   echo "using dataset identifer for local name in source/$LOCAL"
fi

mkdir -p $versionID/source

GOOGLE_SPREADSHEET_ID="$1"
shift

let count=0
while [ $# -gt 0 ]; do

   echo 

   googletoggle="head -1"
   pushd $versionID/source &> /dev/null
      echo "(in $versionID/source)"
      echo `basename $CSV2RDF4LOD_HOME/bin/util/google-spreadsheet-url.sh` $GOOGLE_SPREADSHEET_ID
      echo retrieving:
      echo `basename $CSV2RDF4LOD_HOME/bin/util/google-spreadsheet-url.sh` $GOOGLE_SPREADSHEET_ID | $googletoggle
      let "count= $count + 1"
      if [ $# -ne $count ]; then # pretty neat!
         LOCALc="$LOCAL-$count"
      else
         LOCALc=$LOCAL
      fi
      if [ ${dryRun-"."} == "true" ]; then
         echo pcurl.sh `$CSV2RDF4LOD_HOME/bin/util/google-spreadsheet-url.sh $GOOGLE_SPREADSHEET_ID | $googletoggle` -n $LOCALc -e csv
      else
         pcurl.sh `$CSV2RDF4LOD_HOME/bin/util/google-spreadsheet-url.sh $GOOGLE_SPREADSHEET_ID | $googletoggle` -n $LOCALc -e csv
         # TODO: edit in place and kill the stupid randomly occurring (or not occuring) first line "","","","","","",""
      fi
   popd &> /dev/null

   pushd $versionID &> /dev/null
      if [ ${dryRun-"."} == "true" ]; then
         echo "(in $versionID)"
         #echo `basename $CSV2RDF4LOD_HOME/bin/cr-create-convert-sh.sh` -w --header-line 2 source/$LOCALc.csv
         echo `basename $CSV2RDF4LOD_HOME/bin/cr-create-convert-sh.sh` -w source/$LOCALc.csv
         echo ./*.sh
      else
         #$CSV2RDF4LOD_HOME/bin/cr-create-convert-sh.sh -w --header-line 2 source/$LOCALc.csv
         $CSV2RDF4LOD_HOME/bin/cr-create-convert-sh.sh -w source/$LOCALc.csv
         ./*.sh
         ./*.sh # Run the enhancement, too. It will no-op if none to be done.
      fi
   popd &> /dev/null

   shift
   GOOGLE_SPREADSHEET_ID="$1"
done
