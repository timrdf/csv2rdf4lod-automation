#!/bin/bash
#
#3> <> prov:specializationOf <https://github.com/timrdf/csv2rdf4lod-automation/blob/master/bin/util/nt-nodes.sh>;
#3>    prov:wasDerivedFrom   <https://github.com/timrdf/csv2rdf4lod-automation/blob/master/bin/util/rdf2nt.sh> .
#
# Print the URI subjects and objects of the given RDF file.
#
# To handle more files than 'ls' can provide:
#   find . -name "[^.]*" | xargs      nt-nodes.sh > nodes.txt

if [[ $# -eq 0 || "$1" == "--help" ]]; then
   echo
   echo "usage: `basename $0` <some.rdf>*"
   echo "  Print the URI subjects and objects of the given RDF file."
   exit
fi

version=''
if [[ "$1" == "--version" && $# -gt 1 ]]; then
   version="$2"
   shift 2
fi

total=$#
while [ $# -gt 0 ]; do
   file="$1" 

   if [ ! -f $file ]; then
      continue
   fi

   if [[ $total -eq 1 && `gzipped.sh $file` == "yes" && `guess-syntax.sh $file mime` == "text/plain" ]]; then
      # Avoids dumping to an intermediate file.
      # e.g. 2.0 GB unzipped ntriples file can be done in 1.5 minutes (as opposed to 4.5 minutes).
      gunzip -c             $file | awk '$1 ~ /^<.*/ { print $1 } $3 ~ /^<.*/ { print $3 }'
   else
      echo $total `gzipped.sh $file` `guess-syntax.sh $file mime` >&2
      # Handles any syntax, compressed or not.
      rdf2nt.sh --version 2 $file | awk '$1 ~ /^<.*/ { print $1 } $3 ~ /^<.*/ { print $3 }'
   fi

   shift
done
