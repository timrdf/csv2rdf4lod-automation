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

while [ $# -gt 0 ]; do
   file="$1"
   fileMD5=`$CSV2RDF4LOD_HOME/bin/util/md5.sh $file`
   date_id=`date +%s`

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

   shift
done
