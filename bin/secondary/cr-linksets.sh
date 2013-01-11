#!/bin/bash
#
# <> prov:specializationOf <https://github.com/timrdf/csv2rdf4lod-automation/blob/master/bin/cr-create-versioned-dataset-dir.sh>>;
#    prov:wasDerivedFrom   <https://github.com/timrdf/csv2rdf4lod-automation/blob/master/bin/secondary/cr-linksets.sh> .
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

see="https://github.com/timrdf/csv2rdf4lod-automation/wiki/CSV2RDF4LOD-not-set"
CSV2RDF4LOD_HOME=${CSV2RDF4LOD_HOME:?"not set; source csv2rdf4lod/source-me.sh or see $see"}

CSV2RDF4LOD_BASE_URI=${CSV2RDF4LOD_BASE_URI:?"not set; source csv2rdf4lod/source-me.sh or see $see"}
CSV2RDF4LOD_PUBLISH_DATAHUB_METADATA_OUR_BUBBLE_ID=${CSV2RDF4LOD_PUBLISH_DATAHUB_METADATA_OUR_BUBBLE_ID:?"not set; source csv2rdf4lod/source-me.sh or see $see"}

export PATH=$PATH`$CSV2RDF4LOD_HOME/bin/util/cr-situate-paths.sh`
export CLASSPATH=$CLASSPATH`$CSV2RDF4LOD_HOME/bin/util/cr-situate-classpaths.sh`

# cr:data-root cr:source cr:directory-of-datasets cr:dataset cr:directory-of-versions cr:conversion-cockpit
ACCEPTABLE_PWDs="cr:data-root cr:source cr:dataset cr:directory-of-versions"
if [ `${CSV2RDF4LOD_HOME}/bin/util/is-pwd-a.sh $ACCEPTABLE_PWDs` != "yes" ]; then
   ${CSV2RDF4LOD_HOME}/bin/util/pwd-not-a.sh $ACCEPTABLE_PWDs
   exit 1
fi

TEMP="_"`basename $0``date +%s`_$$.tmp

if [[ $# -lt 2 || "$1" == "--help" ]]; then
   echo "usage: `basename $0` version-identifier URL [--comment-character char]"
   echo "                                                                 [--header-line        row]"
   echo "                                                                 [--delimiter         char]"
   echo "   version-identifier: conversion:version_identifier for the VersionedDataset to create (use cr:auto for default)"
   echo "   URL               : URL to retrieve the data file."
   exit 1
fi

baseURI=${CSV2RDF4LOD_BASE_URI_OVERRIDE:-$CSV2RDF4LOD_BASE_URI}

if [[ `is-pwd-a.sh                                                            cr:directory-of-versions` == "yes" ]]; then
   #-#-#-#-#-#-#-#-#
   version="$1"
   version_reason=""
   url="$2"
   url="${baseURI}/source/${CSV2RDF4LOD_PUBLISH_OUR_SOURCE_ID}/file/cr-full-dump/version/latest/conversion/${CSV2RDF4LOD_PUBLISH_OUR_SOURCE_ID}-cr-full-dump-latest.ttl.gz"
   if [[ "$1" == "cr:auto" && ${#url} -gt 0 ]]; then
      version=`urldate.sh $url`
      #echo "Attempting to use URL modification date to name version: $version"
      version_reason="(URL's modification date)"
   fi
   if [ ${#version} -ne 11 -a "$1" == "cr:auto" ]; then # 11!?
      version=`cr-make-today-version.sh 2>&1 | head -1`
      #echo "Using today's date to name version: $version"
      version_reason="(Today's date)"
   fi
   if [ "$1" == "cr:today" ]; then
      version=`cr-make-today-version.sh 2>&1 | head -1`
      #echo "Using today's date to name version: $version"
      version_reason="(Today's date)"
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
   if [ ! -d $version ]; then

      # Create the directory for the new version.
      mkdir -p $version/source

      # Go into the directory that stores the original data obtained from the source organization.
      echo INFO `cr-pwd.sh`/$version/source
      pushd $version/source &> /dev/null
         touch .__CSV2RDF4LOD_retrieval # Make a timestamp so we know what files were created during retrieval.
         # - - - - - - - - - - - - - - - - - - - - Replace below for custom retrieval  - - - \
         pcurl.sh $url                                                                     # |
         # - - - - - - - - - - - - - - - - - - - - Replace above for custom retrieval - - - -/
      popd &> /dev/null

      # Go into the conversion cockpit of the new version.
      pushd $version &> /dev/null

         if [ ! -e automatic ]; then
            mkdir automatic
         fi

         tarball=${CSV2RDF4LOD_PUBLISH_OUR_SOURCE_ID}-cr-full-dump-latest.ttl.gz
         ours=${CSV2RDF4LOD_PUBLISH_DATAHUB_METADATA_OUR_BUBBLE_ID}
         echo "Extracting list of RDF URI nodes from our bubble: $ours"
         gunzip -c source/$tarball | awk '{print $1}' | grep "^<" | sed 's/^<//;s/>$//' | sort -u > automatic/$ours.txt
         echo "`wc -l automatic/$ours.txt | awk '{print $1}'` RDF URI nodes in our bubble"

         tally=0
         total=`ckan-datasets-in-group.py | wc -l | awk '{print $1}'`
         for bubble in `ckan-datasets-in-group.py`; do
            let "tally=$tally+1"
            if [ ! -e automatic/$bubble ]; then
               mkdir automatic/$bubble
            fi
            uri_space=`ckan-urispace-of-dataset.py $bubble`
            if [ -n "$uri_space" ]; then
               echo "$tally/$total Searching $ours for URIs in $uri_space (for $bubble)"
               echo "$uri_space" > automatic/$bubble/urispace.txt
               grep "^$uri_space" automatic/$ours.txt > automatic/$bubble/linkset.txt
               for linkset in `find automatic/$bubble -name "linkset.txt" -size +1c`; do
                  echo "$tally/$total $bubble `cat automatic/$bubble/linkset.txt | wc -l`"
               done
            else
               echo "WARNING: no URI space found for $bubble"
            fi
         done

         DATAHUB='http://datahub.io'
         for linkset in `find automatic -name "linkset.txt" -size +1c`; do
            # e.g.: automatic/data-gov/linkset.txt
            bubble=`echo $linkset | awk -F/ '{print $2}'`
            wc -l $linkset
            size=`cat automatic/$bubble/linkset.txt | wc -l | awk '{print $1}'`

            ls=`md5.sh -qs $DATAHUB/dataset/$ours\`date +%s\`$DATAHUB/dataset/$bubble`

            echo automatic/$bubble.ttl
            echo "@prefix : <`cr-dataset-uri.sh --uri`> ."                > automatic/$bubble.ttl
            cr-default-prefixes.sh --turtle                              >> automatic/$bubble.ttl
            echo                                                         >> automatic/$bubble.ttl
            echo "<$DATAHUB/dataset/$ours>"                              >> automatic/$bubble.ttl
            echo "    void:subset :linkset_$ls ."                        >> automatic/$bubble.ttl
            echo ""                                                      >> automatic/$bubble.ttl
            echo ":linkset_$ls "                                         >> automatic/$bubble.ttl
            echo "     a void:Linkset, void:Dataset;"                    >> automatic/$bubble.ttl
            echo "     dcterms:created `dateInXSDDateTime.sh --turtle`;" >> automatic/$bubble.ttl
            echo "     void:inDataset <`cr-dataset-uri.sh --uri`>;"      >> automatic/$bubble.ttl
            echo "     void:target "                                     >> automatic/$bubble.ttl
            echo "       <$DATAHUB/dataset/twc-healthdata>, "            >> automatic/$bubble.ttl
            echo "       <$DATAHUB/dataset/2000-us-census-rdf>;"         >> automatic/$bubble.ttl
            echo "     void:triples     $size;"                          >> automatic/$bubble.ttl
            echo "     sio:member-count $size;"                          >> automatic/$bubble.ttl
            echo "."                                                     >> automatic/$bubble.ttl
            echo                                                         >> automatic/$bubble.ttl
            for uri in `cat automatic/$bubble/linkset.txt`; do
               echo "<$uri> void:inDataset :linkset_$ls ."               >> automatic/$bubble.ttl
               echo ":linkset_$ls sio:has-member <$uri> ."               >> automatic/$bubble.ttl
            done
         done

         aggregate-source-rdf.sh automatic/*.ttl

         # #justify.sh $xls $csv xls2csv_`md5.sh \`which justify.sh\`` # TODO: excessive? justify.sh needs to know the broad class rule/engine
         #                                                # TODO: shouldn't you be hashing the xls2csv.sh, not justify.sh?
         #  justify.sh $xls $csv csv2rdf4lod_xls2csv_sh

      popd &> /dev/null
   else
      echo "Version exists; skipping."
   fi
elif [[  `is-pwd-a.sh                        cr:dataset                                                  ` == "yes" ]]; then
   if [[ ! -d version ]]; then
      mkdir version
   fi
   pushd version &> /dev/null
      $0 $* # Recursive call to base case 'cr:directory-of-versions'
   popd &> /dev/null
elif [[  `is-pwd-a.sh              cr:source                                                             ` == "yes" ]]; then
   # In a directory such as source/healthdata-tw-rpi-edu
   datasetID=`basename $0`
   datasetID=${datasetID%.*}
   if [[ ! -e $datasetID ]]; then
      mkdir $datasetID
   fi
   pushd $datasetID &> /dev/null
      $0 $* # Recursive call to base case 'cr:directory-of-versions'
   popd &> /dev/null
elif [[  `is-pwd-a.sh cr:data-root                                                                       ` == "yes" ]]; then
   CSV2RDF4LOD_PUBLISH_OUR_SOURCE_ID=${CSV2RDF4LOD_PUBLISH_OUR_SOURCE_ID:?"not set; source csv2rdf4lod/source-me.sh or see $see"}
   sourceID=$CSV2RDF4LOD_PUBLISH_OUR_SOURCE_ID
   if [[ ! -e $sourceID ]]; then
      mkdir $sourceID
   fi
   pushd $sourceID &> /dev/null
      $0 $* # Recursive call to base case 'cr:directory-of-versions'
   popd &> /dev/null
fi
