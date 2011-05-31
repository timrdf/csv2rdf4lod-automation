#!/bin/bash
# 
# exit 0 if it likes it's guess
# exit 1 if it does not.

if [ $# -lt 1 ]; then
   echo "usage: `basename $0` url-of.rdf [tool:{rapper,jena}]"
   exit 1
fi

url=$1
tool=$2

if [ ${tool:-"."} == "rapper" ]; then
   if [[ $url =~ \.nt$ || $url =~ \.nt\. ]]; then
      echo "-i ntriples"
   elif [[ $url =~ \.ttl$ || $url =~ \.ttl\. ]]; then
      echo "-i turtle"
   elif [[ $url =~ \.rdf$ || $url =~ \.rdf\. || $url =~ \.rdf# ]]; then
      echo "-i rdfxml"
   else
      # We faild to guess based on the file name.
      # rdf:about=
      echo "-g"
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
