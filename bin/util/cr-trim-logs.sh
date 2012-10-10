#!/bin/bash
#
#   Copyright 2012 Timothy Lebo
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
#
# https://github.com/timrdf/csv2rdf4lod-automation/blob/master/bin/util/cr-trim-logs.sh

if [[ "$1" == "--help" || "$1" == "-h" ]]; then
   echo "usage: `basename $0` [-w]"
   echo "  Trim logs in doc/logs/ so that they are no larger than 16kb"
   echo "  -w : Avoid dryrun; do it. If not provided, will only dry run."
   exit
fi

CSV2RDF4LOD_HOME=${CSV2RDF4LOD_HOME:?"not set; source csv2rdf4lod/source-me.sh or see https://github.com/timrdf/csv2rdf4lod-automation/wiki/CSV2RDF4LOD-not-set"}

# cr:data-root cr:source cr:directory-of-datasets cr:dataset cr:directory-of-versions cr:conversion-cockpit
ACCEPTABLE_PWDs="cr:data-root cr:source cr:directory-of-datasets cr:dataset cr:directory-of-versions cr:conversion-cockpit"
if [ `${CSV2RDF4LOD_HOME}/bin/util/is-pwd-a.sh $ACCEPTABLE_PWDs` != "yes" ]; then
   echo `pwd` `cr-pwd.sh` `cr-pwd-type.sh` `${CSV2RDF4LOD_HOME}/bin/util/is-pwd-a.sh $ACCEPTABLE_PWDs`
   ${CSV2RDF4LOD_HOME}/bin/util/pwd-not-a.sh $ACCEPTABLE_PWDs
   exit 1
fi

write="no"
if [[ "$1" == "-w" || "$1" == "--write" ]]; then
   write="yes"
fi

TEMP="_"`basename $0``date +%s`_$$.tmp

if [[ `is-pwd-a.sh cr:conversion-cockpit` == "yes" ]]; then

   echo "========== `cr-pwd.sh` ========================================"
   echo

   has_logs="no"
   if [[ -d doc/logs && `ls doc/logs/*log* | wc -l | awk '{print $1}'` -gt 0 ]]; then
      echo `du -sh doc/logs` total
      has_logs="yes"
   fi

   if [ $has_logs == "yes" ]; then
      for log in doc/logs/*log*; do
         size_kb=`du -sk $log | awk '{print $1}'`
         if [ "$size_kb" -ge 16 ]; then
            head -100 $log > $TEMP
            size_kb2=`du -sk $TEMP | awk '{print $1}'`
            if [ "$write" == "yes" ]; then
               mv $TEMP $log
               size_kb2=`du -sk $log | awk '{print $1}'`
            fi
            echo "$log   $size_kb -> $size_kb2"
         else
            echo "$log   $size_kb"
         fi
      done

      if [ "$write" == "no" ]; then
         echo
         echo "Note: Performed dry run only; no changes occurred. Use `basename $0` -w to avoid dry run and make modifications."
         echo
      fi
   fi
elif [[ `is-pwd-a.sh cr:data-root cr:source cr:directory-of-datasets            cr:directory-of-versions` == "yes" ]]; then
   for next in `directories.sh`; do
      pushd $next > /dev/null
         # Recursive call to base case 'cr:conversion-cockpit'
         $0 $*
      popd > /dev/null
   done
elif [[ `is-pwd-a.sh              cr:source                                                             ` == "yes" ]]; then
   # TODO
   pushd dataset > /dev/null
      # Recursive call to base case 'cr:conversion-cockpit'
      $0 $*
   popd > /dev/null
elif [[ `is-pwd-a.sh                                                 cr:dataset                         ` == "yes" ]]; then
   pushd version > /dev/null
      # Recursive call to base case 'cr:conversion-cockpit'
      $0 $*
   popd > /dev/null
fi

if [ -e $TEMP ]; then
   rm -f $TEMP
fi
