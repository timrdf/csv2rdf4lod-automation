#!/bin/bash
#
# print out some information about the dataset in the current directory.

CSV2RDF4LOD_HOME=${CSV2RDF4LOD_HOME:?"not set; source csv2rdf4lod/source-me.sh or see https://github.com/timrdf/csv2rdf4lod-automation/wiki/CSV2RDF4LOD-not-set"}

ACCEPTABLE_PWDs="cr:dataset cr:directory-of-versions cr:conversion-cockpit"
if [ `${CSV2RDF4LOD_HOME}/bin/util/is-pwd-a.sh $ACCEPTABLE_PWDs` != "yes" ]; then
   ${CSV2RDF4LOD_HOME}/bin/util/pwd-not-a.sh $ACCEPTABLE_PWDs
   exit 1
   # cr:data-root cr:source cr:directory-of-datasets cr:dataset cr:directory-of-versions cr:conversion-cockpit
fi

prefixDef=""
prefix=""
q1=""  # Quote
q2=""  # Quote
a1=""  # Angle
a2=""  # Angle
end="" # Period
if [ ${1:-"."} == 'void' ]; then
   prefixDef="@prefix conversion: <http://purl.org/twc/vocab/conversion/> ."
   isabstract="    a conversion:AbstractDataset;"
   if [ `${CSV2RDF4LOD_HOME}/bin/util/is-pwd-a.sh cr:conversion-cockpit` == "yes" ]; then
      isversioned="    a conversion:VersionedDataset;"
   fi
   prefix="conversion:"
   a1="<"
   a2=">"
   q1="\""
   q2="\";"
   end="."
fi
base_uri=${CSV2RDF4LOD_BASE_URI_OVERRIDE:-$CSV2RDF4LOD_BASE_URI}

sourceID=`is-pwd-a.sh  cr:bone --id-of source`
datasetID=`is-pwd-a.sh cr:bone --id-of dataset`
versionID=`is-pwd-a.sh cr:bone --id-of version`

CSV2RDF4LOD_BASE_URI=${CSV2RDF4LOD_BASE_URI:?"not set; source csv2rdf4lod/source-me.sh or see https://github.com/timrdf/csv2rdf4lod-automation/wiki/CSV2RDF4LOD-not-set"}

echo "#   base_uri              $CSV2RDF4LOD_BASE_URI # (env)"
echo "#   base_uri              $CSV2RDF4LOD_BASE_URI_OVERRIDE # (override)"
echo $prefixDef
echo
echo "$a1$CSV2RDF4LOD_BASE_URI/source/$sourceID/dataset/$datasetID$a2"
#   grep -H ":base_uri" manual/*.params.ttl | awk '{print "    base_uri (params)     "$3,"   ",$1}' | sed -e 's/:$//' -e 's/"//g' -e 's/..xsd:anyURI;//'
echo      $isabstract
echo "    ${prefix}base_uri              ${q1}$base_uri${q2}"
echo "    ${prefix}source_identifier     ${q1}$sourceID${q2}"                                        
echo "    ${prefix}dataset_identifier    ${q1}$datasetID${q2}"                                    
echo $end
echo
if [ `${CSV2RDF4LOD_HOME}/bin/util/is-pwd-a.sh cr:conversion-cockpit` == "yes" ]; then
   echo "$a1$CSV2RDF4LOD_BASE_URI/source/$sourceID/dataset/$datasetID/version/$versionID$a2"
   echo      $isversioned
   echo "    ${prefix}base_uri              ${q1}$base_uri${q2}"
   echo "    ${prefix}source_identifier     ${q1}$sourceID${q2}"                                        
   echo "    ${prefix}dataset_identifier    ${q1}$datasetID${q2}"                                    
   echo "    ${prefix}version_identifier    ${q1}$versionID${q2}"
   echo $end 
fi
