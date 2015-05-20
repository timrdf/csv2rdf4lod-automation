#!/bin/bash
#
#3> <> prov:specializationOf <https://github.com/timrdf/csv2rdf4lod-automation/blob/master/bin/util/mirror-endpoint.sh>;
#3>    prov:alternateOf <https://github.com/timrdf/DataFAQs/blob/master/bin/df-mirror-endpoint.sh>;
#3>    rdfs:seeAlso     <https://github.com/timrdf/csv2rdf4lod-automation/wiki/Named-graphs-that-know-where-they-came-from#mirroring-another-endpoints-named-graph>;
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
# See https://github.com/timrdf/csv2rdf4lod-automation/wiki/Named-graphs-that-know-where-they-came-from

if [[ $# -lt 2 ]]; then
   echo "usage: `basename $0` [--limit-offset <count>] [--to {vload, files}] <endpoint> <sd_name> [sd_name] ..."
   exit 1
fi

see='https://github.com/timrdf/csv2rdf4lod-automation/wiki/CSV2RDF4LOD-not-set'
CSV2RDF4LOD_HOME=${CSV2RDF4LOD_HOME:?"not set; source csv2rdf4lod/source-me.sh or see $see"}

limit_offset='1000'
if [[ "$1" == '--limit-offset' ]]; then
   limit_offset="$2"
   shift 2
fi

destination='vload'
if [[ "$1" == '--to' ]]; then
   destination="$2" # 'files'
   shift 2
fi

endpoint=$1
shift

# Copied from https://github.com/timrdf/DataFAQs/blob/master/bin/df-mirror-endpoint.sh
function noprotocolnohash {
   url="$1"
   url=${url#'http://'}
   url=${url#'https://'}
   url=${url%#*} # take off fragment identifier
   echo $url
}

while [ $# -gt 0 ]; do
   sd_name=$1
   echo "Grabbing sd:name $sd_name from $endpoint"

   #
   # Query it in via cache-queries (this models the endpoint and query explicitly).
   #
   if [[ "$sd_name" == 'cr:none' ]]; then
      query="construct { ?s ?p ?o } where {                   ?s ?p ?o  }"
   else
      query="construct { ?s ?p ?o } where { graph <$sd_name> {?s ?p ?o} }"
   fi

   if [[ "$destination" == 'vload' ]]; then

      TEMP_query="_"`basename $0``date +%s`_$$.rq
      TEMP_results="_"`basename $0``date +%s`_$$.tmp

      echo $query > $TEMP_query

      #                                                       \/        \/ hacks applies only to Virtuoso
      ${CSV2RDF4LOD_HOME}/bin/util/cache-queries.sh $endpoint -p format -o xml -q $TEMP_query -od $TEMP_results
     
      ${CSV2RDF4LOD_HOME}/bin/util/virtuoso/vload rdf $TEMP_results/$TEMP_query.xml         $sd_name # NOTE: No provenance of this load; done with pvload.sh below.
      ${CSV2RDF4LOD_HOME}/bin/util/virtuoso/vload ttl $TEMP_results/$TEMP_query.xml.pml.ttl $sd_name # NOTE: No provenance of this load

      queryURL=`grep "^<.*query=construct" $TEMP_results/$TEMP_query.xml.pml.ttl | awk '{gsub(/<|>/,"");print}' | head -1` # grepping when should be sparqling...
     
      #
      # Query it in directly (will connect up with previous provenance via queryURL)
      #
      if [ ${#queryURL} -gt 0 ]; then
         if [ "$CSV2RDF4LOD_CONVERT_DEBUG_LEVEL" == "finest" ]; then
            echo "pvloading $queryURL"
         fi
         ${CSV2RDF4LOD_HOME}/bin/util/pvload.sh $queryURL -ng $sd_name # Queries endpoint again.
      fi

      if [ "$CSV2RDF4LOD_CONVERT_DEBUG_LEVEL" != "finest" ]; then
         rm -rf $TEMP_results $TEMP_query &> /dev/null
      fi

   elif [[ "$destination" == 'files' ]]; then

      endpoint_path=`noprotocolnohash $endpoint`
      sd_name_path=`noprotocolnohash $sd_name`
      rq=$endpoint_path/__sd_name__/$sd_name_path/spo.rq
      nt=$endpoint_path/__sd_name__/$sd_name_path/spo.nt
      mkdir -p `dirname $rq`
      echo $query > $rq

      #echo
      #echo                                          $endpoint -p format -o xml -q $rq --limit-offset $limit_offset -od `dirname $rq`
      ${CSV2RDF4LOD_HOME}/bin/util/cache-queries.sh $endpoint -p format -o xml -q $rq --limit-offset $limit_offset -od `dirname $rq`

      ${CSV2RDF4LOD_HOME}/bin/util/rdf2nt.sh $rq*.xml > $nt
      if [[ `void-triples.sh $nt` -gt 0 ]]; then
         rm $rq*.xml
         # TODO: what about the prov.ttl files?
      fi
   else
      echo "ERROR: did not recognize destination type"
   fi

   shift
done
