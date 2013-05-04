#!/bin/bash
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
# https://github.com/timrdf/csv2rdf4lod-automation/blob/master/bin/cr-publish-params-to-endpoint.sh
#
# See also:
# https://github.com/timrdf/csv2rdf4lod-automation/wiki/Aggregating-subsets-of-converted-datasets
#
# Usage:

HOME=$(cd ${0%/*} && echo ${PWD%/*})
export PATH=$PATH`$HOME/bin/util/cr-situate-paths.sh`
export CLASSPATH=$CLASSPATH`$HOME/bin/util/cr-situate-classpaths.sh`
CSV2RDF4LOD_HOME=${CSV2RDF4LOD_HOME:?$HOME}

# cr:data-root cr:source cr:directory-of-datasets cr:dataset cr:directory-of-versions cr:conversion-cockpit
ACCEPTABLE_PWDs="cr:data-root cr:source"
if [ `${CSV2RDF4LOD_HOME}/bin/util/is-pwd-a.sh $ACCEPTABLE_PWDs` != "yes" ]; then
   ${CSV2RDF4LOD_HOME}/bin/util/pwd-not-a.sh $ACCEPTABLE_PWDs
   exit 1
fi

TEMP="_"`basename $0``date +%s`_$$.tmp

sourceID=$CSV2RDF4LOD_PUBLISH_OUR_SOURCE_ID
datasetID=`basename $0 | sed -e 's/-publish/-aggregated/' -e 's/-to-endpoint//' -e 's/.sh$//'` # e.g. cr-publish-void-to-endpoint.sh -> cr-void
versionID=`date +%Y-%b-%d`

graphName=${CSV2RDF4LOD_BASE_URI_OVERRIDE:-$CSV2RDF4LOD_BASE_URI}/source/$sourceID/dataset/$datasetID/version/$versionID

if [[ "$1" == "--help" ]]; then
   echo "usage: `basename $0` [--target] [-n] [--clear-graph] <named_graph_URI | cr:auto | .>"
   echo ""
   echo "Find all csv2rdf4lod params ttl files and put them into a named graph on a virtuoso sparql endpoint."
   echo ""
   echo "         --target : return the name of graph that will be loaded; then quit."
   echo "               -n : perform dry run only; do not load named graph."
   echo "    --clear-graph : clear the named graph."
   echo
   echo "  named_graph_URI : use graph name given"
   echo "          cr:auto : use graph name $namedGraph"
   echo "                . : print to stdout (to not put in graph)"
   exit
fi

if [[ "$1" == "--target" ]]; then
   echo $namedGraph 
   exit
fi

dryRun="false"
if [ "$1" == "-n" ]; then
   dryRun="true"
   dryrun.sh $dryrun beginning
   shift
fi

if [[ "$1" == "--clear-graph" ]]; then
   echo ""
   echo "Deleting $namedGraph"                                         >&2
   echo  "  ${CSV2RDF4LOD_HOME}/bin/util/virtuoso/vdelete $namedGraph" >&2
   if [ "$dryRun" != "true" -a $namedGraph != "." ]; then
      ${CSV2RDF4LOD_HOME}/bin/util/virtuoso/vdelete $namedGraph 
   fi
   shift
fi

#if [ "$1" != "cr:auto" ]; then
#   namedGraph="$1"
#   shift 
#fi

cockpit="$sourceID/$datasetID/version/$versionID"
if [ ! -d $cockpit/source ]; then
   mkdir -p $cockpit/source
   mkdir -p $cockpit/automatic
fi
rm -rf $cockpit/source/*

if [ `${CSV2RDF4LOD_HOME}/bin/util/is-pwd-a.sh 'cr:source'` == "yes" ]; then
   pushd ../ &> /dev/null
fi

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
echo "Finding all csv2rdf4lod-params in `pwd`." >&2

for param in `find . -mindepth 6 -maxdepth 6 -name *.params.ttl -not -name *.global.* -not -name *.raw.params.*`; do
   echo $param
   # e.g. ./datahub-io/corpwatch/version/2013-Apr-24/automatic/companies.csv.raw.params.ttl
   path=`md5.sh -qs $param`

   # NOTE: assumes no relative paths, which is the case for 97% of the params.

   echo "   --> $path.ttl"
   if [ "$dryRun" != "true" ]; then
      cat $param | grep -v "delimits_cell" > $cockpit/source/$path.ttl
   fi
done
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

pushd $cockpit &> /dev/null
   echo
   echo aggregate-source-rdf.sh --link-as-latest source/* 
   if [ "$dryRun" != "true" ]; then
      aggregate-source-rdf.sh --link-as-latest source/*
      # WARNING: ^^ publishes even with -n b/c it checks for CSV2RDF4LOD_PUBLISH_VIRTUOSO
   fi
popd &> /dev/null

if [ "$clearGraph" == "true" ]; then
   echo
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
