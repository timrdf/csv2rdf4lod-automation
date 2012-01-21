#!/bin/bash
#
#

CSV2RDF4LOD_HOME=${CSV2RDF4LOD_HOME:?"not set; source csv2rdf4lod/source-me.sh or see https://github.com/timrdf/csv2rdf4lod-automation/wiki/CSV2RDF4LOD-not-set"}

if [[ $# -lt 1 || "$1" == "--help" ]]; then
   echo "usage: `basename $0` [-v] [--replace-extension] file [file...]"
   exit 1
fi

verbose="false"
if [[ "$1" == "-v" || "$1" == "--verbose" ]]; then
   verbose="true"
fi



rename_style="append"
if [[ "$1" == "--replace-extension" ]]; then
   echo "--replace-extension not implemented" # need to worry about no extension being there.
   exit 1
fi

while [ $# -gt 0 ]; do
   file="$1"
   if [ -e "$file" ]; then
      extension=`$CSV2RDF4LOD_HOME/bin/util/guess-syntax.sh --inspect $file extension`
      if [[ "$extension" == "ttl" || "$extension" == "rdf" || "$extension" == "nt" ]]; then
         mv $file $file.$extension
         if [ "$verbose" == "true" ]; then
            echo $file.$extension
         else
            echo $file
         fi
      fi
   fi
   shift
done
