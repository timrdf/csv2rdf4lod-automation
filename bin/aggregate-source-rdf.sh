#!/bin/bash

if [ $# -ne 1 ]; then
   echo "usage: `basename $0` source/some.{rdf,ttl,nt}"
fi

if [ ! -d publish/bin ]; then
   mkdir -p publish/bin
fi

while [ $# -gt 1 ]; do
   rdfFile="$1"

   echo "source/$rdfFile.graph"
   if [ ! -e source/$rdfFile.graph ]; then
      cr-dataset-uri.sh | grep "^h" | tail -1 > source/$rdfFile.graph
   else 
      echo "WARNING: publish/$rdfFile.void.ttl existed; not replacing"
   fi

   echo "publish/$rdfFile.void.ttl"
   if [ ! -e publish/$rdfFile.void.ttl ]; then
      cr-dataset-uri.sh void > publish/$rdfFile.void.ttl
   else 
      echo "WARNING: publish/$rdfFile.void.ttl existed; not replacing"
   fi

   echo "publish/bin/virtuoso-load.sh"
   echo "sudo /opt/virtuoso/scripts/vload ttl source/crawl.ttl `cat source/$rdfFile.graph`" > publish/bin/virtuoso-load.sh

   echo "publish/bin/virtuoso-load-metadata.sh"
   echo "sudo /opt/virtuoso/scripts/vload ttl publish/crawl.ttl.void.ttl http://logd.tw.rpi.edu/vocab/Dataset" > publish/bin/virtuoso-load-metadata.sh
done
