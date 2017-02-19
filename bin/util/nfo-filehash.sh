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

if [[ $# -eq 0 || "$1" == '--help' ]]; then
   echo "usage: `basename $0` [--foci]"
   exit
fi

mode="describe"
if [[ "$1" == "--foci" ]]; then
   mode="foci" 
   shift
fi

while [ $# -gt 0 ]; do
   file="$1"
   fileMD5=`$CSV2RDF4LOD_HOME/bin/util/md5.sh $file`
   date_id=`date +%s`

   fileAbsolute="$(cd `dirname $file` && echo ${PWD})/`basename $file`"

   pathMD5=`$CSV2RDF4LOD_HOME/bin/util/md5.sh -qs $fileAbsolute`
   md5URI=${CSV2RDF4LOD_BASE_URI_OVERRIDE:-$CSV2RDF4LOD_BASE_URI}/id/md5/$fileMD5
   specialization=${CSV2RDF4LOD_BASE_URI_OVERRIDE:-$CSV2RDF4LOD_BASE_URI}/id/md5/$fileMD5/path/$pathMD5/`basename $file`
   specializationPath=${CSV2RDF4LOD_BASE_URI_OVERRIDE:-$CSV2RDF4LOD_BASE_URI}/id/path/$pathMD5/`basename $file`
   if [[ "$mode" == "https://github.com/timrdf/csv2rdf4lod-automation/commit/45e7a33144b02c03ba8ed4cf664315794bde4da4#diff-80071c340dfce1c99d897887ff8b1889" ]]; then
      # This modeling is deprecated.
      echo "<$file>"                                                                    
      echo "   a nfo:FileDataObject;"                                                    
      echo "   nfo:fileName \"$file\";"                                
      echo "   nfo:hasHash <md5_${fileMD5}_time_${date_id}>;"                                
      echo "."                                                                      
      echo "<md5_${fileMD5}_time_${date_id}>"                                             
      echo "   a nfo:FileHash; "                                                 
      echo "   dcterms:date      \"`dateInXSDDateTime.sh`\"^^xsd:dateTime;"
      echo "   nfo:hashAlgorithm \"md5\";"                                      
      echo "   nfo:hashValue     \"$fileMD5\";"                          
      echo "."                                                                
   elif [[ "$mode" == "describe" ]]; then
      # See https://github.com/timrdf/csv2rdf4lod-automation/wiki/Modeling-file-provenance
      if [[ `is-pwd-a.sh cr:conversion-cockpit` == 'yes' ]]; then
         echo "<`cr-dataset-uri.sh --uri`>"
         echo "   prov:wasDerivedFrom"
         echo "      <$specialization> ."
         echo
      fi
      echo "<$specialization>"                                                                    
      echo "   a nfo:FileDataObject;"                                                    
      echo "   nfo:fileName \"`basename $file`\";"                                
      echo "   dcterms:date \"`dateInXSDDateTime.sh`\"^^xsd:dateTime;"
      echo "   nfo:hasHash     <$md5URI>;" #<md5_${fileMD5}_time_${date_id}>;"                                
      echo "   prov:atLocation <$specializationPath>;"
      echo "."                                                                      
      echo "<$md5URI>"                                             
      echo "   a nfo:FileHash; "                                                 
      echo "   nfo:hashAlgorithm \"md5\";"                                      
      echo "   nfo:hashValue     \"$fileMD5\";"                          
      echo "."                                                                
      if [[ "`cr-pwd-type.sh`" == 'cr:conversion-cockpit' ]]; then
         eg=`cr-ln-to-www-root.sh --url-of-filepath \`cr-ln-to-www-root.sh -n source\``
         echo "<$specializationPath>"
         echo "   prv:serializedBy <`dirname $eg`/$file> ."
      else
         echo "<$specializationPath> prv:serializedBy <`basename $file`> ."
      fi
   elif [[ "$mode" == "foci" ]]; then
      echo "<$specialization>" 
   fi

   shift
done
