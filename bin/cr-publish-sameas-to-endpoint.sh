#!/bin/bash
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
      namedGraph="http://purl.org/twc/vocab/conversion/SameAsDataset"
   else
      echo "  Working directory does not appear to be a SOURCE directory."
      echo "  Run `basename $0` from a SOURCE directory (e.g. csv2rdf4lod/data/source/SOURCE/)"
      exit 1
   fi
else
   numDatasets="one"      
   namedGraph="http://purl.org/twc/vocab/conversion/SameAsDataset"
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
   echo "       (NOTE: only performing dryrun; remove -n parameter to actually convert.)"
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

TEMP_sameas="_"`basename $0``date +%s`_$$.tmp

assudo="sudo"
if [ `whoami` == "root" ]; then
   assudo=""
fi

echo "Finding all SameAs. Will populate into $namedGraph" >&2
if [ $numDatasets == "one" ]; then
   sames=`$assudo find */version/*/publish -name "*sameas.nt" | xargs du -s | sort -nr | awk '$2!="total"{print $2}'`
else
   sames=`$assudo find */*/version/*/publish/ -name "*sameas.nt" | xargs du -s | sort -nr | awk '$2!="total"{print $2}'`
fi

for same in $sames
do
   count=`wc $same | awk '{print $1}'`
   echo "$count . $same" >&2
   cat $same >> $TEMP_sameas
   #if [ ${dryRun:-"."} != "true" ]; then
   #   rapper -i turtle -o ntriples $same >> $TEMP_sameas
   #fi
done

echo ""
echo "Deleting $namedGraph"                                 >&2
echo  "  $assudo /opt/virtuoso/scripts/vdelete $namedGraph" >&2
if [ ${dryRun:-"."} != "true" -a $namedGraph != "." ]; then
   $assudo /opt/virtuoso/scripts/vdelete               $namedGraph 
fi

echo ""
echo "Loading sameas into $namedGraph"                                   >&2
echo "  $assudo /opt/virtuoso/scripts/vload nt $TEMP_sameas $namedGraph" >&2
if [ ${dryRun:-"."} != "true" -a $namedGraph != "." ]; then
   $assudo /opt/virtuoso/scripts/vload   nt $TEMP_sameas $namedGraph
fi

if [ -e $TEMP_sameas ]; then
   if [ $namedGraph == "." ]; then
      echo "dumping to stdout" >&2      
      cat $TEMP_sameas
   fi
   rm $TEMP_sameas 
fi
