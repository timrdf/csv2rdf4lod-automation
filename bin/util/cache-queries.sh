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
   echo "usage: `basename $0` <endpoint> [-p {output,format}] [-o {sparql,gvds,xml,exhibit,csv}+]"
   echo "                                   [-q a.sparql b.sparql ...]*"
   echo "                                   [--limit-offset [count]] [--nap [count]]"
   echo "                                   [--strip-count] [-od path/to/output/dir]"
   echo
   echo "    Executes SPARQL queries against an endpoint requesting the given output formats."
   echo
   echo "            -p          : the URL parameter name used to request a different output/format from <endpoint>."
   echo "    default -p          : 'output'"
   echo "            -o          : the URL parameter value(s) to request."
   echo "    default -o          : $outputTypes"
   echo "    default -q          : *.sparql *.rq"
   echo " --limit-offset [count] : iterate with LIMIT / OFFSET until no more useful results. If no LIMIT in a.sparql, defaults to 10000."
   echo "                        : Note that Virtuoso's default LIMIT restriction is 10,000 -- so going above that is a bad idea."
   echo "          --nap [count] : sleep **on average** [count] seconds between --limit-offset queries; '0' will not nap, default is '5'."
   echo "                        : in all cases, if the previous request time takes longer than the specified nap time,"
   echo "                        : `basename $0` will use the previous request time as the upper bound sleep cap."
   echo "  --strip-count         : modify the SPARQL query to remove count() operator."
   echo "                          e.g. 'select count(distinct ?s) where' --> 'select distinct ?s where'"
   echo "            -od         : output directory"
   echo "    default -od         : results/"
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
   while [[ $# -gt 0 && ( "$1" != '-od' && "$1" != '--limit-offset' ) ]]; do
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
   if [[ "$2" =~ [0-9]+ ]]; then
      #echo "`basename $0` accepting LIMIT override: $2" >&2
      limit_offset="$2" # An actual number.
      shift
   else
      echo "`basename $0` will use default LIMIT, or the LIMIT defined in the file ($2)." > /dev/null
      #echo "`basename $0` will use default LIMIT, or the LIMIT defined in the file ($2)." >&2
   fi
   shift
fi

nap='5'
if [[ "$1" == '--nap' ]]; then
   if [[ "$2" =~ [0-9]+ ]]; then
      nap=$2
      shift
   fi
   shift
fi

strip_count='no'
if [[ "$1" == '--strip-count' ]]; then
   strip_count='yes'
   shift
fi

results="results"
if [ "$1" == "-od" -a $# -gt 1 ]; then
   shift
   results="$1"
   #echo "results to $results" >&2 
fi
if [ ! -d $results ]; then
   mkdir -p $results
fi

for sparql in $queryFiles; do
   echo $sparql
   TEMPrq="_"`basename $0``date +%s`_$$.rq
   if [[ "$strip_count" == 'yes' ]]; then
      echo "  (stripping count()):"
      cat $sparql | sed 's/^\(.*\)count(\([^)]*\))/\1\2/' > $TEMPrq
      diff $sparql $TEMPrq | awk '{print "         "$0}'
   else
      cat $sparql                                         > $TEMPrq
   fi

   for output in $outputTypes; do

      limit=''
      offset='0'
      if [[ -n "$limit_offset" ]]; then # limit_offset is either: '' (no), 'yes', or a caller-provided number e.g. '100000'
         limit=`cat $sparql | grep -i '^limit' | awk '{print $2}' | head -1`
         if [[ "$limit" =~ [0-9]+ ]]; then
            if [[ -n "$CSV2RDF4LOD_CONVERT_DEBUG_LEVEL" ]]; then
               echo "Found LIMIT in $TEMPrq: $limit" >&2
            fi
            limit_is_in_query='yes'
         else
            if [[ -n "$CSV2RDF4LOD_CONVERT_DEBUG_LEVEL" ]]; then
               echo "No LIMIT in $sparql; assuming default of 10000" >&2
            fi
            limit_is_in_query='no'
            limit='10000'
         fi
         if [[ "$limit_offset" =~ [0-9]+ ]]; then
            if [[ -n "$CSV2RDF4LOD_CONVERT_DEBUG_LEVEL" ]]; then
               echo "Overriding LIMIT to $limit_offset" >&2
            fi
            limit="$limit_offset"
         fi
         if [[ "$limit" =~ [0-9]+ ]]; then
            iteration='1'
         fi
      fi
      # limit  is either '' or a number e.g. '100000'
      # offset is always '0'
      if [[ -n "$limit" ]]; then
         echo "  (will exhaust with limit/offset: $limit/$offset)"
      fi

      # $offset starts at '0' and becomes either '' or a number e.g. '10000'
      # So, will run first time and maybe more.
      lastResultsFile=''
      while [ -n "$offset" ]; do
         query=`cr-urlencode.sh --from-file "$TEMPrq"`
         qi='' # '' -> '_2' -> '_3' ...

         if [[ -n "$CSV2RDF4LOD_CONVERT_DEBUG_LEVEL" ]]; then
            echo "limit_is_in_query : |$limit_is_in_query|" >&2
         fi
         [[ "$limit_is_in_query" == 'yes' || -z "$limit" ]] && queryLIMIT='' || queryLIMIT='%0A'`cr-urlencode.sh " limit $limit"`
         if [[ -n "$CSV2RDF4LOD_CONVERT_DEBUG_LEVEL" ]]; then
            echo "queryLIMIT : |$queryLIMIT|" >&2
         fi

         queryOFFSET=''
         if [[ -n "$offset" ]]; then   
            if [[ "$offset" -gt 0 ]]; then
               qi=".$iteration"
               queryOFFSET='%0A'`cr-urlencode.sh " offset $offset "`
            fi
         fi
         escapedOutput=`cr-urlencode.sh $output`
         if [[ "$output" == "xml" ]]; then
            accept='application/xml'
         else
            accept='application/xml'
         fi

         timeout='&timeout=300000'
         request="$endpoint?query=$query$queryLIMIT$queryOFFSET$timeout&$outputVarName=$escapedOutput"
         if [[ -n "$CSV2RDF4LOD_CONVERT_DEBUG_LEVEL" ]]; then
            echo $request
         fi

         resultsFile=$results/`basename $sparql`$qi.`echo $output | tr '/+-' '_'`
         if [[ "$offset" -eq 0 ]]; then
            printf "  $output -> $resultsFile"
         else
            adaptiveNapL=" sec."
            if [[ -n "$requestDuration" && $requestDuration -gt 1 ]]; then
               if [[ -n "$nap" && $nap -gt 0 ]]; then
                  if [[ $requestDuration -gt $nap ]]; then
                     adaptiveNap=$requestDuration
                     adaptiveNapL="'|$requestDuration > $nap sec."
                     #
                     # When each request "happens to be" at least 10 seconds,
                     #     2 5,000/5,000   zzz 1'|11  > 5 sec.
                     #     3 5,000/10,000  zzz 3'|10  > 5 sec.
                     #     4 5,000/15,000  zzz 10'|11 > 5 sec.
                     #     5 5,000/20,000  zzz 2'|12  > 5 sec.
                     #     6 5,000/25,000  zzz 1'|11  > 5 sec.
                     #     7 5,000/30,000  zzz 2'|11  > 5 sec.
                     #     8 5,000/35,000  zzz 0'|11  > 5 sec.
                     #     9 5,000/40,000  zzz 2'|11  > 5 sec.
                     #     10 5,000/45,000 zzz 3'|11  > 5 sec.
                     #     11 5,000/50,000 zzz 8'|11  > 5 sec.
                     #     12 5,000/55,000 zzz 0'|11  > 5 sec.
                     #     13 5,000/60,000 zzz 3'|11  > 5 sec.
                     #     14 5,000/65,000 zzz 2'|10  > 5 sec.
                     #     15 5,000/70,000 zzz 0'|11  > 5 sec.
                     #     16 5,000/75,000 zzz 7'|11  > 5 sec.
                     #     17 5,000/80,000 zzz 0'|11  > 5 sec.
                     #     18 5,000/85,000 zzz 2'|11  > 5 sec.
                     #     19 5,000/90,000 zzz 2'|11  > 5 sec.
                  else
                     adaptiveNap=$nap
                  fi
               else
                  # There was no $nap set, so step in and nap it.
                  adaptiveNap=$requestDuration
                  adaptiveNapL="'|$requestDuration > $nap sec."
               fi
            else
               adaptiveNap=$nap
            fi
            if [[ "$adaptiveNap" -gt 0 ]]; then
               sec=$(($RANDOM%$adaptiveNap))
               if [[ "$sec" -gt 0 ]]; then
                  zzz="zzz $sec"
               else
                  zzz=''
                  adaptiveNapL="|$requestDuration sec."
               fi
            else
               adaptiveNapL="|$requestDuration sec."
            fi
            # http://stackoverflow.com/questions/9374868/number-formatting-in-bash-with-thousand-separator
            iterationL=`printf "%'.0f\n" $iteration`
            limitL=`    printf "%'.0f\n" $limit`
            offsetL=`   printf "%'.0f\n" $offset`
            echo   "  `echo $output | sed 's/./ /g'`    $iterationL $limitL/$offsetL $zzz$adaptiveNapL"
            if [[ "$sec" -gt 0 ]]; then
               sleep $sec
            fi
         fi
         startedAtTime=`date +"%s"`
         curl -H "Accept: $accept" -L "$request" > $resultsFile 2> /dev/null
         endedAtTime=`date +"%s"`
         let "requestDuration=endedAtTime-startedAtTime"
         usageDateTime=`dateInXSDDateTime.sh`
         usageDateTimePath=`dateInXSDDateTime.sh --uri-path $usageDateTime`

         query_queryLIMIT_queryOFFSET=`cr-urlencode.sh --decode "$query$queryLIMIT$queryOFFSET"`

         #
         # Record the provenance of the query request
         #
         requestID=`resource-name.sh`
         requestDate=`dateInXSDDateTime.sh`
         sparqlQuery=${CSV2RDF4LOD_BASE_URI_OVERRIDE:-$CSV2RDF4LOD_BASE_URI}/id/md5/`md5.sh $sparql`
         sparqlQuery_i=${CSV2RDF4LOD_BASE_URI_OVERRIDE:-$CSV2RDF4LOD_BASE_URI}/id/md5/`md5.sh -qs "$query_queryLIMIT_queryOFFSET"`
             quotation=${CSV2RDF4LOD_BASE_URI_OVERRIDE:-$CSV2RDF4LOD_BASE_URI}/id/url/`md5.sh -qs "$query_queryLIMIT_queryOFFSET"`/quoted/$usageDateTimePath
         sd_service=${CSV2RDF4LOD_BASE_URI_OVERRIDE:-$CSV2RDF4LOD_BASE_URI}/id/service/`md5.sh -qs "$endpoint"`
         $CSV2RDF4LOD_HOME/bin/util/cr-default-prefixes.sh --turtle                                         > $resultsFile.prov.ttl
         echo "@prefix hartigprov: <http://purl.org/net/provenance/ns#> ."                                 >> $resultsFile.prov.ttl
         echo "@prefix prvtypes:   <http://purl.org/net/provenance/types#> ."                              >> $resultsFile.prov.ttl
         echo "@prefix pml:        <http://provenanceweb.org/ns/pml#> ."                                   >> $resultsFile.prov.ttl
         echo "@prefix pmlp:       <http://inference-web.org/2.0/pml-provenance.owl#> ."                   >> $resultsFile.prov.ttl
         echo "@prefix pmlj:       <http://inference-web.org/2.0/pml-justification.owl#> ."                >> $resultsFile.prov.ttl
         echo "@prefix pmlb:       <http://inference-web.org/2.b/pml-provenance.owl#> ."                   >> $resultsFile.prov.ttl
         echo "@prefix oboro:      <http://obofoundry.org/ro/ro.owl#> ."                                   >> $resultsFile.prov.ttl
         echo "@prefix oprov:      <http://openprovenance.org/ontology#> ."                                >> $resultsFile.prov.ttl
         echo                                                                                              >> $resultsFile.prov.ttl
         $CSV2RDF4LOD_HOME/bin/util/user-account.sh                                                        >> $resultsFile.prov.ttl
         echo                                                                                              >> $resultsFile.prov.ttl
         #pushd $results &> /dev/null
         #resultsFileAbstract=`$CSV2RDF4LOD_HOME/bin/util/nfo-filehash.sh --foci "\`basename $resultsFile\`"`
         #$CSV2RDF4LOD_HOME/bin/util/nfo-filehash.sh "`basename $resultsFile`"                   >> `basename $resultsFile.prov.ttl`
         #popd &> /dev/null # nfo-filehash.sh can handle relative paths correctly now (?)
                                     $CSV2RDF4LOD_HOME/bin/util/nfo-filehash.sh        "$resultsFile"      >> $resultsFile.prov.ttl
                resultsFileAbstract=`$CSV2RDF4LOD_HOME/bin/util/nfo-filehash.sh --foci "$resultsFile"`
         echo "$resultsFileAbstract"                                                                       >> $resultsFile.prov.ttl
         echo "   a prov:Entity;"                                                                          >> $resultsFile.prov.ttl
         echo "   prov:wasDerivedFrom      <$sd_service>;"                                                 >> $resultsFile.prov.ttl
         echo "   pml:wasGeneratedWithPlan <$sparqlQuery_i>;"                                              >> $resultsFile.prov.ttl
         echo "   prov:wasQuotedFrom       <$request>;"                                                    >> $resultsFile.prov.ttl
         echo "   prov:qualifiedQuotation  <$quotation>;"                                                  >> $resultsFile.prov.ttl
         echo "   prv:serializedBy <`basename $resultsFile`>;"                                             >> $resultsFile.prov.ttl
         echo "."                                                                                          >> $resultsFile.prov.ttl
         echo                                                                                              >> $resultsFile.prov.ttl
         echo "<$sparqlQuery_i>"                                                                           >> $resultsFile.prov.ttl
         echo "   a prvtypes:SPARQLQuery;"                                                                 >> $resultsFile.prov.ttl
         echo "   prov:value \"\"\"$query_queryLIMIT_queryOFFSET\"\"\";"                                   >> $resultsFile.prov.ttl
         echo "   prov:specializationOf <$sparqlQuery>;"                                                   >> $resultsFile.prov.ttl
         echo "   prov:wasDerivedFrom   <$sparqlQuery>;"                                                   >> $resultsFile.prov.ttl
         if [[ ${#iteration} -gt 0 ]]; then
            echo "   pml:atIndex $iteration;"                                                              >> $resultsFile.prov.ttl
         fi
         echo "."                                                                                          >> $resultsFile.prov.ttl
         echo "<$sparqlQuery>"                                                                             >> $resultsFile.prov.ttl
         echo "   a prvtypes:SPARQLQuery;"                                                                 >> $resultsFile.prov.ttl
         echo "   prov:value     \"\"\"`cat $sparql`\"\"\";"                                               >> $resultsFile.prov.ttl
         echo "   prv:serializedBy <../$sparql>;"                                                          >> $resultsFile.prov.ttl
         echo "."                                                                                          >> $resultsFile.prov.ttl
                                     $CSV2RDF4LOD_HOME/bin/util/nfo-filehash.sh        "$sparql"           >> $resultsFile.prov.ttl
                sparqlNFO=`$CSV2RDF4LOD_HOME/bin/util/nfo-filehash.sh --foci "$sparql"`
         #echo "<$sparql.$output>"                                                                          >> $resultsFile.prov.ttl
         #echo "   a pmlp:Information;"                                                                     >> $resultsFile.prov.ttl
         #echo "   pmlp:hasModificationDateTime \"$requestDate\"^^xsd:dateTime;"                            >> $resultsFile.prov.ttl
         #echo "   pmlp:hasReferenceSourceUsage <sourceusage$requestID>;"                                   >> $resultsFile.prov.ttl
         #echo "."                                                                                          >> $resultsFile.prov.ttl
         echo                                                                                              >> $resultsFile.prov.ttl
         echo "<${quotation}>"                                                                             >> $resultsFile.prov.ttl
         echo "   a prov:Quotation;"                                                                       >> $resultsFile.prov.ttl
         echo "   prov:entity <$request>;"                                                                 >> $resultsFile.prov.ttl
         echo "   prov:atTime \"$usageDateTime\"^^xsd:dateTime;"                                           >> $resultsFile.prov.ttl
         echo "."                                                                                          >> $resultsFile.prov.ttl
         #echo "<sourceusage_$requestID>"                                                                   >> $resultsFile.prov.ttl
         #echo "   a pmlp:SourceUsage;"                                                                     >> $resultsFile.prov.ttl
         #echo "   pmlp:hasSource        <$request>;"                                                       >> $resultsFile.prov.ttl
         #echo "   pmlp:hasUsageDateTime \"$requestDate\"^^xsd:dateTime;"                                   >> $resultsFile.prov.ttl
         #echo "."                                                                                          >> $resultsFile.prov.ttl
         echo                                                                                              >> $resultsFile.prov.ttl
         #echo "<$request>"                                                                                 >> $resultsFile.prov.ttl
         #echo "   a pmlj:Query, pmlp:Source;"                                                              >> $resultsFile.prov.ttl
         #echo "   pmlj:isFromEngine <$endpoint>;"                                                          >> $resultsFile.prov.ttl
         #echo "   pmlj:hasAnswer    <nodeset$requestID>;"                                                  >> $resultsFile.prov.ttl
         #echo "."                                                                                          >> $resultsFile.prov.ttl
         echo                                                                                              >> $resultsFile.prov.ttl
         echo "<$sd_service>"                                                                              >> $resultsFile.prov.ttl
         echo "   a sd:Service, pmlp:WebService;"                                                          >> $resultsFile.prov.ttl
         echo "   rdfs:seeAlso <http://uri4uri.net/uri/`cr-urlencode.sh "$endpoint"`>;"                    >> $resultsFile.prov.ttl
         echo "   sd:endpoint <$endpoint>;"                                                                >> $resultsFile.prov.ttl
         echo "."                                                                                          >> $resultsFile.prov.ttl
         #echo                                                                                              >> $resultsFile.prov.ttl
         #echo "<nodeset_$requestID>"                                                                       >> $resultsFile.prov.ttl
         #echo "   a pmlj:NodeSet;"                                                                         >> $resultsFile.prov.ttl
         #echo "   pmlj:hasConclusion <$sparql.$output>;"                                                   >> $resultsFile.prov.ttl
         #echo "   pmlj:isConsequentOf <inferenceStep_$requestID>;"                                         >> $resultsFile.prov.ttl
         #echo "."                                                                                          >> $resultsFile.prov.ttl
         #echo "<inferenceStep_$requestID>"                                                                 >> $resultsFile.prov.ttl
         #echo "   a pmlj:InferenceStep;"                                                                   >> $resultsFile.prov.ttl
         #echo "   pmlj:hasIndex 0;"                                                                        >> $resultsFile.prov.ttl
         #echo "   pmlj:hasAntecedentList ("                                                                >> $resultsFile.prov.ttl
         #echo "      [ a pmlj:NodeSet; pmlp:hasConclusion <query$requestID> ]"                             >> $resultsFile.prov.ttl
         #echo "      [ a pmlj:NodeSet; pmlp:hasConclusion ["                                               >> $resultsFile.prov.ttl
         #echo "            a pmlb:AttributeValuePair;"                                                     >> $resultsFile.prov.ttl
         #echo "            pmlb:attribute \"output\"; pmlb:value \"$output\""                              >> $resultsFile.prov.ttl
         #echo "          ]"                                                                                >> $resultsFile.prov.ttl
         #echo "      ]"                                                                                    >> $resultsFile.prov.ttl
         #echo "   );"                                                                                      >> $resultsFile.prov.ttl
         #echo "   oboro:has_agent          `$CSV2RDF4LOD_HOME/bin/util/user-account.sh --cite`;"           >> $resultsFile.prov.ttl
         #echo "   hartigprov:involvedActor `$CSV2RDF4LOD_HOME/bin/util/user-account.sh --cite`;"           >> $resultsFile.prov.ttl
         #echo "      pmlj:hasSourceUsage     $sourceUsage;"                                               >> $resultsFile.prov.ttl
         #echo "      pmlj:hasInferenceEngine <$engine_name$requestID>;"                                   >> $resultsFile.prov.ttl
         #echo "      pmlj:hasInferenceRule   conv:${engine_name}_Method;"                                 >> $resultsFile.prov.ttl
         #echo "."                                                                                          >> $resultsFile.prov.ttl
         #echo "<wasControlled_$requestID>"                                                                 >> $resultsFile.prov.ttl
         #echo "   a oprov:WasControlledBy;"                                                                >> $resultsFile.prov.ttl
         #echo "   oprov:cause  `$CSV2RDF4LOD_HOME/bin/util/user-account.sh --cite`;"                       >> $resultsFile.prov.ttl
         #echo "   oprov:effect <inferenceStep$requestID>;"                                                 >> $resultsFile.prov.ttl
         #echo "   oprov:endTime \"$usageDateTime\"^^xsd:dateTime;"                                         >> $resultsFile.prov.ttl
         #echo "."                                                                                          >> $resultsFile.prov.ttl
         #echo ""                                                                                           >> $resultsFile.prov.ttl
         #echo "<query_$requestID>"                                                                         >> $resultsFile.prov.ttl
         #echo "   a pmlb:AttributeValuePair;"                                                              >> $resultsFile.prov.ttl
         #echo "   pmlb:attribute \"query\";"                                                               >> $resultsFile.prov.ttl
         #echo "   pmlb:value     \"\"\"`cat $sparql`\"\"\";"                                               >> $resultsFile.prov.ttl
         #echo "."                                                                                          >> $resultsFile.prov.ttl

         psychotic='no'
         if [[ -n "$lastResultsFile" && -e "$lastResultsFile" ]]; then
            diffs=`diff --brief "$lastResultsFile" "$resultsFile"`
            if [ ${#diffs} -gt 0 ]; then
               psychotic='no'
            else
               psychotic='yes'
               #echo "WARNING: $lastResultsFile is no different than $resultsFile; we're psychotic"
            fi
         fi

         # If query results are "valid", and we were asked to exhaust the query with limit/offset...
         if [[ ( `valid-rdf.sh $resultsFile` == 'yes' && `void-triples.sh $resultsFile` -gt 0 \
                  ||                                                                          \
                 $output == 'csv' && `wc -l $resultsFile | awk '{print $1}'` -gt 1) &&        \
               $psychotic != 'yes' ]]; then

            if [[ -n "$offset" && -n "$limit" ]]; then   
               if [[ "$offset" -eq 0 ]]; then
                  echo
               fi
               let "offset=$offset+$limit"
               let "iteration=$iteration+1"
               echo "            (continuing b/c"                                            >&2
               echo "                 psychotic  : $psychotic"                               >&2
               echo "                    format  : $output"                                  >&2
               echo "                 line count : `wc -l $resultsFile | awk '{print $1}'`"  >&2
               echo "                 valid RDF  : `valid-rdf.sh $resultsFile`"              >&2
               echo "                 triples    : `void-triples.sh $resultsFile`)"          >&2
            else
               offset=''
            fi
         else
            offset=''
            echo "            (not continuing b/c"                                        >&2
            echo "                 psychotic  : $psychotic"                               >&2
            echo "                    format  : $output"                                  >&2
            echo "                 line count : `wc -l $resultsFile | awk '{print $1}'`"  >&2
            echo "                 valid RDF  : `valid-rdf.sh $resultsFile`"              >&2
            echo "                 triples    : `void-triples.sh $resultsFile`)"          >&2
            # TODO: clean up last query result since it wasn't valid. >&2
         fi 
         lastResultsFile="$resultsFile"
      done
   done
   echo ""
done 

rm -f $TEMPrq
