#!/bin/sh

back_zero=`pwd`
ANCHOR_SHOULD_BE_SOURCE=`basename $back_zero`
if [ $ANCHOR_SHOULD_BE_SOURCE != "source" ]; then
   echo "  Working directory does not appear to be a source directory."
   echo "  Run `basename $0` from a source/ directory (e.g. csv2rdf4lod/data/source)"
   exit 1
fi

dryRun=""
if [ $1 == "-n" ]; then
   dryRun="-n"
fi

for source in `cr-list-sources.sh -s`; 
do 
   pushd $source; 
      cr-rerun-convert-sh.sh $dryRun -con cr:ALL cr:ALL; 
   popd; 
done
