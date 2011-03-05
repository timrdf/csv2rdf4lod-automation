#!/bin/bash

# NOTE: implemented in bin/util/header2params2.awk, too.

if [ ${#CSV2RDF4LOD_CONVERT_PERSON_URI} -a ${#CSV2RDF4LOD_CONVERT_MACHINE_URI} ]; then

   echo "<$CSV2RDF4LOD_CONVERT_MACHINE_URI`whoami`>"

elif [ ${#CSV2RDF4LOD_CONVERT_MACHINE_URI} ]; then

   echo "${CSV2RDF4LOD_CONVERT_MACHINE_URI}`whoami`"; # TODO: same as above.

elif [ ${#CSV2RDF4LOD_CONVERT_PERSON_URI} ]; then

   echo "[ a foaf:OnlineAccount; foaf:accountName \"`whoami`\";"
   echo "                        sioc:account_of <$CSV2RDF4LOD_CONVERT_PERSON_URI> ];"

else

   echo "[ a foaf:OnlineAccount; foaf:accountName \"`whoami`\" ];"

fi
