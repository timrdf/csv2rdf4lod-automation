#!/bin/bash
#
#3> <> prov:specializationOf <https://github.com/timrdf/csv2rdf4lod-automation/blob/master/bin/util/prefix.cc>;
#3> <> prov:wasDerivedFrom   <https://github.com/timrdf/csv2rdf4lod-automation/blob/master/bin/util/o-of-p.sh> .
#
# Print the objects of the given predicate in the given RDF file.
#
# To handle more files than 'ls' can provide:
#   find . -name "[^.]*" | xargs      nt-nodes.sh > nodes.txt

if [[ $# -eq 0 || "$1" == "--help" ]]; then
   echo                                                                                 >&2
   echo "usage: `basename $0` <uri>+"                                                   >&2
   echo " <uri> : e.g. sio:has-member  http://www.w3.org/1999/02/22-rdf-syntax-ns#type" >&2
   exit
fi

while [ $# -gt 0 ]; do

   uri="$1"
   shift

   if [[ "$uri" =~ http* ]]; then
      echo $uri
   else
      prefix=${uri%%:*}
      namespace=`curl -s http://prefix.cc/$prefix.file.txt | awk '{print $2}'`
      uri=$namespace${uri#*:}
      echo $uri
   fi

done
