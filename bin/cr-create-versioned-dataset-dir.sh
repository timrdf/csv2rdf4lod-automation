#!/bin/bash
#
#3> <> prov:specializationOf <https://github.com/timrdf/csv2rdf4lod-automation/blob/master/bin/cr-create-versioned-dataset-dir.sh>;
#3>    prov:wasDerivedFrom   <https://github.com/timrdf/csv2rdf4lod-automation/blob/master/bin/cr-create-versioned-dataset-dir.sh>;
#3>    # ONLY uncomment this is your script really is... a conversion:Idempotent;
#3>    rdfs:seeAlso <https://github.com/timrdf/csv2rdf4lod-automation/wiki/Automated-creation-of-a-new-Versioned-Dataset#idempotency>;
#3> .
#3> <> a conversion:RetrievalTrigger, doap:Project; # Could also be conversion:Idempotent;
#3>    dcterms:description 
#3>      "Script to retrieve and convert a new version of the dataset.";
#3>    rdfs:seeAlso 
#3>      <https://github.com/timrdf/csv2rdf4lod-automation/wiki/Automated-creation-of-a-new-Versioned-Dataset>,
#3>      <https://github.com/timrdf/csv2rdf4lod-automation/wiki/tic-turtle-in-comments>;
#3> .
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
# This script sets up a new version of a dataset when given a URL to a tabular file and some options
# describing its structure (comment character, header line, and delimter).
#
# If you have a non-tabular file, or custom software to retrieve data, then this script can be 
# used as a template for the retrieve.sh that is placed in the version directory.
#
# See:
# https://github.com/timrdf/csv2rdf4lod-automation/wiki/Automated-creation-of-a-new-Versioned-Dataset
#

this=$(cd ${0%/*} && echo $PWD/${0##*/})

see="https://github.com/timrdf/csv2rdf4lod-automation/wiki/CSV2RDF4LOD-not-set"
CSV2RDF4LOD_HOME=${CSV2RDF4LOD_HOME:?"not set; source csv2rdf4lod/source-me.sh or see $see"}

# cr:data-root cr:source cr:directory-of-datasets cr:dataset cr:directory-of-versions cr:conversion-cockpit
ACCEPTABLE_PWDs="cr:directory-of-versions cr:conversion-cockpit"
if [ `${CSV2RDF4LOD_HOME}/bin/util/is-pwd-a.sh $ACCEPTABLE_PWDs` != "yes" ]; then
   ${CSV2RDF4LOD_HOME}/bin/util/pwd-not-a.sh $ACCEPTABLE_PWDs
   exit 1
fi

if [[ `cr-pwd-type.sh` == "cr:conversion-cockpit" ]]; then
   pushd ../ &> /dev/null
fi

TEMP="_"`basename $0``date +%s`_$$.tmp

if [[ "$1" == "--help" ]]; then
   echo "usage: `basename $0` version-identifier URL [--comment-character char]"
   echo "                                                                 [--header-line        row]"
   echo "                                                                 [--delimiter         char]"
   echo "   version-identifier: conversion:version_identifier for the VersionedDataset to create (use cr:auto for default)"
   echo "   URL               : URL to retrieve the data file."
   exit 1
fi


#-#-#-#-#-#-#-#-#
version="$1"
version_reason=""
url="$2"
if [[ "$1" == "cr:auto" && ${#url} -gt 0 ]]; then
   version=`urldate.sh $url`
   #echo "Attempting to use URL modification date to name version: $version"
   version_reason="(URL's modification date)"
fi
if [[ ${#version} -eq 0                        || \
      ${#version} -ne 11 && "$1" == "cr:auto"  || \
                            "$1" == "cr:today" || \
                            "$1" == "cr:force" ]]; then
   # We couldn't determine the date from the URL (11 length from e.g. "2013-Aug-12")
   # Or, there was no URL given.
   # Or, we're told to use today's date.
   version=`cr-make-today-version.sh 2>&1 | head -1`
   #echo "Using today's date to name version: $version"
   version_reason="(Today's date)"
fi
if [[ -e "$version" && "$1" == "cr:force"  ]]; then
   version=`date +%Y-%m-%d-%H-%M_%s`
fi
if [ ${#version} -gt 0 -a `echo $version | grep ":" | wc -l | awk '{print $1}'` -gt 0 ]; then
   # No colons allowed?
   echo "Version identifier invalid."
   exit 1
fi
iteration=`find . -mindepth 1 -maxdepth 1 -name "$version*" | wc -l | awk '{print $1}'`
if [[ "$iteration" -gt 0 ]]; then
   let "iteration=$iteration+1"
   iteration="_$iteration"
fi
shift 2

#-#-#-#-#-#-#-#-#
commentCharacter="#"
if [ "$1" == "--comment-character" -a $# -ge 2 ]; then
   commentCharacter="$2"
   shift 2
fi

#-#-#-#-#-#-#-#-#
headerLine=1
if [ "$1" == "--header-line" -a $# -ge 2 ]; then
   headerLine="$2"
   shift 2
fi

#-#-#-#-#-#-#-#-#
delimiter='\t'
delimiter=','
if [ "$1" == "--delimiter" -a $# -ge 2 ]; then
   delimiter="$2"
   shift 2
fi

echo "INFO url       : $url"
echo "INFO version   : $version $version_reason"
echo "INFO comment   : $commentCharacter"
echo "INFO header    : $headerLine"
echo "INFO delimiter : $delimiter"
echo

#
# This script is invoked from a cr:directory-of-versions, 
# e.g. source/contactingthecongress/directory-for-the-112th-congress/version
#
if [[ ! -d $version || ! -d $version/source || `find $version -empty -type d -name source` ]]; then

   # Create the directory for the new version.
   mkdir -p $version/source

   # Go into the directory that stores the original data obtained from the source organization.
   echo INFO `cr-pwd.sh`/$version/source
   pushd $version/source &> /dev/null
      touch .__CSV2RDF4LOD_retrieval # Make a timestamp so we know what files were created during retrieval.
      # - - - - - - - - - - - - - - - - - - - - Replace below for custom retrieval  - - - \
      if [[ "$CSV2RDF4LOD_PUBLISH_SPARQL_ENDPOINT" =~ http* ]]; then                     # |
         for rq in `find ../../../src/ -name "*.rq"`; do                                 # |
            cache-queries.sh "$CSV2RDF4LOD_PUBLISH_SPARQL_ENDPOINT" -o rdf -q $rq -od .  # |
         done                                                                            # |
      else                                                                               # | 
         echo "WARNING: CSV2RDF4LOD_PUBLISH_SPARQL_ENDPOINT not defined" >&2             # |
      fi                                                                                 # |
      if [[ "$url" =~ http* ]]; then                                                     # |
         pcurl.sh $url                                                                   # |
         while [ $# -gt 0 ]; do                                                          # |
            anotherURL="$1"                                                              # |
            if [[ "$anotherURL" =~ http* ]]; then                                        # |
               pcurl.sh "$anotherURL"                                                    # |
            fi                                                                           # |
            shift                                                                        # |
         done                                                                            # |
      fi                                                                                 # | 
      if [ `ls *.gz *.zip 2> /dev/null | wc -l` -gt 0 ]; then                            # |
         # Uncompress anything that is compressed.                                       # |
         touch .__CSV2RDF4LOD_retrieval # Ignore the compressed file                     # |
         sleep 1                                                                         # |
         for zip in `ls *.gz *.zip 2> /dev/null`; do                                     # |
            punzip.sh $zip              # We are capturing provenance of decompression.  # |
         done                                                                            # |
      fi                                                                                 # |
      if [ `ls *.htm 2> /dev/null | wc -l` -gt 0 ]; then                                 # |
         # Tidy any HTML                                                                 # |
         touch .__CSV2RDF4LOD_retrieval # Ignore the compressed file                     # |
         sleep 1                                                                         # |
         tidy.sh *.htm                                                                   # |
      fi                                                                                 # |
      if [ `ls *.html 2> /dev/null | wc -l` -gt 0 ]; then                                # |
         # Tidy any HTML                                                                 # |
         touch .__CSV2RDF4LOD_retrieval # Ignore the compressed file                     # |
         sleep 1                                                                         # |
         tidy.sh *.html                                                                  # |
      fi                                                                                 # |
      if [[ "$CSV2RDF4LOD_RETRIEVE_DROID_SOURCES" != "false" ]]; then                    # |
         sleep 1                                                                         # |
         cr-droid.sh . > cr-droid.ttl                                                    # |
      fi                                                                                 # |
      # - - - - - - - - - - - - - - - - - - - - Replace above for custom retrieval - - - -/
   popd &> /dev/null

   # Go into the conversion cockpit of the new version.
   pushd $version &> /dev/null

      mkdir -p manual automatic

      retrieved_files=`find source -newer source/.__CSV2RDF4LOD_retrieval -type f | grep -v "pml.ttl$" | grep -v "cr-droid.ttl$"`

      all_rdf="yes"
      for file in $retrieved_files; do
         if [[ `${CSV2RDF4LOD_HOME}/bin/util/valid-rdf.sh $file` != "yes" ]]; then
            all_rdf="no"
         fi
      done

      if [[ -e ../prepare.sh || -e ../2manual.sh || -e ../../prepare.sh ]]; then
         # Leave it up to the global preparation trigger to populate manual/ from any of the source/
         # The preparation trigger should also create the cr-create-convert.sh.
         # See https://github.com/timrdf/csv2rdf4lod-automation/wiki/Automated-creation-of-a-new-Versioned-Dataset#preparation-trigger
         # 2manual.sh is the legacy name for the preparation trigger.
         if [[ -e ../prepare.sh ]]; then
            trigger=../prepare.sh
         elif [[ -e ../2manual.sh ]]; then
            trigger=../2manual.sh
         elif [[ -e ../../prepare.sh ]]; then # More local overrides more global (we think?)
            trigger=../../prepare.sh
         else
            trigger=../2manual.sh
         fi
         chmod +x $trigger
         $trigger
         
      elif [[ `find source -name "*.xls" | wc -l` -gt 0 ]]; then
         # Tackle the xls files
         for xls in `find source -name "*.xls"`; do
            touch .__CSV2RDF4LOD_csvify
            sleep 1
            xls2csv.sh -w -od source $xls
            for csv in `find source -type f -newer .__CSV2RDF4LOD_csvify`; do
               #justify.sh $xls $csv xls2csv_`md5.sh \`which justify.sh\`` # TODO: excessive? justify.sh needs to know the broad class rule/engine
                                                             # TODO: shouldn't you be hashing the xls2csv.sh, not justify.sh?
               justify.sh $xls $csv csv2rdf4lod_xls2csv_sh
            done
         done

         files=`find source/ -name "*.csv"`
         cr-create-conversion-trigger.sh  -w --comment-character "$commentCharacter" --header-line $headerLine --delimiter ${delimiter:-","} $files
      elif [[ `find source -name "*.htm.tidy" -o -name "*.html.tidy" | wc -l` -gt 0 && -e ../../src/html2csv.xsl ]]; then
         # HTML files
         for tidy in `find source -name "*.htm.tidy" -o -name "*.html.tidy"`; do
            csv="manual/`basename ${tidy%.tidy}`.csv"
            saxon.sh ../../src/html2csv.xsl a a $tidy > $csv
            justify.sh $tidy $csv html2csv
         done

         files=`find manual -name "*.csv"`
         cr-create-conversion-trigger.sh -w --comment-character "$commentCharacter" --header-line $headerLine --delimiter ${delimiter:-","} $files
      elif [[ `find source -name "*.json" | wc -l` -gt 0 && -e ../../src/json2csv.py ]]; then
         # JSON files
         for json in `find source -name "*.json"`; do
            csv="manual/`basename ${json%.json}`.csv"
            python ../../src/json2csv.py $json > $csv
            justify.sh $json $csv custom_json2csv
         done

         files=`find manual -name "*.csv"`
         cr-create-conversion-trigger.sh -w --comment-character "$commentCharacter" --header-line $headerLine --delimiter ${delimiter:-","} $files
      elif [[ $all_rdf == "yes" ]]; then
         echo "[INFO] All retrieved files are RDF; not creating conversion trigger."
      else
         # Take a best guess as to what data files should be converted.
         # Include source/* that is newer than source/.__CSV2RDF4LOD_retrieval and NOT *.pml.ttl

         existing_files=""
         for name in $retrieved_files; do
            if [[ -e $name ]]; then
               existing_files="$existing_files $name"
            else
               echo "[INFO] \"$name\" does not exist."
            fi
         done
         if [[ ${#existing_files} -gt 0 ]]; then
            # Create a conversion trigger for the files obtained during retrieval.
            cr-create-conversion-trigger.sh -w --comment-character "$commentCharacter" --header-line $headerLine --delimiter ${delimiter:-","} $existing_files
         else
            echo
            echo "ERROR: No valid files found when retrieving `cr-dataset-id.sh`; not creating conversion trigger."
         fi
      fi

      cr-convert.sh
      if [[ -e cr-convert-`cr-dataset-id.sh`.sh ]]; then
         for enhancementID in `cr-list-enhancement-identifiers.sh`; do
            flag=""
            if [ $enhancementID != "1" ]; then
               flag="-e $enhancementID"
            fi
            ./cr-convert-`cr-dataset-id.sh`.sh $flag # Run enhancement (flag not used for first enhancement)
         done
      fi

   popd &> /dev/null
else
   echo "Version exists; skipping."
fi

if [[ `cr-pwd-type.sh` == "cr:conversion-cockpit" ]]; then
   popd ../ &> /dev/null
fi
