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
# https://github.com/timrdf/csv2rdf4lod-automation/blob/master/bin/util/cr-list-enhancement-identifiers.sh

see='https://github.com/timrdf/csv2rdf4lod-automation/wiki/CSV2RDF4LOD-not-set'
CSV2RDF4LOD_HOME=${CSV2RDF4LOD_HOME:?"not set; source csv2rdf4lod/source-me.sh or see $see"}

# cr:data-root cr:source cr:directory-of-datasets cr:dataset cr:directory-of-versions cr:conversion-cockpit
ACCEPTABLE_PWDs="cr:conversion-cockpit"
if [ `${CSV2RDF4LOD_HOME}/bin/util/is-pwd-a.sh $ACCEPTABLE_PWDs` != "yes" ]; then
   ${CSV2RDF4LOD_HOME}/bin/util/pwd-not-a.sh $ACCEPTABLE_PWDs
   exit 1
fi

TEMP="../_"`basename $0``date +%s`_$$.tmp

# Find "1" and "2" from files:
#
# manual/some.csv.global.e1.params.ttl
# manual/some.csv.e1.params.ttl
# ../e1.params.ttl
# ../e2.params.ttl

# This would be great, except it might get a parameter that hasn't been modified yet:
find manual          -name "*.params.ttl" | sed -e 's/.*e\([^\.]\)\.params.ttl$/\1/' >  $TEMP
find ../ -maxdepth 1 -name "*.params.ttl" | sed -e 's/.*e\([^\.]\)\.params.ttl$/\1/' >> $TEMP
cat $TEMP | sort -ru
rm $TEMP
