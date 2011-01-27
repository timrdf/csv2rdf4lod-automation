#!/bin/bash
#
# usage:

back_one=`cd .. 2>/dev/null && pwd`
back_zero=`pwd`
ANCHOR_SHOULD_BE_SOURCE=`basename $back_one`
if [ $ANCHOR_SHOULD_BE_SOURCE != "source" ]; then
   if [ `basename $back_zero` == "source" ]; then
      for sameas in `find */*/version/*/publish -name "*.sameas.nt" -size +1c`
      do
         #echo ""
         #echo $sameas
         dir=`dirname $sameas`
         #echo $dir
         dir2=`dirname $dir`
         #echo $dir2

         pushd $dir2 &> /dev/null
            pwd
            for lodsh in `find publish/bin/ -name "lod-materialize-*" | grep -v "apache"`
            do
               $lodsh
            done
         popd &> /dev/null
      done
   else
      echo "  Working directory does not appear to be a SOURCE directory."
      echo "  Run `basename $0` from a SOURCE directory (e.g. csv2rdf4lod/data/source/SOURCE/)"
      exit 1
   fi
else
   find */version/*/publish -name "*.sameas.nt" -size +1c | sed -e 's/\/.*$//' 
fi
