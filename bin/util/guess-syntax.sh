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
   echo "usage: `basename $0` [--inspect] url-of.rdf [{rapper,jena}]"
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

#
# Take a stab:
#

if [[ $url =~ \\.nt$ || $url =~ \\.nt\\. || $url =~ \\.nt# ]]; then # Replaced \. with \\. b/c other OSes were recognizing them as regex.
   guess="-i ntriples"
elif [[ $url =~ \\.ttl$ || $url =~ \\.ttl\\. || $url =~ \\.ttl# ]]; then
   guess="-i turtle"
elif [[ $url =~ \\.rdf$ || $url =~ \\.rdf\\. || $url =~ \\.rdf# ]]; then
   guess="-i rdfxml"
elif [[ $url =~ \\.xml$ || $url =~ \\.xml\\. || $url =~ \\.xml# ]]; then
   guess="-i rdfxml"
else
   # We failed to guess based on the file name.
   guess="-g"
fi
if [ $inspect == "true" ]; then
   if [[   `head -1000 $url | awk '$0 ~ /[^<]*<[^>]+>[^>]*[^<]*<[^>]+>[^>]*[^<]*<[^>]+>[^>]*/ && $0 !~ "rdf:about=" && $0 !~ "rdf:nodeID=" {c++;print} END {printf("%s",c)}'` -gt 2 ]]; then
      # <> <> <>
      guess="-i ntriples"
   elif [[ `head -1000 $url | awk '$0 ~ /^@prefix.*/ {c++} END {printf("%s",c)}'` -gt 2 ]]; then
      # @prefix
      guess="-i turtle"
   elif [[ `head -1000 $url | awk '$0 ~ "rdf:about=" {c++} END {printf("%s",c)}'` -gt 2 ]]; then
      # rdf:about=
      guess="-i rdfxml"
   else
      #echo "still no idea after --inspect"
      #echo "ntriples: `head -1000 $url | awk '$0 ~ /[^<]*<[^>]+>[^>]*[^<]*<[^>]+>[^>]*[^<]*<[^>]+>[^>]*/{c++}END{printf("%s",c)}'`"
      #echo "turtle:   `head -1000 $url | awk '$0 ~ /^@prefix.*/ {c++} END {printf("%s",c)}'`"
      #echo "rdfxml:   `head -1000 $url | awk '$0 ~ "rdf:about=" {c++} END {printf("%s",c)}'`"
      guess="-g"
   fi
fi

#
# Translate to whims of each tool:
#

if [ ${tool:-"."} == "rapper" ]; then
   guess=$guess

elif [ ${tool:-"."} == "jena" ]; then
   if [[ $guess == "-i ntriples" ]]; then
      guess="$guess"
   elif [[ $guess == "-i ntriples" ]]; then
      guess="$guess"
   else
      echo "rdf"
      exit 1
   fi

elif [ ${tool:-"."} == "vload" ]; then
   # rdf, ttl, nt, nq
   if [[ $guess == "-i ntriples" ]]; then
      guess="nt"
   elif [[ $guess == "-i turtle" ]]; then
      guess="ttl"
   elif [[ $guess == "-i rdfxml" ]]; then
      guess="rdf"
   elif [[ $guess == "-g" ]]; then
      echo "rdf"
      exit 1
   else
      echo "rdf"
      exit 1
   fi
fi

echo $guess
if [[ $guess == "-g" || $guess == "" ]]; then
   exit 1
fi
