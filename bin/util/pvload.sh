#!/bin/bash
#
#3> <> prov:specializationOf <https://github.com/timrdf/csv2rdf4lod-automation/blob/master/bin/util/pvload.sh>;
#3>    rdfs:seeAlso <https://github.com/timrdf/csv2rdf4lod-automation/wiki/vload#pvloadsh>;
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
#

usage_message="usage: `basename $0` [--help] [-n] <url> [-ng <graph-name>] [--separate-provenance [--into (<prov-graph> | 'one')]]" 

if [[ "$1" == "--help" || $# -lt 1 ]]; then
   echo $usage_message 
   echo "  -n                    : dry run - do not download or load into named graph."
   echo "  <url>                 : the URL to retrieve and load into a named graph."
   echo "  -ng <graph-name>      : the name of the graph to place <url>. (if not provided, -ng == <url>)."
   echo "  --separate-provenance [ --into <prov-graph> ] :"
   echo "                          store the provenance of loading <url> in a separate named graph, not in '-ng'."
   echo "                          if <prov-graph> is the value 'one', choose a global graph name."
   echo
   echo "  (Setting envvar CSV2RDF4LOD_CONVERT_DEBUG_LEVEL=finest will leave temporary files after invocation.)"
   echo "  (See https://github.com/timrdf/csv2rdf4lod-automation/wiki/Script:-pvload.sh)"
   exit 1
fi

see='https://github.com/timrdf/csv2rdf4lod-automation/wiki/CSV2RDF4LOD-not-set'
CSV2RDF4LOD_HOME=${CSV2RDF4LOD_HOME:?"not set; source csv2rdf4lod/source-me.sh or see $see"}
CSV2RDF4LOD_BASE_URI=${CSV2RDF4LOD_BASE_URI:?"not set; source csv2rdf4lod/source-me.sh or see $see"}

export PATH=$PATH`$CSV2RDF4LOD_HOME/bin/util/cr-situate-paths.sh`
export CLASSPATH=$CLASSPATH`$CSV2RDF4LOD_HOME/bin/util/cr-situate-classpaths.sh`

dryrun="false"
if [ $1 == "-n" ]; then
   dryrun="true"; shift 
fi

function no_scheme {
   local uri="$1"
   local uri_NO_SCHEME=${uri#http://}
         uri_NO_SCHEME=${uri_NO_SCHEME#https://}
   echo $uri_NO_SCHEME
}

PROV_BASE="http://www.provenanceweb.net/id/"
PROV_BASE="${CSV2RDF4LOD_BASE_URI_OVERRIDE:-$CSV2RDF4LOD_BASE_URI}/id/"

# MD5 this script
curlMD5="md5_`$CSV2RDF4LOD_HOME/bin/util/md5.sh \`which curl\``"

# MD5 this script
myMD5="md5_`$CSV2RDF4LOD_HOME/bin/util/md5.sh $0`"

TEMP="_"`basename $0``date +%s`_$$.response

escapedEndpoint=`cr-urlencode.sh ${CSV2RDF4LOD_PUBLISH_VIRTUOSO_SPARQL_ENDPOINT}`

if [[ "$1" == '--prov-graph-name' && "$2" =~ http* ]]; then
   # Un-exposed option for other scripts to use.
   graph_name="$2"
   echo ${CSV2RDF4LOD_BASE_URI_OVERRIDE:-$CSV2RDF4LOD_BASE_URI}/graph-prov/`no_scheme $graph_name`
   exit
fi

logID=`resource-name.sh`
while [ $# -gt 0 ]; do
   echo
   echo "/////------------------------------ `basename $0` ------------------------------\\\\\\\\\\"

   url="$1"
   shift
   requestID=`resource-name.sh`

   #
   # Grab the file.
   #
   usageDateTime=`$CSV2RDF4LOD_HOME/bin/util/dateInXSDDateTime.sh`
   usageDateTimeSlug=`$CSV2RDF4LOD_HOME/bin/util/dateInXSDDateTime.sh coin:slug`
   if [ "$dryrun" != "true" ]; then
      $CSV2RDF4LOD_HOME/bin/util/pcurl.sh $url -n $TEMP     # Side affect: creates $TEMP.prov.ttl (will be loaded below).
      echo
      unzipped=""
      gunzip -t $TEMP &> /dev/null
      if [ $? -eq 0 ]; then
         unzipped=".unzipped"
         echo "[INFO] `basename $0`: HTTP response was compressed; uncompressing."
         gunzip -c $TEMP > ${TEMP}${unzipped}
      fi
   else
      echo `basename $CSV2RDF4LOD_HOME/bin/util/pcurl.sh` $url -n $TEMP
      echo "<http://www.w3.org/2002/07/owl#sameAs> <http://www.w3.org/2002/07/owl#sameAs> <http://www.w3.org/2002/07/owl#sameAs> ." > $TEMP
   fi

   #echo "PVLOAD: url                $url"
   #echo "rest: $*"
   if [[ "$1" == "-ng" && "$2" =~ http* ]]; then # Override the default named graph name (the URL of the source).
      named_graph="$2"
      #echo "PVLOAD: -ng             $named_graph"; 
      #echo "PVLOAD: $*"; 
      shift 2
      #echo "PVLOAD: $*"; 
   elif [[ "$1" == "-ng" && $# -lt 2 ]]; then
      echo "ERROR: -ng given with no value."
      exit 1
   elif [[ "$1" == "-ng" ]]; then
      shift 1
      named_graph="$url"                          # Default to a named graph name of the URL source.
   else
      #echo "PVLOAD: -ng?"; 
      named_graph="$url"                          # Default to a named graph name of the URL source.
   fi
   echo "[INFO] `basename $0`: (URL) $url"
   echo "                   --> (Named Graph) $named_graph"

   separate_provenance="no"
   prov_graph=$named_graph
   #echo "rest: $*"
   if [[ "$1" == '--separate-provenance' ]]; then
      separate_provenance="yes"
      if [[ "$2" == '--into' ]]; then
         if [[ "$3" =~ http* && -n "$3" ]]; then
            prov_graph="$3"
            shift 
         elif [[ "$3" == 'one' ]]; then
            prov_graph="${CSV2RDF4LOD_BASE_URI_OVERRIDE:-$CSV2RDF4LOD_BASE_URI}/graph-prov"
            shift 
         fi
         shift 
      else
         # Note: coordinate with pvdelete.sh
         prov_graph=${CSV2RDF4LOD_BASE_URI_OVERRIDE:-$CSV2RDF4LOD_BASE_URI}/graph-prov/`no_scheme $named_graph`
      fi
      shift
   fi
   echo "                   --> (PROV Graph)  $prov_graph"

   #
   # Normalize into ntriples 
   # (because Virtuoso chokes on some well-formatted Turtle, and they don't respond to bugs).
   # (note, this step is not worth describing in the provenance).
   #
   #echo guessing `$CSV2RDF4LOD_HOME/bin/util/guess-syntax.sh $url rapper`
   syntax=`$CSV2RDF4LOD_HOME/bin/util/guess-syntax.sh $url rapper`
   liked_guess=$? # 0 : liked its guess, 1: did NOT like its guess
   if [[ $liked_guess == 1 ]]; then
      #echo "DIDN'T LIKED SYNTAX GUESS $syntax: $liked_guess"
      syntax=`$CSV2RDF4LOD_HOME/bin/util/guess-syntax.sh --inspect ${TEMP}${unzipped} rapper`
      echo "[INFO] Guess by inspection: $syntax"
   else
      echo "[INFO] Guessing syntax without inspection: $syntax ($url)"
   fi

   # Turtle to N-TRIPLES (b/c Virtuoso chokes on some Turtle and we need to spoon feed).
   too_big="no" # TODO: use too-big-for-rapper.sh ?
   for file in `find . -size +1900M -name ${TEMP}${unzipped}`; do 
      too_big="yes"; 
      echo "${TEMP}${unzipped} exceeds 1900MB, chunking."; 
      rm cHuNk* &> /dev/null
      $CSV2RDF4LOD_HOME/bin/split_ttl.pl ${TEMP}${unzipped} # NOTE: This only works for csv2rdf4lod's flavor of TTL.
      for chunk in cHuNk*; do
         rapper -q $syntax -o ntriples $chunk >> ${TEMP}${unzipped}.nt
         #debug wc -l ${TEMP}${unzipped}.nt
      done
      rm cHuNk*
   done
   if [ $too_big == "no" ]; then
      rapper -q $syntax -o ntriples ${TEMP}${unzipped} > ${TEMP}${unzipped}.nt
   fi

   if [ "$CSV2RDF4LOD_CONVERT_DEBUG_LEVEL" != "finest" ]; then
      rm $TEMP
   fi

   NT_triple_count=`wc -l ${TEMP}${unzipped}.nt | awk '{print $1}'`
   if [ "$NT_triple_count" -gt 0 ]; then
      # Relative paths.
      sourceUsage="sourceUsage$requestID"
      escapedNG=`echo $named_graph | perl -e 'use URI::Escape; @userinput = <STDIN>; foreach (@userinput) { chomp($_); print uri_escape($_); }'`
      # see https://github.com/timrdf/csv2rdf4lod-automation/wiki/Naming-sparql-service-description's-sd:NamedGraph
      # TODO: adopt name-resource.sh as per https://github.com/timrdf/csv2rdf4lod-automation/wiki/Naming-sparql-service-description's-sd:NamedGraph
      named_graph_global="${CSV2RDF4LOD_PUBLISH_VIRTUOSO_SPARQL_ENDPOINT}?query=PREFIX%20sd%3A%20%3Chttp%3A%2F%2Fwww.w3.org%2Fns%2Fsparql-service-description%23%3E%20CONSTRUCT%20%7B%20%3Fendpoints_named_graph%20%3Fp%20%3Fo%20%7D%20WHERE%20%7B%20GRAPH%20%3C${escapedNG}%3E%20%7B%20%5B%5D%20sd%3Aurl%20%3C${escapedEndpoint}%3E%3B%20sd%3AdefaultDatasetDescription%20%5B%20sd%3AnamedGraph%20%3Fendpoints_named_graph%20%5D%20.%20%3Fendpoints_named_graph%20sd%3Aname%20%3C${escapedNG}%3E%3B%20%3Fp%20%3Fo%20.%20%7D%20%7D"

      xsl="-xsl:$CSV2RDF4LOD_HOME/bin/util/pvload-latest-ng-load.xsl"
      noop="-s:$CSV2RDF4LOD_HOME/bin/util/pvload-latest-ng-load.xsl"
      java_saxon="java -cp $CLASSPATH:$CSV2RDF4LOD_HOME/bin/dup/saxonb9-1-0-8j.jar net.sf.saxon.Transform $xsl $noop"
      latest_NG_nodeset=`$java_saxon endpoint=${CSV2RDF4LOD_PUBLISH_VIRTUOSO_SPARQL_ENDPOINT} named-graph=${named_graph}` 
      # pvload-latest-ng-load.xsl can call vsr:endpoint for a generic call, but it needs to not be dumb about its caching.
      if [ ${#latest_NG_nodeset} -gt 0 ]; then
         echo "[INFO] `basename $0` found provenance of previous named graph load: $latest_NG_nodeset"
         latest_NG_nodeset="<$latest_NG_nodeset>"
         cogs_load_type='Incremental'
      else
         cogs_load_type='Initial'
      fi

      echo
      echo "@prefix xsd:        <http://www.w3.org/2001/XMLSchema#> ."                                          > ${TEMP}${unzipped}.load.prov.ttl
      echo "@prefix rdfs:       <http://www.w3.org/2000/01/rdf-schema#> ."                                     >> ${TEMP}${unzipped}.load.prov.ttl
      echo "@prefix dcterms:    <http://purl.org/dc/terms/> ."                                                 >> ${TEMP}${unzipped}.load.prov.ttl
      echo "@prefix sioc:       <http://rdfs.org/sioc/ns#> ."                                                  >> ${TEMP}${unzipped}.load.prov.ttl
      echo "@prefix skos:       <http://www.w3.org/2004/02/skos/core#> ."                                      >> ${TEMP}${unzipped}.load.prov.ttl
      echo "@prefix pmlp:       <http://inference-web.org/2.0/pml-provenance.owl#> ."                          >> ${TEMP}${unzipped}.load.prov.ttl
      echo "@prefix pmlj:       <http://inference-web.org/2.0/pml-justification.owl#> ."                       >> ${TEMP}${unzipped}.load.prov.ttl
      echo "@prefix foaf:       <http://xmlns.com/foaf/0.1/> ."                                                >> ${TEMP}${unzipped}.load.prov.ttl
      echo "@prefix sd:         <http://www.w3.org/ns/sparql-service-description#> ."                          >> ${TEMP}${unzipped}.load.prov.ttl
      echo "@prefix oboro:      <http://obofoundry.org/ro/ro.owl#> ."                                          >> ${TEMP}${unzipped}.load.prov.ttl
      echo "@prefix oprov:      <http://openprovenance.org/ontology#> ."                                       >> ${TEMP}${unzipped}.load.prov.ttl
      echo "@prefix hartigprov: <http://purl.org/net/provenance/ns#> ."                                        >> ${TEMP}${unzipped}.load.prov.ttl
      echo "@prefix prov:       <http://www.w3.org/ns/prov#> ."                                                >> ${TEMP}${unzipped}.load.prov.ttl
      echo "@prefix dcat:       <http://www.w3.org/ns/dcat#> ."                                                >> ${TEMP}${unzipped}.load.prov.ttl
      echo "@prefix void:       <http://rdfs.org/ns/void#>."                                                   >> ${TEMP}${unzipped}.load.prov.ttl
      echo "@prefix cogs:       <http://vocab.deri.ie/cogs#> ."                                                >> ${TEMP}${unzipped}.load.prov.ttl
      echo "@prefix conversion: <http://purl.org/twc/vocab/conversion/> ."                                     >> ${TEMP}${unzipped}.load.prov.ttl
      echo                                                                                                     >> ${TEMP}${unzipped}.load.prov.ttl
      $CSV2RDF4LOD_HOME/bin/util/user-account.sh                                                               >> ${TEMP}${unzipped}.load.prov.ttl
      echo                                                                                                     >> ${TEMP}${unzipped}.load.prov.ttl
      echo "<$url>"                                                                                            >> ${TEMP}${unzipped}.load.prov.ttl
      echo "   a pmlp:Source;"                                                                                 >> ${TEMP}${unzipped}.load.prov.ttl
      echo "."                                                                                                 >> ${TEMP}${unzipped}.load.prov.ttl
      echo                                                                                                     >> ${TEMP}${unzipped}.load.prov.ttl
      echo "<${CSV2RDF4LOD_PUBLISH_VIRTUOSO_SPARQL_ENDPOINT}>"                                                 >> ${TEMP}${unzipped}.load.prov.ttl
      echo "   a pmlp:InferenceEngine, pmlp:WebService;"                                                       >> ${TEMP}${unzipped}.load.prov.ttl
      echo "."                                                                                                 >> ${TEMP}${unzipped}.load.prov.ttl
      echo                                                                                                     >> ${TEMP}${unzipped}.load.prov.ttl
      echo "<${PROV_BASE}nodeSet${requestID}>"                                                                 >> ${TEMP}${unzipped}.load.prov.ttl
      echo "   a pmlj:NodeSet;"                                                                                >> ${TEMP}${unzipped}.load.prov.ttl
      echo "   pmlp:hasCreationDateTime \"${usageDateTime}\"^^xsd:dateTime; # deprecate"                       >> ${TEMP}${unzipped}.load.prov.ttl
      echo "   dcterms:created          \"${usageDateTime}\"^^xsd:dateTime;"                                   >> ${TEMP}${unzipped}.load.prov.ttl
      echo "   pmlj:hasConclusion <${named_graph_global}#${usageDateTimeSlug}>;"                               >> ${TEMP}${unzipped}.load.prov.ttl
      echo "   pmlj:isConsequentOf <${PROV_BASE}infStep${requestID}>;"                                         >> ${TEMP}${unzipped}.load.prov.ttl
      echo "."                                                                                                 >> ${TEMP}${unzipped}.load.prov.ttl
      echo "<${named_graph_global}#${usageDateTimeSlug}> skos:broader <${named_graph_global}> ."               >> ${TEMP}${unzipped}.load.prov.ttl
      echo                                                                                                     >> ${TEMP}${unzipped}.load.prov.ttl
      echo "<${PROV_BASE}infStep${requestID}>"                                                                 >> ${TEMP}${unzipped}.load.prov.ttl
      echo "   a pmlj:InferenceStep;"                                                                          >> ${TEMP}${unzipped}.load.prov.ttl
      echo "   pmlj:hasAntecedentList ( $latest_NG_nodeset "                                                   >> ${TEMP}${unzipped}.load.prov.ttl
      echo "                            [ a pmlj:NodeSet; pmlj:hasConclusion <$url>; ] );"                     >> ${TEMP}${unzipped}.load.prov.ttl
      echo "   pmlj:hasInferenceEngine [ a conversion:TripleStore ];"                                          >> ${TEMP}${unzipped}.load.prov.ttl
      #echo "   pmlj:hasInferenceRule <http://inference-web.org/registry/MPR/TRIPLE_STORE_LOAD.owl#>;"         >> ${TEMP}${unzipped}.load.prov.ttl
      echo "   pmlj:hasInferenceRule <http://inference-web.org/registry/MPR/RDFModelUnion.owl#RDFModelUnion>;" >> ${TEMP}${unzipped}.load.prov.ttl
      echo "   oboro:has_agent          `$CSV2RDF4LOD_HOME/bin/util/user-account.sh --cite`;"                  >> ${TEMP}${unzipped}.load.prov.ttl
      echo "   hartigprov:involvedActor `$CSV2RDF4LOD_HOME/bin/util/user-account.sh --cite`;"                  >> ${TEMP}${unzipped}.load.prov.ttl
      echo "   dcterms:date \"`$CSV2RDF4LOD_HOME/bin/util/dateInXSDDateTime.sh`\"^^xsd:dateTime;"              >> ${TEMP}${unzipped}.load.prov.ttl
      echo "."                                                                                                 >> ${TEMP}${unzipped}.load.prov.ttl

      #
      # The above is PML. Below is PROV-O
      #
      echo "# PROV-O is better than PML 2: "                                                                   >> ${TEMP}${unzipped}.load.prov.ttl

      echo "<$url>"                                                                                            >> ${TEMP}${unzipped}.load.prov.ttl
      echo "   a foaf:Document;"                                                                               >> ${TEMP}${unzipped}.load.prov.ttl
      echo "."                                                                                                 >> ${TEMP}${unzipped}.load.prov.ttl
      echo                                                                                                     >> ${TEMP}${unzipped}.load.prov.ttl
      echo "<${named_graph_global}#${usageDateTimeSlug}>"                                                      >> ${TEMP}${unzipped}.load.prov.ttl
      echo "   a sd:NamedGraph;"                                                                               >> ${TEMP}${unzipped}.load.prov.ttl
      echo "   dcterms:created      \"${usageDateTime}\"^^xsd:dateTime;"                                       >> ${TEMP}${unzipped}.load.prov.ttl
      echo "   dcterms:identifier   \"${usageDateTimeSlug}\";"                                                 >> ${TEMP}${unzipped}.load.prov.ttl
      echo "   prov:specializationOf <${named_graph_global}>;"                                                 >> ${TEMP}${unzipped}.load.prov.ttl
      echo "   prov:wasDerivedFrom ${latest_NG_nodeset:-"<$named_graph_global>"};"                             >> ${TEMP}${unzipped}.load.prov.ttl
      echo "."                                                                                                 >> ${TEMP}${unzipped}.load.prov.ttl
      echo ""                                                                                                  >> ${TEMP}${unzipped}.load.prov.ttl
      echo "<${named_graph_global}>"                                                                           >> ${TEMP}${unzipped}.load.prov.ttl
      echo "   a sd:NamedGraph;"                                                                               >> ${TEMP}${unzipped}.load.prov.ttl
      echo "   sd:name <$named_graph>;"                                                                        >> ${TEMP}${unzipped}.load.prov.ttl
      echo "   dcterms:modified     \"${usageDateTime}\"^^xsd:dateTime;"                                       >> ${TEMP}${unzipped}.load.prov.ttl
      echo "."                                                                                                 >> ${TEMP}${unzipped}.load.prov.ttl
      echo                                                                                                     >> ${TEMP}${unzipped}.load.prov.ttl
      echo "<${PROV_BASE}sdService$requestID> a sd:Service;"                                                   >> ${TEMP}${unzipped}.load.prov.ttl
      if [ ${#CSV2RDF4LOD_PUBLISH_VIRTUOSO_SPARQL_ENDPOINT} -gt 0 ]; then
         echo "   sd:endpoint <$CSV2RDF4LOD_PUBLISH_VIRTUOSO_SPARQL_ENDPOINT>;"                                >> ${TEMP}${unzipped}.load.prov.ttl
      fi
      echo "   sd:availableGraphs <${PROV_BASE}collection$requestID>;"                                         >> ${TEMP}${unzipped}.load.prov.ttl
      echo "."                                                                                                 >> ${TEMP}${unzipped}.load.prov.ttl
      echo                                                                                                     >> ${TEMP}${unzipped}.load.prov.ttl
      echo "<${PROV_BASE}collection$requestID>"                                                                >> ${TEMP}${unzipped}.load.prov.ttl
      echo "  a sd:GraphCollection, dcat:Dataset;"                                                             >> ${TEMP}${unzipped}.load.prov.ttl
      echo "  sd:namedGraph <$named_graph_global>;"                                                            >> ${TEMP}${unzipped}.load.prov.ttl
      echo "."                                                                                                 >> ${TEMP}${unzipped}.load.prov.ttl
      echo                                                                                                     >> ${TEMP}${unzipped}.load.prov.ttl
      echo "<$TEMP>"                                                                                           >> ${TEMP}${unzipped}.load.prov.ttl
      echo "   void:triples $NT_triple_count;"                                                                 >> ${TEMP}${unzipped}.load.prov.ttl
      echo "."                                                                                                 >> ${TEMP}${unzipped}.load.prov.ttl
      echo "<${PROV_BASE}activity${requestID}>"                                                                >> ${TEMP}${unzipped}.load.prov.ttl
      echo "   a cogs:${cogs_load_type}Loading, cogs:Loading, prov:Activity;"                                  >> ${TEMP}${unzipped}.load.prov.ttl
      echo "   prov:used ${latest_NG_nodeset:-"<$named_graph_global>"}, <$url>,"                               >> ${TEMP}${unzipped}.load.prov.ttl
      echo "             <$TEMP>;"                                                                             >> ${TEMP}${unzipped}.load.prov.ttl
      echo "   prov:wasAssociatedWith          `$CSV2RDF4LOD_HOME/bin/util/user-account.sh --cite`;"           >> ${TEMP}${unzipped}.load.prov.ttl
      echo "   prov:qualifiedAssociation ["                                                                    >> ${TEMP}${unzipped}.load.prov.ttl
      echo "      a prov:Association;"                                                                         >> ${TEMP}${unzipped}.load.prov.ttl
      echo "      prov:agent `$CSV2RDF4LOD_HOME/bin/util/user-account.sh --cite`;"                             >> ${TEMP}${unzipped}.load.prov.ttl
      echo "      prov:hadPlan <http://inference-web.org/registry/MPR/RDFModelUnion.owl#RDFModelUnion>;"       >> ${TEMP}${unzipped}.load.prov.ttl
      echo "   ];"                                                                                             >> ${TEMP}${unzipped}.load.prov.ttl
      echo "   prov:generated <${named_graph_global}#${usageDateTimeSlug}>;"                                   >> ${TEMP}${unzipped}.load.prov.ttl
      echo "   prov:startedAtTime \"`$CSV2RDF4LOD_HOME/bin/util/dateInXSDDateTime.sh`\"^^xsd:dateTime;"        >> ${TEMP}${unzipped}.load.prov.ttl
      echo "."                                                                                                 >> ${TEMP}${unzipped}.load.prov.ttl


      #
      # Virtuoso can't handle all turtle files that rapper can.
      #

      vload=$CSV2RDF4LOD_HOME/bin/util/virtuoso/vload
      #echo $vload nt ${TEMP}${unzipped}.nt $named_graph
      if [ "$dryrun" != "true" ]; then #        Actual response (in ntriples syntax).
         $vload nt ${TEMP}${unzipped}.nt              $named_graph 2>&1 | grep -v "Loading" 
         #cat /tmp/virtuoso-tmp/vload.log
      fi

      #
      # When loading into graph named:   'http://example.org/pvload-test',
      # we can keep the provenance separate by loading in into the graph named 
      #  'http://opendap.tw.rpi.edu/graph/http/example.org/pvload-test'
      #
      if [[ "$separate_provenance" == 'yes' && -z "$prov_graph" ]]; then
         # We were asked to put the provenance into a separate graph,
         # but we weren't told which graph to put it into.
         # So, figure out a graph to put it into.
         prov_graph=${CSV2RDF4LOD_BASE_URI_OVERRIDE:-$CSV2RDF4LOD_BASE_URI}/graph-prov/${g#http:/}
         echo "Separate graph for prov: $named_graph -> $prov_graph"
      else
         # We were told which prov_graph to use, or it shouldn't be separated out.
         prov_graph=${prov_graph:-$named_graph}
      fi
      #echo $vload ttl ${TEMP}.prov.ttl      $prov_graph
      if [ "$dryrun" != "true" ]; then # Provenance of response (SourceUsage created by pcurl.sh).
         rapper -q -g -o ntriples ${TEMP}.prov.ttl > ${TEMP}.prov.ttl.nt
         $vload nt ${TEMP}.prov.ttl.nt                 $prov_graph 2>&1 | grep -v "Loading"
         #cat /tmp/virtuoso-tmp/vload.log
      fi
      #echo $vload ttl ${TEMP}.load.prov.ttl  $prov_graph
      if [ "$dryrun" != "true" ]; then # Provenance of loading file into the store. TODO: cat ${TEMP}${unzipped}.load.prov.ttl into a pmlp:hasRawString?
         rapper -q -g -o ntriples ${TEMP}${unzipped}.load.prov.ttl > ${TEMP}${unzipped}.load.prov.ttl.nt
         $vload nt ${TEMP}${unzipped}.load.prov.ttl.nt $prov_graph 2>&1 | grep -v "Loading"             
         #cat /tmp/virtuoso-tmp/vload.log
      fi
      echo "\\\\\\\\\\------------------------------ `basename $0` ------------------------------/////"
   else
      echo "[WARNING] `basename $0` skipping b/c no triples returned."
   fi

   #
   # Clean up
   #
   if [ "$CSV2RDF4LOD_CONVERT_DEBUG_LEVEL" != "finest" ]; then
      rm -f ${TEMP}*
      rm -f ${TEMP}.unzipped
      rm -f ${TEMP}.unzipped.nt
      rm -f ${TEMP}.prov.ttl 
      rm -f ${TEMP}.prov.ttl.nt 
      rm -f ${TEMP}${unzipped} 
      rm -f ${TEMP}.nt
      rm -f ${TEMP}${unzipped}.nt
      rm -f ${TEMP}${unzipped}.load.prov.ttl 
      rm -f ${TEMP}${unzipped}.load.prov.ttl.nt
      rm -f _pvload*
   fi
done
