#!/bin/bash
# 
# See https://github.com/timrdf/csv2rdf4lod-automation/wiki/Script:-pcurl.sh
#
# Usage:
#
#   pcurl.sh http://www.whitehouse.gov/files/disclosures/visitors/WhiteHouse-WAVES-Key-1209.txt
#   (produces WhiteHouse-WAVES-Key-1209.txt and WhiteHouse-WAVES-Key-1209.txt.pml.ttl)
#
# Three ways to name the local file:
#   1) basename of original URL given (deprecated)
#   2) basename of final redirected URL
#   3) overriding with -n (and optional -e)
#
#   pcurl.sh <url> -e can be used to append an extension to a url that does not have one.
#
# See https://github.com/timrdf/csv2rdf4lod-automation/wiki/Script:-pcurl.sh

usage_message="usage: `basename $0` [-I] [--repeat a.pml.ttl] [url [-F \"a=b\"]* [-n name] [-e extension]]     [url [-F \"a=b\"]* [-n name] [-e extension]]*" #todo: [-from a.pml] " 

if [ $# -lt 1 ]; then
   echo $usage_message 
   echo "  -I       : do not download file; just obtain HTTP header information (c.f. curl -I)"
   echo "  url      : the URL to retrieve"
   echo "  -F       : submit POST with variable=value"
   echo "  -n       : use 'name' as the local file name."
   echo "  -e       : use 'extension' as the extension to the local file name."
   echo "  --repeat : dig into a PML file and retrieve the pmlp:Sources it describes."
   exit 1
fi

CSV2RDF4LOD_HOME=${CSV2RDF4LOD_HOME:?"not set; source csv2rdf4lod/source-me.sh or see https://github.com/timrdf/csv2rdf4lod-automation/wiki/CSV2RDF4LOD-not-set"}

downloadFile="true"
if [ $1 == "-I" ]; then
   downloadFile="."
   shift 
fi

# md5s
myMD5="md5_`$CSV2RDF4LOD_HOME/bin/util/md5.sh $0`"
curlMD5="md5_`md5.sh \`which curl\``"

logID=`java edu.rpi.tw.string.NameFactory`
while [ $# -gt 0 ]; do

   if [ "$1" == "--repeat" ]; then
      if [ $# -gt 1 ]; then
         local_pml="$2"
         shift 2
         if [ -e $local_pml ]; then
            sources=`rapper -g -o ntriples $local_pml 2>/dev/null | awk '$3 == "<http://inference-web.org/2.0/pml-provenance.owl#Source>"{if(saw[$1]!=$1){saw[$1]=$1;gsub(/<|>/,"");printf("%s",$1)}}'`
            for url in $sources; do
               echo "repeating retrieval of $url"
               $CSV2RDF4LOD_HOME/bin/util/pcurl.sh $url # It's a good day when you get to use recursion.
            done
            # TODO: dig in to find -e -n params
            # TODO: dig in to find POST att=values
         else
            echo "error: a.pml.ttl not specified"
         fi
      else
         echo "error: a.pml.ttl not specified"
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
      echo "INFO: POST fields:$formFields"
      shift 2 
   done

   #echo "PCURL: url                $url"
   localName=""
   urlBaseName=`basename $url`
   #echo "PCURL: url basename       $urlBaseName"
   flag=$2
   if [ $# -ge 3 -a ${flag:=""} == "-n" ]; then
      localName="$3"
      #echo "PCURL: -n localname       $localName"
      shift 2
   else
      localName=$urlBaseName
      #echo "PCURL: basename localname $localName"
   fi

   flag=$2
   if [ $# -ge 3 -a ${flag:=""} == "-e" ]; then
      extension=".$3"
      #echo "PCURL: -e localname       $localName$extension"
      shift 2
   else
      extension=""
      #echo "PCURL: basename localname $localName"
   fi

   #echo getting last mod xsddatetime
   urlINFO=`curl -I --globoff $url 2> /dev/null`
   urlModDateTime=`urldate.sh -field Last-Modified: -format dateTime $url`
   #echo "PCURL: URL modification date:  $urlModDateTime"

   #echo getting redirect name
   redirectedURL=`filename-v3.pl $url`
   redirectedURLINFO=`curl -I --globoff $redirectedURL 2> /dev/null`
   redirectedModDate=`urldate.sh -field Last-Modified: -format dateTime $redirectedURL`
   #echo "PCURL: http redirect basename `basename $redirectedURL`"

   #echo getting last mod
   documentVersion=`urldate.sh -field Last-Modified: $url`
   #echo "PCURL: URL mod date: $documentVersion"
   if [ ${#documentVersion} -le 3 ]; then
      documentVersion="undated"
      #echo "version: $documentVersion"
   fi

   file=`basename $redirectedURL`$extension
   if [ ${#localName} -gt 0 ]; then
      file=$localName$extension
      #echo "PCURL: local name overriding redirected name"
   fi
   #file=${localName}-$documentVersion${extension}
   #echo "INFO `basename $0`: local file name will be $file"

   if [ ! -e $file -a ${#documentVersion} -gt 0 ]; then 
      requestID=`java edu.rpi.tw.string.NameFactory`
      usageDateTime=`date +%Y-%m-%dT%H:%M:%S%z | sed 's/^\(.*\)\(..\)$/\1:\2/'`

      #echo "$url (mod $urlModDateTime)"
      #echo "$redirectedURL (mod $redirectedModDate) to $file (@ $usageDateTime)"
      # TODO: curl -H "Accept: application/rdf+xml, */*; q=0.1", but 406
      # http://dowhatimean.net/2008/03/what-is-your-rdf-browsers-accept-header
      prefRDF="" #"-H 'Accept: application/rdf+xml, */*; q=0.1'"
      #echo curl $prefRDF -L $url 
      if [ ${downloadFile:-"."} == "true" ]; then
         echo "curl -L --globoff --insecure $url $formFields ($file)"
               curl -L --globoff --insecure $url $formFields > $file
         downloadedFileMD5=`md5.sh $file`
      fi

      Eurl=`echo $url | awk '{gsub(/\//,"\\\\/");print}'`  # Escaped URL

      # Relative paths.
      sourceUsage="sourceUsage$requestID"
      nodeSet="nodeSet$requestID"
      inferenceStep="inferenceStep$requestID"
      wasControlled="wasControlledBy$requestID"

      echo
      echo "@prefix rdfs:       <http://www.w3.org/2000/01/rdf-schema#> ."                                         > $file.pml.ttl
      echo "@prefix xsd:        <http://www.w3.org/2001/XMLSchema#> ."                                            >> $file.pml.ttl
      echo "@prefix dcterms:    <http://purl.org/dc/terms/> ."                                                    >> $file.pml.ttl
      echo "@prefix pmlp:       <http://inference-web.org/2.0/pml-provenance.owl#> ."                             >> $file.pml.ttl
      echo "@prefix pmlj:       <http://inference-web.org/2.0/pml-justification.owl#> ."                          >> $file.pml.ttl
      echo "@prefix foaf:       <http://xmlns.com/foaf/0.1/> ."                                                   >> $file.pml.ttl
      echo "@prefix sioc:       <http://rdfs.org/sioc/ns#> ."                                                     >> $file.pml.ttl
      echo "@prefix oboro:      <http://obofoundry.org/ro/ro.owl#> ."                                             >> $file.pml.ttl
      echo "@prefix oprov:      <http://openprovenance.org/ontology#> ."                                          >> $file.pml.ttl
      echo "@prefix hartigprov: <http://purl.org/net/provenance/ns#> ."                                           >> $file.pml.ttl
      echo "@prefix irw:        <http://www.ontologydesignpatterns.org/ont/web/irw.owl#> ."                       >> $file.pml.ttl
      echo "@prefix nfo:        <http://www.semanticdesktop.org/ontologies/nfo/#> ."                              >> $file.pml.ttl
      echo "@prefix conv:       <http://purl.org/twc/vocab/conversion/> ."                                        >> $file.pml.ttl
      echo "@prefix httphead:   <http://inference-web.org/registry/MPR/HTTP_1_1_HEAD.owl#> ."                     >> $file.pml.ttl
      echo "@prefix httpget:    <http://inference-web.org/registry/MPR/HTTP_1_1_GET.owl#> ."                      >> $file.pml.ttl
      echo "@prefix httppost:   <http://inference-web.org/registry/MPR/HTTP_1_1_POST.owl#> ."                     >> $file.pml.ttl
      echo                                                                                                        >> $file.pml.ttl
      $CSV2RDF4LOD_HOME/bin/util/user-account.sh                                                                  >> $file.pml.ttl
      echo                                                                                                        >> $file.pml.ttl
      echo "<$url>"                                                                                               >> $file.pml.ttl
      echo "   a pmlp:Source;"                                                                                    >> $file.pml.ttl
         if [ $redirectedURL != $url ]; then
            if [ ${#urlModDateTime} -gt 3 ]; then
               echo "   pmlp:hasModificationDateTime \"$urlModDateTime\"^^xsd:dateTime;"                          >> $file.pml.ttl
            fi
            echo "   irw:redirectsTo <$redirectedURL>;"                                                           >> $file.pml.ttl
         fi
      echo "."                                                                                                    >> $file.pml.ttl
      echo                                                                                                        >> $file.pml.ttl
      echo "<$redirectedURL>"                                                                                     >> $file.pml.ttl
      echo "   a pmlp:Source;"                                                                                    >> $file.pml.ttl
         if [ ${#redirectedModDate} -gt 3 ]; then
            echo "   pmlp:hasModificationDateTime \"$redirectedModDate\"^^xsd:dateTime;"                          >> $file.pml.ttl
         fi
      echo "."                                                                                                    >> $file.pml.ttl
      echo                                                                                                        >> $file.pml.ttl
      if [ ${downloadFile:-"."} == "true" ]; then
         echo "<$file>"                                                                                           >> $file.pml.ttl
         echo "   a pmlp:Information;"                                                                            >> $file.pml.ttl
         echo "   pmlp:hasReferenceSourceUsage <${sourceUsage}_content>;"                                         >> $file.pml.ttl
         echo "."                                                                                                 >> $file.pml.ttl
         $CSV2RDF4LOD_HOME/bin/util/nfo-filehash.sh "$file"                                                       >> $file.pml.ttl
         echo                                                                                                     >> $file.pml.ttl
         echo "<${nodeSet}_content>"                                                                              >> $file.pml.ttl
         echo "   a pmlj:NodeSet;"                                                                                >> $file.pml.ttl
         echo "   pmlj:hasConclusion <$file>;"                                                                    >> $file.pml.ttl
         echo "   pmlj:isConsequentOf <${inferenceStep}_content>;"                                                >> $file.pml.ttl
         echo "."                                                                                                 >> $file.pml.ttl
         echo "<${inferenceStep}_content>"                                                                        >> $file.pml.ttl
         echo "   a pmlj:InferenceStep;"                                                                          >> $file.pml.ttl
         echo "   pmlj:hasIndex 0;"                                                                               >> $file.pml.ttl
         echo "   pmlj:hasAntecedentList ();"                                                                     >> $file.pml.ttl
         echo "   pmlj:hasSourceUsage     <${sourceUsage}_content>;"                                              >> $file.pml.ttl
         echo "   pmlj:hasInferenceEngine conv:curl_$curlMD5;"                                                    >> $file.pml.ttl
         echo "   pmlj:hasInferenceRule   http`echo $HTTP_TYPE | awk '{print tolower($0)}'`:HTTP_1_1_$HTTP_TYPE;" >> $file.pml.ttl
         echo "   oboro:has_agent          `$CSV2RDF4LOD_HOME/bin/util/user-account.sh --cite`;"                  >> $file.pml.ttl
         echo "   hartigprov:involvedActor `$CSV2RDF4LOD_HOME/bin/util/user-account.sh --cite`;"                  >> $file.pml.ttl
               for field in $formFields; do
                  if [ $field != "-F" ]; then
                     attribute=`echo $field | awk -F\= '{print $1}'`
                         value=`echo $field | awk -F\= '{print $2}'`
                     echo "metaBinding: $field is $attribute and $value"
         echo "   pmlj:hasVariableMapping [ pmlj:mapFrom \"$attribute\"; pmlj:mapTo \"$value\"; ];"               >> $file.pml.ttl
                  fi
               done
         echo "."                                                                                                 >> $file.pml.ttl
         echo                                                                                                     >> $file.pml.ttl
         echo "<${sourceUsage}_content>"                                                                          >> $file.pml.ttl
         echo "   a pmlp:SourceUsage;"                                                                            >> $file.pml.ttl
         echo "   pmlp:hasSource        <$redirectedURL>;"                                                        >> $file.pml.ttl
         echo "   pmlp:hasUsageDateTime \"$usageDateTime\"^^xsd:dateTime;"                                        >> $file.pml.ttl
         echo "."                                                                                                 >> $file.pml.ttl
         echo                                                                                                     >> $file.pml.ttl
         echo "<${wasControlled}_content>"                                                                        >> $file.pml.ttl
         echo "   a oprov:WasControlledBy;"                                                                       >> $file.pml.ttl
         echo "   oprov:cause  `$CSV2RDF4LOD_HOME/bin/util/user-account.sh --cite`;"                              >> $file.pml.ttl
         echo "   oprov:effect <${inferenceStep}_content>;"                                                       >> $file.pml.ttl
         echo "   oprov:endTime \"$usageDateTime\"^^xsd:dateTime;"                                                >> $file.pml.ttl
         echo "."                                                                                                 >> $file.pml.ttl
      fi
      echo " "                                                                                                    >> $file.pml.ttl
      echo "<info${requestID}_url_header>"                                                                        >> $file.pml.ttl
      echo "   a pmlp:Information, conv:HTTPHeader;"                                                              >> $file.pml.ttl
      echo "   pmlp:hasRawString \"\"\"$urlINFO\"\"\";"                                                           >> $file.pml.ttl
      echo "   pmlp:hasReferenceSourceUsage <${sourceUsage}_url_header>;"                                         >> $file.pml.ttl
      echo "."                                                                                                    >> $file.pml.ttl
      echo " "                                                                                                    >> $file.pml.ttl
      echo "<${nodeSet}_url_header>"                                                                              >> $file.pml.ttl
      echo "   a pmlj:NodeSet;"                                                                                   >> $file.pml.ttl
      echo "   pmlj:hasConclusion <info${requestID}_url_header>;"                                                 >> $file.pml.ttl
      echo "   pmlj:isConsequentOf <${inferenceStep}_url_header>;"                                                >> $file.pml.ttl
      echo "."                                                                                                    >> $file.pml.ttl
      echo "<${inferenceStep}_url_header>"                                                                        >> $file.pml.ttl
      echo "   a pmlj:InferenceStep;"                                                                             >> $file.pml.ttl
      echo "   pmlj:hasIndex 0;"                                                                                  >> $file.pml.ttl
      echo "   pmlj:hasAntecedentList ();"                                                                        >> $file.pml.ttl
      echo "   pmlj:hasSourceUsage     <${sourceUsage}_url_header>;"                                              >> $file.pml.ttl
      echo "   pmlj:hasInferenceEngine conv:curl_$curlMD5;"                                                       >> $file.pml.ttl
      echo "   pmlj:hasInferenceRule   httphead:HTTP_1_1_HEAD;"                                                   >> $file.pml.ttl
      echo "   oboro:has_agent          `$CSV2RDF4LOD_HOME/bin/util/user-account.sh --cite`;"                     >> $file.pml.ttl
      echo "   hartigprov:involvedActor `$CSV2RDF4LOD_HOME/bin/util/user-account.sh --cite`;"                     >> $file.pml.ttl
      echo "."                                                                                                    >> $file.pml.ttl
      echo                                                                                                        >> $file.pml.ttl
      echo "<${sourceUsage}_url_header>"                                                                          >> $file.pml.ttl
      echo "   a pmlp:SourceUsage;"                                                                               >> $file.pml.ttl
      echo "   pmlp:hasSource        <$url>;"                                                                     >> $file.pml.ttl
      echo "   pmlp:hasUsageDateTime \"$usageDateTime\"^^xsd:dateTime;"                                           >> $file.pml.ttl
      echo "."                                                                                                    >> $file.pml.ttl
      echo "<${wasControlled}_url_header>"                                                                        >> $file.pml.ttl
      echo "   a oprov:WasControlledBy;"                                                                          >> $file.pml.ttl
      echo "   oprov:cause  `$CSV2RDF4LOD_HOME/bin/util/user-account.sh --cite`;"                                 >> $file.pml.ttl
      echo "   oprov:effect <${nodeSet}_url_header>;"                                                             >> $file.pml.ttl
      echo "   oprov:endTime \"$usageDateTime\"^^xsd:dateTime;"                                                   >> $file.pml.ttl
      echo "."                                                                                                    >> $file.pml.ttl
      echo                                                                                                        >> $file.pml.ttl
         if [ $redirectedURL != $url ]; then
            echo "<info${requestID}_redirected_url_header>"                                                       >> $file.pml.ttl
            echo "   a pmlp:Information, conv:HTTPHeader;"                                                        >> $file.pml.ttl
            echo "   pmlp:hasRawString \"\"\"$redirectedURLINFO\"\"\";"                                           >> $file.pml.ttl
            echo "   pmlp:hasReferenceSourceUsage <${sourceUsage}_redirected_url_header>;"                        >> $file.pml.ttl
            echo "."                                                                                              >> $file.pml.ttl
            echo                                                                                                  >> $file.pml.ttl
            echo "<${nodeSet}_redirected_url_header>"                                                             >> $file.pml.ttl
            echo "   a pmlj:NodeSet;"                                                                             >> $file.pml.ttl
            echo "   pmlj:hasConclusion <info${requestID}_redirected_url_header>;"                                >> $file.pml.ttl
            echo "   pmlj:isConsequentOf <${inferenceStep}_redirected_url_header>;"                               >> $file.pml.ttl
            echo "."                                                                                              >> $file.pml.ttl
            echo "<${inferenceStep}_redirected_url_header>"                                                       >> $file.pml.ttl
            echo "   a pmlj:InferenceStep;"                                                                       >> $file.pml.ttl
            echo "   pmlj:hasIndex 0;"                                                                            >> $file.pml.ttl
            echo "   pmlj:hasAntecedentList ();"                                                                  >> $file.pml.ttl
            echo "   pmlj:hasSourceUsage     <${sourceUsage}_redirected_url_header>;"                             >> $file.pml.ttl
            echo "   pmlj:hasInferenceEngine conv:curl_$curlMD5;"                                                 >> $file.pml.ttl
            echo "   pmlj:hasInferenceRule   httphead:HTTP_1_1_HEAD;"                                             >> $file.pml.ttl
            echo "   oboro:has_agent          `$CSV2RDF4LOD_HOME/bin/util/user-account.sh --cite`;"               >> $file.pml.ttl
            echo "   hartigprov:involvedActor `$CSV2RDF4LOD_HOME/bin/util/user-account.sh --cite`;"               >> $file.pml.ttl
            echo "."                                                                                              >> $file.pml.ttl
            echo                                                                                                  >> $file.pml.ttl
            echo "<${sourceUsage}_redirected_url_header>"                                                         >> $file.pml.ttl
            echo "   a pmlp:SourceUsage;"                                                                         >> $file.pml.ttl
            echo "   pmlp:hasSource        <$redirectedURL>;"                                                     >> $file.pml.ttl
            echo "   pmlp:hasUsageDateTime \"$usageDateTime\"^^xsd:dateTime;"                                     >> $file.pml.ttl
            echo "."                                                                                              >> $file.pml.ttl
            echo "<${wasControlled}_redirected_url_header>"                                                       >> $file.pml.ttl
            echo "   a oprov:WasControlledBy;"                                                                    >> $file.pml.ttl
            echo "   oprov:cause  `$CSV2RDF4LOD_HOME/bin/util/user-account.sh --cite`;"                           >> $file.pml.ttl
            echo "   oprov:effect <${inferenceStep}_redirected_url_header>;"                                      >> $file.pml.ttl
            echo "   oprov:endTime \"$usageDateTime\"^^xsd:dateTime;"                                             >> $file.pml.ttl
            echo "."                                                                                              >> $file.pml.ttl
         fi
      echo                                                                                                        >> $file.pml.ttl
      echo "conv:curl_$curlMD5"                                                                                   >> $file.pml.ttl
      echo "   a pmlp:InferenceEngine, conv:Curl;"                                                                >> $file.pml.ttl
      echo "   dcterms:identifier \"$curlMD5\";"                                                                  >> $file.pml.ttl
      echo "   dcterms:description \"\"\"`curl --version`\"\"\";"                                                 >> $file.pml.ttl
      echo "."                                                                                                    >> $file.pml.ttl
      echo                                                                                                        >> $file.pml.ttl
      echo "conv:Curl rdfs:subClassOf pmlp:InferenceEngine ."                                                     >> $file.pml.ttl
   elif [ ! -e $file ]; then
      echo "could not obtain dataset version."
   else 
      echo "$file already exists."
   fi
   echo "\\\\\\\\\\------------------------------ `basename $0`  ------------------------------/////"
   shift
done
