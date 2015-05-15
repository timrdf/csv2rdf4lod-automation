#!/bin/bash
#
#3> <> prov:specializationOf <https://github.com/timrdf/csv2rdf4lod-automation/blob/master/bin/util/cr-urlencode.sh>;
#3>    prov:wasDerivedFrom   <http://stackoverflow.com/questions/296536/urlencode-from-a-bash-script>;
#3> .
#

if [[ $# -eq 0 || "$1" == "--help" ]]; then
   echo "usage: `basename $0` [--help] [--from-file] <string>+"
   echo
   echo "      --from-file : interpret <string> as a filename whose contents should be urlencoded."
   echo
   echo "  e.g."
   echo "      cr-urlencode.sh 'prefix xsd:    <http://www.w3.org/2001/XMLSchema#>'"
   echo "      -> prefix%20xsd%3a%20%20%20%20%3chttp%3a%2f%2fwww.w3.org%2f2001%2fXMLSchema%23%3e"
   exit
fi

from_file="no"
if [[ "$1" == "--from-file" ]]; then
   from_file="yes"
   shift
fi

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

# http://stackoverflow.com/questions/296536/urlencode-from-a-bash-script
# Returns a string in which the sequences with percent (%) signs followed by
# two hex digits have been replaced with literal characters.
rawurldecode() { # http://stackoverflow.com/questions/296536/urlencode-from-a-bash-script

  # This is perhaps a risky gambit, but since all escape characters must be
  # encoded, we can replace %NN with \xNN and pass the lot to printf -b, which
  # will decode hex for us

  printf -v REPLY '%b' "${1//%/\\x}" # You can either set a return variable (FASTER)
  echo "${REPLY}"  #+or echo the result (EASIER)... or both... :p
}

# "easier":
#request=$service$(rawurlencode "$target")'&responseType=rdf'
# "faster":
#rawurlencode "$target"
#echo $request

decode='no'
if [[ "$1" == "--decode" ]]; then
   decode='yes'
   shift
fi

if [[ $# -gt 0 ]]; then
   if [[ "$decode" == 'yes' ]]; then
      if [[ "$from_file" == 'yes' ]]; then
         rawurldecode "`cat "$1"`"
      else
         rawurldecode "$1"
      fi
   else 
      if [[ "$from_file" == 'yes' ]]; then
         rawurlencode "`cat "$1"`"
      else
         rawurlencode "$1"
      fi
   fi
fi

# Using Perl (but depends on URI::Escape)
#encoded=`echo $target | perl -e 'use URI::Escape; @userinput = <STDIN>; foreach (@userinput) { chomp($_); print uri_escape($_); }'`
#request=$service$encoded'&responseType=rdf'
#echo $request

# Or use curl --data-urlencode
