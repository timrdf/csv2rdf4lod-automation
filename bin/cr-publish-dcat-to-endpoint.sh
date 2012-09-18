#!/bin/bash
#
# https://github.com/timrdf/csv2rdf4lod-automation/blob/master/bin/cr-publish-dcat-to-endpoint.sh
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
# See also:
#    https://github.com/timrdf/csv2rdf4lod-automation/wiki/Aggregating-subsets-of-converted-datasets
#
# Environment variables used:
#
#    CSV2RDF4LOD_HOME                   - root for executables.
#    CSV2RDF4LOD_BASE_URI               - namespace for data.
#    CSV2RDF4LOD_PUBLISH_OUR_SOURCE_ID  - e.g. "twc-rpi-edu"
#
#    (see https://github.com/timrdf/csv2rdf4lod-automation/wiki/CSV2RDF4LOD-environment-variables)
#
# Usage:
#
# Example usage:
#   cd /srv/logd/data/source
#      datasetGraph=`cr-publish-dcat-to-endpoint.sh   -n auto 2>&1 | awk '/Will populate into/{print $7}'`
#      cr-publish-dcat-to-endpoint.sh   auto # http://logd.tw.rpi.edu/vocab/Dataset

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
   # e.g. http://purl.org/twc/health/source/tw-rpi-edu/dataset/cr-publish-dcat-to-endpoint/version/2012-Sep-07
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
fi
rm -rf $cockpit/source/*

dcats=`find . -mindepth 3 -maxdepth 4 -name "*dcat.ttl" | xargs wc -l | sort -nr | awk '$2!="total"{print $2}'`
valid=""
for dcat in $dcats; do
   count=`void-triples.sh $dcat`
   echo "$count . ${dcat#./}" >&2
   sdv=$(cd `dirname $dcat` && cr-sdv.sh)
   ln $dcat $cockpit/source/$sdv.dcat.ttl
   if [ "$count" -gt 0 ]; then
      valid="$valid $dcat"
   fi
done

pushd $cockpit &> /dev/null
   aggregate-source-rdf.sh source/*
popd &> /dev/null

if [ "$clearGraph" == "true" ]; then
   echo ""
   echo "Deleting $graphName"                                         >&2
   if [ "$dryRun" != "true" -a $graphName != "." ]; then
      #${CSV2RDF4LOD_HOME}/bin/util/virtuoso/vdelete             $graphName
      publish/bin/virtuoso-delete-$sourceID-$datasetID-$versionID.sh
   fi
   shift
fi

if [ "$dryRun" != "true" ]; then
   pushd $cockpit &> /dev/null
      #${CSV2RDF4LOD_HOME}/bin/util/virtuoso/vload nt $TEMP $graphName
      publish/bin/virtuoso-load-$sourceID-$datasetID-$versionID.sh
   popd &> /dev/null
fi

#if [ -e $TEMP ]; then
#   if [ $graphName == "." ]; then
#      echo "dumping to stdout" >&2      
#      cat $TEMP
#   fi
#   if [ ${#ARCHIVED_dcat} -gt 0 ]; then
#      tar czf $TEMP.tgz $TEMP
#   fi
#   rm $TEMP 
#fi

dryrun.sh $dryrun ending
