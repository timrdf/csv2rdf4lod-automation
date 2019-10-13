#!/bin/bash
#
#   Copyright 2012 Timothy Lebo
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
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
   # for eparams defaults: bin/util/header2params2.awk
   echo "prefix rdf:        <http://www.w3.org/1999/02/22-rdf-syntax-ns#>"
   echo "prefix rdfs:       <http://www.w3.org/2000/01/rdf-schema#>"
   echo "prefix xsd:        <http://www.w3.org/2001/XMLSchema#>"
   echo "prefix owl:        <http://www.w3.org/2002/07/owl#>"
   echo "prefix wgs:        <http://www.w3.org/2003/01/geo/wgs84_pos#>"
   echo "prefix dcterms:    <http://purl.org/dc/terms/>"
   echo "prefix doap:       <http://usefulinc.com/ns/doap#>"
   echo "prefix foaf:       <http://xmlns.com/foaf/0.1/>"
   echo "prefix skos:       <http://www.w3.org/2004/02/skos/core#>"
   echo "prefix sioc:       <http://rdfs.org/sioc/ns#>"
   echo "prefix dcat:       <http://www.w3.org/ns/dcat#>"             
   echo "prefix void:       <http://rdfs.org/ns/void#>"             
   echo "prefix ov:         <http://open.vocab.org/terms/>"
   echo "prefix frbr:       <http://purl.org/vocab/frbr/core#>"
   echo "prefix qb:         <http://purl.org/linked-data/cube#>"             
   echo "prefix sd:         <http://www.w3.org/ns/sparql-service-description#>"
   echo "prefix moby:       <http://www.mygrid.org.uk/mygrid-moby-service#>"
   echo "prefix conversion: <http://purl.org/twc/vocab/conversion/>"
   echo "prefix datafaqs:   <http://purl.org/twc/vocab/datafaqs#>"
   echo "prefix dbpedia:    <http://dbpedia.org/resource/>"
   echo "prefix prov:       <http://www.w3.org/ns/prov#>"
   echo "prefix prv:        <http://purl.org/net/provenance/ns#>"
   echo "prefix nfobad:     <http://www.semanticdesktop.org/ontologies/nfo/#>"
   echo "prefix nfo:        <http://www.semanticdesktop.org/ontologies/2007/03/22/nfo#>"
   echo "prefix sio:        <http://semanticscience.org/resource/>"
   echo "prefix org:        <http://www.w3.org/ns/org#>"
   echo "prefix gn:         <http://www.geonames.org/ontology#>"
   echo "prefix cc:         <http://creativecommons.org/ns#>"
   echo "prefix vsr:        <http://purl.org/twc/vocab/vsr#>"
   echo "prefix cogs:       <http://vocab.deri.ie/cogs#>"
   echo "prefix pml:        <http://provenanceweb.org/ns/pml#>"
   echo "prefix twi:        <http://tw.rpi.edu/instances/>"
   echo
   # curl http://prefix.cc/rdfs,void,conversion.file.sparql | grep PREFIX
fi
