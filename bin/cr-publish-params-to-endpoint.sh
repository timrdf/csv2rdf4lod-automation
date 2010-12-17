#!/bin/sh
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

back_one=`cd .. 2>/dev/null && pwd`
back_zero=`pwd`
ANCHOR_SHOULD_BE_SOURCE=`basename $back_one`
if [ $ANCHOR_SHOULD_BE_SOURCE != "source" ]; then
   if [ `basename $back_zero` == "source" ]; then
      numDatasets="all"      
      namedGraph="http://purl.org/twc/vocab/conversion/ConversionProcess"
   else
      echo "  Working directory does not appear to be a SOURCE directory."
      echo "  Run `basename $0` from a SOURCE directory (e.g. csv2rdf4lod/data/source/SOURCE/)"
      exit 1
   fi
else
   numDatasets="one"      
   namedGraph="http://purl.org/twc/vocab/conversion/ConversionProcess"
fi

if [ $# -lt 1 ]; then
   echo "usage: `basename $0` [-n] <named_graph_URI | auto | .>"
   echo ""
   echo "Find all csv2rdf4lod params ttl files and put them into a named graph on a virtuoso sparql endpoint."
   echo ""
   echo "  auto - use named graph $namedGraph"
   echo "  .    - print to stdout"
   exit 1
fi

dryRun="false"
if [ "$1" == "-n" ]; then
   dryRun="true"
   echo "" 
   echo "       (NOTE: only performing dryrun; remove -n parameter to actually populate endpoint.)"
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

CSV2RDF4LOD_HOME=${CSV2RDF4LOD_HOME:?"must be set. source csv2rdf4lod/source-me.sh."}
CSV2RDF4LOD_BASE_URI=${CSV2RDF4LOD_BASE_URI:?"must be set. source csv2rdf4lod/source-me.sh."}

TEMP_params="_"`basename $0``date +%s`_$$.tmp

assudo="sudo"
if [ `whoami` == "root" ]; then
   assudo=""
fi

echo "Finding all csv2rdf4lod-params. Will populate into $namedGraph" >&2
if [ $numDatasets == "one" ]; then
   params=`$assudo find */version/* -name "*params.ttl" | xargs du -s | sort -nr | awk '{print $2}'`
else
   params=`$assudo find */*/version/* -name "*params.ttl" | xargs du -s | sort -nr | awk '{print $2}'`
fi

for param in $params
do
   count=`wc $param | awk '{print $1}'`
   echo "$count . $param" >&2
   cat $param >> $TEMP_params
   echo ""    >> $TEMP_params
   echo ""    >> $TEMP_params
   #if [ ${dryRun:-"."} != "true" ]; then
   #   rapper -i turtle -o ntriples $param >> $TEMP_params
   #fi
done

echo ""
echo "Deleting $namedGraph"                                 >&2
echo  "  $assudo /opt/virtuoso/scripts/vdelete $namedGraph" >&2
if [ ${dryRun:-"."} != "true" -a $namedGraph != "." ]; then
   $assudo /opt/virtuoso/scripts/vdelete               $namedGraph 
fi

echo ""
echo "Loading params into $namedGraph"                                   >&2
echo "  $assudo /opt/virtuoso/scripts/vload nt $TEMP_params $namedGraph" >&2
if [ ${dryRun:-"."} != "true" -a $namedGraph != "." ]; then
   $assudo /opt/virtuoso/scripts/vload   nt $TEMP_params $namedGraph
fi

if [ -e $TEMP_params ]; then
   if [ $namedGraph == "." ]; then
      echo "dumping to stdout" >&2      
      cat $TEMP_params
   fi
   rm $TEMP_params 
fi
