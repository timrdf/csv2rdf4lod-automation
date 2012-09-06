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
# usage:
#   cr-list-sources-datasets.sh
#
#   cr-list-sources-datasets.sh -s 
#     List datasets by size.

CSV2RDF4LOD_HOME=${CSV2RDF4LOD_HOME:?"not set; source csv2rdf4lod/source-me.sh or see https://github.com/timrdf/csv2rdf4lod-automation/wiki/CSV2RDF4LOD-not-set"}

# cr:data-root cr:source cr:directory-of-datasets cr:dataset cr:directory-of-versions cr:conversion-cockpit
ACCEPTABLE_PWDs="cr:source"
if [ `${CSV2RDF4LOD_HOME}/bin/util/is-pwd-a.sh $ACCEPTABLE_PWDs` != "yes" ]; then
   ${CSV2RDF4LOD_HOME}/bin/util/pwd-not-a.sh $ACCEPTABLE_PWDs
   exit 1
fi

TEMP="_"`basename $0``date +%s`_$$.tmp

if [ $# -gt 0 -a "$1" == "-s" ]; then
   # sort by directory size
   find . -maxdepth 1 -type d | sed -e 's/\.\///' -e 's/^\.$//' | grep -v "^$" | grep -v "\..*" | xargs du -s | sort -n | awk '{print $2}' | grep -v "^doc$"
else
   find . -maxdepth 1 -type d | sed -e 's/\.\///' -e 's/^\.$//' | grep -v "^$" | grep -v "\..*" | grep -v "^doc$" # NOTE: HACK
fi
