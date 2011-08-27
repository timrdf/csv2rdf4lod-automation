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

type=""
for pwd_type in `${CSV2RDF4LOD_HOME}/bin/util/is-pwd-a.sh --types`; do
   is=`${CSV2RDF4LOD_HOME}/bin/util/is-pwd-a.sh $pwd_type`
   if [[ "$is" == "yes" ]]; then
      type="$pwd_type"
   fi
   #echo $pwd_type $is
done

if [[ ${#type} -gt 0 ]]; then
   echo $type
else
   echo "Not recognized; see https://github.com/timrdf/csv2rdf4lod-automation/wiki/Directory-Conventions" 
fi
