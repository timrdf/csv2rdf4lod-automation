#!/bin/bash
#
# Return the type of directory pwd is.
#
# https://github.com/timrdf/csv2rdf4lod-automation/blob/master/bin/util/cr-pwd-type.sh
# https://github.com/timrdf/csv2rdf4lod-automation/wiki/Directory-Conventions

CSV2RDF4LOD_HOME=${CSV2RDF4LOD_HOME:?"not set; source my-csv2rdf4lod-source-me.sh or see https://github.com/timrdf/csv2rdf4lod-automation/wiki/CSV2RDF4LOD-not-set"}

if [[ "$1" == "--types" ]]; then
   ${CSV2RDF4LOD_HOME}/bin/util/is-pwd-a.sh --types
   exit 1 
fi

if   [[ `${CSV2RDF4LOD_HOME}/bin/util/is-pwd-a.sh cr:data-root`             == "yes" ]]; then
   echo "source/"
elif [[ `${CSV2RDF4LOD_HOME}/bin/util/is-pwd-a.sh cr:source`                == "yes" ]]; then
   pwd
elif [[ `${CSV2RDF4LOD_HOME}/bin/util/is-pwd-a.sh cr:directory-of-datasets` == "yes" ]]; then
   pwd
elif [[ `${CSV2RDF4LOD_HOME}/bin/util/is-pwd-a.sh cr:dataset`               == "yes" ]]; then
   pwd
elif [[ `${CSV2RDF4LOD_HOME}/bin/util/is-pwd-a.sh cr:directory-of-versions` == "yes" ]]; then
   pwd
elif [[ `${CSV2RDF4LOD_HOME}/bin/util/is-pwd-a.sh cr:conversion-cockpit`    == "yes" ]]; then
   pwd
else
   echo "Not recognized; see https://github.com/timrdf/csv2rdf4lod-automation/wiki/Directory-Conventions" 
fi
