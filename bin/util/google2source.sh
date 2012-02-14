#!/bin/bash
#
# https://github.com/timrdf/csv2rdf4lod-automation/blob/master/bin/util/google2source.sh
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

CSV2RDF4LOD_HOME=${CSV2RDF4LOD_HOME:?"not set; source csv2rdf4lod/source-me.sh or see https://github.com/timrdf/csv2rdf4lod-automation/wiki/CSV2RDF4LOD-not-set"}
export PATH=$PATH`$CSV2RDF4LOD_HOME/bin/util/cr-situate-paths.sh`
export CLASSPATH=$CLASSPATH`$CSV2RDF4LOD_HOME/bin/util/cr-situate-classpaths.sh`

# cr:data-root cr:source cr:directory-of-datasets cr:dataset cr:directory-of-versions cr:conversion-cockpit
ACCEPTABLE_PWDs="cr:directory-of-versions"
if [ `${CSV2RDF4LOD_HOME}/bin/util/is-pwd-a.sh $ACCEPTABLE_PWDs` != "yes" ]; then
   ${CSV2RDF4LOD_HOME}/bin/util/pwd-not-a.sh $ACCEPTABLE_PWDs
   exit 1
fi

TEMP="_"`basename $0``date +%s`_$$.tmp

if [[ $# -lt 2 || "$1" == "--help" ]]; then
   echo "usage: `basename $0` [-{w,f}] google-key local-name [google-key]*"
   echo "    -w or --write - write instead of doing a dry run (dry run is default)."
   echo "    -f or --force - force another version, even though there is already one for today."
   echo "    google-key    - key from google spreadsheet URL"
   echo "    local-name    - filename to use for files retrieved and saved in source/ (use 'cr:auto' to use dataset identifier)"
   echo "    [google-key]* - more keys from google spreadsheet URLs"
   exit 1
fi

dryRun="true"
versionID=`date +%Y-%b-%d`
if [[ "$1" == "-w" || "$1" == "--write" ]]; then
   dryRun="false"
   shift
elif [[ "$1" == "-f" || "$1" == "--force" ]]; then
   dryRun="false"
   versionID=`date +%Y-%b-%d_%H_%M_%S`
   shift
else
   echo ""
   echo "       (NOTE: only performing dry run; add -w parameter to actually fetch."
   echo ""
fi

if [ -d $versionID ]; then
   echo "version/$versionID already exists. Wait until tomorrow or use -f"
   exit 1
fi

if [ $# -lt 2 ]; then
   $0 --help
   exit
fi

GOOGLE_SPREADSHEET_IDs="$1"

local_filename="$2"
if [ $local_filename == "auto" -o $local_filename == "cr:auto" ]; then
   local_filename=`$CSV2RDF4LOD_HOME/bin/util/cr-dataset-id.sh`
   echo "using dataset identifer for local name in source/$local_filename"
fi

shift 2

let num_spreadsheets="1 + $#"
while [ $# -gt 0 ]; do
   GOOGLE_SPREADSHEET_IDs="$GOOGLE_SPREADSHEET_IDs $1"
   shift
done

mkdir -p $versionID/source

googletoggle="head -1" # get the first URL from google-spreadsheet-url.sh - second does not work.
pushd $versionID/source &> /dev/null

   let count=0
   for GOOGLE_SPREADSHEET_ID in $GOOGLE_SPREADSHEET_IDs; do
      let "count= $count + 1"
      echo 
      echo "$count of $num_spreadsheets in $versionID/source"
      #echo `basename $CSV2RDF4LOD_HOME/bin/util/google-spreadsheet-url.sh` $GOOGLE_SPREADSHEET_ID
      #echo retrieving:
      #echo `basename $CSV2RDF4LOD_HOME/bin/util/google-spreadsheet-url.sh` $GOOGLE_SPREADSHEET_ID | $googletoggle
      if [ $num_spreadsheets -gt 1 ]; then
         local_filenameC="$local_filename-$count"
      else
         local_filenameC=$local_filename
      fi
      if [ ${dryRun-"."} == "true" ]; then
         echo pcurl.sh `$CSV2RDF4LOD_HOME/bin/util/google-spreadsheet-url.sh $GOOGLE_SPREADSHEET_ID | $googletoggle` -n $local_filenameC -e csv
      else
         $CSV2RDF4LOD_HOME/bin/util/pcurl.sh `$CSV2RDF4LOD_HOME/bin/util/google-spreadsheet-url.sh $GOOGLE_SPREADSHEET_ID | $googletoggle` -n $local_filenameC -e csv
         # Edit in place and kill the stupid randomly occurring (or not occuring) first line (e.g. "","","","","","","")
         perl -ni -e 'print if ($l || !/""(?:,""){3,4}/); ++$l;' $local_filenameC.csv # Thanks to Eric Prud'hommeaux for this! 2011 Jul 09
      fi
   done

popd &> /dev/null

pushd $versionID &> /dev/null
   if [ ${dryRun-"."} == "true" ]; then
      echo "(in $versionID)"
      #echo `basename $CSV2RDF4LOD_HOME/bin/cr-create-convert-sh.sh` -w --header-line 2 source/$local_filenameC.csv
      echo `basename $CSV2RDF4LOD_HOME/bin/cr-create-convert-sh.sh` -w source/*.csv
      echo ./*.sh
   else
      #$CSV2RDF4LOD_HOME/bin/cr-create-convert-sh.sh -w --header-line 2 source/$local_filenameC.csv
      $CSV2RDF4LOD_HOME/bin/cr-create-convert-sh.sh -w source/*.csv
      ./*.sh # Run raw conversion
      for enhancementID in `$CSV2RDF4LOD_HOME/bin/util/cr-list-enhancement-identifiers.sh`; do
         flag=""
         if [ $enhancementID != "1" ]; then
            flag="-e $enhancementID"
         fi
         ./*.sh $flag # Run enhancement (flag not used for first enhancement)
      done
   fi
popd &> /dev/null
