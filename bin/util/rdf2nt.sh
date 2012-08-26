#!/bin/bash

# Accept an RDF file in RDF/XML, Turtle, or N-TRIPLES and output N-TRIPLES or N-QUADS file.
# N-TRIPLES output will be produce collision-safe bnodes (b/c will prepend with filepath hash).

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
   md5=`md5 -qs $fullpath`
   
   # rapper cannot contextualize bnodes and may lead to a collision.
   # serdi can, but cannot handle RDF/XML (so use rapper to preprocess it)
   rapper -q $serialization -o ntriples $file | serdi -i ntriples -p $md5 -

   shift
done
