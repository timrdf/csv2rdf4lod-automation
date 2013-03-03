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


if [ "$1" != "--cite" ]; then

   echo "@prefix foaf:    <http://xmlns.com/foaf/0.1/> ."
   echo "@prefix sioc:    <http://rdfs.org/sioc/ns#> ."
   echo "@prefix dcterms: <http://purl.org/dc/terms/> ."
   echo "@prefix prov:    <http://www.w3.org/ns/prov#> ."
   echo

   #
   # NOTE: implemented in bin/util/header2params2.awk, too.
   #

   if [ -n "$CSV2RDF4LOD_CONVERT_MACHINE_URI" ]; then
      echo "<${CSV2RDF4LOD_CONVERT_MACHINE_URI}>"
      echo "   a prov:Entity;"
      echo "."
      if [ -n "$CSV2RDF4LOD_CONVERT_PERSON_URI" ]; then
         echo "<$CSV2RDF4LOD_CONVERT_PERSON_URI>"
         echo "  a prov:Agent, foaf:Agent;"
         echo "  foaf:holdsAccount <${CSV2RDF4LOD_CONVERT_MACHINE_URI}#`whoami`>;"
         echo "."
      fi 
      echo "<${CSV2RDF4LOD_CONVERT_MACHINE_URI}#`whoami`>"
      echo "   a foaf:OnlineAccount, prov:Agent;"
      echo "   foaf:accountName \"`whoami`\";"
      echo "   dcterms:isPartOf <$CSV2RDF4LOD_CONVERT_MACHINE_URI>;"
      if [ -n "$CSV2RDF4LOD_CONVERT_PERSON_URI" ]; then
         echo "   sioc:account_of      <$CSV2RDF4LOD_CONVERT_PERSON_URI>;"
         echo "   prov:actedOnBehalfOf <$CSV2RDF4LOD_CONVERT_PERSON_URI>;"
      fi 
      echo "."
   elif [ -n "$CSV2RDF4LOD_CONVERT_PERSON_URI" ]; then
      echo "<$CSV2RDF4LOD_CONVERT_PERSON_URI> dcterms:identifier \"`whoami`\" ."
   fi

else

   #
   # NOTE: implemented in bin/util/header2params2.awk, too.
   #

   if [[ -n "$CSV2RDF4LOD_CONVERT_PERSON_URI" && -n "$CSV2RDF4LOD_CONVERT_MACHINE_URI" ]]; then

      echo "<${CSV2RDF4LOD_CONVERT_MACHINE_URI}#`whoami`>"

   elif [ -n "$CSV2RDF4LOD_CONVERT_MACHINE_URI" ]; then

      echo "<${CSV2RDF4LOD_CONVERT_MACHINE_URI}#`whoami`>" # TODO: same as above.

   elif [ -n "$CSV2RDF4LOD_CONVERT_PERSON_URI" ]; then

      echo "[ a foaf:OnlineAccount; foaf:accountName \"`whoami`\";"
      echo "                        sioc:account_of <$CSV2RDF4LOD_CONVERT_PERSON_URI> ]"

   else

      echo "[ a foaf:OnlineAccount; foaf:accountName \"`whoami`\" ]"

   fi
fi
