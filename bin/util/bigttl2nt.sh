#!/bin/bash
#
# https://github.com/timrdf/csv2rdf4lod-automation/blob/master/bin/util/bigttl2nt.sh
#
# Print N-Triples for each Turtle file given. 
# "large" Turtle is handled and spoon-fed to rapper.

if [ $# -lt 1 ]; then
   echo "usage `$basename $0` some2GB.ttl ..."
   echo "outputs NT version of *.ttl to stdout"
   exit 1
fi

CSV2RDF4LOD_HOME=${CSV2RDF4LOD_HOME:?"not set; source csv2rdf4lod/source-me.sh or see https://github.com/timrdf/csv2rdf4lod-automation/wiki/CSV2RDF4LOD-not-set"}

# For each Turtle file
while [ $# -gt 0 ]; do
   ttl2chunk="$1"

   if [ `too-big-for-rapper.sh $ttl2chunk` == "yes" ]; then
      rm -f `dirname $ttl2chunk`/cHuNk-*.ttl   # Clean up before chunking

      #echo "   cHuNking $ttl2chunk"
      $CSV2RDF4LOD_HOME/bin/split_ttl.pl $ttl2chunk # This produces a bunch of cHuNks in local directory.
      for chunk in `dirname $ttl2chunk`/cHuNk-*; do
            #echo "   NT'ing $chunk"
            #echo rapper -i turtle $chunk -o ntriples
            rapper -q -i turtle $chunk -o ntriples
      done

      rm -f `dirname $ttl2chunk`/cHuNk-*.ttl   # Clean up after chunking
   else
      # The Turtle file is small enough for rapper to handle on its own.
      rapper -q -i turtle -o ntriples $ttl2chunk
   fi

   shift
done
