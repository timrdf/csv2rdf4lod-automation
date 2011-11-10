#!/bin/bash
#
# usage:

CSV2RDF4LOD_HOME=${CSV2RDF4LOD_HOME:?"not set; source csv2rdf4lod/source-me.sh or see https://github.com/timrdf/csv2rdf4lod-automation/wiki/CSV2RDF4LOD-not-set"}

# cr:data-root cr:source cr:directory-of-datasets cr:dataset cr:directory-of-versions cr:conversion-cockpit
ACCEPTABLE_PWDs="cr:dataset cr:directory-of-versions cr:conversion-cockpit"
if [ `${CSV2RDF4LOD_HOME}/bin/util/is-pwd-a.sh $ACCEPTABLE_PWDs` != "yes" ]; then
   ${CSV2RDF4LOD_HOME}/bin/util/pwd-not-a.sh $ACCEPTABLE_PWDs
   exit 1
fi

TEMP="_"`basename $0``date +%s`_$$.tmp

if   [[ `${CSV2RDF4LOD_HOME}/bin/util/is-pwd-a.sh cr:dataset`                                                == "yes" ]]; then
   find version -mindepth 1 -maxdepth 1 -type d | grep -v "/\." | sed 's/^version.//'
elif [[ `${CSV2RDF4LOD_HOME}/bin/util/is-pwd-a.sh            cr:directory-of-versions`                       == "yes" ]]; then
   find .       -mindepth 1 -maxdepth 1 -type d | grep -v "/\." | sed 's/^\.\///'
elif [[ `${CSV2RDF4LOD_HOME}/bin/util/is-pwd-a.sh                                     cr:conversion-cockpit` == "yes" ]]; then
   echo `pwd | awk -F\/ '{print $NF}'`
fi

