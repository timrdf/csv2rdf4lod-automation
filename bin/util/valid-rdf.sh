#!/bin/bash
#
#>3 <> prov:specializationOf <https://github.com/timrdf/csv2rdf4lod-automation/blob/master/bin/util/valid-rdf.sh>;
#3>    rdfs:seeAlso <http://www.rdfabout.com/demo/validator/>
#3> .

printFile="no"
if [[ "$1" == "-v" || "$1" == "--verbose" ]]; then
   printFile="yes"
   shift
fi

file=""
while [ $# -gt 0 ]; do
   syntax=`guess-syntax.sh --inspect $1 rapper`
   #echo "`basename $0` checking full file for validity: $1" >&2 # NOTE this messes up DataFAQs' pretty printing.
   error=`rapper -q $syntax -c $1 2>&1 | grep Error` # TODO: does not handle gz
   if [ "$printFile" == "yes" ]; then
      file=" $1"
   fi
   if [ ${#error} -gt 0 ]; then
      echo "no${file}"
   else
      echo "yes${file}"
   fi
   shift
done
