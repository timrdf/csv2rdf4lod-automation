#!/bin/bash
#
# See also:
# https://github.com/timrdf/csv2rdf4lod-automation/wiki/Aggregating-subsets-of-converted-datasets
#
# Usage:
#
# Example usage:
#   pushd /work/data-gov/v2010/csv2rdf4lod/data/source
#      datasetGraph=`cr-publish-void-to-endpoint.sh   -n auto 2>&1 | awk '/Will populate into/{print $7}'`
#      cr-publish-void-to-endpoint.sh   auto # http://logd.tw.rpi.edu/vocab/Dataset

CSV2RDF4LOD_HOME=${CSV2RDF4LOD_HOME:?"must be set. source csv2rdf4lod/source-me.sh."}
CSV2RDF4LOD_BASE_URI=${CSV2RDF4LOD_BASE_URI:?"must be set. source csv2rdf4lod/source-me.sh."}

ACCEPTABLE_PWDs="cr:data-root cr:source"
if [ `${CSV2RDF4LOD_HOME}/bin/util/is-pwd-a.sh $ACCEPTABLE_PWDs` != "yes" ]; then
   ${CSV2RDF4LOD_HOME}/bin/util/pwd-not-a.sh $ACCEPTABLE_PWDs
   exit 1
   # cr:data-root cr:source cr:directory-of-datasets cr:dataset cr:directory-of-versions cr:conversion-cockpit
fi

if [ `${CSV2RDF4LOD_HOME}/bin/util/is-pwd-a.sh cr:data-root` == "yes" ]; then
   numDatasets="all"      
   namedGraph="$CSV2RDF4LOD_BASE_URI/vocab/Dataset"
elif [ `${CSV2RDF4LOD_HOME}/bin/util/is-pwd-a.sh cr:source` == "yes" ]; then
   numDatasets="one"      
   namedGraph=$CSV2RDF4LOD_BASE_URI/source/`is-pwd-a.sh cr:bone --id-of source`/vocab/Dataset
fi

if [ $# -lt 1 ]; then
   echo "usage: `basename $0` [-n] <named_graph_URI | auto | .>"
   echo ""
   echo "Find all void subset ttl files and put them into a named graph on a virtuoso sparql endpoint."
   echo ""
   echo "  auto - use named graph $namedGraph"
   echo "  .    - print to stdout"
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
   echo "usage: `basename $0` [-n] <named graph URI | auto>"
   exit 1
fi

if [ $# -gt 0 -a "$1" != "auto" ]; then
   namedGraph="$1"
   shift 
fi


TEMP_void="_"`basename $0``date +%s`_$$.tmp
ARCHIVED_void=""

assudo="sudo"
if [ `whoami` == "root" ]; then
   if [ ${dryRun:-"."} != "true" ]; then
      assudo="" # Only needed when not doing a dry run.
   fi
fi

echo "Finding all VoIDs from `pwd`. Will populate into $namedGraph" >&2
if [ $numDatasets == "one" ]; then
   # all datasets of ONE source
   voids=`$assudo find */version/*/publish -name "*void.ttl" | xargs wc -l | sort -nr | awk '$2!="total"{print $2}'`
else
   # all datasets of ALL sources
   voids=`$assudo find */*/version/*/publish -name "*void.ttl" | xargs wc -l | sort -nr | awk '$2!="total"{print $2}'`
   #echo "$CSV2RDF4LOD_PUBLISH_OUR_SOURCE_ID and $CSV2RDF4LOD_PUBLISH_OUR_DATASET_ID"
   if [ ${#CSV2RDF4LOD_PUBLISH_OUR_SOURCE_ID} -gt 0 -a ${#CSV2RDF4LOD_PUBLISH_OUR_DATASET_ID} -gt 0 ]; then
      ARCHIVED_void=$CSV2RDF4LOD_PUBLISH_OUR_SOURCE_ID/$CSV2RDF4LOD_PUBLISH_OUR_DATASET_ID-metadata/version/`date +%Y-%b-%d`/source/conversion-metadata.nt
      echo Archiving all VoID to $ARCHIVED_void
      if [ ${dryRun:-"."} != "true" ]; then
         mkdir -p `dirname $ARCHIVED_void`
         if [ -e $ARCHIVED_void ]; then 
            rm $ARCHIVED_void # In case we've run this script earlier today.
         fi
      fi
      TEMP_void=$ARCHIVED_void
   fi
fi

for void in $voids
do
   count=`wc $void | awk '{print $1}'`
   echo "$count . $void" >&2
   if [ ${dryRun:-"."} != "true" ]; then
      rapper -i turtle -o ntriples $void >> $TEMP_void
   fi
done

echo ""
echo "Deleting $namedGraph"                              >&2
echo  "  $assudo /opt/virtuoso/scripts/vdelete $namedGraph" >&2
if [ ${dryRun:-"."} != "true" -a $namedGraph != "." ]; then
   $assudo /opt/virtuoso/scripts/vdelete               $namedGraph 
   # TODO: ${CSV2RDF4LOD_HOME}/bin/util/virtuoso/vdelete
fi

echo ""
echo "Loading void into $namedGraph"                                >&2
echo "  $assudo /opt/virtuoso/scripts/vload nt $TEMP_void $namedGraph" >&2
if [ ${dryRun:-"."} != "true" -a $namedGraph != "." ]; then
   $assudo /opt/virtuoso/scripts/vload   nt $TEMP_void $namedGraph
   # TODO: ${CSV2RDF4LOD_HOME}/bin/util/virtuoso/vload
fi

if [ -e $TEMP_void ]; then
   if [ $namedGraph == "." ]; then
      echo "dumping to stdout" >&2      
      cat $TEMP_void
   fi
   if [ ${#ARCHIVED_void} -gt 0 ]; then
      tar czf $TEMP_void.tgz $TEMP_void
   fi
   rm $TEMP_void 
fi

if [ "$dryRun" == "true" ]; then
   echo "" 
   echo "" 
   echo "       (NOTE: only performed dryrun; remove -n parameter to actually load triple store.)"
   echo ""
   echo ""
   shift 
fi
