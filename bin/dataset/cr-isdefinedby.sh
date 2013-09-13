#!/bin/bash
#
#3> <> a conversion:RetrievalTrigger;
#3>    prov:specializationOf <https://github.com/timrdf/csv2rdf4lod-automation/blob/master/bin/cr-publish-isdefinedby-to-endpoint.sh>;
#3>    rdfs:seeAlso          <https://github.com/timrdf/csv2rdf4lod-automation/wiki/Aggregating-subsets-of-converted-datasets> .
#
# Environment variables used:
#
#    CSV2RDF4LOD_PUBLISH_OUR_SOURCE_ID - to know which source-id to place the dataset into.
#                                        (not needed if invoked within a cr:source directory)
#
#    CSV2RDF4LOD_BASE_URI - to know the URI of the dataset created.
#
#    CSV2RDF4LOD_PUBLISH_SPARQL_ENDPOINT - the SPARQL endpoint to look for vocabulary terms used.
#
#    CSV2RDF4LOD_PUBLISH_VIRTUOSO_SPARQL_ENDPOINT - fallback, in case ^^ is not defined.
#
#    (see https://github.com/timrdf/csv2rdf4lod-automation/wiki/CSV2RDF4LOD-environment-variables)
#
# Usage:
#
# Example usage:
# 

[ -n "`readlink $0`" ] && this=`readlink $0` || this=$0
HOME=$(cd ${this%/*/*/*} && pwd)
export PATH=$PATH`$HOME/bin/util/cr-situate-paths.sh`
export CLASSPATH=$CLASSPATH`$HOME/bin/util/cr-situate-classpaths.sh`

# cr:data-root cr:source cr:directory-of-datasets cr:dataset cr:directory-of-versions cr:conversion-cockpit
ACCEPTABLE_PWDs="cr:data-root cr:source cr:dataset cr:directory-of-versions cr:conversion-cockpit"
if [ `is-pwd-a.sh $ACCEPTABLE_PWDs` != "yes" ]; then
   pwd-not-a.sh $ACCEPTABLE_PWDs
   exit 1
fi

TEMP="_"`basename $0``date +%s`_$$.tmp

sourceID=$CSV2RDF4LOD_PUBLISH_OUR_SOURCE_ID
datasetID=`basename $0 | sed -e 's/-publish//' -e 's/-to-endpoint//' -e 's/.sh$//'` # e.g. cr-publish-void-to-endpoint.sh -> cr-void
versionID=`date +%Y-%b-%d`

if [[ "$1" == "--help" ]]; then
   echo "usage: `basename $0` [version-identifier] [URL]"
   echo "   version-identifier: conversion:version_identifier for the VersionedDataset to create. Can be '', 'cr:auto', 'cr:today', 'cr:force'."
   echo "   URL               : URL to use during retrieval."
   exit 1
fi

n=''
dryRun="false"
if [ "$1" == "-n" ]; then
   n="-n"
   dryRun="true"
   dryrun.sh $dryrun beginning
   shift 
fi

if [[ `is-pwd-a.sh                                                                                       cr:conversion-cockpit` == "yes" ]]; then

   versionID=`cr-version-id.sh`
   pushd ../ &> /dev/null
      $this $n $versionID 
   popd &> /dev/null

elif [[ `is-pwd-a.sh                                                              cr:directory-of-versions` == "yes" ]]; then

   endpoint="$CSV2RDF4LOD_PUBLISH_SPARQL_ENDPOINT"
   if [ ${#endpoint} -eq 0 ]; then
      endpoint="$CSV2RDF4LOD_PUBLISH_VIRTUOSO_SPARQL_ENDPOINT"
   fi
   if [ ${#endpoint} -eq 0 ]; then
      echo "ERROR: no endpoint defined. Define CSV2RDF4LOD_PUBLISH_SPARQL_ENDPOINT"
      exit 1
   fi

   if [ -e $versionID ]; then
      echo "[INFO] `basename $0`: version $versionID already exists; skipping."
      exit 1
   fi

   cockpit="$versionID"
   if [ ! -d $cockpit/automatic ]; then
      mkdir -p $cockpit/automatic # TODO: pull down as csv, convert with eparams.
   fi
   rm -rf $cockpit/source/* # opposite of "if exists, quit" above.

   echo "[INFO] python $CSV2RDF4LOD_HOME/bin/cr-publish-isdefinedby-to-endpoint.py $endpoint"
   if [ "$dryRun" != "true" ]; then
      python $CSV2RDF4LOD_HOME/bin/cr-publish-isdefinedby-to-endpoint.py $endpoint > $cockpit/automatic/isdefinedby.nt
      pushd $cockpit &> /dev/null
         aggregate-source-rdf.sh --link-as-latest automatic/* 
         # ^^ publishes if CSV2RDF4LOD_PUBLISH_VIRTUOSO
      popd &> /dev/null
   fi

   dryrun.sh $dryrun ending
elif [[ `is-pwd-a.sh                                                 cr:dataset`                          == "yes" ]]; then
   if [ ! -e version ]; then
      mkdir version # See https://github.com/timrdf/csv2rdf4lod-automation/wiki/Directory-Conventions
   fi
   pushd version &> /dev/null
      $0 $* # Recursive call
   popd &> /dev/null
elif [[ `is-pwd-a.sh              cr:source                                  ` == "yes" ]]; then
   if [ -d dataset ]; then
      # This would conform to the directory structure if 
      # we had included 'dataset' in the convention.
      # This is here in case we ever fully support it.
      pushd dataset > /dev/null
         $0 $* # Recursive call
      popd > /dev/null
   else
      # Handle the original (3-year old) directory structure 
      # that does not include 'dataset' as a directory.
      datasetID=`basename $0`
      if [ ! -d ${datasetID%.*} ]; then
         mkdir ${datasetID%.*}
      fi
      pushd ${datasetID%.*} > /dev/null
         $0 $* # Recursive call
      popd > /dev/null
   fi
elif [[ `is-pwd-a.sh cr:data-root                                            ` == "yes" ]]; then
   see="https://github.com/timrdf/csv2rdf4lod-automation/wiki/Aggregating-subsets-of-converted-datasets"
   CSV2RDF4LOD_PUBLISH_OUR_SOURCE_ID=${CSV2RDF4LOD_PUBLISH_OUR_SOURCE_ID:?"not set; see $see"}

   pushd $CSV2RDF4LOD_PUBLISH_OUR_SOURCE_ID > /dev/null
      $0 $* # Recursive call
   popd > /dev/null
fi
