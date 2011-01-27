#!/bin/bash
#
# usage:
#   cr-mark-dataset-for-update.sh 92
#   cr-mark-dataset-for-update.sh 92 93 94 95 105 789
#   cr-mark-dataset-for-update.sh `echo '' | awk '{for(i=12;i<=32;i++) printf("%s ",i)}'`
#
usage="usage: `basename $0` datasetIdentifier ..."

if [ $# -lt 1 ]; then
   echo $usage
   exit 1
fi

back_one=`cd .. 2>/dev/null && pwd`
ANCHOR_SHOULD_BE_SOURCE=`basename $back_one`
if [ $ANCHOR_SHOULD_BE_SOURCE != "source" ]; then
   echo "  Working directory does not appear to be a SOURCE directory."
   echo "  Run `basename $0` from a SOURCE directory (e.g. csv2rdf4lod/data/source/SOURCE/)"
   exit 1
fi

CSV2RDF4LOD_HOME=${CSV2RDF4LOD_HOME:?"must be set; source csv2rdf4lod/source-me.sh (created by install.sh)."}
formats=${formats:?"must be set; source csv2rdf4lod/source-me.sh (created by install.sh)."}

while [ $# -gt 0 ]; do

   datasetIdentifier=$1

   if [ ! -e $datasetIdentifier ]; then
      echo "dataset $datasetIdentifier does not exist; no need to mark for update"
   elif [ ! -e $datasetIdentifier/urls.txt ]; then
      echo "dataset $datasetIdentifier already marked for update"
   else
      rm $datasetIdentifier/urls.txt
      echo "dataset $datasetIdentifier marked for update"
   fi

   shift
done
