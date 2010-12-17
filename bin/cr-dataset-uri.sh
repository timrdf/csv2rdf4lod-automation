#!/bin/sh
#
# print out some information about the dataset in the current directory.

back_one=`cd .. 2>/dev/null && pwd`
ANCHOR_SHOULD_BE_VERSION=`basename $back_one`
if [ $ANCHOR_SHOULD_BE_VERSION != "version" ]; then
   echo "  Working directory does not appear to be a VERSION directory."
   echo "  Run `basename $0` from a VERSION directory (e.g. csv2rdf4lod/data/source/SOURCE/DDD/version/VVV/)"
   exit 1
fi

prefixDef=""
prefix=""
q1=""
q2=""
a1=""
a2=""
end=""
if [ ${1:-"."} == 'void' ]; then
   prefixDef="@prefix conversion: <http://purl.org/twc/vocab/conversion/> ."
   prefix="conversion:"
   a1="<"
   a2=">"
   q1="\""
   q2="\";"
   end="."
fi
base_uri=${CSV2RDF4LOD_BASE_URI_OVERRIDE:-$CSV2RDF4LOD_BASE_URI}

back_three=`cd ../../.. 2>/dev/null && pwd`
sourceID=`basename $back_three` # Use the names from the canonical directory structure
if [ $sourceID == "data.gov" ]; then
   sourceID="data-gov"
fi

back_two=`cd ../.. 2>/dev/null && pwd`
datasetID=`basename $back_two` # Use the names from the canonical directory structure

datasetDir=`pwd`
versionID=`basename $datasetDir` # Use the names from the canonical directory structure

CSV2RDF4LOD_BASE_URI=${CSV2RDF4LOD_BASE_URI:?"not set; source csv2rdf4lod/source-me.sh"}

echo "#   base_uri              $CSV2RDF4LOD_BASE_URI # (env)"
echo "#   base_uri              $CSV2RDF4LOD_BASE_URI_OVERRIDE # (override)"
echo $prefixDef
echo
echo "$a1$CSV2RDF4LOD_BASE_URI/source/$sourceID/dataset/$datasetID$a2"
#   grep -H ":base_uri" manual/*.params.ttl | awk '{print "    base_uri (params)     "$3,"   ",$1}' | sed -e 's/:$//' -e 's/"//g' -e 's/..xsd:anyURI;//'
echo "    ${prefix}base_uri              ${q1}$base_uri${q2}"
echo "    ${prefix}source_identifier     ${q1}$sourceID${q2}"                                        
echo "    ${prefix}dataset_identifier    ${q1}$datasetID${q2}"                                    
echo $end
echo
echo "$a1$CSV2RDF4LOD_BASE_URI/source/$sourceID/dataset/$datasetID/version/$versionID$a2"
echo "    ${prefix}base_uri              ${q1}$base_uri${q2}"
echo "    ${prefix}source_identifier     ${q1}$sourceID${q2}"                                        
echo "    ${prefix}dataset_identifier    ${q1}$datasetID${q2}"                                    
echo "    ${prefix}version_identifier    ${q1}$versionID${q2}"
echo $end


