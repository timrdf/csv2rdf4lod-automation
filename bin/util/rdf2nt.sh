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

HOME=$(cd ${0%/*/*} && echo ${PWD%/*})
export CLASSPATH=$CLASSPATH`$HOME/bin/util/cr-situate-classpaths.sh`
CSV2RDF4LOD_HOME=${CSV2RDF4LOD_HOME:?$HOME}
export PATH=$PATH`$HOME/bin/util/cr-situate-paths.sh`

see="https://github.com/timrdf/csv2rdf4lod-automation/wiki/Installing-csv2rdf4lod-automation---complete"

if [[ $# -eq 0 || "$1" == "--help" ]]; then
   echo
   echo "usage: `basename $0` [--version <version>] [--verbose] [-I <base-uri>] <some.rdf>*"
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
   echo
   echo "  --verbose           | print more."
   echo ""
   echo "  -I <base-uri>       | Use <base-uri> for any relative URIs."
   exit
fi

version='2'
flag_version="--version 2"
if [[ "$1" == "--version" && $# -gt 1 ]]; then
   version="$2"
   flag_version="--version $2"
   shift 2
fi

verbose='no'
flag_verbose=""
if [[ "$1" == "--verbose" || "$1" == "-v" ]]; then
   verbose='yes'
   flag_verbose="--verbose"
   shift
fi

I=""  # The base URI
if [[ "$1" == "-I" ]]; then
   I="$2"
   shift 2
fi

TEMP="_"`basename $0``date +%s`_$$.tmp
while [ $# -gt 0 ]; do
   file="$1" 
   shift

   if [ ! -f $file ]; then
      if [[ "$file" =~ http.* ]]; then
         if [[ "$verbose" == 'yes' ]]; then
            echo "`basename $0` retrieving $file from web." >&2
         fi
         rapper -q -g -o ntriples $file -I $file > $TEMP         
         $0 $flag_version $flag_verbose $TEMP
         rm $TEMP
      fi
      continue
   fi

   if [[ "$file" == "${file%.*}" || ! ( "${file##*.}" == "ttl" || "${file##*.}" == "rdf" || "${file##*.}" == "nt" ) ]]; then 
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
   #echo "`basename $0` guessed syntax: $serialization" >&2
   

   # Determine a prefix for bnodes (to avoid bnode collision when concatenating multiple files).
   fullpath=`pwd`/$1 # Does not need to be exact; only needs to be unique.
   md5=""
   if [ `which md5 2> /dev/null` ]; then
      md5=urlhash`md5 -qs $fullpath`
   elif [ `which md5sum 2> /dev/null` ]; then
      md5=urlhash`echo $fullpath | md5sum | awk '{print $1}'`
   fi
 
   if [ "$version" == "2" ]; then

      # $I can be set with command line arguments above.
      if [[ -z "$I" && -e $file.sd_name ]]; then
         if [[ "$verbose" == 'yes' ]]; then
            echo "`basename $0` using -I basename from .sd_name" >&2
         fi
         I="`cat $file.sd_name`"
      elif [[ -z "$I" && `which cr-pwd-type.sh` && `cr-pwd-type.sh` == 'cr:conversion-cockpit' && -d "$CSV2RDF4LOD_PUBLISH_VARWWW_ROOT" && `which cr-ln-to-www-root.sh` ]]; then
         # Find out where the file will be on the web.
         if [[ "$verbose" == 'yes' ]]; then
            echo "`basename $0` using -I basename from conversion cockpit conventions." >&2
         fi
         I="`cr-ln-to-www-root.sh -n --url-of-filepath $file`"
      elif [[ -z "$I" && `which cr-pwd-type.sh` && `cr-pwd-type.sh` == 'cr:conversion-cockpit' && 
              -n "$CSV2RDF4LOD_BASE_URI" && ! "$CSV2RDF4LOD_BASE_URI" =~ *localhost* ]]; then
         I="$CSV2RDF4LOD_BASE_URI/source/`cr-source-id.sh`/file/`cr-dataset-id.sh`/version/`cr-version-id.sh`/$file" 
         if [ "$verbose" == "yes" ]; then
            echo "no cr-ln; I => : $I"
         fi
      else
         # Always need a -I since we can be sending it via stdin
         I="file:///localhost/`resource-name.sh`/$file"
      fi
      if [[ -n "$I" ]]; then
         II="-I $I"
      else
         II=""
      fi

      gzipped=`gzipped.sh $file`

      if [ "$serialization" == "application/rdf+xml" ]; then
         # Need to use rapper to decompose into N-TRIPLES.
         # Need to use serdi to prepend bnodes with a unique prefix.
         if [[ `which rapper` && `which serdi` ]]; then
            if [[ "$gzipped" == 'yes' ]]; then
               if [ "$verbose" == "yes" ]; then
                  echo "gunzip -c $file | rapper -q -i rdfxml -o ntriples $II - | serdi -b -i ntriples -o ntriples -p $md5 -" >&2
               fi
               gunzip -c $file | rapper -q -i rdfxml -o ntriples $II - | serdi -b -i ntriples -o ntriples -p $md5 -
            else
               if [ "$verbose" == "yes" ]; then
                  echo "rapper -q -i rdfxml -o ntriples $II $file | serdi -b -i ntriples -o ntriples -p $md5 -" >&2
               fi
               rapper -q -i rdfxml -o ntriples $II $file | serdi -b -i ntriples -o ntriples -p $md5 -
            fi
         elif [[ ! `which rapper` ]]; then
            echo "ERROR(1): `basename $0` requires rapper. See $see" >&2
            if [[ ! `which serdi` ]]; then
               echo "ERROR(2): `basename $0` requires serdi. See $see" >&2
            fi
         elif [[ ! `which serdi` ]]; then
            echo "ERROR(3): `basename $0` requires serdi. See $see" >&2
         fi
      elif [ "$serialization" == "text/plain" ]; then
         # Need to use serdi to prepend bnodes with a unique prefix.
         if [[ `which serdi` ]]; then
            if [[ "$gzipped" == 'yes' ]]; then
               if [ "$verbose" == "yes" ]; then
                  echo "gunzip -c $file | serdi -b -i ntriples -o ntriples -p $md5 - $I" >&2
               fi
               gunzip -c $file | serdi -b -i ntriples -o ntriples -p $md5 - $I
            else
               if [ "$verbose" == "yes" ]; then
                  echo "serdi -b -i ntriples -o ntriples -p $md5 $file $I" >&2
               fi
               serdi -b -i ntriples -o ntriples -p $md5 $file $I
            fi
         else
            echo "ERROR(4): `basename $0` requires serdi. See $see" >&2
         fi
      elif [ "$serialization" == "text/turtle" ]; then
         # Need to use serdi to prepend bnodes with a unique prefix.
         if [[ `which serdi` ]]; then
            if [[ "$gzipped" == 'yes' ]]; then
               if [ "$verbose" == "yes" ]; then
                  echo "gunzip -c $file | serdi -b -i turtle -o ntriples -p $md5 - $I" >&2
               fi
               gunzip -c $file | serdi -b -i turtle -o ntriples -p $md5 - $I
            else
               if [ "$verbose" == "yes" ]; then
                  echo "serdi -b -i turtle -o ntriples -p $md5 $file $I" >&2
               fi
               serdi -b -i turtle -o ntriples -p $md5 $file $I
            fi
         else
            echo "ERROR(5): `basename $0` requires serdi. $PATH See $see" >&2
         fi
      elif [[ -f "$file" ]]; then
         echo "WARNING: `basename $0` could not determine serialization for `pwd` $file" >&2
      fi

      if [ -e "$TEMP" ]; then
         rm "$TEMP"
      fi 

      # End of version 2

   else 

      # Original version

      # -q : quiet
      # -o : output ntriples
      # rapper cannot contextualize bnodes and may lead to a collision.
      if [[ `which rapper` && `which serdi` ]]; then
         rapper -q $serialization -o ntriples $file | serdi -i ntriples -p $md5 -
      elif [ `which rapper` ]; then
         echo "ERROR(6): `basename $0` requires rapper. See $see" >&2
      else
         echo "ERROR(7): `basename $0` requires serdi. See $see" >&2
      fi
      # serdi can, but cannot handle RDF/XML (so use rapper to preprocess it).
      # -p : prepend bnodes with $md5
      # -  : read from stdin
      # (prints to stdout)
   fi

done
