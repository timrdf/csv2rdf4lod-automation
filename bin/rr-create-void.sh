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

if [ ${1:-"."} == "--help" ]; then
   echo "usage: `basename $0` [[-w] file]"
   exit 1
fi

back_one=`cd .. 2>/dev/null && pwd`
ANCHOR_SHOULD_BE_VERSION=`basename $back_one`
if [ $ANCHOR_SHOULD_BE_VERSION != "version" ]; then
   echo "  Working directory does not appear to be a VERSION directory."
   echo "  Run `basename $0` from a SOURCE directory (e.g. csv2rdf4lod/data/source/SOURCE/version/VERSION/)"
   exit 1
fi

CSV2RDF4LOD_HOME=${CSV2RDF4LOD_HOME:?"must be set; source csv2rdf4lod/source-me.sh (created by install.sh)."}

write="-"
if [ ${1:-"."} == "-w" ]; then
   write="-w"
   shift
fi
   
file=""
if [ $# -gt 0 ]; then
   file="$1"
fi

TMP=`date +%s`_$$_`basename $0`.tmp

#echo "@prefix rdfs:    <http://www.w3.org/2000/01/rdf-schema#> ."                   > $TMP
echo "@prefix xsd:     <http://www.w3.org/2001/XMLSchema#> ."                      >> $TMP
echo "@prefix dcterms: <http://purl.org/dc/terms/> ."                              >> $TMP
#echo "@prefix pmlp:    <http://inference-web.org/2.0/pml-provenance.owl#> ."       >> $TMP
#echo "@prefix pmlj:    <http://inference-web.org/2.0/pml-justification.owl#> ."    >> $TMP
#echo "@prefix irw:     <http://www.ontologydesignpatterns.org/ont/web/irw.owl#> ." >> $TMP
#echo "@prefix nfo:     <http://www.semanticdesktop.org/ontologies/nfo/#> ."        >> $TMP
#echo "@prefix conv:    <http://purl.org/twc/vocab/conversion/> ."                  >> $TMP
echo "@prefix void:    <http://rdfs.org/ns/void#> ."                               >> $TMP
echo ""                                                                            >> $TMP

unversioned="`cr-dataset-uri.sh void | grep '^<' | head -1`"
versioned="`cr-dataset-uri.sh void | grep '^<' | tail -1`"

echo "$unversioned void:subset $versioned ."                                       >> $TMP
if [ ${#file} -gt 0 ]; then
   if [ -e $file ]; then
      date=`modifiedXSDDateTime.sh $file -o`
      if [ ${#date} -gt 0 ]; then
         echo "$versioned dcterms:modified $date ."                                >> $TMP
      fi
   fi
fi

cr-dataset-uri.sh void >> $TMP

if [ $write == "-w" ]; then
   cat $TMP > $file.void.ttl # TODO: populate-void*.sh only looks in publish/, so it'll miss this...
else
   cat $TMP
fi

rm $TMP 2> /dev/null
