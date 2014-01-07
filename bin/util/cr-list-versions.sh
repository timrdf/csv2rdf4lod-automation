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
#3> <> prov:specializationOf <https://github.com/timrdf/csv2rdf4lod-automation/blob/master/bin/util/cr-list-versions.sh> .
#
# List the versions in this dataset, sorted by the last-modified time of its directory.
#
# usage:
#   $ cr-list-versions.sh 
#     2011-Apr-20
#     2011-Jun-15
#     2011-Aug-10        # Sorted by last modified date (newest last)
#   $ touch 2011-Jun-15
#   $ cr-list-versions.sh 
#     2011-Apr-20
#     2011-Aug-10
#     2011-Jun-15        # Sorted by last modified date (newest last) 
#   $ touch 2011-Aug-10
#   $ cr-list-versions.sh 
#     2011-Apr-20
#     2011-Jun-15
#     2011-Aug-10        # Sorted by last modified date (newest last)

see='https://github.com/timrdf/csv2rdf4lod-automation/wiki/CSV2RDF4LOD-not-set'
CSV2RDF4LOD_HOME=${CSV2RDF4LOD_HOME:?"not set; source csv2rdf4lod/source-me.sh or see $see"}

# cr:data-root cr:source cr:directory-of-datasets cr:dataset cr:directory-of-versions cr:conversion-cockpit
ACCEPTABLE_PWDs="cr:source cr:dataset cr:directory-of-versions cr:conversion-cockpit"
if [ "`${CSV2RDF4LOD_HOME}/bin/util/is-pwd-a.sh $ACCEPTABLE_PWDs`" != "yes" ]; then
   ${CSV2RDF4LOD_HOME}/bin/util/pwd-not-a.sh $ACCEPTABLE_PWDs
   exit 1
fi

TEMP="_"`basename $0``date +%s`_$$.tmp

if   [[ `${CSV2RDF4LOD_HOME}/bin/util/is-pwd-a.sh cr:source`                                                 == "yes" ]]; then
   # Avoid this; $0 could return any bad error and it would not be valid.
   for dataset_id in `cr-list-datasets.sh `; do
      pushd $dataset_id &> /dev/null
         for version_id in `$0 *`; do
            echo `cr-source-id.sh`/$dataset_id/version/$version_id # Call this script again
         done
      popd &> /dev/null
   done
elif [[ `${CSV2RDF4LOD_HOME}/bin/util/is-pwd-a.sh           cr:dataset`                                      == "yes" ]]; then
   #find version -mindepth 1 -maxdepth 1 -type d | grep -v "/\." | sed 's/^version.//'
   pushd version &> /dev/null
      $0 $* # Call this script again
   popd &> /dev/null
elif [[ `${CSV2RDF4LOD_HOME}/bin/util/is-pwd-a.sh                     cr:directory-of-versions`              == "yes" ]]; then
   #find .       -mindepth 1 -maxdepth 1 -type d | grep -v "/\." | sed 's/^\.\///'
   # List directories and when they were modified, bring to one line, sort so oldest is first, get rid of hidden directories.
   find . -mindepth 1 -maxdepth 1                               \
          -type d                                               \
          -exec modification-date.sh '{}' \; -exec echo '{}' \; \
        | awk '{if(NR%2==1){printf("%s ",$0)}else{print}}'      \
        | sort -n                                               \
        | sed 's/\.\///g' | grep -v " \." | awk '{print $2}'
elif [[ `${CSV2RDF4LOD_HOME}/bin/util/is-pwd-a.sh                                     cr:conversion-cockpit` == "yes" ]]; then
   echo `pwd | awk -F\/ '{print $NF}'`
fi
