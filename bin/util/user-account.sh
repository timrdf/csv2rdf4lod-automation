#!/bin/bash

#
# NOTE: implemented in bin/util/header2params2.awk, too.
#

if [ ${#CSV2RDF4LOD_CONVERT_MACHINE_URI} -gt 0 ]; then
   if [ ${#CSV2RDF4LOD_CONVERT_PERSON_URI} ]; then
      echo "<$CSV2RDF4LOD_CONVERT_PERSON_URI> foaf:holdsAccount <$CSV2RDF4LOD_CONVERT_MACHINE_URI`whoami`> ."
   fi 
   echo "<$CSV2RDF4LOD_CONVERT_MACHINE_URI`whoami`>"
   echo "   a foaf:OnlineAccount;"
   echo "   foaf:accountName \"`whoami`\";"
   echo "   dcterms:isPartOf <$CSV2RDF4LOD_CONVERT_MACHINE_URI>;"
   if [ ${#CSV2RDF4LOD_CONVERT_PERSON_URI} ]; then
      echo "   sioc:account_of  <$CSV2RDF4LOD_CONVERT_PERSON_URI>;"
   fi 
   echo "."
elif [ ${#CSV2RDF4LOD_CONVERT_PERSON_URI} ]; then
   echo "<$CSV2RDF4LOD_CONVERT_PERSON_URI> dcterms:identifier \"`whoami`\" ."
fi
