#!/bin/bash

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
   elif [[ $url =~ \.rdf$ || $url =~ \.rdf\. ]]; then
      echo "-i rdfxml"
   else
      echo "-g"
   fi
elif [ ${tool:-"."} == "rapper" ]; then
   if [[ $url =~ \.nt$ || $url =~ \.nt\. ]]; then
      echo "ntriples"
   elif [[ $url =~ \.ttl$ || $url =~ \.ttl\. ]]; then
      echo "turtle"
   elif [[ $url =~ \.rdf$ || $url =~ \.rdf\. ]]; then
      echo "rdfxml"
   fi
fi
