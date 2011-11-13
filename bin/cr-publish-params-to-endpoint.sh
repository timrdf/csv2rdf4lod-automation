#!/bin/bash
#
# https://github.com/timrdf/csv2rdf4lod-automation/blob/master/bin/cr-publish-params-to-endpoint.sh
#
# See also:
# https://github.com/timrdf/csv2rdf4lod-automation/wiki/Aggregating-subsets-of-converted-datasets
#
# Usage:

CSV2RDF4LOD_HOME=${CSV2RDF4LOD_HOME:?"not set; source csv2rdf4lod/source-me.sh or see https://github.com/timrdf/csv2rdf4lod-automation/wiki/CSV2RDF4LOD-not-set"}

# cr:data-root cr:source cr:directory-of-datasets cr:dataset cr:directory-of-versions cr:conversion-cockpit
ACCEPTABLE_PWDs="cr:data-root cr:source"
if [ `${CSV2RDF4LOD_HOME}/bin/util/is-pwd-a.sh $ACCEPTABLE_PWDs` != "yes" ]; then
   ${CSV2RDF4LOD_HOME}/bin/util/pwd-not-a.sh $ACCEPTABLE_PWDs
   exit 1
fi

TEMP="_"`basename $0``date +%s`_$$.tmp

namedGraph="http://purl.org/twc/vocab/conversion/ConversionProcess"

if [[ $# -lt 1 || "$1" == "--help" ]]; then
   echo "usage: `basename $0` [--target] [-n] [--clear-graph] <named_graph_URI | cr:auto | .>"
   echo ""
   echo "Find all csv2rdf4lod params ttl files and put them into a named graph on a virtuoso sparql endpoint."
   echo ""
   echo "         --target : return the name of graph that will be loaded."
   echo "               -n : perform dry run only; do not load named graph."
   echo "    --clear-graph : clear the named graph."
   echo
   echo "  named_graph_URI : use graph name given"
   echo "          cr:auto : use graph name $namedGraph"
   echo "                . : print to stdout (to not put in graph)"
   exit 1
fi

if [[ "$1" == "--target" ]]; then
   echo $namedGraph 
   exit 0
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
   $0 --help
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

if [ "$1" != "auto" ]; then
   namedGraph="$1"
   shift 
fi

echo "Finding all csv2rdf4lod-params in `pwd`. Will populate into $namedGraph" >&2
if [ `is-pwd-a.sh cr:data-root` == "yes" ]; then
   params=`find */*/version/* -name "*params.ttl" | xargs du -s | sort -nr | awk '$2!="total"{print $2}'`
elif [ `is-pwd-a.sh cr:source` == "yes" ]; then
   params=`find   */version/* -name "*params.ttl" | xargs du -s | sort -nr | awk '$2!="total"{print $2}'`
fi

for param in $params; do
   count=`wc $param | awk '{print $1}'`
   echo "$count . $param" >&2
   cat $param >> $TEMP
   echo ""    >> $TEMP
   echo ""    >> $TEMP
   #if [ "$dryRun" != "true" ]; then
   #   rapper -i turtle -o ntriples $param >> $TEMP
   #fi
done

echo ""
echo "Loading params into $namedGraph"                                    >&2
echo "  ${CSV2RDF4LOD_HOME}/bin/util/virtuoso/vload nt $TEMP $namedGraph" >&2
if [ "$dryRun" != "true" -a $namedGraph != "." ]; then
   ${CSV2RDF4LOD_HOME}/bin/util/virtuoso/vload nt $TEMP $namedGraph
fi

if [ -e $TEMP ]; then
   if [ $namedGraph == "." ]; then
      echo "dumping to stdout" >&2      
      cat $TEMP
   fi
   rm $TEMP 
fi
