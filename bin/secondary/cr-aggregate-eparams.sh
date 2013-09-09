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
#3> <> a conversion:RetrievalTrigger;
#3>    prov:specializationOf <https://github.com/timrdf/csv2rdf4lod-automation/blob/master/bin/secondary/cr-aggregate-eparams.sh>;
#3>    rdfs:seeAlso <https://github.com/timrdf/csv2rdf4lod-automation/wiki/Aggregating-subsets-of-converted-datasets> .
#
# Usage:

HOME=$(cd ${0%/*/*} && echo ${PWD%/*})
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

if [[ "$1" == "--help" ]]; then
   echo "usage: `basename $0` [-n] [version-identifier]"
   echo ""
   echo "Create a dataset from the aggregation of all csv2rdf4lod conversion parameter files."
   echo ""
   echo "               -n : perform dry run only; do not load named graph."
   echo
   exit
fi

dryrun="false"
if [ "$1" == "-n" ]; then
   dryrun="true"
   dryrun.sh $dryrun beginning
   shift
fi

if [[ -n "$CSV2RDF4LOD_PUBLISH_OUR_SOURCE_ID" ]]; then
   sourceID="$CSV2RDF4LOD_PUBLISH_OUR_SOURCE_ID"
elif [[ `${CSV2RDF4LOD_HOME}/bin/util/is-pwd-a.sh cr:source` == "yes" ]]; then
   sourceID=`cr-source-id.sh`
fi
datasetID=`basename $0 | sed -e 's/.sh$//'`
versionID=${2:-`date +%Y-%b-%d`}

echo $sourceID $datasetID $versionID
exit

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
   if [ "$dryrun" != "true" ]; then
      cat $param | grep -v "delimits_cell" > $cockpit/source/$path.ttl
   fi
done
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

pushd $cockpit &> /dev/null
   echo
   echo aggregate-source-rdf.sh --link-as-latest source/* 
   if [ "$dryrun" != "true" ]; then
      aggregate-source-rdf.sh --link-as-latest source/*
      # NOTE: ^^ publishes even with -n b/c it checks for CSV2RDF4LOD_PUBLISH_VIRTUOSO
   fi
popd &> /dev/null

dryrun.sh $dryrun ending
