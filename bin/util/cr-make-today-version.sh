#!/bin/bash

if [ ${1:-"."} == "--help" ]; then
   echo "usage: `basename $0` [-w]"
   exit 1
fi

CSV2RDF4LOD_HOME=${CSV2RDF4LOD_HOME:?"not set; source csv2rdf4lod/source-me.sh or see https://github.com/timrdf/csv2rdf4lod-automation/wiki/CSV2RDF4LOD-not-set"}

# cr:data-root cr:source cr:directory-of-datasets cr:dataset cr:directory-of-versions cr:conversion-cockpit
ACCEPTABLE_PWDs="cr:directory-of-versions"
if [ `${CSV2RDF4LOD_HOME}/bin/util/is-pwd-a.sh $ACCEPTABLE_PWDs` != "yes" ]; then
   ${CSV2RDF4LOD_HOME}/bin/util/pwd-not-a.sh $ACCEPTABLE_PWDs
   exit 1
fi

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
