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
# Usage:
#
#   justify.sh 

if [ $# -lt 3 -o $# -gt 4 ]; then
   echo "usage:   `basename $0` /path/to/source/a.xls /path/to/destination/a.xls.csv <engine-name>" 
   echo "or" 
   echo "usage: . `basename $0` /path/to/source/a.xls /path/to/destination/a.xls.csv <engine-name> [-h | --history]" 
   echo ""
   echo "   source      file: a file used to create 'destination file'."
   echo ""
   echo "   destination file: a file derived from 'source file'."
   echo ""
   echo "   engine-name     : URI-friendly local name of method used to create destination from source:"
   echo "      xls2csv,   tab2comma,     redelimit,            file_rename,   escaping_commas_redelimit"
   echo "      duplicate, google_refine, serialization_change, parse_field,   tabulating_fixed_width"
   echo "      html_tidy, pretty_print,  xsl_html_scrape,      manual_csvify, uncompress"
   echo "      select_subset, etc."
   echo ""
   echo "   --history: search command history for the command that created 'destination-file' "
   echo "              from 'source-file' and include it in the provenance."
   echo "              NOTE: a period (.) must precede the `basename $0` command to access history."
else

   CSV2RDF4LOD_HOME=${CSV2RDF4LOD_HOME:?"not set; source csv2rdf4lod/source-me.sh or see https://github.com/timrdf/csv2rdf4lod-automation/wiki/CSV2RDF4LOD-not-set"}

   if [ $0 == "bash" ]; then
      # In case of --history's . invocation
      myMD5=`md5.sh $CSV2RDF4LOD_HOME/bin/util/justify.sh` 
   else
      # In case of no --history
      myMD5=`md5.sh $0`
   fi

   alias rname="java edu.rpi.tw.string.NameFactory"
   logID=`java edu.rpi.tw.string.NameFactory`

   antecedent="$1"
   consequent="$2"

   if [[ ${3:-"."} == "-h" || ${3:-"."} == "--history" ]]; then
      echo "ERROR: Requested -h --history, but did not specify <engine-name>."
   else
      method="`echo $3 | awk '{print tolower($0)}'`"                                                           # e.g., 'serialization_change'
      method_name="conv:${method}_Method"                                                                      # e.g., 'serialization_change_Method'
      engine_type="conv:`echo $method | awk '{print toupper(substr($0,0,1)) substr($0,2,length($0))}'`_Engine" # e.g.  'Serialization_change_Engine

      echo "my MD5     : $myMD5"
      echo "antecedent : $antecedent"
      echo "consequent : $consequent"
      echo "method     : $method"
      echo "method name: $method_name"
      echo "engine type: $engine_type"

      commandUsed=""
      if [ $# -ge 4 ]; then
         if [ ${4:-"."} == "-h" -o ${4:-"."} == "--history" ]; then
            if [ `history | wc -l` -gt 0 ]; then
               commandUsed=`history | grep -v "justify.sh" | grep "$antecedent" | grep "$consequent" | tail -1`

               if [ ${#commandUsed} -lt 1 ]; then
                  # If we didn't find one for both, find one with just the consequent.
                  commandUsed=`history | grep -v "justify.sh" | grep "$consequent" | tail -1`
               fi
               if [ ${#commandUsed} -lt 1 ]; then
                  # If we didn't find one for both, find one with just the consequent.
                  commandUsed=`history | grep -v "justify.sh" | grep "$antecedent" | tail -1`
               fi
               # history command gives a command number: 511 cat source/NUTR_DEF.txt
               #   we want remove that:                      cat source/NUTR_DEF.txt
               commandUsed=`echo $commandUsed | sed 's/^ *[^ ]* *//'`
               commandUsed=`echo $commandUsed | sed 's/\\\\/\\\\\\\\/g'` # If the command has "s/~\^~/" we need to escape the escapes to "s/~\\^~/\"
               #commandUsed=`echo $commandUsed | sed 's/"/\\\\"/g'` #was around until feb 2012
            else
               echo "    ERROR: `basename $0` could not access history. "
               echo "    Invoke `basename $0` with a period:"
               echo "    . `basename $0` $*"
               capture="no"
            fi
         fi
      fi

      if [ ! -e $antecedent ]; then
         echo "$antecedent does not exist; no justifications asserted."
         capture="no"
      fi
      if [ ! -e $consequent ]; then
         echo "$consequent does not exist; no justifications asserted."
         capture="no"
      fi
      echo
      if [ "$capture" != "no" ]; then
         echo ---------------------------------- justify ---------------------------------------
         if [ `man stat | grep 'BSD General Commands Manual' | wc -l` -gt 0 ]; then
            # mac version
            antecedentModDateTime=`stat -t "%Y-%m-%dT%H:%M:%S%z" $antecedent | awk '{gsub(/"/,"");print $9}' | sed 's/^\(.*\)\(..\)$/\1:\2/'`
            consequentModDateTime=`stat -t "%Y-%m-%dT%H:%M:%S%z" $consequent | awk '{gsub(/"/,"");print $9}' | sed 's/^\(.*\)\(..\)$/\1:\2/'`
         elif [ `man stat | grep '%y     Time of last modification' | wc -l` -gt 0 ]; then
            # some other unix version
            antecedentModDateTime=`stat -c "%y" $antecedent | sed -e 's/ /T/' -e 's/\..* / /' -e 's/ //' -e 's/\(..\)$/:\1/'`
            consequentModDateTime=`stat -c "%y" $consequent | sed -e 's/ /T/' -e 's/\..* / /' -e 's/ //' -e 's/\(..\)$/:\1/'`
         fi

         usageDateTime=`$CSV2RDF4LOD_HOME/bin/util/dateInXSDDateTime.sh`
         requestID=`java edu.rpi.tw.string.NameFactory`
         engine_name="$method$requestID"

         echo "$antecedent (a $engine_type applying $method_name) -> $consequent"
         echo $consequent came from $antecedent
         echo "$antecedent -> $consequent"
         if [ ${#commandUsed} -gt 0 ]; then
            echo $commandUsed
         fi

         # Relative paths.
         consequentURI="<`basename $consequent`>"
         sourceUsage="<sourceUsage$requestID>"
         nodeSet="<nodeSet$requestID>"
         antecedentNodeSet="<nodeSet${requestID}_antecedent>"
         userNodeSet="<nodeSet${requestID}_user>"

         echo "@prefix rdfs:       <http://www.w3.org/2000/01/rdf-schema#> ."                     > $consequent.pml.ttl
         echo "@prefix xsd:        <http://www.w3.org/2001/XMLSchema#> ."                        >> $consequent.pml.ttl
         echo "@prefix foaf:       <http://xmlns.com/foaf/0.1/> ."                               >> $consequent.pml.ttl
         echo "@prefix dcterms:    <http://purl.org/dc/terms/> ."                                >> $consequent.pml.ttl
         echo "@prefix sioc:       <http://rdfs.org/sioc/ns#> ."                                 >> $consequent.pml.ttl
         echo "@prefix pmlp:       <http://inference-web.org/2.0/pml-provenance.owl#> ."         >> $consequent.pml.ttl
         echo "@prefix oboro:      <http://obofoundry.org/ro/ro.owl#> ."                         >> $consequent.pml.ttl
         echo "@prefix oprov:      <http://openprovenance.org/ontology#> ."                      >> $consequent.pml.ttl
         echo "@prefix hartigprov: <http://purl.org/net/provenance/ns#> ."                       >> $consequent.pml.ttl
         echo "@prefix nfo:        <http://www.semanticdesktop.org/ontologies/nfo/#> ."          >> $consequent.pml.ttl
         echo "@prefix pmlj:       <http://inference-web.org/2.0/pml-justification.owl#> ."      >> $consequent.pml.ttl
         echo "@prefix conv:       <http://purl.org/twc/vocab/conversion/> ."                    >> $consequent.pml.ttl
         echo                                                                                    >> $consequent.pml.ttl
         $CSV2RDF4LOD_HOME/bin/util/user-account.sh                                              >> $consequent.pml.ttl
         echo                                                                                    >> $consequent.pml.ttl
         echo $consequentURI                                                                     >> $consequent.pml.ttl
         echo "   a pmlp:Information;"                                                           >> $consequent.pml.ttl
         echo "   pmlp:hasModificationDateTime \"$consequentModDateTime\"^^xsd:dateTime;"        >> $consequent.pml.ttl
         #echo "   pmlp:hasReferenceSourceUsage $sourceUsage;"                                   >> $consequent.pml.ttl
         echo "."                                                                                >> $consequent.pml.ttl
         pushd `dirname $consequent` &> /dev/null # in manual/
         $CSV2RDF4LOD_HOME/bin/util/nfo-filehash.sh "`basename $consequent`"                     >> `basename $consequent.pml.ttl`
         popd &> /dev/null
         echo                                                                                    >> $consequent.pml.ttl
         #echo "$sourceUsage"                                                                     >> $consequent.pml.ttl
         #echo "   a pmlp:SourceUsage;"                                                           >> $consequent.pml.ttl
         #echo "   pmlp:hasSource        <$antecedent>;"                                          >> $consequent.pml.ttl
         #echo "   pmlp:hasUsageDateTime \"$usageDateTime\"^^xsd:dateTime;"                       >> $consequent.pml.ttl
         #echo "."                                                                                >> $consequent.pml.ttl
         #echo                                                                                    >> $consequent.pml.ttl
         echo "<../$antecedent>"                                                                 >> $consequent.pml.ttl
         echo "   a pmlp:Information;"                                                           >> $consequent.pml.ttl
         echo "   pmlp:hasModificationDateTime \"$antecedentModDateTime\"^^xsd:dateTime;"        >> $consequent.pml.ttl
         echo "."                                                                                >> $consequent.pml.ttl
         pushd `dirname $consequent` &> /dev/null # in manual/
         $CSV2RDF4LOD_HOME/bin/util/nfo-filehash.sh "../$antecedent"                             >> `basename $consequent.pml.ttl`
         popd &> /dev/null
         echo                                                                                    >> $consequent.pml.ttl
         echo $nodeSet                                                                           >> $consequent.pml.ttl
         echo "   a pmlj:NodeSet;"                                                               >> $consequent.pml.ttl
         echo "   pmlj:hasConclusion $consequentURI;"                                            >> $consequent.pml.ttl
         echo "   pmlj:isConsequentOf <inferenceStep_$requestID>;"                               >> $consequent.pml.ttl
         echo "."                                                                                >> $consequent.pml.ttl
         echo "<inferenceStep$requestID>"                                                        >> $consequent.pml.ttl
         echo "   a pmlj:InferenceStep;"                                                         >> $consequent.pml.ttl
         echo "   pmlj:hasIndex 0;"                                                              >> $consequent.pml.ttl
         echo "   pmlj:hasAntecedentList ( $antecedentNodeSet );"                                >> $consequent.pml.ttl
         #echo     pmlj:hasSourceUsage     $sourceUsage;"                                        >> $consequent.pml.ttl
         echo "   pmlj:hasInferenceEngine <$method$requestID>;"                                  >> $consequent.pml.ttl
         echo "   pmlj:hasInferenceRule   $method_name;"                                         >> $consequent.pml.ttl
         echo "   oboro:has_agent          `$CSV2RDF4LOD_HOME/bin/util/user-account.sh --cite`;" >> $consequent.pml.ttl
         echo "   hartigprov:involvedActor `$CSV2RDF4LOD_HOME/bin/util/user-account.sh --cite`;" >> $consequent.pml.ttl
         if [ ${#commandUsed} -gt 0 ]; then
         echo "   dcterms:description \"\"\"$commandUsed\"\"\";"                                 >> $consequent.pml.ttl
         fi
         echo "."                                                                                >> $consequent.pml.ttl
         echo                                                                                    >> $consequent.pml.ttl
         echo "<wasControlled$requestID>"                                                        >> $consequent.pml.ttl
         echo "   a oprov:WasControlledBy;"                                                      >> $consequent.pml.ttl
         echo "   oprov:cause  `$CSV2RDF4LOD_HOME/bin/util/user-account.sh --cite`;"             >> $consequent.pml.ttl
         echo "   oprov:effect <inferenceStep$requestID>;"                                       >> $consequent.pml.ttl
         echo "   oprov:endTime \"$usageDateTime\"^^xsd:dateTime;"                               >> $consequent.pml.ttl
         echo "."                                                                                >> $consequent.pml.ttl
         echo $antecedentNodeSet                                                                 >> $consequent.pml.ttl
         echo "   a pmlj:NodeSet;"                                                               >> $consequent.pml.ttl
         echo "   pmlj:hasConclusion <$antecedent>;"                                             >> $consequent.pml.ttl
         echo "."                                                                                >> $consequent.pml.ttl
         echo ""                                                                                 >> $consequent.pml.ttl
         echo "<$engine_name>"                                                                   >> $consequent.pml.ttl
         echo "   a pmlp:InferenceEngine, $engine_type;"                                         >> $consequent.pml.ttl
         echo "   dcterms:identifier \"$engine_name\";"                                          >> $consequent.pml.ttl
         echo "."                                                                                >> $consequent.pml.ttl
         echo                                                                                    >> $consequent.pml.ttl
         echo "$engine_type rdfs:subClassOf pmlp:InferenceEngine ."                              >> $consequent.pml.ttl
         echo --------------------------------------------------------------------------------
         shift
      fi
   fi
fi
