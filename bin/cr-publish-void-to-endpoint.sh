#!/bin/bash
#
# https://github.com/timrdf/csv2rdf4lod-automation/blob/master/bin/cr-publish-void-to-endpoint.sh
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

CSV2RDF4LOD_HOME=${CSV2RDF4LOD_HOME:?"not set; source csv2rdf4lod/source-me.sh or see https://github.com/timrdf/csv2rdf4lod-automation/wiki/CSV2RDF4LOD-not-set"}

# cr:data-root cr:source cr:directory-of-datasets cr:dataset cr:directory-of-versions cr:conversion-cockpit
ACCEPTABLE_PWDs="cr:data-root cr:source"
if [ `${CSV2RDF4LOD_HOME}/bin/util/is-pwd-a.sh $ACCEPTABLE_PWDs` != "yes" ]; then
   ${CSV2RDF4LOD_HOME}/bin/util/pwd-not-a.sh $ACCEPTABLE_PWDs
   exit 1
fi

TEMP="_"`basename $0``date +%s`_$$.tmp

if [ `is-pwd-a.sh cr:data-root` == "yes" ]; then
   namedGraph="$CSV2RDF4LOD_BASE_URI/vocab/Dataset"
elif [ `is-pwd-a.sh cr:source` == "yes" ]; then
   namedGraph=$CSV2RDF4LOD_BASE_URI/source/`cr-source-id.sh`/vocab/Dataset
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
   echo "          cr:auto : use named graph $namedGraph"
   echo "                . : print to stdout"
   exit 1
fi

dryRun="false"
if [ "$1" == "-n" ]; then
   dryRun="true"
   echo "" 
   echo "" 
   echo "       (NOTE: only performing dryrun; remove -n parameter to actually load triple store.)"
   echo "" 
   echo ""
   shift 
fi

if [ $# -lt 1 ]; then
   $0 --help
fi

if [ "$1" == "--clear-graph" ]; then
   echo ""
   echo "Deleting $namedGraph"                                         >&2
   echo  "  ${CSV2RDF4LOD_HOME}/bin/util/virtuoso/vdelete $namedGraph" >&2
   if [ "$dryRun" != "true" -a $namedGraph != "." ]; then
      ${CSV2RDF4LOD_HOME}/bin/util/virtuoso/vdelete             $namedGraph
   fi
   shift
fi

if [ "$1" != "cr:auto" ]; then
   namedGraph="$1"
   shift 
fi

ARCHIVED_void=""

echo "Finding all VoIDs from `pwd`. Will populate into $namedGraph" >&2
echo ""
if [ `is-pwd-a.sh cr:source` == "yes" ]; then
   voids=`find   */version/*/publish -name "*void.ttl" | xargs wc -l | sort -nr | awk '$2!="total"{print $2}'`
elif [ `is-pwd-a.sh cr:data-root` == "yes" ]; then
   voids=`find */*/version/*/publish -name "*void.ttl" | xargs wc -l | sort -nr | awk '$2!="total"{print $2}'`

   if [ ${#CSV2RDF4LOD_PUBLISH_OUR_SOURCE_ID} -gt 0 -a ${#CSV2RDF4LOD_PUBLISH_OUR_DATASET_ID} -gt 0 ]; then
      ARCHIVED_void=$CSV2RDF4LOD_PUBLISH_OUR_SOURCE_ID/$CSV2RDF4LOD_PUBLISH_OUR_DATASET_ID-metadata/version/`date +%Y-%b-%d`/source/conversion-metadata.nt
      echo Archiving all VoID to $ARCHIVED_void
      echo ""
      if [ "$dryRun" != "true" ]; then
         mkdir -p `dirname $ARCHIVED_void`
         if [ -e $ARCHIVED_void ]; then 
            rm $ARCHIVED_void # In case we've run this script earlier today.
         fi
      fi
      TEMP=$ARCHIVED_void
   fi
fi

for void in $voids; do
   count=`wc $void | awk '{print $1}'`
   echo "$count . $void" >&2
   if [ "$dryRun" != "true" ]; then
      rapper -i turtle -o ntriples $void >> $TEMP
   fi
done

echo ""
echo "Loading void into $namedGraph"                                           >&2
echo "  ${CSV2RDF4LOD_HOME}/bin/util/virtuoso/vload nt $TEMP $namedGraph" >&2
if [ "$dryRun" != "true" -a $namedGraph != "." ]; then
   ${CSV2RDF4LOD_HOME}/bin/util/virtuoso/vload nt $TEMP $namedGraph
fi

if [ -e $TEMP ]; then
   if [ $namedGraph == "." ]; then
      echo "dumping to stdout" >&2      
      cat $TEMP
   fi
   if [ ${#ARCHIVED_void} -gt 0 ]; then
      tar czf $TEMP.tgz $TEMP
   fi
   rm $TEMP 
fi

if [ "$dryRun" == "true" ]; then
   echo "" 
   echo "" 
   echo "       (NOTE: only performed dryrun; remove -n parameter to actually load triple store's <$namedGraph>)"
   echo ""
   echo ""
   shift 
fi
