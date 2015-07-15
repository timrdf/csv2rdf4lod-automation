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
# print out some information about the dataset in the current directory.

if [[ "$1" == "--help" || "$1" == "-h" ]]; then
   echo "usage: `basename $0` {void, uri}"   
   exit 1
fi

see='https://github.com/timrdf/csv2rdf4lod-automation/wiki/CSV2RDF4LOD-not-set'
CSV2RDF4LOD_HOME=${CSV2RDF4LOD_HOME:?"not set; source csv2rdf4lod/source-me.sh or see $see"}


#see='https://github.com/timrdf/csv2rdf4lod-automation/wiki/CSV2RDF4LOD-not-set'
#CSV2RDF4LOD_BASE_URI=${CSV2RDF4LOD_BASE_URI:?"not set; source csv2rdf4lod/source-me.sh or see $see"}
see='https://github.com/timrdf/csv2rdf4lod-automation/wiki/CSV2RDF4LOD_BASE_URI#needed-by-bincr-dataset-urish'
CSV2RDF4LOD_BASE_URI=${CSV2RDF4LOD_BASE_URI-"$see"}

# cr:data-root cr:source cr:directory-of-datasets cr:dataset cr:directory-of-versions cr:conversion-cockpit
ACCEPTABLE_PWDs="cr:dataset cr:directory-of-versions cr:conversion-cockpit"
if [ `${CSV2RDF4LOD_HOME}/bin/util/is-pwd-a.sh $ACCEPTABLE_PWDs` != "yes" ]; then
   ${CSV2RDF4LOD_HOME}/bin/util/pwd-not-a.sh $ACCEPTABLE_PWDs
   exit 1
fi

base_uri=${CSV2RDF4LOD_BASE_URI_OVERRIDE:-$CSV2RDF4LOD_BASE_URI}
sourceID=`cr-source-id.sh`
datasetID=`cr-dataset-id.sh`
versionID=`cr-version-id.sh`

if [[ "$1" == "uri" || "$1" == "--uri" ]]; then
   if [[ "`cr-pwd-type.sh`" == "cr:dataset" || "`cr-pwd-type.sh`" == "cr:directory-of-versions" ]]; then
      echo $base_uri/source/$sourceID/dataset/$datasetID
   else
      echo $base_uri/source/$sourceID/dataset/$datasetID/version/$versionID
   fi
   exit 0
elif [[ "$1" == "abstract" || "$1" == "--abstract" || "$1" == "abstract-uri" || "$1" == "--abstract-uri" ]]; then
   echo $base_uri/source/`cr-source-id.sh`/dataset/`cr-dataset-id.sh`
   exit 0
fi

prefix=""
q1=""  # Quote
q2=""  # Quote
a1=""  # Angle
a2=""  # Angle
end="" # Period

if [[ "$1" == 'void' || "$1" == "--void" ]]; then
   echo "@prefix void:       <http://rdfs.org/ns/void#> ."
   echo "@prefix conversion: <http://purl.org/twc/vocab/conversion/> ."

   isabstract="a conversion:AbstractDataset, void:Dataset;"
   if [ `${CSV2RDF4LOD_HOME}/bin/util/is-pwd-a.sh cr:conversion-cockpit` == "yes" ]; then
      isversioned="a conversion:VersionedDataset, void:Dataset;"
   fi
   echo
   prefix="conversion:"
   a1="<"
   a2=">"
   q1="\""
   q2="\";"
   end="."
fi

# TODO: use base_uri to permit override.

if [[ "$1" == 'void' || "$1" == "--void" ]]; then
   # See https://github.com/jimmccusker/twc-healthdata/wiki/Using-VoID-for-Accessibility
   echo "<$base_uri/void> a void:Dataset;"
   echo "   void:rootResource <$base_uri/void>;"
   echo "   void:subset       <$base_uri/source/$sourceID/dataset/$datasetID>;"
   echo "."
fi
echo "$a1$base_uri/source/$sourceID/dataset/$datasetID$a2"
echo "    $isabstract"
echo "    ${prefix}base_uri              ${q1}$base_uri${q2}"
echo "    ${prefix}source_identifier     ${q1}$sourceID${q2}"                                        
echo "    ${prefix}dataset_identifier    ${q1}$datasetID${q2}"                                    
echo $end
echo
if [ `${CSV2RDF4LOD_HOME}/bin/util/is-pwd-a.sh cr:conversion-cockpit` == "yes" ]; then
   if [[ "$1" == 'void' || "$1" == "--void" ]]; then
      # See https://github.com/jimmccusker/twc-healthdata/wiki/Using-VoID-for-Accessibility
      echo "<$base_uri/source/$sourceID/dataset/$datasetID> a conversion:AbstractDataset;"
      echo "   void:subset <$base_uri/source/$sourceID/dataset/$datasetID/version/$versionID> ."
   fi
   echo "$a1$base_uri/source/$sourceID/dataset/$datasetID/version/$versionID$a2"
   echo "    $isversioned"
   echo "    ${prefix}base_uri              ${q1}$base_uri${q2}"
   echo "    ${prefix}source_identifier     ${q1}$sourceID${q2}"                                        
   echo "    ${prefix}dataset_identifier    ${q1}$datasetID${q2}"                                    
   echo "    ${prefix}version_identifier    ${q1}$versionID${q2}"
   echo $end 
fi
