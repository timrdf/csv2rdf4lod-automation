#!/bin/bash

echo "@prefix foaf:    <http://xmlns.com/foaf/0.1/> ."
echo "@prefix sioc:    <http://rdfs.org/sioc/ns#> ."
echo "@prefix dcterms: <http://purl.org/dc/terms/> ."

if [ ${1-"."} != "--cite" ]; then

   #
   # NOTE: implemented in bin/util/header2params2.awk, too.
   #

   if [ ${#CSV2RDF4LOD_CONVERT_MACHINE_URI} -gt 0 ]; then
      if [ ${#CSV2RDF4LOD_CONVERT_PERSON_URI} -gt 0 ]; then
         echo "<$CSV2RDF4LOD_CONVERT_PERSON_URI> foaf:holdsAccount <${CSV2RDF4LOD_CONVERT_MACHINE_URI}#`whoami`> ."
      fi 
      echo "<${CSV2RDF4LOD_CONVERT_MACHINE_URI}#`whoami`>"
      echo "   a foaf:OnlineAccount;"
      echo "   foaf:accountName \"`whoami`\";"
      echo "   dcterms:isPartOf <$CSV2RDF4LOD_CONVERT_MACHINE_URI>;"
      if [ ${#CSV2RDF4LOD_CONVERT_PERSON_URI} -gt 0 ]; then
         echo "   sioc:account_of  <$CSV2RDF4LOD_CONVERT_PERSON_URI>;"
      fi 
      echo "."
   elif [ ${#CSV2RDF4LOD_CONVERT_PERSON_URI} -gt 0 ]; then
      echo "<$CSV2RDF4LOD_CONVERT_PERSON_URI> dcterms:identifier \"`whoami`\" ."
   fi

else

   #
   # NOTE: implemented in bin/util/header2params2.awk, too.
   #

   if [ ${#CSV2RDF4LOD_CONVERT_PERSON_URI} -gt 0 -a ${#CSV2RDF4LOD_CONVERT_MACHINE_URI} -gt 0 ]; then

      echo "<${CSV2RDF4LOD_CONVERT_MACHINE_URI}#`whoami`>"

   elif [ ${#CSV2RDF4LOD_CONVERT_MACHINE_URI} -gt 0 ]; then

      echo "<${CSV2RDF4LOD_CONVERT_MACHINE_URI}#`whoami`>"; # TODO: same as above.

   elif [ ${#CSV2RDF4LOD_CONVERT_PERSON_URI} -gt 0 ]; then

      echo "[ a foaf:OnlineAccount; foaf:accountName \"`whoami`\";"
      echo "                        sioc:account_of <$CSV2RDF4LOD_CONVERT_PERSON_URI> ];"

   else

      echo "[ a foaf:OnlineAccount; foaf:accountName \"`whoami`\" ];"

   fi

fi
