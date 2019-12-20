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
# See https://github.com/timrdf/csv2rdf4lod-automation/wiki/Script:-pcurl.sh
#
# Usage:
#
#   pcurl.sh http://www.whitehouse.gov/files/disclosures/visitors/WhiteHouse-WAVES-Key-1209.txt
#   (produces WhiteHouse-WAVES-Key-1209.txt and WhiteHouse-WAVES-Key-1209.txt.prov.ttl)
#
# Three ways to name the local file:
#   1) basename of original URL given (deprecated)
#   2) basename of final redirected URL
#   3) overriding with -n (and optional -e)
#
#   pcurl.sh <url> -e can be used to append an extension to a url that does not have one.
#
# See https://github.com/timrdf/csv2rdf4lod-automation/wiki/Script:-pcurl.sh

usage_message="usage: `basename $0` [-I] [--repeat a.prov.ttl] [url [-F \"a=b\"]* [-n name] [-e extension]]     [url [-F \"a=b\"]* [-n name] [-e extension]]*" #todo: [-from a.prov] " 

if [ $# -lt 1 ]; then
   echo $usage_message 
   echo "  -I       : do not download file; just obtain HTTP header information (c.f. curl -I)"
   echo "  url      : the URL to retrieve"
   echo "  -F       : submit POST with variable=value"
   echo "  -n       : use 'name' as the local file name."
   echo "  -e       : use 'extension' as the extension to the local file name."
   echo "  --dig    : dig into a PML file and print the URL that was retrieved."
   echo "  --repeat : dig into a PML file and retrieve the pmlp:Sources it describes."
   exit 1
fi

function log {
   message="$1"
   if [[ -n "$CSV2RDF4LOD_CONVERT_DEBUG_LEVEL" ]]; then
      echo $message
   fi
}

see='https://github.com/timrdf/csv2rdf4lod-automation/wiki/CSV2RDF4LOD-not-set'
CSV2RDF4LOD_HOME=${CSV2RDF4LOD_HOME:?"not set; source csv2rdf4lod/source-me.sh or see $see"}
CLASSPATH=$CLASSPATH`$CSV2RDF4LOD_HOME/bin/util/cr-situate-classpaths.sh`

downloadFile="true"
if [ $1 == "-I" ]; then
   downloadFile="."
   shift 
fi

# md5s
myMD5="md5_`$CSV2RDF4LOD_HOME/bin/util/md5.sh $0`"
curlMD5="md5_`md5.sh \`which curl\``"

logID=`resource-name.sh`
while [ $# -gt 0 ]; do

   if [ "$1" == "--repeat" ]; then
      if [ $# -gt 1 ]; then
         local_prov="$2"
         shift 2
         if [ -e $local_prov ]; then
            sources=`rapper -g -o ntriples $local_prov 2>/dev/null | awk '$3 == "<http://inference-web.org/2.0/pml-provenance.owl#Source>"{if(saw[$1]!=$1){saw[$1]=$1;gsub(/<|>/,"");printf("%s",$1)}}'`
            for url in $sources; do
               echo "repeating retrieval of $url"
               $CSV2RDF4LOD_HOME/bin/util/pcurl.sh $url # Recursive call
            done
            # TODO: dig in to find -e -n params
            # TODO: dig in to find POST att=values
         else
            echo "error: a.prov.ttl not specified"
         fi
      else
         echo "error: a.prov.ttl not specified"
         shift
      fi
   fi
   if [ $# -eq 0 ]; then
      exit # Nothing to do after the --repeat
   fi

   echo
   echo "/////------------------------------ `basename $0`  ------------------------------\\\\\\\\\\"
   url="$1"
 
   HTTP_TYPE="GET"
   formFields=""
   while [ "$2" == "-F" -a $# -ge 3 ]; do
      HTTP_TYPE="POST"
      formFields="$formFields -F $3"
      echo "[INFO] POST fields:$formFields"
      shift 2 
   done

   #echo "Finding content-dispostion of $url" >&2
   log "Content-Disposition:..."
   dispositionFileName=`curl -sLI "$url" | grep 'Content-Disposition:' | tail -1 | sed 's/^.*filename=//; s/\s*$//; s/^"//; s/".*$//'`
   log "Content-Disposition: --$dispositionFileName--"

   #echo "PCURL: url                $url"
   localName=""
   urlBaseName=`basename $url`
   #echo "PCURL: url basename       $urlBaseName"
   flag=$2
   if [ $# -ge 3 -a "$flag" == "-n" ]; then
      localName="$3"
      #echo "PCURL: -n localname       $localName"
      shift 2
   elif [[ -n "$dispositionFileName" ]]; then
      localName="$dispositionFileName"
   else
      localName=$urlBaseName
      #echo "PCURL: basename localname $localName"
   fi

   flag=$2
   if [ $# -ge 3 -a "$flag" == "-e" ]; then
      extension=".$3"
      #echo "PCURL: -e localname       $localName$extension"
      shift 2
   else
      extension=""
      #echo "PCURL: basename localname $localName"
   fi

   log "HTTP HEAD..."
   urlINFO=`curl -I --globoff "$url" 2> /dev/null | grep -v 'Set-Cookie'`
   log "Last-Modified:..."
   urlModDateTime=`urldate.sh -field Last-Modified: -format dateTime "$url"`
   log "Last-Modified: $urlModDateTime"

   log "Redirect?..."
   redirectedURL=`filename-v3.pl "$url"`
   log "HTTP HEAD (redirect) $redirectedURL"
   redirectedURLINFO=`curl -I --globoff $redirectedURL 2> /dev/null`
   log "Last-Modified:... (redirect)"
   redirectedModDate=`urldate.sh -field Last-Modified: -format dateTime $redirectedURL`
   log "Last-Modified: $redirectedModDate"

   log "Last-Modified:... ($url)"
   documentVersion=`urldate.sh -field Last-Modified: $url`
   log "PCURL: URL mod date: $documentVersion"
   if [ ${#documentVersion} -le 3 ]; then
      documentVersion="undated"
   fi

   file=`basename $redirectedURL`$extension
   if [[ -n "$localName" ]]; then
      # Either b/c of -n flag, or by Content-Disposition response header.
      file=$localName$extension
      file="$(echo -e "${file}" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')" # https://stackoverflow.com/a/3232433
      log "PCURL: local name overriding redirected name"
   fi
   #file=${localName}-$documentVersion${extension}
   log "[INFO] `basename $0`: local file name will be $file"

   if [ ! -e "$file" -a ${#documentVersion} -gt 0 ]; then 
      requestID=`resource-name.sh`
      #usageDateTime=`date +%Y-%m-%dT%H:%M:%S%z | sed 's/^\(.*\)\(..\)$/\1:\2/'` # TODO: why not use dateInXSDDateTime.sh  ?

      # https://github.com/timrdf/csv2rdf4lod-automation/wiki/PROV-URI-Templates#provquotation
      usageDateTime=`dateInXSDDateTime.sh`
      usageDateTimePath=`dateInXSDDateTime.sh --uri-path $usageDateTime`

      log "$url (mod $urlModDateTime)"
      log "$redirectedURL (mod $redirectedModDate) to $file (@ $usageDateTime)"
      # TODO: curl -H "Accept: application/rdf+xml, */*; q=0.1", but 406
      # http://dowhatimean.net/2008/03/what-is-your-rdf-browsers-accept-header
      prefRDF="" #"-H 'Accept: application/rdf+xml, */*; q=0.1'"
      log "curl $prefRDF -L $url"
      if [ "$downloadFile" == "true" ]; then
         echo "curl -sL --globoff --insecure $url $formFields ($file)"
               curl -sL --globoff --insecure $url $formFields > $file
         downloadedFileMD5=`md5.sh $file`
      fi

      Eurl=`echo $url | awk '{gsub(/\//,"\\\\/");print}'`  # Escaped URL

      # Relative paths.
      #quotation="quotation_$requestID"
      # https://github.com/timrdf/csv2rdf4lod-automation/wiki/PROV-URI-Templates#provquotation
      quotation=${CSV2RDF4LOD_BASE_URI_OVERRIDE:-$CSV2RDF4LOD_BASE_URI}/id/url/`md5.sh -qs "$url"`/quoted/$usageDateTimePath
      sourceUsage="sourceUsage$requestID"
      nodeSet="nodeSet$requestID"
      inferenceStep="inferenceStep$requestID"
      wasControlled="wasControlledBy$requestID"

      echo "@prefix rdfs:       <http://www.w3.org/2000/01/rdf-schema#> ."                                         > $file.prov.ttl
      echo "@prefix xsd:        <http://www.w3.org/2001/XMLSchema#> ."                                            >> $file.prov.ttl
      echo "@prefix dcterms:    <http://purl.org/dc/terms/> ."                                                    >> $file.prov.ttl
      echo "@prefix pmlp:       <http://inference-web.org/2.0/pml-provenance.owl#> ."                             >> $file.prov.ttl
      echo "@prefix pmlj:       <http://inference-web.org/2.0/pml-justification.owl#> ."                          >> $file.prov.ttl
      echo "@prefix foaf:       <http://xmlns.com/foaf/0.1/> ."                                                   >> $file.prov.ttl
      echo "@prefix sioc:       <http://rdfs.org/sioc/ns#> ."                                                     >> $file.prov.ttl
      echo "@prefix oboro:      <http://obofoundry.org/ro/ro.owl#> ."                                             >> $file.prov.ttl
      echo "@prefix oprov:      <http://openprovenance.org/ontology#> ."                                          >> $file.prov.ttl
      echo "@prefix hartigprov: <http://purl.org/net/provenance/ns#> ."                                           >> $file.prov.ttl
      echo "@prefix irw:        <http://www.ontologydesignpatterns.org/ont/web/irw.owl#> ."                       >> $file.prov.ttl
      echo "@prefix nfo:        <http://www.semanticdesktop.org/ontologies/nfo/#> ."                              >> $file.prov.ttl
      echo "@prefix conv:       <http://purl.org/twc/vocab/conversion/> ."                                        >> $file.prov.ttl
      echo "@prefix httphead:   <http://inference-web.org/registry/MPR/HTTP_1_1_HEAD.owl#> ."                     >> $file.prov.ttl
      echo "@prefix httpget:    <http://inference-web.org/registry/MPR/HTTP_1_1_GET.owl#> ."                      >> $file.prov.ttl
      echo "@prefix httppost:   <http://inference-web.org/registry/MPR/HTTP_1_1_POST.owl#> ."                     >> $file.prov.ttl
      echo "@prefix prv:        <http://purl.org/net/provenance/ns#>."                                            >> $file.prov.ttl
      echo "@prefix prov:       <http://www.w3.org/ns/prov#> ."                                                   >> $file.prov.ttl
      echo                                                                                                        >> $file.prov.ttl
      $CSV2RDF4LOD_HOME/bin/util/user-account.sh                                                                  >> $file.prov.ttl
      echo                                                                                                        >> $file.prov.ttl
      echo "<$url>"                                                                                               >> $file.prov.ttl
      echo "   a prov:Entity;"                                                                                    >> $file.prov.ttl
         if [ "$redirectedURL" != "$url" ]; then
            if [ ${#urlModDateTime} -gt 3 ]; then
               echo "   pmlp:hasModificationDateTime \"$urlModDateTime\"^^xsd:dateTime;"                          >> $file.prov.ttl
               echo "   dcterms:modified             \"$urlModDateTime\"^^xsd:dateTime;"                          >> $file.prov.ttl
            fi
            echo "   irw:redirectsTo <$redirectedURL>;"                                                           >> $file.prov.ttl
         fi
      echo "."                                                                                                    >> $file.prov.ttl
      echo                                                                                                        >> $file.prov.ttl
      echo "<$redirectedURL>"                                                                                     >> $file.prov.ttl
      echo "   a prov:Entity;"                                                                                    >> $file.prov.ttl
         if [ ${#redirectedModDate} -gt 3 ]; then
            echo "   dcterms:modified \"$redirectedModDate\"^^xsd:dateTime;"                                      >> $file.prov.ttl
         fi
      echo "."                                                                                                    >> $file.prov.ttl
      echo                                                                                                        >> $file.prov.ttl
      if [ "$downloadFile" == "true" ]; then
         fileSpecializationURI=`$CSV2RDF4LOD_HOME/bin/util/nfo-filehash.sh --foci "$file"`
         echo "$fileSpecializationURI"                                                                            >> $file.prov.ttl
         echo "   a nfo:FileDataObject, prov:Entity;"                                                             >> $file.prov.ttl
         #echo "   prv:serializedBy        <$file>;"                                                               >> $file.prov.ttl
         echo "   prov:wasQuotedFrom      <$redirectedURL>;"                                                      >> $file.prov.ttl
         echo "   prov:qualifiedQuotation <${quotation}>;"                                                        >> $file.prov.ttl
         #echo "   pmlp:hasReferenceSourceUsage <${sourceUsage}_content>;"                                        >> $file.prov.ttl
         echo "."                                                                                                 >> $file.prov.ttl
         $CSV2RDF4LOD_HOME/bin/util/nfo-filehash.sh "$file"                                                       >> $file.prov.ttl
         echo                                                                                                     >> $file.prov.ttl
         echo "<${nodeSet}_content>"                                                                              >> $file.prov.ttl
         echo "   a pmlj:NodeSet;"                                                                                >> $file.prov.ttl
         echo "   pmlj:hasConclusion $fileSpecializationURI;"                                                     >> $file.prov.ttl
         echo "   pmlj:isConsequentOf <${inferenceStep}_content>;"                                                >> $file.prov.ttl
         echo "."                                                                                                 >> $file.prov.ttl
         echo "<${inferenceStep}_content>"                                                                        >> $file.prov.ttl
         echo "   a pmlj:InferenceStep;"                                                                          >> $file.prov.ttl
         echo "   pmlj:hasIndex 0;"                                                                               >> $file.prov.ttl
         echo "   pmlj:hasAntecedentList ();"                                                                     >> $file.prov.ttl
         echo "   pmlj:hasSourceUsage     <${sourceUsage}_content>;"                                              >> $file.prov.ttl
         echo "   pmlj:hasInferenceEngine conv:curl_$curlMD5;"                                                    >> $file.prov.ttl
         echo "   pmlj:hasInferenceRule   http`echo $HTTP_TYPE | awk '{print tolower($0)}'`:HTTP_1_1_$HTTP_TYPE;" >> $file.prov.ttl
         echo "   oboro:has_agent          `$CSV2RDF4LOD_HOME/bin/util/user-account.sh --cite`;"                  >> $file.prov.ttl
         echo "   hartigprov:involvedActor `$CSV2RDF4LOD_HOME/bin/util/user-account.sh --cite`;"                  >> $file.prov.ttl
               for field in $formFields; do
                  if [ $field != "-F" ]; then
                     attribute=`echo $field | awk -F\= '{print $1}'`
                         value=`echo $field | awk -F\= '{print $2}'`
                     echo "metaBinding: $field is $attribute and $value"
         echo "   pmlj:hasVariableMapping [ pmlj:mapFrom \"$attribute\"; pmlj:mapTo \"$value\"; ];"               >> $file.prov.ttl
                  fi
               done
         echo "."                                                                                                 >> $file.prov.ttl
         echo                                                                                                     >> $file.prov.ttl
         echo "<${quotation}>"                                                                                    >> $file.prov.ttl
         echo "   a prov:Quotation;"                                                                              >> $file.prov.ttl
         echo "   prov:entity <$redirectedURL>;"                                                                  >> $file.prov.ttl
         echo "   prov:atTime \"$usageDateTime\"^^xsd:dateTime;"                                                  >> $file.prov.ttl
         echo "."                                                                                                 >> $file.prov.ttl
         echo                                                                                                     >> $file.prov.ttl
         #echo "<${sourceUsage}_content>"                                                                         >> $file.prov.ttl
         #echo "   a pmlp:SourceUsage;"                                                                           >> $file.prov.ttl
         #echo "   pmlp:hasSource        <$redirectedURL>;"                                                       >> $file.prov.ttl
         #echo "   pmlp:hasUsageDateTime \"$usageDateTime\"^^xsd:dateTime;"                                       >> $file.prov.ttl
         #echo "."                                                                                                >> $file.prov.ttl
         echo                                                                                                     >> $file.prov.ttl
         echo "<${wasControlled}_content>"                                                                        >> $file.prov.ttl
         echo "   a oprov:WasControlledBy;"                                                                       >> $file.prov.ttl
         echo "   oprov:cause  `$CSV2RDF4LOD_HOME/bin/util/user-account.sh --cite`;"                              >> $file.prov.ttl
         echo "   oprov:effect <${inferenceStep}_content>;"                                                       >> $file.prov.ttl
         echo "   oprov:endTime \"$usageDateTime\"^^xsd:dateTime;"                                                >> $file.prov.ttl
         echo "."                                                                                                 >> $file.prov.ttl
      fi
      echo " "                                                                                                    >> $file.prov.ttl
      echo "<info${requestID}_url_header>"                                                                        >> $file.prov.ttl
      echo "   a prov:Entity, conv:HTTPHeader;"                                                                   >> $file.prov.ttl
      echo "   prov:value \"\"\"$urlINFO\"\"\";"                                                                  >> $file.prov.ttl
      echo "   pmlp:hasReferenceSourceUsage <${sourceUsage}_url_header>;"                                         >> $file.prov.ttl
      echo "."                                                                                                    >> $file.prov.ttl
      echo " "                                                                                                    >> $file.prov.ttl
      echo "<${nodeSet}_url_header>"                                                                              >> $file.prov.ttl
      echo "   a pmlj:NodeSet;"                                                                                   >> $file.prov.ttl
      echo "   pmlj:hasConclusion <info${requestID}_url_header>;"                                                 >> $file.prov.ttl
      echo "   pmlj:isConsequentOf <${inferenceStep}_url_header>;"                                                >> $file.prov.ttl
      echo "."                                                                                                    >> $file.prov.ttl
      echo "<${inferenceStep}_url_header>"                                                                        >> $file.prov.ttl
      echo "   a pmlj:InferenceStep;"                                                                             >> $file.prov.ttl
      echo "   pmlj:hasIndex 0;"                                                                                  >> $file.prov.ttl
      echo "   pmlj:hasAntecedentList ();"                                                                        >> $file.prov.ttl
      echo "   pmlj:hasSourceUsage     <${sourceUsage}_url_header>;"                                              >> $file.prov.ttl
      echo "   pmlj:hasInferenceEngine conv:curl_$curlMD5;"                                                       >> $file.prov.ttl
      echo "   pmlj:hasInferenceRule   httphead:HTTP_1_1_HEAD;"                                                   >> $file.prov.ttl
      echo "   oboro:has_agent          `$CSV2RDF4LOD_HOME/bin/util/user-account.sh --cite`;"                     >> $file.prov.ttl
      echo "   hartigprov:involvedActor `$CSV2RDF4LOD_HOME/bin/util/user-account.sh --cite`;"                     >> $file.prov.ttl
      echo "."                                                                                                    >> $file.prov.ttl
      echo                                                                                                        >> $file.prov.ttl
      echo "<${sourceUsage}_url_header>"                                                                          >> $file.prov.ttl
      echo "   a pmlp:SourceUsage;"                                                                               >> $file.prov.ttl
      echo "   pmlp:hasSource        <$url>;"                                                                     >> $file.prov.ttl
      echo "   pmlp:hasUsageDateTime \"$usageDateTime\"^^xsd:dateTime;"                                           >> $file.prov.ttl
      echo "."                                                                                                    >> $file.prov.ttl
      echo "<${wasControlled}_url_header>"                                                                        >> $file.prov.ttl
      echo "   a oprov:WasControlledBy;"                                                                          >> $file.prov.ttl
      echo "   oprov:cause  `$CSV2RDF4LOD_HOME/bin/util/user-account.sh --cite`;"                                 >> $file.prov.ttl
      echo "   oprov:effect <${nodeSet}_url_header>;"                                                             >> $file.prov.ttl
      echo "   oprov:endTime \"$usageDateTime\"^^xsd:dateTime;"                                                   >> $file.prov.ttl
      echo "."                                                                                                    >> $file.prov.ttl
      echo                                                                                                        >> $file.prov.ttl
         if [ "$redirectedURL" != "$url" ]; then
            echo "<info${requestID}_redirected_url_header>"                                                       >> $file.prov.ttl
            echo "   a prov:Entity, conv:HTTPHeader;"                                                             >> $file.prov.ttl
            echo "   prov:value \"\"\"$redirectedURLINFO\"\"\";"                                                  >> $file.prov.ttl
            echo "   pmlp:hasReferenceSourceUsage <${sourceUsage}_redirected_url_header>;"                        >> $file.prov.ttl
            echo "."                                                                                              >> $file.prov.ttl
            echo                                                                                                  >> $file.prov.ttl
            echo "<${nodeSet}_redirected_url_header>"                                                             >> $file.prov.ttl
            echo "   a pmlj:NodeSet;"                                                                             >> $file.prov.ttl
            echo "   pmlj:hasConclusion <info${requestID}_redirected_url_header>;"                                >> $file.prov.ttl
            echo "   pmlj:isConsequentOf <${inferenceStep}_redirected_url_header>;"                               >> $file.prov.ttl
            echo "."                                                                                              >> $file.prov.ttl
            echo "<${inferenceStep}_redirected_url_header>"                                                       >> $file.prov.ttl
            echo "   a pmlj:InferenceStep;"                                                                       >> $file.prov.ttl
            #echo "   pmlj:hasIndex 0;"                                                                            >> $file.prov.ttl
            #echo "   pmlj:hasAntecedentList ();"                                                                  >> $file.prov.ttl
            echo "   pmlj:hasSourceUsage     <${sourceUsage}_redirected_url_header>;"                             >> $file.prov.ttl
            echo "   pmlj:hasInferenceEngine conv:curl_$curlMD5;"                                                 >> $file.prov.ttl
            echo "   pmlj:hasInferenceRule   httphead:HTTP_1_1_HEAD;"                                             >> $file.prov.ttl
            echo "   oboro:has_agent          `$CSV2RDF4LOD_HOME/bin/util/user-account.sh --cite`;"               >> $file.prov.ttl
            echo "   hartigprov:involvedActor `$CSV2RDF4LOD_HOME/bin/util/user-account.sh --cite`;"               >> $file.prov.ttl
            echo "."                                                                                              >> $file.prov.ttl
            echo                                                                                                  >> $file.prov.ttl
            echo "<${sourceUsage}_redirected_url_header>"                                                         >> $file.prov.ttl
            echo "   a pmlp:SourceUsage;"                                                                         >> $file.prov.ttl
            echo "   pmlp:hasSource        <$redirectedURL>;"                                                     >> $file.prov.ttl
            echo "   pmlp:hasUsageDateTime \"$usageDateTime\"^^xsd:dateTime;"                                     >> $file.prov.ttl
            echo "."                                                                                              >> $file.prov.ttl
            echo "<${wasControlled}_redirected_url_header>"                                                       >> $file.prov.ttl
            echo "   a oprov:WasControlledBy;"                                                                    >> $file.prov.ttl
            echo "   oprov:cause  `$CSV2RDF4LOD_HOME/bin/util/user-account.sh --cite`;"                           >> $file.prov.ttl
            echo "   oprov:effect <${inferenceStep}_redirected_url_header>;"                                      >> $file.prov.ttl
            echo "   oprov:endTime \"$usageDateTime\"^^xsd:dateTime;"                                             >> $file.prov.ttl
            echo "."                                                                                              >> $file.prov.ttl
         fi
      echo                                                                                                        >> $file.prov.ttl
      echo "conv:curl_$curlMD5"                                                                                   >> $file.prov.ttl
      echo "   a prov:Agent, pmlp:InferenceEngine, conv:Curl;"                                                    >> $file.prov.ttl
      echo "   dcterms:identifier \"$curlMD5\";"                                                                  >> $file.prov.ttl
      echo "   dcterms:description \"\"\"`curl --version`\"\"\";"                                                 >> $file.prov.ttl
      echo "."                                                                                                    >> $file.prov.ttl
      echo                                                                                                        >> $file.prov.ttl
      echo "conv:Curl rdfs:subClassOf pmlp:InferenceEngine ."                                                     >> $file.prov.ttl
   elif [ ! -e "$file" ]; then
      echo "could not obtain dataset version."
   else 
      echo "$file already exists."
   fi
   echo "\\\\\\\\\\------------------------------ `basename $0`  ------------------------------/////"
   shift
done
