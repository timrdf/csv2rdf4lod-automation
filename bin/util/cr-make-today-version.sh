#!/bin/bash

if [ ${1:-"."} == "--help" ]; then
   echo "usage: `basename $0` [-w]"
   exit 1
fi

here=`pwd`
DIR_SHOULD_BE_VERSION=`basename $here`
if [ $DIR_SHOULD_BE_VERSION != "version" ]; then
   echo "  Working directory does not appear to be a 'version'."
   echo "  Run `basename $0` from a SOURCE directory (e.g. csv2rdf4lod/data/source/SOURCE/version/)"
   exit 1
fi

CSV2RDF4LOD_HOME=${CSV2RDF4LOD_HOME:?"must be set; source csv2rdf4lod/source-me.sh (created by install.sh)."}

# TODO: use date +%Y-%b-%d
dir=`dateInXSDDateTime.sh | sed -e 's/T.*$//' -e 's/-/ /g' | awk '{abbr["01"]="Jan";abbr["02"]="Feb";abbr["03"]="Mar";abbr["04"]="Apr";abbr["05"]="May";abbr["06"]="Jun";abbr["07"]="Jul";abbr["08"]="Aug";abbr["09"]="Sep";abbr["10"]="Oct";abbr["11"]="Nov";abbr["12"]="Dec"; printf("%s-%s-%s",$1,abbr[$2],$3)}'`
if [ ! -e $dir -a ${1:-"."} == '-w' ]; then
   mkdir $dir
   echo $dir
   mkdir $dir/source
   echo $dir/source
else
   echo $dir
   echo "use -w to make dir"
fi
