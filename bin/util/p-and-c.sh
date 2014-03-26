#!/bin/bash
#
#3> <> prov:specializationOf <https://github.com/timrdf/csv2rdf4lod-automation/blob/master/bin/util/p-and-c.sh>;
#3>    prov:wasDerivedFrom   <https://github.com/timrdf/csv2rdf4lod-automation/blob/master/bin/util/uri-nodes.sh> .
#
# Print the predicates and classes in the given RDF file.
#
# To handle more files than 'ls' can provide:
#   find . -name "[^.]*" | xargs      nt-nodes.sh > nodes.txt

if [[ $# -eq 0 || "$1" == "--help" ]]; then
   echo
   echo "usage: `basename $0` [-u] [--as-ttl [type-uri]] <some.rdf>*"
   echo "  Print the URI subjects and objects of the given RDF file."
   echo "                    -u - unique."
   echo "  --as-ttl [class-uri] - output the list as a valid Trutle file, where the nodes are typed to rdfs:Resource."
   echo "           [class-uri] - use this class instead of rdfs:Resource (must be full URI, no <>)"
   exit
fi

unique=''
if [[ "$1" == "-u" ]]; then
   unique="yes"
   shift
fi

as_ttl=''
class="rdfs:Resource"
if [[ "$1" == "--as-ttl" ]]; then
   as_ttl="$2"
   if [[ "$#" -gt 1 && ! -e "$2" ]]; then
      class=$2
      shift
   fi
   shift
fi

total=$#
while [ $# -gt 0 ]; do
   file="$1" 

   if [ ! -f $file ]; then
      shift
      echo "WARNING: `basename $0` skipping $file b/c it does not exist as a file." >&2
      continue
   fi

   if [[ -n "$as_ttl" ]]; then
      echo "@prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#> ."
      echo
      $0 $* | awk -v class=$class '$1 ~ /^</ {print $1,"a",class,"."}'
   else
      format=`guess-syntax.sh --inspect $file formats:`
      if [[ $total -eq 1 && `gzipped.sh $file` == "yes" && ( "$format" == 'http://www.w3.org/ns/formats/N-Quads' || \
                                                             "$format" == 'http://www.w3.org/ns/formats/N-Triples' ) ]]; then
         # Avoids dumping to an intermediate file.
         # e.g. 2.0 GB unzipped ntriples file can be done in 1.5 minutes (as opposed to 4.5 minutes).
         if [[ -n "$unique" ]]; then
            gunzip -c             $file | awk '{if($2 == "<http://www.w3.org/1999/02/22-rdf-syntax-ns#type>"){print $3}; print $2}' | sed 's/^<//;s/>$//' | sort -u
         else
            gunzip -c             $file | awk '{if($2 == "<http://www.w3.org/1999/02/22-rdf-syntax-ns#type>"){print $3}; print $2}' | sed 's/^<//;s/>$//'
         fi
      else
         #echo ".${total}. .`gzipped.sh $file`. .`guess-syntax.sh $file mime`." >&2
         # Handles any syntax, compressed or not.
         rdf2nt.sh --version 2 $file | awk '{if($2 == "<http://www.w3.org/1999/02/22-rdf-syntax-ns#type>"){print $3}; print $2}' | sed 's/^<//;s/>$//'
      fi
   fi

   shift
done
