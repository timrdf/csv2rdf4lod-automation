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
   echo "usage: `basename $0` [--inspect] url-of.rdf [{mime,rapper,jena,extension}]"
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

if   [[ $url =~ \\.nt$  || $url =~ \\.nt\\.  || $url =~ \\.nt#  || $url == *nt ]]; then # Replaced \. with \\. b/c other OSes were recognizing them as regex.
   guess="-i ntriples"
elif [[ $url =~ \\.ttl$ || $url =~ \\.ttl\\. || $url =~ \\.ttl# || $url == *ttl || $url == *.ttl.gz ]]; then # TODO special case should be handled in general.
   guess="-i turtle"
elif [[ $url =~ \\.rdf$ || $url =~ \\.rdf\\. || $url =~ \\.rdf# || $url == *rdf ]]; then
   guess="-i rdfxml"
elif [[ $url =~ \\.xml$ || $url =~ \\.xml\\. || $url =~ \\.xml# || $url == *xml ]]; then
   guess="-i rdfxml"
else
   # We failed to guess based on the file name.
   guess="-g"
fi
if [ $inspect == "true" ]; then
   if [[ `head -1000 $url | awk '$0 ~ /^@prefix.*/ {c++} END {printf("%s",c)}'` -gt 2 ]]; then
      # @prefix
      guess="-i turtle"                   #      <     >     <     >     <     >      .
   elif [[   `head -1000 $url | awk '$0 ~ /^[^<]*<[^>]+>[^>]*<[^>]+>[^>]*<[^>]+>[^<]*\.[^<]*$/ && $0 !~ "rdf:about=" && $0 !~ "rdf:nodeID=" {c++} END {printf("%s",c)}'` -gt 2 ]]; then
      # <> <> <>
      guess="-i ntriples"
   elif [[ `head -1000 $url | awk '$0 ~ "rdf:about=" {c++} END {printf("%s",c)}'` -gt 2 ]]; then
      # rdf:about=
      guess="-i rdfxml"
   elif [[ `head -1000 $url | awk '$0 ~ /> +a +</ {c++} $0 ~ /^ *a +</ {c++} END {printf("%s",c)}'` -gt 1 ]]; then
      # <http://> a <http://>,
      #           a <http://>,
      guess="-i turtle"
   else
      #echo "still no idea after --inspect"
      #echo "ntriples: `head -1000 $url | awk '$0 ~ /[^<]*<[^>]+>[^>]*[^<]*<[^>]+>[^>]*[^<]*<[^>]+>[^>]*/{c++}END{printf("%s",c)}'`"
      #echo "turtle:   `head -1000 $url | awk '$0 ~ /^@prefix.*/ {c++} END {printf("%s",c)}'`"
      #echo "rdfxml:   `head -1000 $url | awk '$0 ~ "rdf:about=" {c++} END {printf("%s",c)}'`"
      guess="-g"
   fi
fi

#
# Translate to whims of each tool: (TODO: reason to mimetype, then translate to tool)
#

if [ "$tool" == "rapper" ]; then
   if [[ $guess == "-i ntriples" || "$guess" == "text/plain" ]]; then
      guess="-i ntriples"
   elif [[ $guess == "-i turtle" || "$guess" == "text/turtle" ]]; then
      guess="-i turtle"
   elif [[ $guess == "-i rdfxml" || "$guess" == "application/rdf+xml" ]]; then
      guess="-i rdfxml"
   elif [[ $guess == "-g" || "$guess" == "undetermined" ]]; then
      echo ""
      exit 1
   else
      echo ""
      exit 1
   fi
   guess=$guess # TODO: transition to mime-based logic.

elif [ "$tool" == "jena" ]; then
   if [[ $guess == "-i ntriples" || "$guess" == "text/plain" ]]; then
      guess="$guess"
   elif [[ $guess == "-i ntriples" || "$guess" == "text/plain" ]]; then
      guess="$guess"
   else
      echo "rdf"
      exit 1
   fi

elif [ "$tool" == "vload" -o "$tool" == "extension" ]; then
   # rdf, ttl, nt, nq
   if [[ $guess == "-i ntriples" || "$guess" == "text/plain" ]]; then
      guess="nt"
   elif [[ $guess == "-i turtle" || "$guess" == "text/turtle" ]]; then
      guess="ttl"
   elif [[ $guess == "-i rdfxml" || "$guess" == "application/rdf+xml" ]]; then
      guess="rdf"
   elif [[ $guess == "-g" || "$guess" == "undetermined" ]]; then
      echo "rdf"
      exit 1
   else
      echo "rdf"
      exit 1
   fi

elif [ "$tool" == "mime" ]; then
   if [[ $guess == "-i ntriples" || "$guess" == "text/plain" ]]; then
      guess="text/plain"
   elif [[ $guess == "-i turtle" || "$guess" == "text/turtle" ]]; then
      guess="text/turtle"
   elif [[ $guess == "-i rdfxml" || "$guess" == "application/rdf+xml" ]]; then
      guess="application/rdf+xml"
   elif [[ $guess == "-g" || "$guess" == "undetermined" ]]; then
      echo ""
      exit 1
   else
      echo ""
      exit 1
   fi
   #guess=$guess # TODO: transition to mime-based logic.

fi

echo $guess
if [[ $guess == "-g" || $guess == "" ]]; then
   exit 1
fi
