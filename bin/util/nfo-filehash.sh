#!/bin/bash

while [ $# -gt 0 ]; do
   file="$1"
   fileMD5=`$CSV2RDF4LOD_HOME/bin/util/md5.sh $file`
   date_id=`date +%s`

   echo "<$file>"                                                                    
   echo "   a pmlp:Information;"                                                    
   echo "   nfo:hasHash <md5_${fileMD5}_time_${date_id}>;"                                
   echo "."                                                                      
   echo "<md5_${fileMD5}_time_${date_id}>"                                             
   echo "   a nfo:FileHash; "                                                 
   echo "   dcterms:date \"`dateInXSDDateTime.sh`\"^^xsd:dateTime;"
   echo "   nfo:hashAlgorithm \"md5\";"                                      
   echo "   nfo:hashValue \"$fileMD5\";"                          
   echo "."                                                                

   shift
done
