#!/bin/bash
#
#3> <> prov:specializationOf <https://github.com/timrdf/csv2rdf4lod-automation/blob/master/bin/util/cr-urlencode.sh>;
#3>    prov:wasDerivedFrom <http://stackoverflow.com/questions/296536/urlencode-from-a-bash-script>;
#3> .

rawurlencode() { # http://stackoverflow.com/questions/296536/urlencode-from-a-bash-script
  local string="${1}"
  local strlen=${#string}
  local encoded=""

  for (( pos=0 ; pos<strlen ; pos++ )); do
     c=${string:$pos:1}
     case "$c" in
        [-_.~a-zA-Z0-9] ) o="${c}" ;;
        * )               printf -v o '%%%02x' "'$c"
     esac
     encoded+="${o}"
  done
  echo "${encoded}"    # You can either set a return variable (FASTER) 
  #REPLY="${encoded}"   #+or echo the result (EASIER)... or both... :p
}

# "easier":
#request=$service$(rawurlencode "$target")'&responseType=rdf'
# "faster":
#rawurlencode "$target"
#echo $request
if [[ $# -gt 0 ]]; then
   rawurlencode "$1"
fi

# Using Perl (but depends on URI::Escape)
#encoded=`echo $target | perl -e 'use URI::Escape; @userinput = <STDIN>; foreach (@userinput) { chomp($_); print uri_escape($_); }'`
#request=$service$encoded'&responseType=rdf'
#echo $request
