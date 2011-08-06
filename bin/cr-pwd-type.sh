#!/bin/bash
#
# https://github.com/timrdf/csv2rdf4lod-automation/blob/master/bin/util/cr-pwd-type.sh

CSV2RDF4LOD_HOME=${CSV2RDF4LOD_HOME:?"not set; source my-csv2rdf4lod-source-me.sh or see https://github.com/timrdf/csv2rdf4lod-automation/wiki/CSV2RDF4LOD-not-set"}

# usage: is-pwd-a.sh {cr:dataset, cr:conversion-cockpit}

type=""
for pwd_type in `${CSV2RDF4LOD_HOME}/bin/util/is-pwd-a.sh | sed 's/^.*{//;s/}//;s/,//g'`; do
   echo $pwd_type `${CSV2RDF4LOD_HOME}/bin/util/is-pwd-a.sh $pwd_type`
   is=`${CSV2RDF4LOD_HOME}/bin/util/is-pwd-a.sh $pwd_type`
   if [[ "$is" == "yes" ]]; then
      type="$pwd_type"
   fi
done

if [[ ${#type} -gt 0 ]]; then
   echo $type
else
   echo "Not recognized; see https://github.com/timrdf/csv2rdf4lod-automation/wiki/Directory-Conventions" 
fi

#if [[ $1 == "cr:version"              || $1 == "cr:conversion-cockpit" ]]; then
#    source=`basename \`cd ../../../../ 2>/dev/null && pwd\``
#   dataset=`basename \`cd ../../       2>/dev/null && pwd\`` # TODO: need to add that step in...
#   version=`basename \`cd ../          2>/dev/null && pwd\``

   #echo "source $source"
   #echo "dataset $dataset"
   #echo "version $version"
#   if [[ "$source" == "source" && "$version" == "version" ]]; then
#      is_a="yes"
#   fi
