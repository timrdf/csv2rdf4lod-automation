#!/bin/bash
#
# https://github.com/timrdf/csv2rdf4lod-automation/blob/master/bin/util/cr-trim-logs.sh

if [ "$1" == "--help" || "$1" == "-h" ]; then
   echo "usage: `basename $0` [-w]"
   echo "  Trim logs in doc/logs/ so that they are no larger than 16kb"
   echo "  -w : modify the logs (if not provided, will only dry run)"
fi

CSV2RDF4LOD_HOME=${CSV2RDF4LOD_HOME:?"not set; source csv2rdf4lod/source-me.sh or see https://github.com/timrdf/csv2rdf4lod-automation/wiki/CSV2RDF4LOD-not-set"}

# cr:data-root cr:source cr:directory-of-datasets cr:dataset cr:directory-of-versions cr:conversion-cockpit
ACCEPTABLE_PWDs="cr:conversion-cockpit"
if [ `${CSV2RDF4LOD_HOME}/bin/util/is-pwd-a.sh $ACCEPTABLE_PWDs` != "yes" ]; then
   ${CSV2RDF4LOD_HOME}/bin/util/pwd-not-a.sh $ACCEPTABLE_PWDs
   exit 1
fi

write="no"
if [ "$1" == "-w" ]; then
   write="yes"
fi

TEMP="_"`basename $0``date +%s`_$$.tmp

for log in doc/logs/csv2rdf4lod_log_*.txt; do
   size_kb=`du -sk $log | awk '{print $1}'`
   if [ "$size_kb" -ge 16 ]; then
      head -100 $log > $TEMP
      if [ "$write" == "yes" ]; then
         mv $TEMP $log
      fi
      size_kb2=`du -sk $log | awk '{print $1}'`
      echo "$size_kb -> $size_kb2 $log"
   else
      echo "$size_kb      $log"
   fi
done

if [ "$write" == "no" ]; then
   echo
   echo "Note: did not trim logs. Use `basename $0` -w to modify doc/logs/*.txt"
   echo
fi

rm -f $TEMP
