#!/bin/bash

if [ $# -lt 1 ]; then
   echo "usage `$basename $0` some2GB.ttl ..."
   echo "outputs NT version of *.ttl to stdout"
   exit 1
fi

CSV2RDF4LOD_HOME=${CSV2RDF4LOD_HOME:?"not set; source csv2rdf4lod/source-me.sh or see https://github.com/timrdf/csv2rdf4lod-automation/wiki/CSV2RDF4LOD-not-set"}

while [ $# -gt 0 ]; do
   ttl2chunk="$1"

   rm `dirname $ttl2chunk`/cHuNk-*.ttl &> /dev/null                               # Clean up before chunking
   #echo "   cHuNking $ttl2chunk"
   $CSV2RDF4LOD_HOME/bin/split_ttl.pl $ttl2chunk # This produces a bunch of cHuNks in local directory.
   for chunk in `dirname $ttl2chunk`/cHuNk-*; do
         #echo "   NT'ing $chunk" | tee -a $CSV2RDF4LOD_LOG
         #echo rapper -i turtle $chunk -o ntriples
         rapper -i turtle $chunk -o ntriples
         # $allSAMEAS created after all NL done.
   done
   rm `dirname $ttl2chunk`/cHuNk-*.ttl &> /dev/null
   shift
done
