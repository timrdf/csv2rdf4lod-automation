#!/bin/bash
#
# https://github.com/timrdf/csv2rdf4lod-automation/blob/master/bin/util/cr-where-was-envvar-set.sh

if [[ "$1" == "--help" || "$1" == "-h" ]]; then
   echo "usage: `basename $0` [-rc ~/.bashrc] [CSV2RDF4LOD_var] [--only]"
   echo "                -rc : the rc (.bashrc, .login, etc.) file used to source all csv2rdf4lod-source-mes"
   echo "  [CSV2RDF4LOD_var] : a CSV2RDF4LOD_ environment variable name."
   echo "                      All variables are listed by running cr-vars.sh"
   echo "                      If not specified, defaults to CSV2RDF4LOD_HOME"
   echo "             --only : omit the CSV2RDF4LOD_ variables that are more specific than the one specified."
   echo 
   echo "see https://github.com/timrdf/csv2rdf4lod-automation/wiki/CSV2RDF4LOD-environment-variables"
   echo "    https://github.com/timrdf/csv2rdf4lod-automation/wiki/Script:-source-me.sh"
   exit 1
fi

rc="~/.bashrc"
if [[ "$1" == "-rc" && $# -ge 2 ]]; then
   rc="$2"
   shift 2
fi

var="CSV2RDF4LOD_HOME"
if [[ $# -gt 0 && "$1" != "--only" ]]; then
   var="$1"
   shift
fi

omit=""
if [[ "$1" == "--only" ]]; then
   omit=`echo $var | awk '{print substr($0,length($0)-2,3)"_"}'` 
fi

if [[ ! -e $rc ]]; then
   echo "`basename $0`: $rc does not exist; try -rc option:"
   echo
   $0 -h
   exit
fi

for sourceme in `grep "^source .*csv2rdf4lod-source-me*" $rc | awk '{print $2}'`; do 
   if [[ ! ${#omit} ]]; then
      echo grep -H "\"^export $var\"" $sourceme
      grep -H "\"^export $var\"" $sourceme
   else
      echo "grep -H "\"^export $var\"" $sourceme | grep -v $omit"
      grep -H "\"^export $var\"" $sourceme | grep -v $omit
   fi
done
