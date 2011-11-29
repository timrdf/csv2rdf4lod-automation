#!/bin/bash
#
# perl -pi -e 's/.prefix/\nprefix/g' if you want to pipe to a file.

if [[ "$1" == "--help" ]]; then
   echo "usage: `basename $0` [--turtle] || --sparql]"
   echo "  --turtle: return turtle syntax (default is sparql)"
   exit 1
fi

if [[ "$1" == "--turtle" ]]; then
   $0 | awk '$0~"prefix" {printf("@%s .\n",$0)}'
   echo
   # curl http://prefix.cc/rdfs,void,conversion.file.ttl
else
   echo "prefix rdf:        <http://www.w3.org/1999/02/22-rdf-syntax-ns#>"
   echo "prefix rdfs:       <http://www.w3.org/2000/01/rdf-schema#>"
   echo "prefix owl:        <http://www.w3.org/2002/07/owl#>"
   echo "prefix dcterms:    <http://purl.org/dc/terms/>"
   echo "prefix doap:       <http://usefulinc.com/ns/doap#>"
   echo "prefix foaf:       <http://xmlns.com/foaf/0.1/>"
   echo "prefix skos:       <http://www.w3.org/2004/02/skos/core#>"
   echo "prefix sioc:       <http://rdfs.org/sioc/ns#>"
   echo "prefix void:       <http://rdfs.org/ns/void#>"             
   echo "prefix conversion: <http://purl.org/twc/vocab/conversion/>"
   echo "prefix twi:        <http://tw.rpi.edu/instances/>"
   echo
   # curl http://prefix.cc/rdfs,void,conversion.file.sparql | grep PREFIX
fi
