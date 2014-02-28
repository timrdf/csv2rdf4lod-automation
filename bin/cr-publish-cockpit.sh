#!/bin/bash
#
#3> <> prov:specializationOf <https://github.com/timrdf/csv2rdf4lod-automation/blob/master/bin/cr-publish-cockpit.sh> .
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

if [[ "$1" == "--help" || "$1" == "-h" ]]; then
   echo "usage: `basename $0` [-w]"
   echo "  Create publish/bin/publish.sh and invoke for every conversion cockpit within the current directory tree."
   echo "  -w : Avoid dryrun; do it. If not provided, will only dry run."
   exit
fi

see='https://github.com/timrdf/csv2rdf4lod-automation/wiki/CSV2RDF4LOD-not-set'
CSV2RDF4LOD_HOME=${CSV2RDF4LOD_HOME:?"not set; source csv2rdf4lod/source-me.sh or see $see"}

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

   if [ "$write" == "yes" ]; then
      export CSV2RDF4LOD_FORCE_PUBLISH="true"
      source $CSV2RDF4LOD_HOME/bin/convert-aggregate.sh
      export CSV2RDF4LOD_FORCE_PUBLISH="false"
   fi

   if [ "$write" == "no" ]; then
      echo
      echo "Note: Performed dry run only; no changes occurred. Use `basename $0` -w to avoid dry run and make modifications."
      echo
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
