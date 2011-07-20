#!/bin/bash

if [ ${1:-"no"} != "CLEAR" ]; then
   #echo "CLASSPATH                             $CLASSPATH"
   #echo "PATH                                  $PATH"

   echo "--"
   echo "CSV2RDF4LOD_HOME                                         ${CSV2RDF4LOD_HOME:-"!!! -- MUST BE SET -- !!! source csv2rdf4lod/source-me.sh"}"
   echo "CSV2RDF4LOD_BASE_URI                                     ${CSV2RDF4LOD_BASE_URI:-"!!! -- MUST BE SET -- !!! source csv2rdf4lod/source-me.sh"}"
   echo "CSV2RDF4LOD_BASE_URI_OVERRIDE                            ${CSV2RDF4LOD_BASE_URI_OVERRIDE:="(not required, \$CSV2RDF4LOD_BASE_URI will be used.)"}"
   echo "--"
   echo "CSV2RDF4LOD_CONVERT_MACHINE_URI                          ${CSV2RDF4LOD_CONVERT_MACHINE_URI:="(not required)"}"
   echo "CSV2RDF4LOD_CONVERT_PERSON_URI                           ${CSV2RDF4LOD_CONVERT_PERSON_URI:="(not required)"}"

   echo "--"
   echo "CSV2RDF4LOD_CONVERT_DATA_ROOT                            ${CSV2RDF4LOD_CONVERT_DATA_ROOT:="(not required)"}"
   echo "CSV2RDF4LOD_CONVERT_OMIT_RAW_LAYER                       ${CSV2RDF4LOD_CONVERT_OMIT_RAW_LAYER:="(will default to: false)"}"
   echo "CSV2RDF4LOD_CONVERT_NUMBER_SAMPLE_ROWS                   ${CSV2RDF4LOD_CONVERT_NUMBER_SAMPLE_ROWS:="(will default to: 2)"}"
   echo "CSV2RDF4LOD_CONVERT_SAMPLE_SUBSET_ONLY                   ${CSV2RDF4LOD_CONVERT_SAMPLE_SUBSET_ONLY:="(will default to: false)"}"
   echo "CSV2RDF4LOD_CONVERT_EXAMPLE_SUBSET_ONLY                  ${CSV2RDF4LOD_CONVERT_EXAMPLE_SUBSET_ONLY:="(will default to: false)"}"
   echo "CSV2RDF4LOD_CONVERT_DUMP_FILE_EXTENSIONS                 ${CSV2RDF4LOD_CONVERT_DUMP_FILE_EXTENSIONS:="(no extension will be used)"}"
   echo "CSV2RDF4LOD_CONVERT_PROVENANCE_GRANULAR                  ${CSV2RDF4LOD_CONVERT_PROVENANCE_GRANULAR:="(will default to: false)"}"
   echo "CSV2RDF4LOD_CONVERT_DEBUG_LEVEL                          ${CSV2RDF4LOD_CONVERT_DEBUG_LEVEL:="(will default to: none \{none,fine,finer,finest\})"}"

   echo "--"
   echo "CSV2RDF4LOD_PUBLISH                                      ${CSV2RDF4LOD_PUBLISH:-"(will default to: true)"}"
   echo "CSV2RDF4LOD_PUBLISH_DELAY_UNTIL_ENHANCED                 ${CSV2RDF4LOD_PUBLISH_DELAY_UNTIL_ENHANCED:-"(will default to: true)"}"
   echo "CSV2RDF4LOD_PUBLISH_COMPRESS                             ${CSV2RDF4LOD_PUBLISH_COMPRESS:-"(will default to: false)"}"
   echo "CSV2RDF4LOD_PUBLISH_OUR_SOURCE_ID                        ${CSV2RDF4LOD_PUBLISH_OUR_SOURCE_ID:="(will not archive conversion metadata into versioned dataset.)"}"
   echo "CSV2RDF4LOD_PUBLISH_OUR_DATASET_ID                       ${CSV2RDF4LOD_PUBLISH_OUR_DATASET_ID:="(will not archive conversion metadata into versioned dataset.)"}"

   echo "CSV2RDF4LOD_PUBLISH_TTL                                  ${CSV2RDF4LOD_PUBLISH_TTL:-"(will default to: true)"}"
   echo "CSV2RDF4LOD_PUBLISH_TTL_LAYERS                           ${CSV2RDF4LOD_PUBLISH_TTL_LAYERS:-"(will default to: true)"}"

   echo "CSV2RDF4LOD_PUBLISH_NT                                   ${CSV2RDF4LOD_PUBLISH_NT:-"(will default to: false)"}"

   echo "CSV2RDF4LOD_PUBLISH_RDFXML                               ${CSV2RDF4LOD_PUBLISH_RDFXML:-"(will default to: false)"}"

   echo "--"
   echo "CSV2RDF4LOD_PUBLISH_SUBSET_VOID                          ${CSV2RDF4LOD_PUBLISH_SUBSET_VOID:="(will default to: true)"}"
   echo "CSV2RDF4LOD_PUBLISH_SUBSET_VOID_NAMED_GRAPH              ${CSV2RDF4LOD_PUBLISH_SUBSET_VOID_NAMED_GRAPH:="(will default to: auto)"}"
   echo "CSV2RDF4LOD_PUBLISH_SUBSET_SAMEAS                        ${CSV2RDF4LOD_PUBLISH_SUBSET_SAMEAS:="(will default to: false)"}"
   echo "CSV2RDF4LOD_PUBLISH_SUBSET_SAMEAS_NAMED_GRAPH            ${CSV2RDF4LOD_PUBLISH_SUBSET_SAMEAS_NAMED_GRAPH:="(will default to: auto)"}"
   echo "CSV2RDF4LOD_PUBLISH_SUBSET_SAMPLES                       ${CSV2RDF4LOD_PUBLISH_SUBSET_SAMPLES:="(will default to: false)"}"

   echo "--"
   echo "CSV2RDF4LOD_PUBLISH_CONVERSION_PARAMS_NAMED_GRAPH        ${CSV2RDF4LOD_PUBLISH_CONVERSION_PARAMS_NAMED_GRAPH:="(will default to: auto)"}"

   echo "--"
   echo "CSV2RDF4LOD_PUBLISH_LOD_MATERIALIZATION                  ${CSV2RDF4LOD_PUBLISH_LOD_MATERIALIZATION:-"(will default to: false)"}"

   echo "CSV2RDF4LOD_PUBLISH_LOD_MATERIALIZATION_WWW_ROOT         ${CSV2RDF4LOD_PUBLISH_LOD_MATERIALIZATION_WWW_ROOT:-"(will default to: VVV/publish/lod-mat/)"}"

   echo "CSV2RDF4LOD_PUBLISH_LOD_MATERIALIZATION_WRITE_FREQUENCY  ${CSV2RDF4LOD_PUBLISH_LOD_MATERIALIZATION_WRITE_FREQUENCY:-"(will default to: 1,000,000)"}"

   echo "CSV2RDF4LOD_PUBLISH_LOD_MATERIALIZATION_REPORT_FREQUENCY ${CSV2RDF4LOD_PUBLISH_LOD_MATERIALIZATION_REPORT_FREQUENCY:-"(will default to: 1,000)"}"

   echo "CSV2RDF4LOD_CONCURRENCY                                  ${CSV2RDF4LOD_CONCURRENCY:-"(will default to: 1)"}"

   echo "--"
   echo "CSV2RDF4LOD_PUBLISH_TDB                                  ${CSV2RDF4LOD_PUBLISH_TDB:-"(will default to: false)"}"

   echo "CSV2RDF4LOD_PUBLISH_TDB_DIR                              ${CSV2RDF4LOD_PUBLISH_TDB_DIR:-"(will default to: VVV/publish/tdb/)"}"

   echo "CSV2RDF4LOD_PUBLISH_TDB_INDIV                            ${CSV2RDF4LOD_PUBLISH_TDB_INDIV:-"(will default to: false)"}"

   echo "--"
   echo "CSV2RDF4LOD_PUBLISH_4STORE                               ${CSV2RDF4LOD_PUBLISH_4STORE:-"(will default to: false)"}"
   echo "CSV2RDF4LOD_PUBLISH_4STORE_KB                            ${CSV2RDF4LOD_PUBLISH_4STORE_KB:-"(will default to: csv2rdf4lod -- leading to /var/lib/4store/csv2rdf4lod)"}" 

   echo "--"
   echo "CSV2RDF4LOD_PUBLISH_VIRTUOSO                             ${CSV2RDF4LOD_PUBLISH_VIRTUOSO:-"(will default to: false)"}"
   echo "CSV2RDF4LOD_PUBLISH_VIRTUOSO_HOME                        ${CSV2RDF4LOD_PUBLISH_VIRTUOSO_HOME:-"(will default to: /opt/virtuoso)"}"
   echo "CSV2RDF4LOD_PUBLISH_VIRTUOSO_ISQL_PATH                   ${CSV2RDF4LOD_PUBLISH_VIRTUOSO_ISQL_PATH:-"(will default to: /opt/virtuoso/bin/isql)"}"
   echo "CSV2RDF4LOD_PUBLISH_VIRTUOSO_PORT                        ${CSV2RDF4LOD_PUBLISH_VIRTUOSO_PORT:-"(will default to: 1111)"}"
   echo "CSV2RDF4LOD_PUBLISH_VIRTUOSO_USERNAME                    ${CSV2RDF4LOD_PUBLISH_VIRTUOSO_USERNAME:-"(will default to: dba)"}"
   echo "CSV2RDF4LOD_PUBLISH_VIRTUOSO_PASSWORD                    ${CSV2RDF4LOD_PUBLISH_VIRTUOSO_PASSWORD:-"(will default to: dba)"}"
   
   echo "CSV2RDF4LOD_PUBLISH_VIRTUOSO_SCRIPT_PATH                 ${CSV2RDF4LOD_PUBLISH_VIRTUOSO_SCRIPT_PATH:-"(will default to: /opt/virtuoso/scripts/vload)"}"
   echo "CSV2RDF4LOD_PUBLISH_VIRTUOSO_SPARQL_ENDPOINT             ${CSV2RDF4LOD_PUBLISH_VIRTUOSO_SPARQL_ENDPOINT:-"(will fail to describe provenance in pvload.sh)"}"

   echo "--"
   echo "CSV2RDF4LOD_PUBLISH_SPARQL_ENDPOINT                      ${CSV2RDF4LOD_PUBLISH_VIRTUOSO:-"(will default to: none)"}"
   echo "CSV2RDF4LOD_PUBLISH_SPARQL_RESULTS_DIRECTORY             ${CSV2RDF4LOD_PUBLISH_VIRTUOSO:-"(will default to: none)"}"

   if [ ${#CSV2RDF4LOD_HOME} -gt 0 ]; then
      echo "--"
      echo "see documentation for variables in:"
      echo "$CSV2RDF4LOD_HOME/bin/setup.sh"
      echo "--"
      echo "http://purl.org/twc/id/software/csv2rdf4lod"
   fi
else

   echo "clearing..."
   export CSV2RDF4LOD_HOME=""
   export CSV2RDF4LOD_BASE_URI=""
   export CSV2RDF4LOD_BASE_URI_OVERRIDE=""           

   export CSV2RDF4LOD_CONVERT_MACHINE_URI=""           
   export CSV2RDF4LOD_CONVERT_PERSON_URI=""           

   export CSV2RDF4LOD_CONVERT_DATA_ROOT=""
   export CSV2RDF4LOD_CONVERT_OMIT_RAW_LAYER=""
   export CSV2RDF4LOD_CONVERT_NUMBER_SAMPLE_ROWS=""
   export CSV2RDF4LOD_CONVERT_SAMPLE_SUBSET_ONLY=""
   export CSV2RDF4LOD_CONVERT_EXAMPLE_SUBSET_ONLY=""
   export CSV2RDF4LOD_CONVERT_DUMP_FILE_EXTENSIONS=""
   export CSV2RDF4LOD_CONVERT_PROVENANCE_GRANULAR=""
   export CSV2RDF4LOD_CONVERT_DEBUG_LEVEL=""
   # "--"

   export CSV2RDF4LOD_PUBLISH=""
   export CSV2RDF4LOD_PUBLISH_DELAY_UNTIL_ENHANCED=""
   export CSV2RDF4LOD_PUBLISH_COMPRESS=""
   export CSV2RDF4LOD_PUBLISH_OUR_SOURCE_ID=""
   export CSV2RDF4LOD_PUBLISH_OUR_DATASET_ID=""
   export CSV2RDF4LOD_PUBLISH_TTL=""
   export CSV2RDF4LOD_PUBLISH_TTL_LAYERS=""
   export CSV2RDF4LOD_PUBLISH_NT=""
   export CSV2RDF4LOD_PUBLISH_RDFXML=""
   # "--"
   export CSV2RDF4LOD_PUBLISH_SUBSET_VOID=""
   export CSV2RDF4LOD_PUBLISH_SUBSET_VOID_NAMED_GRAPH=""
   export CSV2RDF4LOD_PUBLISH_SUBSET_SAMEAS=""
   export CSV2RDF4LOD_PUBLISH_SUBSET_SAMEAS_NAMED_GRAPH=""
   export CSV2RDF4LOD_PUBLISH_SUBSET_SAMPLES=""
   # "--"
   export CSV2RDF4LOD_PUBLISH_LOD_MATERIALIZATION=""
   export CSV2RDF4LOD_PUBLISH_LOD_MATERIALIZATION_WWW_ROOT=""
   export CSV2RDF4LOD_PUBLISH_LOD_MATERIALIZATION_WRITE_FREQUENCY=""
   export CSV2RDF4LOD_PUBLISH_LOD_MATERIALIZATION_REPORT_FREQUENCY=""
   export CSV2RDF4LOD_CONCURRENCY=""
   # "--"
   export CSV2RDF4LOD_PUBLISH_TDB=""
   export CSV2RDF4LOD_PUBLISH_TDB_DIR=""

   export CSV2RDF4LOD_PUBLISH_TDB_INDIV=""

   # "--"
   export CSV2RDF4LOD_PUBLISH_4STORE=""
   export CSV2RDF4LOD_PUBLISH_4STORE_KB=""
   
   # "--"
   export CSV2RDF4LOD_PUBLISH_VIRTUOSO=""
   export CSV2RDF4LOD_PUBLISH_VIRTUOSO_HOME=""
   export CSV2RDF4LOD_PUBLISH_VIRTUOSO_ISQL_PATH=""
   export CSV2RDF4LOD_PUBLISH_VIRTUOSO_PORT=""
   export CSV2RDF4LOD_PUBLISH_VIRTUOSO_USERNAME=""
   export CSV2RDF4LOD_PUBLISH_VIRTUOSO_PASSWORD=""
   export CSV2RDF4LOD_PUBLISH_VIRTUOSO_SCRIPT_PATH=""
   export CSV2RDF4LOD_PUBLISH_VIRTUOSO_SPARQL_ENDPOINT=""

   # "--"
   export CSV2RDF4LOD_PUBLISH_SPARQL_ENDPOINT=""       
   export CSV2RDF4LOD_PUBLISH_SPARQL_RESULTS_DIRECTORY=""
   
   echo "...cleared."
   $0 # Run this script again to show that they were cleared.
fi
