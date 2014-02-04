#!/bin/bash
#
#3> <> prov:specializationOf <https://github.com/timrdf/csv2rdf4lod-automation/blob/master/bin/util/cr-relatively-safe.sh>;
#3>    prov:wasDerivedFrom   <https://github.com/timrdf/csv2rdf4lod-automation/blob/master/bin/util/valid-rdf.sh>;
#3> .

printFile="no"
if [[ "$1" == "-v" || "$1" == "--verbose" ]]; then
   printFile="yes"
   shift
fi

file=""
while [ $# -gt 0 ]; do
   answer='unknown'
   file="$1"
   if [[ `valid-rdf.sh $file` != 'yes' ]]; then
      answer='no'
   elif [[ `too-big-for-rapper.sh $file` == 'no' && `which rapper` ]]; then
      syntax=`guess-syntax.sh --inspect $1 rapper`
      error=`rapper -q $syntax -c $1 2>&1 | grep Error` # TODO: does not handle gz
      if [[ ! `                                                grep --max-count=1 '<file:' "$file"` && \
              `rapper $syntax -o turtle "$file" 2> /dev/null | grep --max-count=1 '<file:'` ]]; then
         # The file does not contain "<file:" as is, 
         # but it does after it gets parsed.
         answer='no'
      else
         answer='yes'
      fi
   fi
   echo $answer
   #if [ "$printFile" == "yes" ]; then
   #   file=" $1" >&2
   #fi
   #if [ ${#error} -gt 0 ]; then
   #   echo "no${file}"
   #else
   #   echo "yes${file}"
   #fi
   shift
done
