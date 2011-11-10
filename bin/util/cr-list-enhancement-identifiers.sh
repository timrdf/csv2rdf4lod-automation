#!/bin/bash

CSV2RDF4LOD_HOME=${CSV2RDF4LOD_HOME:?"not set; source csv2rdf4lod/source-me.sh or see https://github.com/timrdf/csv2rdf4lod-automation/wiki/CSV2RDF4LOD-not-set"}

# cr:data-root cr:source cr:directory-of-datasets cr:dataset cr:directory-of-versions cr:conversion-cockpit
ACCEPTABLE_PWDs="cr:conversion-cockpit"
if [ `${CSV2RDF4LOD_HOME}/bin/util/is-pwd-a.sh $ACCEPTABLE_PWDs` != "yes" ]; then
   ${CSV2RDF4LOD_HOME}/bin/util/pwd-not-a.sh $ACCEPTABLE_PWDs
   exit 1
fi

TEMP="_"`basename $0``date +%s`_$$.tmp


# e.g.
# automatic/streams_all.csv.e1.ttl -> 1
#
#find automatic -name  "*.e[!.].ttl"      | sed -e 's/^.*\.e\([^.]*\).ttl/\1/' | sort -u # WARNING: only handles e1 through e9



# This would be great, except it might get a parameter that hasn't been modified yet:
find manual          -name "*.params.ttl" | sed -e 's/^.*\.e\(.*\)\.params.ttl$/\1/'  > $TEMP
find ../ -maxdepth 1 -name "*.params.ttl" | sed -e 's/^.*\.e\(.*\)\.params.ttl$/\1/' >> $TEMP
cat $TEMP | sort -ru
rm $TEMP
