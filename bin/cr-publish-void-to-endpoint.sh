#!/bin/bash
#
# https://github.com/timrdf/csv2rdf4lod-automation/blob/master/bin/cr-publish-void-to-endpoint.sh
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
#    CSV2RDF4LOD_PUBLISH_OUR_DATASET_ID - e.g. ""
#
#    (see https://github.com/timrdf/csv2rdf4lod-automation/wiki/CSV2RDF4LOD-environment-variables)
#
# Usage:
#
# Example usage:
#   cd /srv/logd/data/source
#      datasetGraph=`cr-publish-void-to-endpoint.sh   -n auto 2>&1 | awk '/Will populate into/{print $7}'`
#      cr-publish-void-to-endpoint.sh   auto # http://logd.tw.rpi.edu/vocab/Dataset

see="https://github.com/timrdf/csv2rdf4lod-automation/wiki/CSV2RDF4LOD-not-set"
CSV2RDF4LOD_HOME=${CSV2RDF4LOD_HOME:?"not set; source csv2rdf4lod/source-me.sh or see $see"}

see="https://github.com/timrdf/csv2rdf4lod-automation/wiki/Aggregating-subsets-of-converted-datasets"
CSV2RDF4LOD_PUBLISH_OUR_SOURCE_ID=${CSV2RDF4LOD_PUBLISH_OUR_SOURCE_ID:?"not set; see $see"}
CSV2RDF4LOD_PUBLISH_OUR_DATASET_ID=${CSV2RDF4LOD_PUBLISH_OUR_DATASET_ID:?"not set; see $see"}

# cr:data-root cr:source cr:directory-of-datasets cr:dataset cr:directory-of-versions cr:conversion-cockpit
ACCEPTABLE_PWDs="cr:data-root cr:source"
if [ `${CSV2RDF4LOD_HOME}/bin/util/is-pwd-a.sh $ACCEPTABLE_PWDs` != "yes" ]; then
   ${CSV2RDF4LOD_HOME}/bin/util/pwd-not-a.sh $ACCEPTABLE_PWDs
   exit 1
fi

TEMP="_"`basename $0``date +%s`_$$.tmp

if [ `is-pwd-a.sh cr:data-root` == "yes" ]; then
   graphName="$CSV2RDF4LOD_BASE_URI/vocab/Dataset"
elif [ `is-pwd-a.sh cr:source` == "yes" ]; then
   graphName=$CSV2RDF4LOD_BASE_URI/source/`cr-source-id.sh`/vocab/Dataset
fi

if [ $# -lt 1 ]; then
   echo "usage: `basename $0` [--target] [-n] --clear-graph <named_graph_URI | cr:auto | .>"
   echo ""
   echo "Find all void subset ttl files and put them into a named graph on a virtuoso sparql endpoint."
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
   echo $graphName
   exit 0
fi

dryRun="false"
if [ "$1" == "-n" ]; then
   dryRun="true"
   dryrun.sh $dryrun beginning
   shift 
fi

if [ $# -lt 1 ]; then
   $0 --help
fi

if [ "$1" != "cr:auto" ]; then
   graphName="$1"
   shift 
fi

sourceID=$CSV2RDF4LOD_PUBLISH_OUR_SOURCE_ID
datasetID=`basename $0 | sed 's/.sh$//'`
versionID=`date +%Y-%b-%d`
cockpit="$sourceID/$datasetID/version/$versionID"
if [ ! -d $cockpit/source ]; then
   mkdir -p $cockpit/source
fi
rm -rf $cockpit/source/*

echo "Finding all VoIDs from `cr-pwd.sh`."
echo "Will populate into $graphName" >&2
echo

voids=`find */*/version/*/publish -name "*void.ttl" | xargs wc -l | sort -nr | awk '$2!="total"{print $2}'`
valid=""
for void in $voids; do
   count=`void-triples.sh $void`
   echo "$count . $void" >&2
   ln $void $cockpit/source
   if [ "$valid" -gt 0 ]; then
      valid="$valid $void"
   fi
done

aggregate-source-rdf.sh $valid

if [ "$1" == "--clear-graph" ]; then
   echo ""
   echo "Deleting $graphName"                                         >&2
   echo  "  ${CSV2RDF4LOD_HOME}/bin/util/virtuoso/vdelete $graphName" >&2
   if [ "$dryRun" != "true" -a $graphName != "." ]; then
      #${CSV2RDF4LOD_HOME}/bin/util/virtuoso/vdelete             $graphName
      publish/bin/virtuoso-delete-$sourceID-$datasetID-$versionID.sh
   fi
   shift
fi

#echo "Loading void into $graphName"                                           >&2

if [ "$dryRun" != "true" -a $graphName != "." ]; then
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
#   if [ ${#ARCHIVED_void} -gt 0 ]; then
#      tar czf $TEMP.tgz $TEMP
#   fi
#   rm $TEMP 
#fi

dryrun.sh $dryrun ending
