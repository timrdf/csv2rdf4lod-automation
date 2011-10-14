#!/bin/bash
# 
# Determine the file extensions that should be used based on the serializations that will be produced.
# This avoids needing to manually determine and set it.

if [[ "$CSV2RDF4LOD_CONVERT_DUMP_FILE_EXTENSIONS" != "cr:auto" && "$1" != "--auto" ]]; then
   echo $CSV2RDF4LOD_CONVERT_DUMP_FILE_EXTENSIONS
   exit
fi


tgz=""
if [ "$CSV2RDF4LOD_PUBLISH_COMPRESS" == "true" ]; then
   tgz=".tgz"
fi

extensions="ttl$tgz"

if [ "$CSV2RDF4LOD_PUBLISH_RDFXML" == "true" ]; then
   extensions="$extensions,rdf$tgz"
fi

if [ "$CSV2RDF4LOD_PUBLISH_NT" == "true" ]; then
   extensions="$extensions,nt$tgz"
fi

echo $extensions
