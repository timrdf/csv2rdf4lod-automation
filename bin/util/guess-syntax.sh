#!/bin/bash
# 
# exit 0 if it likes it's guess
# exit 1 if it does not.
#
#
# Example usage:
#
#   syntax=`$CSV2RDF4LOD_HOME/bin/util/guess-syntax.sh $url rapper`
#   liked_guess=$? # 0 : liked its guess, 1: did NOT like its guess
#   if [[ $liked_guess == 1 ]]; then
#      syntax=`$CSV2RDF4LOD_HOME/bin/util/guess-syntax.sh --inspect ${TEMP}${unzipped} rapper`
#   fi

if [ $# -lt 1 ]; then
   echo "usage: `basename $0` [--inspect] url-of.rdf [tool:{rapper,jena}]"
   echo "  --inspect: look at the local file and guess (if not specified, guesses based on the file name)."
   exit 1
fi

inspect="false"
if [ $1 == "--inspect" ]; then
   inspect="true"
   shift
fi

url=$1
tool=$2

guess=""

if [ ${tool:-"."} == "rapper" ]; then
   if [[ $url =~ \.nt$ || $url =~ \.nt\. || $url =~ \.nt# ]]; then
      guess="-i ntriples"
   elif [[ $url =~ \.ttl$ || $url =~ \.ttl\. || $url =~ \.ttl# ]]; then
      guess="-i turtle"
   elif [[ $url =~ \.rdf$ || $url =~ \.rdf\. || $url =~ \.rdf# ]]; then
      guess="-i rdfxml"
   else
      # We failed to guess based on the file name.
      guess="-g"
   fi
   if [ $inspect == "true" ]; then
      if [[ `head -1000 $url | awk '$0 ~ "rdf:about=" {c++} END {printf("%s",c)}'` > 5 ]]; then
         # rdf:about=
         guess="-i rdfxml"
      fi
   fi
   echo $guess
   if [[ $guess == "-g" ]]; then
      exit 1
   fi
elif [ ${tool:-"."} == "rapper" ]; then
   if [[ $url =~ \.nt$ || $url =~ \.nt\. ]]; then
      echo "ntriples"
   elif [[ $url =~ \.ttl$ || $url =~ \.ttl\. ]]; then
      echo "turtle"
   elif [[ $url =~ \.rdf$ || $url =~ \.rdf\. ]]; then
      echo "rdfxml"
   else
      exit 1
   fi
fi
