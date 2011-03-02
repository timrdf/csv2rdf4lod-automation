#!/bin/bash

while [ $# -gt 0 ]; do
   file="$1"
   fileMD5=`$CSV2RDF4LOD_HOME/bin/util/md5.sh $file`

   echo "<$file>"                                                                    
   echo "   a pmlp:Information;"                                                    
   echo "   nfo:hasHash <md5_$fileMD5>;"                                
   echo "."                                                                      
   echo ""                                                                      
   echo "<md5_$fileMD5>"                                             
   echo "   a nfo:FileHash; "                                                 
   echo "   nfo:hashAlgorithm \"md5\";"                                      
   echo "   nfo:hashValue \"$fileMD5\";"                          
   echo "."                                                                

   shift
done
