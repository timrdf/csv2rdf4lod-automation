#!/bin/bash
#
# https://github.com/timrdf/csv2rdf4lod-automation/blob/master/bin/util/is-pwd-a.sh
# https://github.com/timrdf/csv2rdf4lod-automation/wiki/Directory-Conventions

VALIDS="cr:data-root, cr:source, cr:directory-of-datasets, cr:dataset, cr:directory-of-versions, cr:conversion-cockpit"

if [ "$1" == "--types" ]; then
   echo $VALIDS | sed 's/^.*{//;s/}//;s/,//g'
   exit 1
fi

if [ $# -lt 1 ]; then
   echo "usage: `basename $0` {$VALIDS}+ [--id-of {s, d, v, s-d-v}]"
   echo "  if more than one type is given, \"yes\" is returned if the pwd is ANY of those specified."
   echo "  --id-of: instead of returning \"yes\" or \"no\", return the identifier for source, dataset, or version."
   exit 1
fi

s="" #  source_identifier
d="" # dataset_identifier
v="" # version_identifier
is_a="no"

while [[ $# -ge 1 && "$1" != "--id-of" ]]; do
   if   [[ $1 == "cr:directory-of-sources" || $1 == "cr:data-root"          ]]; then
       source=`basename \`pwd\``
      if [[ "$source" == "source" ]]; then
         is_a="yes"
      fi
   elif [[ $1 == "cr:source"                                                ]]; then
       source=`basename \`cd ../          2>/dev/null && pwd\``
      if [[ "$source" == "source" ]]; then
         is_a="yes"
      fi
   elif [[ $1 == "cr:directory-of-datasets"                                 ]]; then
       source=`basename \`cd ../../       2>/dev/null && pwd\``
       dataset=`basename \`pwd\``                               # TODO: need to add that step in...
      if [[ "$source" == "source" && "$dataset" == "dataset" ]]; then
         is_a="yes"
      fi
   elif [[ $1 == "cr:dataset"                                               ]]; then
      source=`basename \`cd ../../ 2>/dev/null && pwd\``
                                                                # TODO: need to add that step in...
      if [[ "$source" == "source" ]]; then
         is_a="yes"
      fi
   elif [[ $1 == "cr:directory-of-versions"                                 ]]; then
       source=`basename \`cd ../../../    2>/dev/null && pwd\``
            s=`basename \`cd ../../       2>/dev/null && pwd\``
      dataset=`basename \`cd ../../       2>/dev/null && pwd\`` # TODO: need to add that step in...
            d=`basename \`cd ../          2>/dev/null && pwd\`` # TODO: need to add that step in...
      version=`basename \`pwd\``
            v=""
      if [[ "$source" == "source" && "$version" == "version" ]]; then # TODO: need to add that step in...
         is_a="yes"
      fi
   elif [[ $1 == "cr:version"              || $1 == "cr:conversion-cockpit" ]]; then
       source=`basename \`cd ../../../../ 2>/dev/null && pwd\``
            s=`basename \`cd ../../../    2>/dev/null && pwd\``
      dataset=`basename \`cd ../../       2>/dev/null && pwd\`` # TODO: need to add that step in...
            d=`basename \`cd ../../       2>/dev/null && pwd\`` # TODO: need to add that step in...
      version=`basename \`cd ../          2>/dev/null && pwd\``
            v=`basename \`pwd\``

      if [[ "$source" == "source" && "$version" == "version" ]]; then
         is_a="yes"
      fi
   else
      echo "usage: `basename $0` {$VALIDS}"
      exit 1
   fi
   shift
done

if   [[ "$1" == "--id-of" && "$2" == "s-d-v" && ${#s} > 0 && ${#d} > 0 && ${#v} > 0 ]]; then
   echo "$s-$d-$v"
elif [[ "$1" == "--id-of" && "$2" == "s" ]]; #&& ${#s} > 0 ]]; then
   echo "$s"
elif [[ "$1" == "--id-of" && "$2" == "d" ]]; #&& ${#d} > 0 ]]; then
   echo "$d"
elif [[ "$1" == "--id-of" && "$2" == "v" ]]; #&& ${#v} > 0 ]]; then
   echo "$v"
else
   echo $is_a
fi
