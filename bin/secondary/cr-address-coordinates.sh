#!/bin/bash
#
#3> <> prov:specializationOf <https://github.com/timrdf/csv2rdf4lod-automation/blob/master/bin/secondary/cr-address-coordinates.sh>;
#3>    rdfs:seeAlso <https://github.com/timrdf/csv2rdf4lod-automation/wiki/Aggregating-subsets-of-converted-datasets> .
#
# Environment variables used:
#
#    (see https://github.com/timrdf/csv2rdf4lod-automation/wiki/CSV2RDF4LOD-environment-variables)
#
# Usage:
#
# Example usage:
# 

see="https://github.com/timrdf/csv2rdf4lod-automation/wiki/CSV2RDF4LOD-not-set"
CSV2RDF4LOD_HOME=${CSV2RDF4LOD_HOME:?"not set; source csv2rdf4lod/source-me.sh or see $see"}

# cr:data-root cr:source cr:directory-of-datasets cr:dataset cr:directory-of-versions cr:conversion-cockpit
ACCEPTABLE_PWDs="cr:data-root cr:source cr:dataset cr:directory-of-versions"
if [ `${CSV2RDF4LOD_HOME}/bin/util/is-pwd-a.sh $ACCEPTABLE_PWDs` != "yes" ]; then
   ${CSV2RDF4LOD_HOME}/bin/util/pwd-not-a.sh $ACCEPTABLE_PWDs
   exit 1
fi

TEMP="_"`basename $0``date +%s`_$$.tmp

sourceID=$CSV2RDF4LOD_PUBLISH_OUR_SOURCE_ID
datasetID=`basename $0 | sed 's/.sh$//'`
versionID=`date +%Y-%b-%d`

graphName=${CSV2RDF4LOD_BASE_URI_OVERRIDE:-$CSV2RDF4LOD_BASE_URI}/source/$sourceID/dataset/$datasetID/version/$versionID

if [[ $# -lt 1 || "$1" == "--help" ]]; then
   echo "usage: `basename $0` [--target] [-n] --clear-graph <named_graph_URI | cr:auto | .>"
   echo ""
   echo "  Query CSV2RDF4LOD_PUBLISH_SPARQL_ENDPOINT for all classes and predicates used,"
   echo "    assert rdfs:isDefinedBy to its namespace and prov:wasAttributedTo to its domain."
   echo "      load it into a virtuoso sparql endpoint."
   echo ""
   echo "         --target : return the name of graph that will be loaded; then quit."
   echo "               -n : perform dry run only; do not load named graph."
   echo "    --clear-graph : clear the named graph."
   echo
   echo "  named_graph_URI : use graph name given"
   echo "          cr:auto : use named graph $graphName"
   echo "                . : print to stdout"
   exit 1
fi

if [ "$1" == "--target" ]; then
   # a conversion:VersionedDataset:
   # e.g. http://purl.org/twc/health/source/tw-rpi-edu/dataset/cr-publish-tic-to-endpoint/version/2012-Sep-07
   echo $graphName
   exit 0
fi

dryRun="false"
if [ "$1" == "-n" ]; then
   dryRun="true"
   dryrun.sh $dryrun beginning
   shift 
fi

clearGraph="false"
if [ "$1" == "--clear-graph" ]; then
   clearGraph="true"
   shift
fi

if [ "$1" != "cr:auto" ]; then
   graphName="$1"
   shift 
fi

if [[ `is-pwd-a.sh                                                              cr:directory-of-versions` == "yes" ]]; then

   endpoint="$CSV2RDF4LOD_PUBLISH_SPARQL_ENDPOINT"
   if [ ${#endpoint} -eq 0 ]; then
      endpoint="$CSV2RDF4LOD_PUBLISH_VIRTUOSO_SPARQL_ENDPOINT"
   fi
   if [ ${#endpoint} -eq 0 ]; then
      echo "ERROR: no endpoint defined. Define CSV2RDF4LOD_PUBLISH_SPARQL_ENDPOINT"
      exit 1
   fi

   cockpit="$versionID"
   if [ ! -d $cockpit/source ]; then
      mkdir -p $cockpit/automatic
   fi
   rm -rf $cockpit/source/*

   echo python $CSV2RDF4LOD_HOME/bin/cr-publish-isdefinedby-to-endpoint.py $endpoint
   if [ "$dryRun" != "true" ]; then
      python $CSV2RDF4LOD_HOME/bin/secondary/cr-address-coordinates.py $endpoint --prov > $cockpit/source/coordinates.csv
      pushd $cockpit &> /dev/null
         aggregate-source-rdf.sh --link-as-latest automatic/* 
         # ^^ publishes if CSV2RDF4LOD_PUBLISH_VIRTUOSO
      popd &> /dev/null
   fi

   if [ "$clearGraph" == "true" ]; then
      echo ""
      echo "Deleting $graphName" >&2
      if [ "$dryRun" != "true" ]; then
         publish/bin/virtuoso-delete-$sourceID-$datasetID-$versionID.sh
      fi
   fi

   if [ "$dryRun" != "true" ]; then
      pushd $cockpit &> /dev/null
         publish/bin/virtuoso-load-$sourceID-$datasetID-$versionID.sh
      popd &> /dev/null
   fi

   # if [ "$CSV2RDF4LOD_PUBLISH_COMPRESS" == "true" ]; then
   # fi

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
