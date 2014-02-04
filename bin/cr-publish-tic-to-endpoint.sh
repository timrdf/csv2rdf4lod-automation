#!/bin/bash
#
#3> <> prov:specializationOf <https://github.com/timrdf/csv2rdf4lod-automation/blob/master/bin/cr-publish-tic-to-endpoint.sh> .
#
# See also:
#    https://github.com/timrdf/csv2rdf4lod-automation/wiki/Aggregating-subsets-of-converted-datasets
#
# Environment variables used:
#
#   CSV2RDF4LOD_HOME
#   CSV2RDF4LOD_PUBLISH_OUR_SOURCE_ID
#   CSV2RDF4LOD_BASE_URI
#   CSV2RDF4LOD_BASE_URI_OVERRIDE
#
#    (see https://github.com/timrdf/csv2rdf4lod-automation/wiki/CSV2RDF4LOD-environment-variables)
#
# Usage:
#
# Example usage:
# 

see="https://github.com/timrdf/csv2rdf4lod-automation/wiki/CSV2RDF4LOD-not-set"
CSV2RDF4LOD_HOME=${CSV2RDF4LOD_HOME:?"not set; source csv2rdf4lod/source-me.sh or see $see"}

see="https://github.com/timrdf/csv2rdf4lod-automation/wiki/Aggregating-subsets-of-converted-datasets"
CSV2RDF4LOD_PUBLISH_OUR_SOURCE_ID=${CSV2RDF4LOD_PUBLISH_OUR_SOURCE_ID:?"not set; see $see"}

# cr:data-root cr:source cr:directory-of-datasets cr:dataset cr:directory-of-versions cr:conversion-cockpit
ACCEPTABLE_PWDs="cr:data-root"
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
   echo "  Find all metadata Turtle files in any conversion cockpit, "
   echo "    archive them into a new versioned dataset, and "
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

#if [ $# -lt 1 ]; then
#   $0 --help
#fi

if [ "$1" != "cr:auto" ]; then
   graphName="$1"
   shift 
fi

cockpit="$sourceID/$datasetID/version/$versionID"
if [ ! -d $cockpit/source ]; then
   mkdir -p $cockpit/source
   mkdir -p $cockpit/automatic
fi
rm -rf $cockpit/source/*

echo "INFO `basename $0` grepping for ^#3>..."

date
tics=`grep --recursive --files-with-matches --max-count=1 "^#3>" *` # <---- TODO: This takes forever; use heuristic to grep first 100 lines (and if none, move on).
echo $tics
date

#echo
#for file in `find .`; do
#   
#done
#exit

tally=1
#valid=""
for tic in $tics; do
   echo $tic
   ext=${tic#*.}
   let "tally=tally+1"
   echo "INFO `basename $0` processing tic $tally"
   ln     $tic   $cockpit/source/$tally.$ext
   tic.sh $tic > $cockpit/automatic/$tally.$ext.ttl
   #count=`void-triples.sh $cockpit/automatic/$tally$ext.ttl`
   #if [ "$count" -gt 0 ]; then
   #   valid="$valid $tic"
   #fi
done

pushd $cockpit &> /dev/null
   echo "INFO `basename $0`: aggregate-source-rdf.sh --link-as-latest automatic/*"
   aggregate-source-rdf.sh --link-as-latest automatic/* 
   # WARNING: ^^ publishes even with -n b/c it checks for CSV2RDF4LOD_PUBLISH_VIRTUOSO
popd &> /dev/null

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
