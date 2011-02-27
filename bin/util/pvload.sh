#!/bin/bash
#
# Usage:
#
#
#
#
# (vload usage: vload [rdf|ttl|nt|nq] [data_file] [graph_uri])

usage_message="usage: `basename $0` [-n] url [-ng named_graph]" 

if [ $# -lt 1 ]; then
   echo $usage_message 
   echo "  -n  : dry run - do not download or load into named graph."
   echo "  url : the URL to retrieve and load into a named graph."
   echo "  -ng : the named graph to place 'url'. (if not provided, -ng == 'url')."
   exit 1
fi

dryrun="false"
if [ $1 == "-n" ]; then
   dryrun="true"
   shift 
fi

assudo="sudo"
if [ `whoami` == "root" ]; then
   assudo=""
fi

curlPath=`which curl`
curlMD5="md5_`md5.sh $curlPath`"

# md5 this script
pvloadMD5=""
if [ `which md5` ]; then
   # md5 outputs:
   # MD5 (pvload.sh) = ecc71834c2b7d73f9616fb00adade0a4
   pvloadMD5=`md5 $0 | perl -pe 's/^.* = //'`
elif [ `which md5sum` ]; then
   pvloadMD5=`md5sum $0 | perl -pe 's/\s.*//'`
else
   echo "`basename $0`: can not find md5 to md5 this script."
fi

TEMP="_"`basename $0``date +%s`_$$.response

alias rname="java edu.rpi.tw.string.NameFactory"
logID=`java edu.rpi.tw.string.NameFactory`
while [ $# -gt 0 ]; do
   echo
   echo ---------------------------------- pvload ---------------------------------------
   url="$1"

   if [ ${dryrun-"."} != "true" ]; then
      $CSV2RDF4LOD_HOME/bin/util/pcurl.sh $url -n $TEMP
   else
      echo `basename $CSV2RDF4LOD_HOME/bin/util/pcurl.sh` $url -n $TEMP
      echo "<http://purl.org/twc/vocab/conversion/multiplier> <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <http://www.w3.org/1999/02/22-rdf-syntax-ns#Property> ." > $TEMP
   fi

   echo "PVLOAD: url                $url"
   flag=$2
   if [ $# -ge 3 -a ${flag:=""} == "-ng" ]; then
      named_graph="$3"
      echo "PVLOAD: -ng             $named_graph"
      shift 2
   else
      named_graph="$url"
   fi
   echo "PVLOAD: (URL) $url -> (Named Graph) $named_graph"
   rapper -g -o ntriples $TEMP > $TEMP.nt
   rm $TEMP

   requestID=`java edu.rpi.tw.string.NameFactory`
   usageDateTime=`date +%Y-%m-%dT%H:%M:%S%z | sed 's/^\(.*\)\(..\)$/\1:\2/'`

   # Relative paths.
   sourceUsage="sourceUsage$requestID"
   nodeSet="nodeSet$requestID"

   echo
   echo "@prefix rdfs:     <http://www.w3.org/2000/01/rdf-schema#> ."                     > $TEMP.load.pml.ttl
   echo "@prefix xsd:      <http://www.w3.org/2001/XMLSchema#> ."                        >> $TEMP.load.pml.ttl
   echo "@prefix dcterms:  <http://purl.org/dc/terms/> ."                                >> $TEMP.load.pml.ttl
   echo "@prefix pmlp:     <http://inference-web.org/2.0/pml-provenance.owl#> ."         >> $TEMP.load.pml.ttl
   echo "@prefix pmlj:     <http://inference-web.org/2.0/pml-justification.owl#> ."      >> $TEMP.load.pml.ttl
   echo "@prefix irw:      <http://www.ontologydesignpatterns.org/ont/web/irw.owl#> ."   >> $TEMP.load.pml.ttl
   echo "@prefix nfo:      <http://www.semanticdesktop.org/ontologies/nfo/#> ."          >> $TEMP.load.pml.ttl
   echo "@prefix conv:     <http://purl.org/twc/vocab/conversion/> ."                    >> $TEMP.load.pml.ttl
   echo "@prefix httphead: <http://inference-web.org/registry/MPR/HTTP_1_1_HEAD.owl#> ." >> $TEMP.load.pml.ttl
   echo "@prefix httpget:  <http://inference-web.org/registry/MPR/HTTP_1_1_GET.owl#> ."  >> $TEMP.load.pml.ttl
   echo                                                                                  >> $TEMP.load.pml.ttl
   echo "<$TEMP>"                                                                        >> $TEMP.load.pml.ttl
   echo "   a pmlp:Source;"                                                              >> $TEMP.load.pml.ttl
   echo "."                                                                              >> $TEMP.load.pml.ttl
#   echo                                                                                 >> $TEMP.load.pml.ttl
#   echo "<$redirectedURL>"                                                              >> $TEMP.load.pml.ttl
#   echo "   a pmlp:Source;"                                                             >> $TEMP.load.pml.ttl
#      if [ ${#redirectedModDate} -gt 3 ]; then
#         echo "   pmlp:hasModificationDateTime \"$redirectedModDate\"^^xsd:dateTime;"   >> $TEMP.load.pml.ttl
#      fi
#   echo "."                                                                             >> $TEMP.load.pml.ttl
#   echo                                                                                 >> $TEMP.load.pml.ttl
#   if [ ${downloadFile:-"."} == "true" ]; then
#      echo "<$file>"                                                                    >> $TEMP.load.pml.ttl
#      echo "   a pmlp:Information;"                                                     >> $TEMP.load.pml.ttl
#      echo "   pmlp:hasReferenceSourceUsage <${sourceUsage}_content>;"                  >> $TEMP.load.pml.ttl
#      echo "   nfo:hasHash <md5_$downloadedFileMD5>;"                                   >> $TEMP.load.pml.ttl
#      echo "."                                                                          >> $TEMP.load.pml.ttl
#      echo ""                                                                           >> $TEMP.load.pml.ttl
#      echo "<md5_$downloadedFileMD5>"                                                   >> $TEMP.load.pml.ttl
#      echo "   a nfo:FileHash; "                                                        >> $TEMP.load.pml.ttl
#      echo "   nfo:hashAlgorithm \"md5\";"                                              >> $TEMP.load.pml.ttl
#      echo "   nfo:hashValue \"$downloadedFileMD5\";"                                   >> $TEMP.load.pml.ttl
#      echo "."                                                                          >> $TEMP.load.pml.ttl
#      echo                                                                              >> $TEMP.load.pml.ttl
#      echo "<${nodeSet}_content>"                                                       >> $TEMP.load.pml.ttl
#      echo "   a pmlj:NodeSet;"                                                         >> $TEMP.load.pml.ttl
#      echo "   pmlj:hasConclusion <$file>;"                                             >> $TEMP.load.pml.ttl
#      echo "   pmlj:isConsequentOf ["                                                   >> $TEMP.load.pml.ttl
#      echo "      a pmlj:InferenceStep;"                                                >> $TEMP.load.pml.ttl
#      echo "      pmlj:hasIndex 0;"                                                     >> $TEMP.load.pml.ttl
#      echo "      pmlj:hasAntecedentList ();"                                           >> $TEMP.load.pml.ttl
#      echo "      pmlj:hasSourceUsage     <${sourceUsage}_content>;"                    >> $TEMP.load.pml.ttl
#      echo "      pmlj:hasInferenceEngine conv:curl_$curlMD5;"                          >> $TEMP.load.pml.ttl
#      echo "      pmlj:hasInferenceRule   httpget:HTTP_1_1_GET;"                        >> $TEMP.load.pml.ttl
#      echo "   ];"                                                                      >> $TEMP.load.pml.ttl
#      echo "."                                                                          >> $TEMP.load.pml.ttl
#      echo                                                                              >> $TEMP.load.pml.ttl
#      echo "<${sourceUsage}_content>"                                                   >> $TEMP.load.pml.ttl
#      echo "   a pmlp:SourceUsage;"                                                     >> $TEMP.load.pml.ttl
#      echo "   pmlp:hasSource        <$redirectedURL>;"                                 >> $TEMP.load.pml.ttl
#      echo "   pmlp:hasUsageDateTime \"$usageDateTime\"^^xsd:dateTime;"                 >> $TEMP.load.pml.ttl
#      echo "."                                                                          >> $TEMP.load.pml.ttl
#   fi
#   echo " "                                                                             >> $TEMP.load.pml.ttl
#   echo "<info${requestID}_url_header>"                                                 >> $TEMP.load.pml.ttl
#   echo "   a pmlp:Information, conv:HTTPHeader;"                                       >> $TEMP.load.pml.ttl
#   echo "   pmlp:hasRawString \"\"\"$urlINFO\"\"\";"                                    >> $TEMP.load.pml.ttl
#   echo "   pmlp:hasReferenceSourceUsage <${sourceUsage}_url_header>;"                  >> $TEMP.load.pml.ttl
#   echo "."                                                                             >> $TEMP.load.pml.ttl
#   echo " "                                                                             >> $TEMP.load.pml.ttl
#   echo "<${nodeSet}_url_header>"                                                       >> $TEMP.load.pml.ttl
#   echo "   a pmlj:NodeSet;"                                                            >> $TEMP.load.pml.ttl
#   echo "   pmlj:hasConclusion <info${requestID}_url_header>;"                          >> $TEMP.load.pml.ttl
#   echo "   pmlj:isConsequentOf ["                                                      >> $TEMP.load.pml.ttl
#   echo "      a pmlj:InferenceStep;"                                                   >> $TEMP.load.pml.ttl
#   echo "      pmlj:hasIndex 0;"                                                        >> $TEMP.load.pml.ttl
##   echo "      pmlj:hasAntecedentList ();"                                              >> $TEMP.load.pml.ttl
#   echo "      pmlj:hasSourceUsage     <${sourceUsage}_url_header>;"                    >> $TEMP.load.pml.ttl
#   echo "      pmlj:hasInferenceEngine conv:curl_$curlMD5;"                             >> $TEMP.load.pml.ttl
#   echo "      pmlj:hasInferenceRule   httphead:HTTP_1_1_HEAD;"                         >> $TEMP.load.pml.ttl
#   echo "   ];"                                                                         >> $TEMP.load.pml.ttl
#   echo "."                                                                             >> $TEMP.load.pml.ttl
#   echo                                                                                 >> $TEMP.load.pml.ttl
#   echo "<${sourceUsage}_url_header>"                                                   >> $TEMP.load.pml.ttl
#   echo "   a pmlp:SourceUsage;"                                                        >> $TEMP.load.pml.ttl
#   echo "   pmlp:hasSource        <$url>;"                                              >> $TEMP.load.pml.ttl
#   echo "   pmlp:hasUsageDateTime \"$usageDateTime\"^^xsd:dateTime;"                    >> $TEMP.load.pml.ttl
#   echo "."                                                                             >> $TEMP.load.pml.ttl
#   echo                                                                                 >> $TEMP.load.pml.ttl
#   echo                                                                                 >> $TEMP.load.pml.ttl
#   echo "conv:curl_$curlMD5"                                                            >> $TEMP.load.pml.ttl
#   echo "   a pmlp:InferenceEngine, conv:Curl;"                                         >> $TEMP.load.pml.ttl
#   echo "   dcterms:identifier \"$curlMD5\";"                                           >> $TEMP.load.pml.ttl
#   echo "   dcterms:description \"\"\"`curl --version`\"\"\";"                          >> $TEMP.load.pml.ttl
#   echo "."                                                                             >> $TEMP.load.pml.ttl
#   echo                                                                                 >> $TEMP.load.pml.ttl
#   echo "conv:Curl rdfs:subClassOf pmlp:InferenceEngine ."                              >> $TEMP.load.pml.ttl
   echo --------------------------------------------------------------------------------

   if [ ${dryrun-"."} != "true" ]; then
      # TODO: move this hard path to ENV VAR.
      $assudo /opt/virtuoso/scripts/vload nt $TEMP.pml.ttl      $named_graph # How we got the file to load into store.
      $assudo /opt/virtuoso/scripts/vload nt $TEMP.nt           $named_graph # The file (in ntriples syntax).
      $assudo /opt/virtuoso/scripts/vload nt $TEMP.load.pml.ttl $named_graph # The provenance of loading it into the store.
      rm $TEMP.pml.ttl $TEMP.nt $TEMP.load.pml.ttl
   else
      echo "/opt/virtuoso/scripts/vload nt $TEMP.pml.ttl      $named_graph"
      echo "/opt/virtuoso/scripts/vload nt $TEMP.nt           $named_graph"
      echo "/opt/virtuoso/scripts/vload nt $TEMP.load.pml.ttl $named_graph"
   fi

   shift
done
