#!/bin/bash
#
# https://github.com/timrdf/csv2rdf4lod-automation/blob/master/bin/cr-publish-sameas-to-endpoint.sh
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
# Usage:
#    (pwd: source/DDD, e.g. source/data-gov):
#
#    cr-rerun-virtuoso-load-sh.sh -con raw 1623
#       deletes automatic/* and only runs the raw conversion.
#
#    cr-rerun-virtuoso-load-sh.sh 1623
#       same as `cr-rerun-virtuoso-load-sh.sh -con e1 1623`
#
#    cr-rerun-virtuoso-load-sh.sh -con e1 1623
#       if raw conversion is NOT in automatic/, runs the raw conversion
#       if raw conversion is     in automatic/, runs the e1  conversion
#
#    cr-rerun-virtuoso-load-sh.sh -con raw `cr-list-sources-datasets.sh`
#
#    todo:
#       deletes publish/* (not automatic/*) and runs ./convert-1263.sh in all version directories.

CSV2RDF4LOD_HOME=${CSV2RDF4LOD_HOME:?"not set; source csv2rdf4lod/source-me.sh or see https://github.com/timrdf/csv2rdf4lod-automation/wiki/CSV2RDF4LOD-not-set"}

# cr:data-root cr:source cr:directory-of-datasets cr:dataset cr:directory-of-versions cr:conversion-cockpit
ACCEPTABLE_PWDs="cr:data-root cr:source"
if [ `${CSV2RDF4LOD_HOME}/bin/util/is-pwd-a.sh $ACCEPTABLE_PWDs` != "yes" ]; then
   ${CSV2RDF4LOD_HOME}/bin/util/pwd-not-a.sh $ACCEPTABLE_PWDs
   exit 1
fi

TEMP="_"`basename $0``date +%s`_$$.tmp

graphName="http://purl.org/twc/vocab/conversion/SameAsDataset"

if [[ "$1" == "--help" || $# -lt 1 ]]; then
   echo "usage: `basename $0` [--target] [-n] [--clear-graph] <named_graph_URI | cr:auto | .>"
   echo ""
   echo "    Find all void subset ttl files and put them into a named graph on a virtuoso sparql endpoint."
   echo ""
   echo "         --target : return the name of graph that will be loaded; then quit."
   echo "               -n : perform dry run only; do not load named graph."
   echo "    --clear-graph : clear the named graph."
   echo
   echo "  named_graph_URI : use graph name given"
   echo "          cr:auto : use graph name $namedGraph"
   echo "                . : print to stdout (to not put in graph)"
   exit 1
fi

if [ "$1" == "--target" ]; then
   echo $graphName
   exit 0
fi

dryRun="false"
if [ "$1" == "-n" ]; then
   dryRun="true"
   echo "" 
   echo "       (NOTE: only performing dryrun; remove -n parameter to actually convert.)"
   echo ""
   shift 
fi

if [ $# -lt 1 ]; then
   $0 --help
   exit 1
fi

if [ "$1" == "--clear-graph" ]; then
   echo ""
   echo "Deleting $graphName"                                         >&2
   echo  "  ${CSV2RDF4LOD_HOME}/bin/util/virtuoso/vdelete $graphName" >&2
   if [ "$dryRun" != "true" -a $graphName != "." ]; then
      ${CSV2RDF4LOD_HOME}/bin/util/virtuoso/vdelete $graphName 
   fi
   shift
fi

if [ "$1" != "cr:auto" ]; then
   graphName="$1"
   shift 
fi

echo "Finding all SameAs from `pwd`. Will populate into $graphName" >&2
if [ `is-pwd-a.sh cr:source` == "yes" ]; then
   sames=`find   */version/*/publish -name "*sameas.nt" | xargs du -s | sort -nr | awk '$2!="total"{print $2}'`
elif [ `is-pwd-a.sh cr:data-root` == "yes" ]; then
   sames=`find */*/version/*/publish/ -name "*sameas.nt" | xargs du -s | sort -nr | awk '$2!="total"{print $2}'`
fi

for same in $sames; do
   count=`wc $same | awk '{print $1}'`
   echo "$count . $same" >&2
   cat $same >> $TEMP
   #if [ "$dryRun" != "true" ]; then
   #   rapper -i turtle -o ntriples $same >> $TEMP
   #fi
done

echo ""
echo "Loading sameas into $graphName"                                    >&2
echo "  ${CSV2RDF4LOD_HOME}/bin/util/virtuoso/vload nt $TEMP $graphName" >&2
if [ ${dryRun:-"."} != "true" -a $graphName != "." ]; then
   ${CSV2RDF4LOD_HOME}/bin/util/virtuoso/vload nt $TEMP $graphName
fi

if [ -e $TEMP ]; then
   if [ $graphName == "." ]; then
      echo "dumping to stdout" >&2      
      cat $TEMP
   fi
   rm $TEMP 
fi
