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
# See https://github.com/timrdf/csv2rdf4lod-automation/wiki/Named-graphs-that-know-where-they-came-from

if [[ $# -lt 2 ]]; then
   echo "usage: `basename $0` <endpoint> <named_graph> [named_graph] ..."
   exit 1
fi

CSV2RDF4LOD_HOME=${CSV2RDF4LOD_HOME:?"not set; source csv2rdf4lod/source-me.sh or see https://github.com/timrdf/csv2rdf4lod-automation/wiki/CSV2RDF4LOD-not-set"}

endpoint=$1
shift

while [ $# -gt 0 ]; do
   named_graph=$1
   echo grabbing $named_graph from $endpoint

   TEMP_query="_"`basename $0``date +%s`_$$.rq
   TEMP_results="_"`basename $0``date +%s`_$$.tmp
  
   #
   # Query it in via cache-queries (this models the endpoint and query explicitly).
   #
   echo "construct { ?s ?p ?o } where { graph <$named_graph> {?s ?p ?o} }" > $TEMP_query

   #                                                       \/        \/ hacks applies only to Virtuoso
   ${CSV2RDF4LOD_HOME}/bin/util/cache-queries.sh $endpoint -p format -o xml -q $TEMP_query -od $TEMP_results
  
   ${CSV2RDF4LOD_HOME}/bin/util/virtuoso/vload rdf $TEMP_results/$TEMP_query.xml         $named_graph # NOTE: No provenance of this load; done with pvload.sh below.
   ${CSV2RDF4LOD_HOME}/bin/util/virtuoso/vload ttl $TEMP_results/$TEMP_query.xml.pml.ttl $named_graph # NOTE: No provenance of this load

   queryURL=`grep "^<.*query=construct" $TEMP_results/$TEMP_query.xml.pml.ttl | awk '{gsub(/<|>/,"");print}' | head -1` # grepping when should be sparqling...
  
   #
   # Query it in directly (will connect up with previous provenance via queryURL)
   #
   if [ ${#queryURL} -gt 0 ]; then
      if [ ${CSV2RDF4LOD_CONVERT_DEBUG_LEVEL:-"none"} == "finest" ]; then
         echo "pvloading $queryURL"
      fi
      ${CSV2RDF4LOD_HOME}/bin/util/pvload.sh $queryURL -ng $named_graph # Queries endpoint again.
   fi

   if [ ${CSV2RDF4LOD_CONVERT_DEBUG_LEVEL:-"none"} != "finest" ]; then
      rm -rf $TEMP_query $TEMP_results &> /dev/null
   fi

   shift
done
