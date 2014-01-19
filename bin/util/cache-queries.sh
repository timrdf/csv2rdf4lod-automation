#!/bin/bash
#
#3> <> prov:specializationOf <https://github.com/timrdf/csv2rdf4lod-automation/blob/master/bin/util/cache-queries.sh>;
#3>    rdfs:seeAlso          <https://github.com/timrdf/csv2rdf4lod-automation/wiki/Script:-cache-queries.sh>;
#3> .
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

outputTypes="sparql xml"

if [ $# -lt 1 ]; then
   echo "usage: `basename $0` <endpoint> [-p {output,format}] [-o {sparql,gvds,xml,exhibit,csv}+] [-q a.sparql b.sparql ...]* [--limit-offset] [-od path/to/output/dir]"
   echo
   echo "    Executes SPARQL queries against an endpoint requesting the given output formats."
   echo
   echo "            -p  : the URL parameter name used to request a different output/format from <endpoint>."
   echo "    default -p  : 'output'"
   echo "            -o  : the URL parameter value(s) to request."
   echo "    default -o  : $outputTypes"
   echo "    default -q  : *.sparql *.rq"
   echo " --limit-offset : iterate with LIMIT / OFFSET until no more useful results."
   echo "            -od : output directory"
   echo "    default -od : results/"
   exit 1
fi

# http://dbpedia.org/sparql
# format = 
# "text/html"                       HTML
# "application/vnd.ms-excel"        Spreadsheet
# "application/sparql-results+xml"  XML
# "application/sparql-results+json" JSON           &format=application%2Frdf%2Bxml
# "application/javascript"          Javascript
# "text/plain"                      NTriples
# "application/rdf+xml"             RDF/XML
# "text/csv"                        CSV

endpoint="http://logd.tw.rpi.edu/sparql"
endpoint="http://dbpedia.org/sparql"
endpoint="$1"
shift

outputVarName="output"
if [ "$1" == "-p" ]; then
   shift
   outputVarName="$1"
   shift
fi
#echo "`basename $0` using results format param: $outputVarName"

if [ "$1" == "-o" ]; then
   shift
   outputTypes=""
   while [ "$1" != "-q" -a $# -gt 0 ]; do
      outputTypes="$outputTypes $1"
      shift
   done
fi
#echo "`basename $0` using results format value: $outputTypes"

queryFiles=""
if [ $# -gt 0 -a "$1" == "-q" ]; then
   shift
   while [[ $# -gt 0 -a ( "$1" != '-od' && "$1" != '--limit-offset' ) ]]; do
      queryFiles="$queryFiles $1"
      shift 
   done
else
   for sparql in `ls *.sparql *.rq 2> /dev/null`; do
      queryFiles="$queryFiles $sparql"
   done
fi

limit_offset=''
if [[ "$1" == '--limit-offset' ]]; then
   limit_offset='yes' 
   if [[ "$2" =~ -* ]]; then
      echo "`basename $0` will use default LIMIT, or the LIMIT defined in the file." >&2
   else
      limit_offset="$2" # An actual number.
      shift
   fi
   shift
fi

echo "limit_offset: $limit_offset" >&2

results="results"
if [ "$1" == "-od" -a $# -gt 1 ]; then
   shift
   results="$1"
fi
if [ ! -d $results ]; then
   mkdir -p $results
fi

for sparql in $queryFiles; do
   echo $sparql
   for output in $outputTypes; do
      # TODO: use bin//util/cr-urlencode.sh
      query=`        cat  $sparql | perl -e 'use URI::Escape; @userinput = <STDIN>; foreach (@userinput) { print uri_escape($_); }'`
      escapedOutput=`echo $output | perl -e 'use URI::Escape; @userinput = <STDIN>; foreach (@userinput) { chomp($_); print uri_escape($_); }'` # | sed 's/%0A$//'`
      request=$endpoint"?query="$query"&"$outputVarName"="$escapedOutput 
      #echo $request

      resultsFile=$results/`basename $sparql`.`echo $output | tr '/+-' '_'`
      printf "  $output -> $resultsFile"
      curl -L "$request" > $resultsFile 2> /dev/null

      requestID=`resource-name.sh`
      requestDate=`dateInXSDDateTime.sh`
      echo "@prefix rdfs:       <http://www.w3.org/2000/01/rdf-schema#> ."                     > $resultsFile.prov.ttl
      echo "@prefix xsd:        <http://www.w3.org/2001/XMLSchema#> ."                        >> $resultsFile.prov.ttl
      echo "@prefix foaf:       <http://xmlns.com/foaf/0.1/> ."                               >> $resultsFile.prov.ttl
      echo "@prefix dcterms:    <http://purl.org/dc/terms/> ."                                >> $resultsFile.prov.ttl
      echo "@prefix sioc:       <http://rdfs.org/sioc/ns#> ."                                 >> $resultsFile.prov.ttl
      echo "@prefix pmlp:       <http://inference-web.org/2.0/pml-provenance.owl#> ."         >> $resultsFile.prov.ttl
      echo "@prefix pmlb:       <http://inference-web.org/2.b/pml-provenance.owl#> ."         >> $resultsFile.prov.ttl
      echo "@prefix nfo:        <http://www.semanticdesktop.org/ontologies/nfo/#> ."          >> $resultsFile.prov.ttl
      echo "@prefix pmlj:       <http://inference-web.org/2.0/pml-justification.owl#> ."      >> $resultsFile.prov.ttl
      echo "@prefix foaf:       <http://xmlns.com/foaf/0.1/> ."                               >> $resultsFile.prov.ttl
      echo "@prefix sioc:       <http://rdfs.org/sioc/ns#> ."                                 >> $resultsFile.prov.ttl
      echo "@prefix oboro:      <http://obofoundry.org/ro/ro.owl#> ."                         >> $resultsFile.prov.ttl
      echo "@prefix oprov:      <http://openprovenance.org/ontology#> ."                      >> $resultsFile.prov.ttl
      echo "@prefix hartigprov: <http://purl.org/net/provenance/ns#> ."                       >> $resultsFile.prov.ttl
      echo "@prefix conv:    <http://purl.org/twc/vocab/conversion/> ."                       >> $resultsFile.prov.ttl
      echo                                                                                    >> $resultsFile.prov.ttl
      $CSV2RDF4LOD_HOME/bin/util/user-account.sh                                              >> $resultsFile.prov.ttl
      echo                                                                                    >> $resultsFile.prov.ttl
      pushd $results &> /dev/null
      $CSV2RDF4LOD_HOME/bin/util/nfo-filehash.sh "`basename $resultsFile`"                    >> `basename $resultsFile.prov.ttl`
      popd &> /dev/null
      echo                                                                                    >> $resultsFile.prov.ttl
      echo "<$sparql.$output>"                                                                >> $resultsFile.prov.ttl
      echo "   a pmlp:Information;"                                                           >> $resultsFile.prov.ttl
      echo "   pmlp:hasModificationDateTime \"$requestDate\"^^xsd:dateTime;"                  >> $resultsFile.prov.ttl
      echo "   pmlp:hasReferenceSourceUsage <sourceusage$requestID>;"                         >> $resultsFile.prov.ttl
      echo "."                                                                                >> $resultsFile.prov.ttl
      echo                                                                                    >> $resultsFile.prov.ttl
      echo "<sourceusage$requestID>"                                                          >> $resultsFile.prov.ttl
      echo "   a pmlp:SourceUsage;"                                                           >> $resultsFile.prov.ttl
      echo "   pmlp:hasSource        <$request>;"                                             >> $resultsFile.prov.ttl
      echo "   pmlp:hasUsageDateTime \"$requestDate\"^^xsd:dateTime;"                         >> $resultsFile.prov.ttl
      echo "."                                                                                >> $resultsFile.prov.ttl
      echo                                                                                    >> $resultsFile.prov.ttl
      echo "<$request>"                                                                       >> $resultsFile.prov.ttl
      echo "   a pmlj:Query, pmlp:Source;"                                                    >> $resultsFile.prov.ttl
      echo "   pmlj:isFromEngine <$endpoint>;"                                                >> $resultsFile.prov.ttl
      echo "   pmlj:hasAnswer    <nodeset$requestID>;"                                        >> $resultsFile.prov.ttl
      echo "."                                                                                >> $resultsFile.prov.ttl
      echo                                                                                    >> $resultsFile.prov.ttl
      echo "<$endpoint>"                                                                      >> $resultsFile.prov.ttl
      echo "   a pmlp:InferenceEngine, pmlp:WebService;"                                      >> $resultsFile.prov.ttl
      echo "."                                                                                >> $resultsFile.prov.ttl
      echo                                                                                    >> $resultsFile.prov.ttl
      echo "<nodeset$requestID>"                                                              >> $resultsFile.prov.ttl
      echo "   a pmlj:NodeSet;"                                                               >> $resultsFile.prov.ttl
      echo "   pmlj:hasConclusion <$sparql.$output>;"                                         >> $resultsFile.prov.ttl
      echo "   pmlj:isConsequentOf <inferenceStep_$requestID>;"                               >> $resultsFile.prov.ttl
      echo "."                                                                                >> $resultsFile.prov.ttl
      echo "<inferenceStep$requestID>"                                                        >> $resultsFile.prov.ttl
      echo "   a pmlj:InferenceStep;"                                                         >> $resultsFile.prov.ttl
      echo "   pmlj:hasIndex 0;"                                                              >> $resultsFile.prov.ttl
      echo "   pmlj:hasAntecedentList ("                                                      >> $resultsFile.prov.ttl
      echo "      [ a pmlj:NodeSet; pmlp:hasConclusion <query$requestID> ]"                   >> $resultsFile.prov.ttl
      echo "      [ a pmlj:NodeSet; pmlp:hasConclusion ["                                     >> $resultsFile.prov.ttl
      echo "            a pmlb:AttributeValuePair;"                                           >> $resultsFile.prov.ttl
      echo "            pmlb:attribute \"output\"; pmlb:value \"$output\""                    >> $resultsFile.prov.ttl
      echo "          ]"                                                                      >> $resultsFile.prov.ttl
      echo "      ]"                                                                          >> $resultsFile.prov.ttl
      echo "   );"                                                                            >> $resultsFile.prov.ttl
      echo "   oboro:has_agent          `$CSV2RDF4LOD_HOME/bin/util/user-account.sh --cite`;" >> $resultsFile.prov.ttl
      echo "   hartigprov:involvedActor `$CSV2RDF4LOD_HOME/bin/util/user-account.sh --cite`;" >> $resultsFile.prov.ttl
      #echo "      pmlj:hasSourceUsage     $sourceUsage;"                                     >> $resultsFile.prov.ttl
      #echo "      pmlj:hasInferenceEngine <$engine_name$requestID>;"                         >> $resultsFile.prov.ttl
      #echo "      pmlj:hasInferenceRule   conv:${engine_name}_Method;"                       >> $resultsFile.prov.ttl
      echo "."                                                                                >> $resultsFile.prov.ttl
      echo "<wasControlled_$requestID>"                                                       >> $resultsFile.prov.ttl
      echo "   a oprov:WasControlledBy;"                                                      >> $resultsFile.prov.ttl
      echo "   oprov:cause  `$CSV2RDF4LOD_HOME/bin/util/user-account.sh --cite`;"             >> $resultsFile.prov.ttl
      echo "   oprov:effect <inferenceStep$requestID>;"                                       >> $resultsFile.prov.ttl
      echo "   oprov:endTime \"$usageDateTime\"^^xsd:dateTime;"                               >> $resultsFile.prov.ttl
      echo "."                                                                                >> $resultsFile.prov.ttl
      echo ""                                                                                 >> $resultsFile.prov.ttl
      echo "<query$requestID>"                                                                >> $resultsFile.prov.ttl
      echo "   a pmlb:AttributeValuePair;"                                                    >> $resultsFile.prov.ttl
      echo "   pmlb:attribute \"query\";"                                                     >> $resultsFile.prov.ttl
      echo "   pmlb:value     \"\"\"`cat $sparql`\"\"\";"                                     >> $resultsFile.prov.ttl
      echo "."                                                                                >> $resultsFile.prov.ttl
   done
   echo ""
done 
