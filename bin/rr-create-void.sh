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

if [ "$1" == "--help" ]; then
   echo "usage: `basename $0` [[-w] file]"
   exit 1
fi

CSV2RDF4LOD_HOME=${CSV2RDF4LOD_HOME:?"must be set; source csv2rdf4lod/source-me.sh (created by install.sh)."}

# cr:data-root cr:source cr:directory-of-datasets cr:dataset cr:directory-of-versions cr:conversion-cockpit
ACCEPTABLE_PWDs="cr:conversion-cockpit"
if [ `${CSV2RDF4LOD_HOME}/bin/util/is-pwd-a.sh $ACCEPTABLE_PWDs` != "yes" ]; then
   ${CSV2RDF4LOD_HOME}/bin/util/pwd-not-a.sh $ACCEPTABLE_PWDs
   exit 1
fi

write="-"
if [ "$1" == "-w" ]; then
   write="-w"
   shift
fi
   
file=""
if [ $# -gt 0 ]; then
   file="$1"
fi

TEMP=`date +%s`_$$_`basename $0`.tmp

# TODO: could use: cr-default-prefixes.sh

#echo "@prefix rdfs:    <http://www.w3.org/2000/01/rdf-schema#> ."                   > $TEMP
echo "@prefix xsd:     <http://www.w3.org/2001/XMLSchema#> ."                      >> $TEMP
echo "@prefix dcterms: <http://purl.org/dc/terms/> ."                              >> $TEMP
#echo "@prefix pmlp:    <http://inference-web.org/2.0/pml-provenance.owl#> ."       >> $TEMP
#echo "@prefix pmlj:    <http://inference-web.org/2.0/pml-justification.owl#> ."    >> $TEMP
#echo "@prefix irw:     <http://www.ontologydesignpatterns.org/ont/web/irw.owl#> ." >> $TEMP
#echo "@prefix nfo:     <http://www.semanticdesktop.org/ontologies/nfo/#> ."        >> $TEMP
echo "@prefix conversion: <http://purl.org/twc/vocab/conversion/> ."               >> $TEMP
echo "@prefix void:       <http://rdfs.org/ns/void#> ."                            >> $TEMP
echo ""                                                                            >> $TEMP

versionedDataset=`cr-dataset-uri.sh --uri`
if [ ${#file} -gt 0 ]; then
   if [ -e $file ]; then
      date=`modifiedXSDDateTime.sh $file -o`
      if [ ${#date} -gt 0 ]; then
         echo "<$versionedDataset> dcterms:modified $date ."                       >> $TEMP
      fi
   fi
fi

cr-dataset-uri.sh --void                                                           >> $TEMP

sdv=`cr-sdv.sh`
[[ "$CSV2RDF4LOD_PUBLISH_COMPRESS" == 'true' ]] && gz=".gz" || gz=""
found=''
for ext in ttl nt rdf; do
   if [[ -e publish/$sdv.ttl$gz && "$found" != 'yes' ]]; then
      found='yes' 
      echo ""                                                                         >> $TEMP
      dataDump=`cr-ln-to-www-root.sh -n --url-of-filepath publish/$sdv.$ext$gz`
      echo "<$versionedDataset>"                                                      >> $TEMP
      echo "   void:dataDump <$dataDump> ."                                           >> $TEMP
      format=`guess-syntax.sh --tell http://www.w3.org/ns/formats $ext`
      if [[ -n "$format" ]]; then
         echo "<$dataDump>"                                                           >> $TEMP
         echo "   dcterms:format <$format> ."                                         >> $TEMP
      fi
      if [[ -n "$gz" ]]; then
         echo "<$dataDump>"                                                           >> $TEMP
         echo "   dcterms:format <http://provenanceweb.org/format/mime/application/gzip> ." >> $TEMP
      fi
   fi
done

if [ $write == "-w" ]; then
   cat $TEMP > $file.void.ttl # TODO: populate-void*.sh only looks in publish/, so it'll miss this...
else
   cat $TEMP
fi

rm $TEMP 2> /dev/null
