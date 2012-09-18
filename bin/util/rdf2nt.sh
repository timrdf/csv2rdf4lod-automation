#!/bin/bash
#
# Accept an RDF file in RDF/XML, Turtle, or N-TRIPLES and output N-TRIPLES or N-QUADS file.
# N-TRIPLES output will be produce collision-safe bnodes (b/c will prepend with filepath hash).
#
# example usages:
#
# Be careful not to process the output as input:
#   rdf2nt.sh *.* > ../all.nt
#
# To handle more files than 'ls' can provide:
#   find . -name "[^.]*" | xargs      rdf2nt.sh > ../all.nt

while [ $# -gt 0 ]; do
   file="$1" 

   if [ "$file" == "${file%.*}" ]; then 
      # "The filename is the same with and without an extension"
      # The file does not have an extension.
      # Note: this does not rename the file; use rename-by-syntax.sh for that.
      serialization=`guess-syntax.sh --inspect $file rapper`
   else
      serialization="-g" # Assume that the extension is correct
   fi
   fullpath=`pwd`/$1 # Does not need to be exact; only needs to be unique.
   md5=""
   if [ `which md5 2> /dev/null` ]; then
      md5=urlhash`md5 -qs $fullpath`
   elif [ `which md5sum 2> /dev/null` ]; then
      md5=urlhash`echo $fullpath | md5sum | awk '{print $1}'`
   fi
   
   # -q : quiet
   # -o : output ntriples
   # rapper cannot contextualize bnodes and may lead to a collision.
   if [[ `which rapper` && `which serdi` ]]; then
      rapper -q $serialization -o ntriples $file | serdi -i ntriples -p $md5 -
   elif [ `which rapper` ]; then
      see="https://github.com/timrdf/csv2rdf4lod-automation/wiki/Installing-csv2rdf4lod-automation---complete"
      echo "ERROR: `basename $0` requires rapper. See $see"
   else
      see="https://github.com/timrdf/csv2rdf4lod-automation/wiki/Installing-csv2rdf4lod-automation---complete"
      echo "ERROR: `basename $0` requires serdi. See $see"
   fi
   # serdi can, but cannot handle RDF/XML (so use rapper to preprocess it).
   # -p : prepend bnodes with $md5
   # -  : read from stdin
   # (prints to stdout)
   shift
done
