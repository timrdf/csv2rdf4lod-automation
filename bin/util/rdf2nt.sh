#!/bin/bash
#
#3> <> prov:specializationOf <https://github.com/timrdf/csv2rdf4lod-automation/blob/master/bin/util/rdf2nt.sh> .
#
# Accept one or more RDF files in RDF/XML, Turtle, or N-TRIPLES and output N-TRIPLES to stdout.
# The output N-TRIPLES will have collision-safe bnodes (b/c their identifiers are prepended with a filepath hash).
#
# example usages:
#
# Be careful not to process the output as input:
#   rdf2nt.sh *.* > ../all.nt
#
# To handle more files than 'ls' can provide:
#   find . -name "[^.]*" | xargs      rdf2nt.sh > ../all.nt

see="https://github.com/timrdf/csv2rdf4lod-automation/wiki/Installing-csv2rdf4lod-automation---complete"

if [[ $# -eq 0 || "$1" == "--help" ]]; then
   echo
   echo "usage: `basename $0` [--version <version>] <some.rdf>*"
   echo "  output to stderr the N-TRIPLES union of all rdf files given as arguments"
   echo
   echo "  --version <version> : use technique identified by <version>; can be omitted to use original technique."
   echo "                      |"
   echo "             (none)   | use rapper, which can break if turtle is too big."
   echo "                      |"
   echo "  --version  2        | guess-syntax without inspection if it          has  a file extension"
   echo "                      | guess-syntax with    inspection if it does not have a file extension"
   echo "                      | uncompress any gzipped files"
   echo "                      | use serdi to prepend bnodes with prefixes (for all input formats)"
   echo "                      | use rapper for rdf/xml ONLY; use serdi directly for ntriples and turtle"
   exit
fi

version=''
if [[ "$1" == "--version" && $# -gt 1 ]]; then
   version="$2"
   shift 2
fi

while [ $# -gt 0 ]; do
   file="$1" 
   shift

   if [ ! -f $file ]; then
      continue
   fi

   if [ "$file" == "${file%.*}" ]; then 
      # The file does not have an extension.
      # Literally: "The filename is the same with and without an extension"
      # Note: this does not rename the file; use rename-by-syntax.sh for that.
      if [ "$version" == "2" ]; then
         serialization=`guess-syntax.sh --inspect $file mime`
      else
         serialization=`guess-syntax.sh --inspect $file rapper`
         # Original version, feeding through rapper (this can break if file too big.)
      fi
   else
      if [ "$version" == "2" ]; then
         serialization=`guess-syntax.sh           $file mime` # Assume that the file extension is correct (to save time).
      else
         serialization="-g" # Original version, let rapper guess (this can break if file too big.)
      fi
   fi

   # Determine a prefix for bnodes (to avoid bnode collision when concatenating multiple files).
   fullpath=`pwd`/$1 # Does not need to be exact; only needs to be unique.
   md5=""
   if [ `which md5 2> /dev/null` ]; then
      md5=urlhash`md5 -qs $fullpath`
   elif [ `which md5sum 2> /dev/null` ]; then
      md5=urlhash`echo $fullpath | md5sum | awk '{print $1}'`
   fi
 
   if [ "$version" == "2" ]; then

      gunzip --test $file &> /dev/null
      if [ $? -eq 0 ]; then
         gzipped="yes"
         TEMP="_"`basename $0``date +%s`_$$.tmp
         gunzip -c $file > $TEMP

         origFile="$file" # Remember which file we were working with.
         file=$TEMP       # So we can reuse the code that handles uncompressed output.
      else
         gzipped="no"
      fi
      
      if [ "$serialization" == "application/rdf+xml" ]; then
         # Need to use rapper to decompose into N-TRIPLES.
         # Need to use serdi to prepend bnodes with a unique prefix.
         if [[ `which rapper` && `which serdi` ]]; then
            echo "rapper -q -i rdfxml -o ntriples $file | serdi -i ntriples -o ntriples -p $md5 - (from $origFile)" >&2
            rapper -q -i rdfxml -o ntriples $file | serdi -i ntriples -o ntriples -p $md5 -
         elif [[ ! `which rapper` ]]; then
            echo "ERROR: `basename $0` requires rapper. See $see"
            if [[ ! `which serdi` ]]; then
               echo "ERROR: `basename $0` requires serdi. See $see"
            fi
         elif [[ ! `which serdi` ]]; then
            echo "ERROR: `basename $0` requires serdi. See $see"
         fi
      elif [ "$serialization" == "text/plain" ]; then
         # Need to use serdi to prepend bnodes with a unique prefix.
         if [[ `which serdi` ]]; then
            echo "serdi -i ntriples -o ntriples -p $md5 $file (from $origFile)" >&2
            serdi -i ntriples -o ntriples -p $md5 $file
         else
            echo "ERROR: `basename $0` requires serdi. See $see"
         fi
      elif [ "$serialization" == "text/turtle" ]; then
         # Need to use serdi to prepend bnodes with a unique prefix.
         if [[ `which serdi` ]]; then
            echo "serdi -i turtle -o ntriples -p $md5 $file (from $origFile)" >&2
            serdi -i turtle -o ntriples -p $md5 $file
         else
            echo "ERROR: `basename $0` requires serdi. See $see"
         fi
      else
         echo "`basename $0` TODO: $serialization $file" >&2
      fi

      if [ -e "$TEMP" ]; then
         rm "$TEMP"
      fi 

   else 

      # Original version

      # -q : quiet
      # -o : output ntriples
      # rapper cannot contextualize bnodes and may lead to a collision.
      if [[ `which rapper` && `which serdi` ]]; then
         rapper -q $serialization -o ntriples $file | serdi -i ntriples -p $md5 -
      elif [ `which rapper` ]; then
         echo "ERROR: `basename $0` requires rapper. See $see"
      else
         echo "ERROR: `basename $0` requires serdi. See $see"
      fi
      # serdi can, but cannot handle RDF/XML (so use rapper to preprocess it).
      # -p : prepend bnodes with $md5
      # -  : read from stdin
      # (prints to stdout)
   fi

done
