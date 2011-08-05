#!/bin/bash

VALIDS="cr:conversion-cockpit"

if [ $# -lt 1 ]; then
   echo "usage: `basename $0` {$VALIDS}"
   exit 1
fi

 source=`basename \`cd ../../../../ 2>/dev/null && pwd\``
dataset=`basename \`cd ../../       2>/dev/null && pwd\`` # TODO: need to add that step in...
version=`basename \`cd ../          2>/dev/null && pwd\``

#echo "source $source"
#echo "dataset $dataset"
#echo "version $version"

is_a=""

if [ $1 == "cr:conversion-cockpit" ]; then
   is_a="no"
   if [[ "$source" == "source" && "$version" == "version" ]]; then
      is_a="yes"
   fi
elif [ $1 == "cr:source" ]; then # TODO: the rest of these.
   is_a=""
elif [ $1 == "cr:directory-of-sources" ]; then
   is_a=""
elif [ $1 == "cr:dataset" ]; then
   is_a=""
elif [ $1 == "cr:directory-of-datasets" ]; then
   is_a=""
elif [ $1 == "cr:version" ]; then
   is_a=""
elif [ $1 == "cr:directory-of-versions" ]; then
   is_a=""
fi

if [ ${#is_a} -gt 0 ]; then
   echo $is_a
else
   echo "usage: `basename $0` {$VALIDS}"
fi
